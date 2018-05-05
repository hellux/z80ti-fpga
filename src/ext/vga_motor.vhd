library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_motor is port ( 
     clk, ce : in std_logic;
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
    component cntr generic(bitwidth : integer); port(
        clk, rst, ce : in std_logic;
        cnten : in std_logic;
        ld : in std_logic;
        di : in std_logic_vector(bitwidth-1 downto 0);
        do : out std_logic_vector(bitwidth-1 downto 0));
    end component;

    constant VGA_VIS_X : integer := 640;
    constant VGA_VIS_Y : integer := 480;
    constant VGA_X : integer := 800;
    constant VGA_y : integer := 521;
    constant LCD_VIS_X : integer := 96;
    constant LCD_VIS_Y : integer := 64;
    constant PIXEL_SIZE : integer := 4;

    signal x_ld, y_ld : std_logic;
    signal x_out : std_logic_vector(9 downto 0);
    signal y_out : std_logic_vector(8 downto 0);
    signal x_vga : unsigned(9 downto 0);
    signal y_vga : unsigned(8 downto 0);

    signal colour : std_logic_vector(7 downto 0);	
    signal blank : std_logic;
begin
    x_vga <= unsigned(x_out);
    x_ld <= '1' when x_vga = to_unsigned(VGA_X-1, x_vga'length) else '0';
    x_cntr : cntr generic map(x_vga'length)
                  port map(clk, rst, ce, '1', x_ld, "0000000000", x_out);

    y_vga <= unsigned(y_out);
    y_ld <= '1' when y_vga = to_unsigned(VGA_Y-1, y_vga'length) else '0';
    y_cntr : cntr generic map(y_vga'length)
                  port map(clk, rst, ce, x_ld, y_ld, "000000000", y_out);

    Hsync <= '0' when x_vga > 656 and x_vga <= 752 else
             '1';
    Vsync <= '0' when y_vga > 490 and y_vga <= 492 else
             '1';
    blank <= '1' when x_vga >= VGA_VIS_X or y_vga >= VGA_VIS_Y else '0';
    colour <= x"00" when blank = '1' else
              x"00" when x_vga >= LCD_VIS_X*PIXEL_SIZE or
                         y_vga >= LCD_VIS_Y*PIXEL_SIZE else
              x"ff" when data = '1' else
              -- 010 010 00_
              x"48" when data = '0' else
              (others => '-');
  
    x <= x_out(8 downto 2)
        when x_vga < LCD_VIS_X*PIXEL_SIZE else (others => '0');
    y <= y_out(7 downto 2)
        when y_vga < LCD_VIS_Y*PIXEL_SIZE else (others => '0');

    vgaRed 	    <= colour(7 downto 5);
    vgaGreen    <= colour(4 downto 2);
    vgaBlue 	<= colour(1 downto 0);
end Behavioral;
