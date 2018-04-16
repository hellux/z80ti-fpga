library ieee;
use ieee.std_logic_1164.all;

entity vga_motor_tb is
end vga_motor_tb;

architecture arch of vga_motor_tb is
    component vga_motor is
    port (clk			: in std_logic;
	    data			: in std_logic;
	    addr			: out unsigned(12 downto 0);
	    rst			    : in std_logic;
	    vgaRed		    : out std_logic_vector(2 downto 0);
	    vgaGreen	    : out std_logic_vector(2 downto 0);
	    vgaBlue		    : out std_logic_vector(2 downto 1);
	    Hsync		    : out std_logic;
	    Vsync		    : out std_logic);
end vga_motor;

    signal clk, rst : std_logic;
    
begin
    vga : vga_motor port map(
        clk, data, addr, rst, vgaRed, vgaGreen, vgaBlue, Hsync, Vsync);
    
    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    process begin
        rst <= '0';
        wait for 1515 ns;
        rst <= '1';
        wait for 348 ns;
        rst <= '0';
        wait for 100 us;
        
        
        data <= '1';
        wait for 30 ns;
        data <= '0';
        wait for 10 ns;
        data <= '1';
        wait for 10 ns;
        data <= '0';
        wait for 10 ns;
        data <= '1';
        wait for 10 ns;
        data <= '0';
        wait for 50 ns;
        data <= '1';
        wait for 20 ns;
        data <= '0';
        wait for 10 ns;
        data <= '1';
        wait for 10 ns;
        data <= '0';
        wait for 10 ns;
        data <= '1';
        wait for 10 ns;
        
        
    end process;
end arch;
