library ieee;
use ieee.std_logic_1164.all;

entity comp_tb is
end comp_tb;

architecture arch of comp_tb is
    component comp port(
        clk : in std_logic;
        btns : in std_logic_vector(4 downto 0);
        sw : in std_logic_vector(7 downto 0);
        ps2_kbd_clk : in std_logic;
        ps2_kbd_data : in std_logic;
        vga_red : out std_logic_vector(2 downto 0);
        vga_green : out std_logic_vector(2 downto 0);
        vga_blue : out std_logic_vector(2 downto 1);
        hsync, vsync : out std_logic;
        maddr : out std_logic_vector(25 downto 0);
        mdata : inout std_logic_vector(15 downto 0);
        mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
        mlb_c, mub_c : out std_logic;
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    component m45 port(
        clk : in std_logic;
        maddr : in std_logic_vector(25 downto 0);
        mdata : inout std_logic_vector(15 downto 0);
        mclk, madv_c, mcre, mce_c, moe_c, mwe_c : in std_logic;
        mlb_c, mub_c : in std_logic);
    end component;

    signal clk : std_logic;

    signal btns : std_logic_vector(4 downto 0);
    signal rst, step : std_logic;

    signal ps2_kbd_data, ps2_kbd_clk : std_logic;

    signal vga_red : std_logic_vector(2 downto 0);
    signal vga_green : std_logic_vector(2 downto 0);
    signal vga_blue : std_logic_vector(2 downto 1);
    signal hsync, vsync : std_logic;

    signal maddr : std_logic_vector(25 downto 0);
    signal mdata : std_logic_vector(15 downto 0);
    signal mclk, madv_c, mcre, mce_c, moe_c, mwe_c : std_logic;
    signal mlb_c, mub_c : std_logic;


    signal seg : std_logic_vector(7 downto 0);
    signal an : std_logic_vector(3 downto 0);
    signal sw : std_logic_vector(7 downto 0) := x"00";

    procedure press(signal button : out std_logic) is begin
        button <= '1';
        wait for 213 ns;
        button <= '0';
        wait for 124 ns;
    end procedure;
begin
    c : comp port map(clk, btns, sw,
                      ps2_kbd_clk, ps2_kbd_data,
                      vga_red, vga_green, vga_blue, hsync, vsync,
                      maddr, mdata, mclk, madv_c, mcre, mce_c,
                      moe_c, mwe_c, mlb_c, mub_c,
                      seg, an);
    m : m45 port map(clk,
                     maddr, mdata, mclk, madv_c, mcre, mce_c,
                     moe_c, mwe_c, mlb_c, mub_c);
    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    process begin
        sw(7 downto 6) <= "00";
        sw(5 downto 4) <= "00";
        sw(0) <= '0'; -- do not break on addr
        btns <= (others => '0');

        press(btns(1)); -- reset

        -- wait
        wait for 1000 ms;
    end process;
end arch;
