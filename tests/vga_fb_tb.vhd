-- TestBench register swap

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY vga_fb_tb IS
END vga_fb_tb;

architecture Behavioral of vga_fb_tb is
    component vga_fb is port(
    clk         : in std_logic;
    btns        : in std_logic_vector(4 downto 0);
    vgaRed		: out std_logic_vector(2 downto 0);
	vgaGreen	: out std_logic_vector(2 downto 0);
	vgaBlue		: out std_logic_vector(2 downto 1);
	Hsync		: out std_logic;
	Vsync		: out std_logic);
    end component;

    --Store index for which register to write/read from
    signal clk      : std_logic;
    signal btns     : std_logic_vector(4 downto 0);
    
    signal vgaRed, vgaGreen : std_logic_vector(2 downto 0);
    signal vgaBlue          : std_logic_vector(2 downto 1);
    signal Hsync, Vsync     : std_logic;
    
begin
    
    fuck : vga_fb port map(
        clk, btns, vgaRed, vgaGreen, vgaBlue, Hsync, Vsync);
        
process begin
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
end process;

process begin
    btns <= (1 => '1', others => '0');
    wait for 20 ns;
    btns <= (others => '0');
    wait for 50 ms ;
end process;

end Behavioral;
