library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_fb is port(
    clk : in std_logic;
    vgaRed : out std_logic_vector(2 downto 0);
	vgaGreen : out std_logic_vector(2 downto 0);
	vgaBlue : out std_logic_vector(2 downto 1);
	Hsync : out std_logic;
	Vsync : out std_logic);
end vga_fb;

architecture arch of vga_fb is
    component clkgen generic(div : natural); port(
        clk : in std_logic;
        clk_out : out std_logic);
    end component;

    component vga_motor is port(
         clk, ce : in std_logic;
         data : in std_logic;
         rst : in std_logic;
         x : out std_logic_vector(6 downto 0);
         y : out std_logic_vector(5 downto 0);
         vgaRed	: out std_logic_vector(2 downto 0);
         vgaGreen : out std_logic_vector(2 downto 0);
         vgaBlue : out std_logic_vector(2 downto 1);
         Hsync : out std_logic;
         Vsync : out std_logic);
    end component;

    signal counter : unsigned(12 downto 0);
    signal index : integer := 0;
    
    signal rst, clk_vga : std_logic;
    signal x : std_logic_vector(6 downto 0);
    signal y : std_logic_vector(5 downto 0);
    signal gmem_vga_data : std_logic;
begin
    gen_vga : clkgen generic map(4) port map(clk, clk_vga);

    gmem_vga_data <= '1' when x = "0000000" or
                              x = "1011111" or
                              y = "000000" or
                              y = "111111" else '0';
    rst <= '0';
    vga : vga_motor port map(clk, clk_vga, gmem_vga_data, rst, x, y,
                             vgaRed, vgaGreen, vgaBlue, Hsync, Vsync);
end arch;
