library ieee;
use ieee.std_logic_1164.all;            -- basic ieee library
use ieee.numeric_std.all;               -- ieee library for the unsigned type


-- entity
entity vga_motor is port ( 
     clk			: in std_logic;
	 data			: in std_logic_vector(7 downto 0);
	 addr			: out std_logic_vector(9 downto 0);
	 rst			: in std_logic;
	 vgaRed		    : out std_logic_vector(2 downto 0);
	 vgaGreen	    : out std_logic_vector(2 downto 0);
	 vgaBlue		: out std_logic_vector(2 downto 1);
	 Hsync		    : out std_logic;
	 Vsync		    : out std_logic);
end vga_motor;


-- architecture
architecture Behavioral of vga_motor is

  signal	Xpixel	    : unsigned(9 downto 0);     -- Horizontal pixel counter
  signal	Ypixel	    : unsigned(9 downto 0);		-- Vertical pixel counter
  signal	clk_count	: unsigned(1 downto 0);	    -- Clock divisor, to generate 25 MHz signal
  signal	vga_clk		: std_logic;			    -- One pulse width 25 MHz signal
		
  signal 	colour      : std_logic_vector(7 downto 0);	
  
  signal    blank       : std_logic;                        -- blanking signal

	
    signal current_pixel : std_logic;
    signal pixel_index : integer range 0 to 6143;
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
            Xpixel <= (others => '0');     
        elsif vga_clk = '1'  then    
            if Xpixel = 799 then
                Xpixel <= (others => '0');
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
            Ypixel <= (others => '0');  
        elsif vga_clk = '1' then  
            if Ypixel = 520 then
                Ypixel <= (others => '0');
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
  -- varför klockad process? blir en puls fördröjning
  process (clk) begin
    if rising_edge(clk) then
      if (blank = '0') then
        if Xpixel > 576 or Ypixel > 384 then
            colour <= "00000000";
        else
            if (current_pixel = '1') then
                colour <= "11111111";
            elsif (current_pixel = '0') then
                colour <= "01001000";
            end if;
        end if;
      else
        colour <= (others => '0');
      end if;
    end if;
  end process;
  
  -- Picture memory address composite (16 = 96//6, 10 = 64//2)
    current_pixel <= data(pixel_index rem 8);
    pixel_index <= to_integer(xpixel/6) + to_integer(ypixel*24);
    addr <= std_logic_vector(to_unsigned(pixel_index/8, addr'length));
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

