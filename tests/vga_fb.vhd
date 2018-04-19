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
    
    component pict_mem is port (
        clk, rst : in std_logic;
        rd, wl : in std_logic;
        di : in std_logic_vector(7 downto 0);
        do_vga: out std_logic;
        do_lcd: out std_logic_vector(7 downto 0);
        addr_lcd : in std_logic_vector(12 downto 0);
        addr_vga : in std_logic_vector(12 downto 0));
    end component;
    
    signal counter : unsigned(12 downto 0);
    
    signal index : integer := 0;
    
    signal rd       : std_logic;
    signal wl       : std_logic;
    signal do_vga   : std_logic;
    signal do_lcd   : std_logic_vector(7 downto 0);
    signal addr_rd	: std_logic_vector(12 downto 0);
    signal addr_wr  : std_logic_vector(12 downto 0);
    signal di       : std_logic_vector(7 downto 0);
    
begin
 
    vga : vga_motor port map(
        clk, do_vga, addr_wr, btns(1), vgaRed, vgaGreen, vgaBlue, Hsync, Vsync);
        
    mem : pict_mem port map(
        clk, btns(1), rd, wl, di, do_vga, do_lcd, addr_rd, addr_wr);
        
    wl <= '1';
    addr_rd <= std_logic_vector(counter);   
    --addr_wr <= std_logic_vector(counter);
    process(clk) begin
        if rising_edge(clk) then
            if counter >= 0 and counter < 2000 then
                rd <= '1';
                di <= "11111111";
                
                counter <= counter + 1;
            elsif counter < 6144 then
                rd <= '0';
                counter <= counter + 1;
            end if;
        end if;
    end process;   
    
end arch;
