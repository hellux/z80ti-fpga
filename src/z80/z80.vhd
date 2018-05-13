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
        reg_addr : in integer range 0 to 15;
        rdd, rda, rdf : in std_logic;
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
        clk : in std_logic;
        state : in state_t;
        instr : in std_logic_vector(7 downto 0);
        ctrl : out id_ctrl_t;
        cbo : out ctrlbus_out;
        cw : out ctrlword);
    end component;

    component state_machine port(
        clk, ce : in std_logic;
        cbi : in ctrlbus_in;
        flags : in std_logic_vector(7 downto 0);
        iff : in std_logic;
        ctrl : in id_ctrl_t;
        state_out : out state_t);
    end component;

    signal ir_out : std_logic_vector(7 downto 0);
    signal state : state_t;
    signal ctrl : id_ctrl_t;
    signal cw : ctrlword;

    signal addr_in : std_logic_vector(15 downto 0);
    signal pc_in : std_logic_vector(15 downto 0);
    signal pc_rd : std_logic;
    signal addr_zero : std_logic;
    signal rf_dis : std_logic_vector(15 downto 0);
    signal iff : std_logic;

    signal act_rd : std_logic;
    signal acc, act_in, act_out : std_logic_vector(7 downto 0);

    -- flags
    signal rf_f_rd : std_logic;
    signal rf_f_in, rf_f_out, alu_f_out : std_logic_vector(7 downto 0);
    signal flags : std_logic_vector(7 downto 0);
    -- pv source
    signal f_pv : std_logic;
    signal pv_src : pv_src_t;
    -- internal flag swap reg
    signal fsav_out : std_logic_vector(7 downto 0);

    -- dbus/abus src
    signal rf_do, tmp_out, dbufi_out, dbufo_out, alu_res_out, i_out, r_out
        : std_logic_vector(7 downto 0);
    signal rf_ao, tmpa_out, pc_out, dis_out, int_addr, rst_addr
        : std_logic_vector(15 downto 0);

    signal dbus : std_logic_vector(7 downto 0);
    signal abus : std_logic_vector(15 downto 0);
begin
    -- -- CONTROL SECTION -- --
    ir : reg generic map(x"ff", 8)
             port map(clk, cbi.reset, ce, cw.ir_rd, dbus, ir_out);
    id : op_decoder port map(clk, state, ir_out, ctrl, cbo, cw);
    sm : state_machine port map(clk, ce, cbi, rf_f_out, iff, ctrl, state); 

    -- -- REGISTER SECTION -- --
    rf_f_rd <= cw.f_rd or cw.f_load;
    rf_f_in <= fsav_out when cw.f_load = '1' else flags;
    rf : regfile port map(clk, cbi.reset, ce,
        cw.rf_addr, cw.rf_rdd, cw.rf_rda, rf_f_rd, cw.rf_swp,
        dbus, addr_in, rf_f_in, rf_do, rf_ao, rf_dis, acc, rf_f_out,
        dbg.regs);
    fsav : reg generic map(x"ff", 8)
               port map(clk, cbi.reset, ce, cw.f_save, rf_f_out, fsav_out);
    i : reg generic map(x"ff", 8)
            port map(clk, cbi.reset, ce, cw.i_rd, dbus, i_out);
    r : reg generic map(x"ff", 8)
            port map(clk, cbi.reset, ce, cw.r_rd, dbus, r_out);
    pc : reg generic map(x"8000", 16)
             port map(clk, cbi.reset, ce, pc_rd, pc_in, pc_out);
    pc_rd <= cw.pc_rd or cw.pc_rdh or cw.pc_rdl;
    pc_in <= dbus & pc_out(7 downto 0) when cw.pc_rdh = '1' else
             pc_out(15 downto 8) & dbus when cw.pc_rdl = '1' else
             addr_in;
    tmpa : reg generic map(x"ffff", 16)
               port map(clk, cbi.reset, ce, cw.tmpa_rd, addr_in, tmpa_out);
    dis_out <= std_logic_vector(signed(rf_dis) + resize(signed(dbus), 16));

    with cw.addr_op select addr_in <=
        std_logic_vector(unsigned(abus) + 1) when inc,
        abus                                 when none,
        std_logic_vector(unsigned(abus) - 1) when dec;
    addr_zero <= bool_sl(unsigned(addr_in) = 0);
    int_addr <= i_out & dbus(7 downto 1) & '0';
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

    iff_r : ff port map(clk, cbi.reset, ce, '1', cw.iff_next, iff);
    flags(7 downto PV_f+1) <= alu_f_out(7 downto PV_f+1);
    flags(PV_f) <= f_pv;
    flags(PV_f-1 downto 0) <= alu_f_out(PV_f-1 downto 0);
    with cw.pv_src select
        f_pv <= alu_f_out(PV_f) when alu_f,
                iff             when iff_f,
                not addr_zero   when anz_f;

    -- -- BUSES -- --
    -- mux bus input
    with cw.dbus_src select
        dbus <= (others => '-')     when none,
                (others => '0')     when zero_o,
                dbufi_out           when ext_o,
                rf_do               when rf_o,
                tmp_out             when tmp_o,
                alu_res_out         when alu_o,
                pc_out(15 downto 8) when pch_o,
                pc_out(7 downto 0)  when pcl_o,
                i_out               when i_o,
                r_out               when r_o;
    with cw.abus_src select
        abus <= (others => '-') when none,
                pc_out          when pc_o,
                rf_ao           when rf_o,
                tmpa_out        when tmpa_o,
                dis_out         when dis_o,
                int_addr        when int_o,
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

    -- debug
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
                              state.mode = int else '0';
    dbg.state <= state;
    dbg.pc <= pc_out;
    dbg.abus <= abus;
    dbg.ir <= ir_out;
    dbg.tmp <= tmp_out;
    dbg.act <= act_out;
    dbg.alu_op <= cw.alu_op;
    dbg.dbus <= dbus;
    dbg.tmpa <= tmpa_out;
    dbg.dbufo <= dbufo_out;
    dbg.dbufi <= dbufi_out;
end arch;
