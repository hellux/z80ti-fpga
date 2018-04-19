-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type


-- entity
entity vga_motor is port ( 
     clk			: in std_logic;
	 data			: in std_logic;
	 addr			: out std_logic_vector(12 downto 0);
	 rst			: in std_logic;
	 vgaRed		    : out std_logic_vector(2 downto 0);
	 vgaGreen	    : out std_logic_vector(2 downto 0);
	 vgaBlue		: out std_logic_vector(2 downto 1);
	 Hsync		    : out std_logic;
	 Vsync		    : out std_logic);
end vga_motor;


-- architecture
architecture Behavioral of vga_motor is

  signal	Xpixel	    : integer range 0 to 800;   -- Horizontal pixel counter
  signal	Ypixel	    : integer range 0 to 521;	-- Vertical pixel counter
  signal	clk_count	: unsigned(1 downto 0);	    -- Clock divisor, to generate 25 MHz signal
  signal	vga_clk		: std_logic;			    -- One pulse width 25 MHz signal
		
  signal 	colour      : std_logic_vector(7 downto 0);	
  
  signal    blank       : std_logic;                        -- blanking signal

	
begin

  -- Clock divisor
  -- Divide system clock (100 MHz) by 4
  process(clk)
  begin
    if rising_edge(clk) then
        if rst='1' then
            clk_count <= (others => '0');
        else
	        clk_count <= clk_count + 1;
        end if;
    end if;
  end process;
	
  -- 25 MHz clock (one system clock pulse width)
  vga_clk <= '1' when (clk_count = 3) else '0';
	
	
  -- Horizontal pixel counter

  process(clk)
  begin
    if rising_edge(clk) then
        if rst='1' then
            Xpixel <= 0;     
        elsif vga_clk = '1'  then    
            if Xpixel = 799 then
                Xpixel <= 0;
            else
                Xpixel <= Xpixel + 1;
            end if;
        end if;
    end if;
  end process;
            
  
  -- Horizontal sync

  Hsync <= '0' when Xpixel > 656 and Xpixel <= 752 else
           '1';
  
  -- Vertical pixel counter

  process(clk)
  begin
    if rising_edge(clk) then   
        if rst='1' then
            Ypixel <= 0;  
        elsif vga_clk = '1' then  
            if Ypixel = 520 then
                Ypixel <= 0;
            elsif Xpixel = 799 then 
                Ypixel <= Ypixel + 1;
            end if;
        end if;
    end if;
  end process;

  -- Vertical sync

  Vsync <= '0' when Ypixel > 490 and Ypixel <= 492 else
           '1';
  
  -- Video blanking signal

  blank <= '1' when Xpixel > 640 or Ypixel > 480 else
           '0';
  
  -- Tile memory
  process (clk) begin
    if rising_edge(clk) then
      if (blank = '0') then
        if Xpixel > 576 or Ypixel > 384 then
            colour <= "00000000";
        else
            if (data = '1') then
                colour <= "11111111";
            elsif (data = '0') then
                colour <= "01001000";
            end if;
        end if;
      else
        colour <= (others => '0');
      end if;
    end if;
  end process;
  
  -- Picture memory address composite (16 = 96//6, 10 = 64//2)
  addr <= std_logic_vector(to_unsigned(Xpixel* (1/6) + 96*Ypixel * (1/6), addr'length));
  -- Set picture colour based on pos and data. (576 = 96*6, 384 = 64*6)

  -- Text: (10010110) Backgroud: (01001000) Bar: (00000000)
  -- VGA generation
    vgaRed(2) 	<= colour(7);
                   
    vgaRed(1) 	<= colour(6);
                   
    vgaRed(0) 	<= colour(5);
                   
    vgaGreen(2) <= colour(4);
                   
    vgaGreen(1) <= colour(3);
                   
    vgaGreen(0) <= colour(2);
                   
    vgaBlue(2) 	<= colour(1);
                   
    vgaBlue(1) 	<= colour(0);


end Behavioral;

