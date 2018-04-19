library ieee;
use ieee.std_logic_1164.all;

entity comp_tb is
end comp_tb;

architecture arch of comp_tb is
    component comp port(
        clk : in std_logic;
        btns : in std_logic_vector(4 downto 0);
        seg, led : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0);
        vga_red : out std_logic_vector(2 downto 0);
        vga_green : out std_logic_vector(2 downto 0);
        vga_blue : out std_logic_vector(2 downto 1);
        hsync, vsync : out std_logic);
    end component;
    signal clk, rst : std_logic;
    signal seg, led : std_logic_vector(7 downto 0);
    signal an : std_logic_vector(3 downto 0);
    signal sw : std_logic_vector(7 downto 0) := x"00";
    signal btns : std_logic_vector(4 downto 0);
    signal vga_red : std_logic_vector(2 downto 0);
    signal vga_green : std_logic_vector(2 downto 0);
    signal vga_blue : std_logic_vector(2 downto 1);
    signal hsync, vsync : std_logic;
begin
    c : comp port map(clk, btns, seg, led, an,
                      vga_red, vga_green, vga_blue, hsync, vsync);
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
        wait for 25 ns;
        rst <= '0';
        wait for 1000 us;
    end process;
end arch;
