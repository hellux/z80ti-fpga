library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.cmp_comm.all;
use work.util.all;

entity z80 is port(
    clk, ce : in std_logic;
    cbi : in ctrlbus_in;
    cbo : out ctrlbus_out;
    addr : out std_logic_vector(15 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0);
-- dbd stat
    dbg : out dbg_z80_t);
end z80;

architecture arch of z80 is
    component ff port(
        clk, rst, ce : in std_logic;
        rd : in std_logic;
        di : in std_logic;
        do : out std_logic);
    end component;

    component reg generic(init : std_logic_vector; size : integer); port(
        clk, rst, ce : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;

    component alu port(
        op1, op2 : in std_logic_vector(7 downto 0);
        flags_in : in std_logic_vector(7 downto 0);
        op : in instr_t;
        bit_select : in integer range 0 to 7;
        result, flags_out : out std_logic_vector(7 downto 0));
    end component;

    component regfile port(
        clk, rst, ce : in std_logic;
        reg_addr : in std_logic_vector(4 downto 0);
        rp_addr : in std_logic_vector(3 downto 0);
        rdd, rda, rdf, ldpc : in std_logic;
        swp : in rf_swap_t;
        data_in: in std_logic_vector(7 downto 0);
        addr_in : in std_logic_vector(15 downto 0);
        f_in : in std_logic_vector(7 downto 0);
        data_out: out std_logic_vector(7 downto 0);
        addr_out, addr_out_dis : out std_logic_vector(15 downto 0);
        a_out, f_out : out std_logic_vector(7 downto 0);
        dbg_regs : out dbg_regs_t);
    end component;

    component op_decoder port(
        cpu_state : in state_t;
        iff : in std_logic;
        instr : in std_logic_vector(7 downto 0);
        flags : in std_logic_vector(7 downto 0);
        ctrl : out id_ctrl_t;
        cbo : out ctrlbus_out;
        cw : out ctrlword;
        dbg : out dbg_id_t);
    end component;

    component state_machine port(
        clk, ce : in std_logic;
        cbi : in ctrlbus_in;
        ctrl : in id_ctrl_t;
        iff : in std_logic;
        ir_rd : in std_logic;
        instr : in std_logic_vector(7 downto 0);
        state_out : out state_t);
    end component;

    signal state : state_t;
    signal ctrl : id_ctrl_t;
    signal cw : ctrlword;
    signal ir_out : std_logic_vector(7 downto 0);

    signal addr_in : std_logic_vector(15 downto 0);
    signal addr_not_zero : std_logic;
    signal rf_dis : std_logic_vector(15 downto 0);
    signal iff : std_logic;

    signal act_rd : std_logic;
    signal acc, act_in, act_out : std_logic_vector(7 downto 0);
    -- flags
    signal rf_f_out, alu_f_out : std_logic_vector(7 downto 0);
    signal flags : std_logic_vector(7 downto 0);
    -- pv source
    signal f_pv : std_logic;

    -- dbus/abus src
    signal rf_do, tmp_out, dbufi_out, dbufo_out, alu_res_out
        : std_logic_vector(7 downto 0);
    signal rf_ao, dis_out, rst_addr
        : std_logic_vector(15 downto 0);

    signal dbus : std_logic_vector(7 downto 0);
    signal abus : std_logic_vector(15 downto 0);
begin
    -- -- CONTROL SECTION -- --
    ir : reg generic map(x"ff", 8)
             port map(clk, cbi.reset, ce, cw.ir_rd, dbus, ir_out);
    id : op_decoder port map(state, iff, ir_out, rf_f_out,
                             ctrl, cbo, cw,
                             dbg.id);
    sm : state_machine port map(clk, ce, cbi, ctrl,
                                iff, cw.ir_rd, ir_out, state); 
    iff_r : ff port map(clk, cbi.reset, ce, '1', cw.iff_next, iff);

    -- -- REGISTER SECTION -- --
    rf : regfile port map(clk, cbi.reset, ce,
        cw.rf_daddr, cw.rf_aaddr, cw.rf_rdd, cw.rf_rda, cw.f_rd, cw.ldpc,
        cw.rf_swp,
        dbus, addr_in, flags, rf_do, rf_ao, rf_dis, acc, rf_f_out,
        dbg.regs);
    dis_out <= std_logic_vector(signed(rf_dis) + resize(signed(dbus), 16));

    with cw.addr_op select addr_in <=
        std_logic_vector(unsigned(abus) + 1) when inc,
        abus                                 when none,
        std_logic_vector(unsigned(abus) - 1) when dec;
    addr_not_zero <= bool_sl(unsigned(addr_in) /= 0);
    rst_addr <= x"00" & "00" & cw.rst_addr & "000";

    -- -- ALU section -- --
    alu_comp : alu port map(act_out, tmp_out, rf_f_out,
                            cw.alu_op, cw.alu_bs,
                            alu_res_out, alu_f_out);
    act : reg generic map(x"ff", 8)
              port map(clk, cbi.reset, ce, act_rd, act_in, act_out);
    act_rd <= cw.act_rd or cw.act_rd_dbus;
    act_in <= dbus when cw.act_rd_dbus = '1' else acc;
    tmp : reg generic map(x"ff", 8)
              port map(clk, cbi.reset, ce, cw.tmp_rd, dbus, tmp_out);

    with cw.pv_src select
        f_pv <= alu_f_out(PV_f) when alu_f,
                iff             when iff_f,
                addr_not_zero   when anz_f;
    flags(7 downto PV_f+1) <= alu_f_out(7 downto PV_f+1);
    flags(PV_f) <= f_pv;
    flags(PV_f-1 downto 0) <= alu_f_out(PV_f-1 downto 0);

    -- -- BUSES -- --
    -- mux bus input
    with cw.dbus_src select
        dbus <= (others => '-')     when none,
                (others => '0')     when zero_o,
                dbufi_out           when ext_o,
                rf_do               when rf_o,
                tmp_out             when tmp_o,
                alu_res_out         when alu_o;
    with cw.abus_src select
        abus <= (others => '-') when none,
                rf_ao           when rf_o,
                dis_out         when dis_o,
                rst_addr        when rst_o;
    -- buffer dbus both ways
    dbufi : reg generic map(x"ff", 8)
                port map(clk, cbi.reset, ce, cw.data_rdi, data_in, dbufi_out);
    dbufo : reg generic map(x"ff", 8)
                port map(clk, cbi.reset, ce, cw.data_rdo, dbus, dbufo_out);
    data_out <= dbufo_out when cw.data_wro = '1' else x"00";
    -- buffer abus outgoing
    abuf : reg generic map(x"ffff", 16)
               port map(clk, cbi.reset, ce, cw.addr_rd, abus, addr);

    -- bind signals for debugging
    delay_end_start : process(clk) begin
        if rising_edge(clk) then
            if ce = '1' then
                dbg.instr_start <= ctrl.instr_end;
                dbg.cycle_start <= ctrl.cycle_end;
            end if;
        end if;
    end process;
    dbg.int_start <= '1' when state.t = t1 and
                              state.m = m1 and
                              state.mode = interrupt else '0';
    dbg.state <= state;
    dbg.abus <= abus;
    dbg.ir <= ir_out;
    dbg.tmp <= tmp_out;
    dbg.act <= act_out;
    dbg.alu_op <= cw.alu_op;
    dbg.iff <= iff;
    dbg.dbus <= dbus;
    dbg.dbufo <= dbufo_out;
    dbg.dbufi <= dbufi_out;
end arch;
