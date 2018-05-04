library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_motor is port ( 
     clk : in std_logic;
	 data : in std_logic;
	 rst : in std_logic;
     x : out std_logic_vector(6 downto 0);
     y : out std_logic_vector(5 downto 0);
	 vgaRed	: out std_logic_vector(2 downto 0);
	 vgaGreen : out std_logic_vector(2 downto 0);
	 vgaBlue : out std_logic_vector(2 downto 1);
	 Hsync : out std_logic;
	 Vsync : out std_logic);
end vga_motor;

architecture Behavioral of vga_motor is
    constant VGA_VIS_X : integer := 640;
    constant VGA_VIS_Y : integer := 480;
    constant LCD_VIS_X : integer := 96;
    constant LCD_VIS_Y : integer := 64;
    constant PIXEL_SIZE : integer := 4;

    signal Xpixel : integer range 0 to 800; -- horizontal pixel counter
    signal Ypixel : integer range 0 to 521; -- vertical pixel counter
    signal clk_count : unsigned(1 downto 0);
    signal vga_clk : std_logic;
    signal colour : std_logic_vector(7 downto 0);	
    signal blank : std_logic;
begin
    clk_div : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                clk_count <= (others => '0');
            else
	            clk_count <= clk_count + 1;
            end if;
        end if;
    end process;
    vga_clk <= '1' when (clk_count = 3) else '0';

    x_cntr : process(clk) begin
        if rising_edge(clk) then
            if rst ='1' then
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
    y_cntr : process(clk) begin
        if rising_edge(clk) then   
            if rst = '1' then
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

    Hsync <= '0' when Xpixel > 656 and Xpixel <= 752 else
             '1';
    Vsync <= '0' when Ypixel > 490 and Ypixel <= 492 else
             '1';
    blank <= '1' when Xpixel >= VGA_VIS_X or Ypixel >= VGA_VIS_Y else '0';
    colour <= x"00" when blank = '1' else
              x"00" when Xpixel >= LCD_VIS_X*PIXEL_SIZE or
                         Ypixel >= LCD_VIS_Y*PIXEL_SIZE else
              x"ff" when data = '1' else
              -- 010 010 00_
              x"48" when data = '0' else
              (others => '-');
  
    x <= std_logic_vector(to_unsigned(Xpixel/PIXEL_SIZE, x'length))
        when Xpixel < LCD_VIS_X*PIXEL_SIZE else (others => '0');
    y <= std_logic_vector(to_unsigned(Ypixel/PIXEL_SIZE, y'length))
        when Ypixel < LCD_VIS_Y*PIXEL_SIZE else (others => '0');

    vgaRed 	    <= colour(7 downto 5);
    vgaGreen    <= colour(4 downto 2);
    vgaBlue 	<= colour(1 downto 0);
end Behavioral;

