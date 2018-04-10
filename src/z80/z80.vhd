library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity z80 is port(
    clk : in std_logic; --(buffer only for testing)
    cbi : in ctrlbus_in; -- samee
    cbo : out ctrlbus_out;
    addr : out std_logic_vector(15 downto 0);
    data : inout std_logic_vector(7 downto 0));
end z80;

architecture arch of z80 is
    component reg_8 port(
        clk, rst : in std_logic;
        rd, wr : in std_logic;
        di : in std_logic_vector(7 downto 0);
        do : out std_logic_vector(7 downto 0));
    end component;

    component reg_16 port(
        clk, rst : in std_logic;
        rd, wr : in std_logic;
        di : in std_logic_vector(15 downto 0);
        do : out std_logic_vector(15 downto 0));
    end component;

    component buf8 port(
        clk, rst : in std_logic;
        rd, wr : in std_logic;
        di : in std_logic_vector(7 downto 0);
        do : out std_logic_vector(7 downto 0));
    end component;

    component buf16 port(
        clk, rst : in std_logic;
        rd, wr : in std_logic;
        di : in std_logic_vector(15 downto 0);
        do : out std_logic_vector(15 downto 0));
    end component;

    component alu port(
        clk : in std_logic;
        op1, op2 : in std_logic_vector(7 downto 0);
        flags_in : in std_logic_vector(7 downto 0);
        op : in instr_t;
        bit_select : in integer range 0 to 7;
        result, flags_out : out std_logic_vector(7 downto 0));
    end component;

    component regfile port(
        clk, rst : in std_logic;
        reg_addr : in integer range 0 to 15;
        rdd, rda, rdf : in std_logic;
        wrd, wra: in std_logic;
        swp : in rf_swap_t;
        data : inout std_logic_vector(7 downto 0);
        addr : in std_logic_vector(15 downto 0);
        f_in : in std_logic_vector(7 downto 0);
        addr_out, addr_out_dis : out std_logic_vector(15 downto 0);
        a_out, f_out : out std_logic_vector(7 downto 0);
        dbg_regs : out dbg_regs_t);
    end component;

    component op_decoder port(
        clk : in std_logic;
        cbi : in ctrlbus_in;
        cbo : out ctrlbus_out;
        instr, flags : in std_logic_vector(7 downto 0);
        cw : out ctrlword);
    end component;

    signal instr : std_logic_vector(7 downto 0);
    signal addr_in, pc_out : std_logic_vector(15 downto 0);
    signal cw : ctrlword;

    signal rf_disp_addr, disp_addr : std_logic_vector(15 downto 0);

    signal alu_result : std_logic_vector(7 downto 0);
    signal acc, op1, tmp_do : std_logic_vector(7 downto 0);
    signal flags_in, flags_out : std_logic_vector(7 downto 0); -- rel to alu

    signal dbus : std_logic_vector(7 downto 0) := "ZZZZZZZZ";
    signal abus : std_logic_vector(15 downto 0);

    -- debug
    signal dbg_regs : dbg_regs_t;
begin
    -- -- CONTROL SECTION -- --
    ir : reg_8 port map(clk, cbi.reset, cw.ir_rd, '1', dbus, instr);
    id : op_decoder port map(clk, cbi, cbo, instr, flags_in, cw);

    -- -- REGISTER SECTION -- --
    rf : regfile port map(clk, cbi.reset,
        cw.rf_addr, cw.rf_rdd, cw.rf_rda, cw.f_rd,
                    cw.rf_wrd, cw.rf_wra, cw.rf_swp,
        dbus, addr_in, flags_out, abus, rf_disp_addr, acc, flags_in,
        dbg_regs);
    pc : reg_16 port map(clk, cbi.reset, cw.pc_rd, '1', addr_in, pc_out);
    abus <= pc_out when cw.pc_wr = '1' else (others => 'Z');
    disp_addr <= pc_out when cw.pc_disp = '1' else rf_disp_addr;
    with cw.addr_in_op select addr_in <=
        std_logic_vector(unsigned(abus) + 1) when inc,
        abus                                 when none,
        std_logic_vector(unsigned(abus) - 1) when dec;
    abus <=
        std_logic_vector(signed(disp_addr) + resize(signed(dbus), 16))
            when cw.dis_wr = '1' else
        (others => 'Z');


    -- -- ALU section -- --
    alu_comp : alu port map(clk, op1, tmp_do, flags_in, cw.alu_op, cw.alu_bs,
                            alu_result, flags_out);
    act : reg_8 port map(clk, cbi.reset, cw.act_rd, '1', acc, op1);
    tmp : reg_8 port map(clk, cbi.reset, cw.tmp_rd, '1', dbus, tmp_do);
    dbus <= tmp_do when cw.tmp_wr = '1' else (others => 'Z');
    dbus <= alu_result when cw.alu_wr = '1' else (others => 'Z');


    -- -- BUSES -- --
    -- data bus, buffer both ways
    dbufi : buf8 port map(clk, cbi.reset, cw.data_rdi, cw.data_wri,
                             data, dbus);
    dbufo : buf8 port map(clk, cbi.reset, cw.data_rdo, cw.data_wro,
                             dbus, data);

    -- addr bus, buffer outgoing
    abuf : buf16 port map(clk, cbi.reset, cw.addr_rd, cw.addr_wr,
                              abus, addr);
end arch;
