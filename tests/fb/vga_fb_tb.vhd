library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_fb_tb is
end vga_fb_tb;

architecture Behavioral of vga_fb_tb is
    component vga_fb is port(
        clk : in std_logic;
        vgaRed : out std_logic_vector(2 downto 0);
        vgaGreen : out std_logic_vector(2 downto 0);
        vgaBlue : out std_logic_vector(2 downto 1);
        Hsync : out std_logic;
        Vsync : out std_logic);
    end component;

    signal clk : std_logic;
    
    signal vgaRed, vgaGreen : std_logic_vector(2 downto 0);
    signal vgaBlue : std_logic_vector(2 downto 1);
    signal Hsync, Vsync : std_logic;
begin
    fb : vga_fb port map(clk, vgaRed, vgaGreen, vgaBlue, Hsync, Vsync);

    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;
end Behavioral;
