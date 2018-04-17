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
	    addr    	    : out std_logic_vector(12 downto 0);
	    rst			    : in std_logic;
	    vgaRed		    : out std_logic_vector(2 downto 0);
	    vgaGreen	    : out std_logic_vector(2 downto 0);
	    vgaBlue		    : out std_logic_vector(2 downto 1);
	    Hsync		    : out std_logic;
	    Vsync		    : out std_logic);
    end component;
    
    component pict_mem is
    port (clk		: in std_logic;
         di     	: in std_logic;
         do     	: out std_logic;
         addr_in		: in std_logic_vector(12 downto 0);
         addr_vga		: in std_logic_vector(12 downto 0));    
    end component;
    
    signal addr_in : std_logic_vector(12 downto 0);
    signal addr_vga : std_logic_vector(12 downto 0);
    signal addr_f : unsigned(12 downto 0);
    
    signal data : std_logic;
    signal index : integer := 0;
    
    signal mem_di : std_logic;
    signal mem_do : std_logic;
    
begin
 
    vga : vga_motor port map(
        clk, data, addr_vga, btns(1), vgaRed, vgaGreen, vgaBlue, Hsync, Vsync);
        
    mem : pict_mem port map(
        clk, mem_di, mem_do, addr_in, addr_vga);
        
   
    addr_in <= std_logic_vector(addr_f);   
    process(clk) begin
        if rising_edge(clk) then
            if addr_f >= 0 and addr_f < 2000 then
                mem_di <= '1';
                addr_f <= addr_f + 1;
            elsif addr_f < 6144 then
                addr_f <= addr_f + 1;
            end if;
        end if;
    end process;
    
    
    data <= mem_do;
   
    
end arch;
