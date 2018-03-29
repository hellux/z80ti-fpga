library ieee;
use ieee.std_logic_1164.all;

entity z80 is port(
    clk : buffer std_logic;
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
        op_set : in std_logic_vector(2 downto 0);
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

    signal alu_calc : std_logic;
    signal alu_result : std_logic_vector(7 downto 0);
    signal alu_op : std_logic_vector(7 downto 0);
    signal alu_set : std_logic_vector(2 downto 0);
    signal op1, op2 : std_logic_vector(7 downto 0);
    signal flags_in, flags_out : std_logic_vector(7 downto 0);
    signal tmp_rd : std_logic := '0';
    signal acc_rd : std_logic := '0';
    signal f_swp : std_logic;

    -- help signals
    signal load_acc : std_logic;
    signal load_tmp : std_logic;

    signal rf_rd, rf_wr : std_logic;
    signal rf_swp : std_logic_vector(1 downto 0);
    signal rf_addr : std_logic_vector(2 downto 0);

    signal dbus : std_logic_vector(7 downto 0) := "ZZZZZZZZ";
    signal abus : std_logic_vector(15 downto 0);
begin
    alu_comp : alu port map(clk, op1, op2, flags_in,
                            alu_op, alu_set, alu_result, flags_out);
    acc : reg_8 port map(clk, reset, acc_rd, wr=>'1', di=>dbus, do=>op1);
    tmp : reg_8 port map(clk, reset, tmp_rd, wr=>'1', di=>dbus, do=>op2);
    f : reg_pair port map(clk, reset, rd=>alu_calc, wr=>'1', swp=>f_swp,
                          di=>flags_out, do=>flags_in);
    dbus <= alu_result when alu_calc = '1' else (others => 'Z');

    rf : reg_file port map(clk, reset, rf_rd, rf_wr, rf_addr, rf_addr,
                           '0', '0', rf_swp, di=>dbus, do=>dbus);

    -- help signals
    rf_wr <= '1' when load_tmp = '1' else 'Z';
    tmp_rd <= '1' when load_tmp = '1' else 'Z';

    rf_wr <= '1' when load_acc = '1' else 'Z';
    acc_rd <= '1' when load_acc = '1' else 'Z';

    -- test
    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    process begin
        reset <= '0';
        alu_op <= x"00";
        wait for 10 ns;
        reset <= '1';
        wait for 10 ns;
        reset <= '0';
        wait for 20 ns;

        report "tb start";
        -- write to a, b
        rf_addr <= "111";
        dbus <= x"aa";
        rf_rd <= '1';
        wait for 10 ns;
        rf_addr <= "000";
        dbus <= x"bb";
        rf_rd <= '1';
        wait for 10 ns;
        rf_rd <= '0';
        dbus <= (others => 'Z');

        -- add a,b to a
        wait for 20 ns;
        rf_addr <= "111";
        rf_wr <= '1';
        acc_rd <= '1';
        wait for 10 ns;
        acc_rd <= '0';
        rf_addr <= "000";
        rf_wr <= '1';
        tmp_rd <= '1';
        wait for 10 ns;
        rf_wr <= '0';
        tmp_rd <= '0';
        alu_op <= x"80";
        alu_set <= "000";
        alu_calc <= '1';
        rf_addr <= "111";
        rf_rd <= '1';
        wait for 10 ns;
        alu_calc <= '0';
        rf_rd <= '0';
        wait for 30 ns;
        rf_addr <= "111";
        rf_wr <= '1';
        wait for 10 ns;
        rf_wr <= '0';

        wait for 20 ns;
        assert false report "tb end" severity failure;
    end process;
end arch;
