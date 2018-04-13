-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            
use IEEE.NUMERIC_STD.ALL;


-- entity
entity vga_motor is
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


-- architecture
architecture Behavioral of vga_motor is

  signal	Xpixel	    : unsigned(9 downto 0);     -- Horizontal pixel counter
  signal	Ypixel	    : unsigned(9 downto 0);		-- Vertical pixel counter

    -- Background (10010110) 	Text(01001000) Bar(00000000)
  signal 	pixel_colour	: std_logic_vector(1 downto 0);  	
  signal    blank       : std_logic;
  signal    pic_mem    : std_logic_vector(6143 downto 0);
	
begin
	
  -- Horizontal pixel counter
    process(clk) begin
        if rising_edge(clk) then
            if rst='1' then
	            Xpixel <= (others => '0');
            elsif (Xpixel > 800) then
	            Xpixel <= "00000000";
	        else
	            Xpixel <= Xpixel + 1;
            end if;
        end if;
    end process;

  -- Horizontal sync
    Hsync <= '1' when Xpixel <= 656 and Xpixel >= 752 else '0';
 
  
  -- Vertical pixel counter
    process(clk) begin
        if rising_edge(clk) then
            if rst='1' then
	            Ypixel <= (others => '0');
            elsif (Ypixel > 521) then
	            Ypixel <= "00000000";
	        elsif (Xpixel = 800) then
	            Ypixel <= Ypixel + 1;
            end if;
        end if;
    end process;
 
  -- Vertical sync
     Vsync <= '1' when Ypixel <= 490 and Ypixel >= 492 else '0';

  -- Blank signal
    blank <= '1' when Xpixel > 640 or Ypixel > 480 else '0'; 
             
    
    pixel_colour <= '0' & (pic_mem(96* to_integer(Ypixel)/6 + to_integer(Xpixel)/6)) when
                    Xpixel < 96*6 and Ypixel <= 64*6 else "11";

  -- Background: (00), (10010110) Text: (01), (01001000) Bar: (11),(00000000)
  -- VGA generation
    vgaRed(2) 	<= '1' when pixel_colour = "00" else 
                   '0' when pixel_colour = "01" else
                   '0' when pixel_colour = "11";
                   
    vgaRed(1) 	<= '0' when pixel_colour = "00" else 
                   '1' when pixel_colour = "01" else
                   '0' when pixel_colour = "11";
                   
    vgaRed(0) 	<= '0' when pixel_colour = "00" else 
                   '0' when pixel_colour = "01" else
                   '0' when pixel_colour = "11";
                   
    vgaGreen(2) <= '1' when pixel_colour = "00" else 
                   '0' when pixel_colour = "01" else
                   '0' when pixel_colour = "11";
                   
    vgaGreen(1) <= '0' when pixel_colour = "00" else 
                   '1' when pixel_colour = "01" else
                   '0' when pixel_colour = "11";
                   
    vgaGreen(0) <= '1' when pixel_colour = "00" else 
                   '0' when pixel_colour = "01" else
                   '0' when pixel_colour = "11";
                   
    vgaBlue(2) 	<= '1' when pixel_colour = "00" else 
                   '0' when pixel_colour = "01" else
                   '0' when pixel_colour = "11";
                   
    vgaBlue(1) 	<= '0' when pixel_colour = "00" else 
                   '0' when pixel_colour = "01" else
                   '0' when pixel_colour = "11";

end Behavioral;

