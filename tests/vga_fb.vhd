library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type

entity vga_fb is port (
    clk         : in std_logic;
    btns        : in std_logic_vector(4 downto 0);
    vgaRed		: out std_logic_vector(2 downto 0);
	vgaGreen	: out std_logic_vector(2 downto 0);
	vgaBlue		: out std_logic_vector(2 downto 1);
	Hsync		: out std_logic;
	Vsync		: out std_logic);
end vga_fb;

architecture arch of vga_fb is
    component vga_motor is
    port (clk			: in std_logic;
	    data			: in std_logic;
	    addr			: out std_logic_vector(12 downto 0);
	    rst			    : in std_logic;
	    vgaRed		    : out std_logic_vector(2 downto 0);
	    vgaGreen	    : out std_logic_vector(2 downto 0);
	    vgaBlue		    : out std_logic_vector(2 downto 1);
	    Hsync		    : out std_logic;
	    Vsync		    : out std_logic);
    end component;
    
    signal addr : std_logic_vector(12 downto 0);
    
    signal data : std_logic;
    signal index : integer := 0;
    constant pattern : std_logic_vector(9 downto 0) := "0000011111";
    
begin
 
    vga : vga_motor port map(
        clk, data, addr, btns(1), vgaRed, vgaGreen, vgaBlue, Hsync, Vsync);

     process(clk) begin
        if rising_edge(clk) then
            if index = 9 then
                index <= 0;
            else
                index <= index + 1;
            end if;
        end if;
    end process;

    data <= pattern(index);
    
    
end arch;
