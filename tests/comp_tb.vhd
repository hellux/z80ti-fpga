library ieee;
use ieee.std_logic_1164.all;

entity comp_tb is
end comp_tb;

architecture arch of comp_tb is
    component comp port(
        clk : in std_logic;
    -- buttons
        btns : in std_logic_vector(4 downto 0);
    -- keyboard
        ps2_kbd_clk : in std_logic;
        ps2_kbd_data : in std_logic;
    -- vga monitor
        vga_red : out std_logic_vector(2 downto 0);
        vga_green : out std_logic_vector(2 downto 0);
        vga_blue : out std_logic_vector(2 downto 1);
        hsync, vsync : out std_logic;
    -- memory
        maddr : out std_logic_vector(26 downto 0);
        mdata : inout std_logic_vector(15 downto 0);
        mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
        mlb_c, mub_c : out std_logic;
        mwait : in std_logic;
    -- 7 segment, led
        seg, led : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    component m45 port(
        clk : in std_logic;
        maddr : in std_logic_vector(26 downto 0);
        mdata : inout std_logic_vector(15 downto 0);
        mclk, madv_c, mcre, mce_c, moe_c, mwe_c : in std_logic;
        mlb_c, mub_c : in std_logic;
        mwait : out std_logic);
    end component;

    signal clk, rst : std_logic;

    signal btns : std_logic_vector(4 downto 0);

    signal ps2_kbd_data, ps2_kbd_clk : std_logic;

    signal vga_red : std_logic_vector(2 downto 0);
    signal vga_green : std_logic_vector(2 downto 0);
    signal vga_blue : std_logic_vector(2 downto 1);
    signal hsync, vsync : std_logic;

    signal maddr : std_logic_vector(26 downto 0);
    signal mdata : std_logic_vector(15 downto 0);
    signal mclk, madv_c, mcre, mce_c, moe_c, mwe_c : std_logic;
    signal mlb_c, mub_c : std_logic;
    signal mwait : std_logic;

    signal seg, led : std_logic_vector(7 downto 0);
    signal an : std_logic_vector(3 downto 0);
    signal sw : std_logic_vector(7 downto 0) := x"00";
begin
    c : comp port map(clk, btns,
                      ps2_kbd_clk, ps2_kbd_data,
                      vga_red, vga_green, vga_blue, hsync, vsync,
                      maddr, mdata, mclk, madv_c, mcre, mce_c,
                      moe_c, mwe_c, mlb_c, mub_c, mwait,
                      seg, led, an);
    m : m45 port map(clk,
                     maddr, mdata, mclk, madv_c, mcre, mce_c,
                     moe_c, mwe_c, mlb_c, mub_c, mwait);
    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    btns <= (1 => rst, others => '0');
    process begin
        rst <= '0';
        wait for 10 ns;
        rst <= '1';
        wait for 500 ns;
        rst <= '0';
        wait for 160 us;
        rst <= '1';
        wait for 500 ns;
        rst <= '0';
        wait for 1000 us;
    end process;
end arch;
