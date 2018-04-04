library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80comm.all;

entity z80 is port(
    clk : buffer std_logic; --(buffer only for testing)
    -- use vector for control bus?
    -- system control
    m1, mreq, iorq, rd, wr, rfsh: out std_logic;
    -- cpu control
    halt : out std_logic;
    wt, int, nmi, reset : buffer std_logic;
    -- cpu bus control
    busrq : in std_logic;
    busack : out std_logic;
    -- buses 
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
        di : in std_logic_vector(7 downto 0);
        do : out std_logic_vector(7 downto 0));
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

    component reg_pair port(
        clk, rst : in std_logic;
        rd, wr, swp : in std_logic;
        di : in std_logic_vector(7 downto 0);
        do : out std_logic_vector(7 downto 0));
    end component;

    component alu port(
        clk : in std_logic;
        op1, op2 : in std_logic_vector(7 downto 0);
        flags_in : in std_logic_vector(7 downto 0);
        op : in std_logic_vector(7 downto 0);
        op_set : in instr_set_t;
        result, flags_out : out std_logic_vector(7 downto 0));
    end component;

    component reg_file port(
        clk : in std_logic;
        rst : in std_logic;
        rd, wr : in std_logic;
        rd_adr, wr_adr : in std_logic_vector(2 downto 0);
        rd_f, wr_f : in std_logic;
        swp : in std_logic_vector(1 downto 0);
        di : in std_logic_vector(7 downto 0);
        do : out std_logic_vector(7 downto 0));
    end component;

    component op_decoder port(
        clk, rst : in std_logic;
        instr : in std_logic_vector(7 downto 0);
        cw : out ctrlword);
    end component;

    signal alu_result : std_logic_vector(7 downto 0);
    signal op1, op2 : std_logic_vector(7 downto 0);
    signal flags_in, flags_out : std_logic_vector(7 downto 0);

    signal instr : std_logic_vector(7 downto 0);
    signal addr_incr : std_logic_vector(15 downto 0);
    signal cw : ctrlword;

    signal rd_data, wr_data : std_logic;
    signal rd_addr, wr_addr : std_logic;
    signal dbus : std_logic_vector(7 downto 0) := "ZZZZZZZZ";
    signal abus : std_logic_vector(15 downto 0);
begin
    -- -- ALU section -- --
    alu_comp : alu port map(clk, op1, op2, flags_in,
                            cw.alu_op, main, alu_result, flags_out);
    -- TODO use f in reg_file, need special bus. a needs parallel bus as well
    act : reg_8 port map(clk, reset, cw.act_rd, wr=>'1', di=>dbus, do=>op1);
    tmp : reg_8 port map(clk, reset, cw.tmp_rd, wr=>'1', di=>dbus, do=>op2);
    f : reg_pair port map(clk, reset, rd=>cw.f_rd, wr=>'1', swp=>'0',
                          di=>flags_out, do=>flags_in);
    dbus <= alu_result when cw.alu_wr = '1' else (others => 'Z');


    -- -- REGISTER SECTION -- --
    -- TODO create larger address, bus for abus, flags, act
    --rf : reg_file port map(clk, reset,
    --                     cw.rf_rdd, cw.rf_wrd, cw.rf_addr, cw.rf_addr,
    --                     '0', '0', cw.rf_swp, dbus, dbus);


    -- -- CONTROL SECTION -- --
    ir : reg_8 port map(clk, reset, cw.ir_rd, '1', dbus, instr);
    id : op_decoder port map(clk, reset, instr, cw);
    --pc : reg_16 port map(clk, reset, cw.pc_rd, cw.pc_wr, addr_incr, abus);
    addr_incr <= std_logic_vector(unsigned(abus) + 1);

    -- -- BUSES -- --

    -- data bus, buffer when outgoing
    dbus_buf : buf8 port map(clk, reset, rd_data, wr_data, dbus, data);
    dbus <= data;

    -- addr bus, buffered
    abus_buf : buf16 port map(clk, reset, rd_addr, wr_addr, abus, addr);


    -- -- TESTING -- --
    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    process begin
        dbus <= x"80";
        reset <= '0';
        wait for 10 ns;
        reset <= '1';
        wait for 10 ns;
        reset <= '0';
        wait for 20 ns;

        report "tb start";
        wait for 200 ns;
        assert false report "tb end" severity failure;
    end process;
end arch;
