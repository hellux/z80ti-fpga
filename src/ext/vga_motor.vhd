library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util.all;

entity vga_motor is port ( 
     clk, rst, ce : in std_logic;
	 gmem_data : in std_logic;
     gmem_x : out std_logic_vector(6 downto 0);
     gmem_y : out std_logic_vector(5 downto 0);
     mon_data : in std_logic;
     mon_x : out std_logic_vector(8 downto 0);
     mon_y : out std_logic_vector(5 downto 0);
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
        di : in unsigned(bitwidth-1 downto 0);
        do : out unsigned(bitwidth-1 downto 0));
    end component;

    constant VGA_VIS_X : integer := 640;
    constant VGA_VIS_Y : integer := 480;
    constant VGA_X : integer := 800;
    constant VGA_y : integer := 521;

    constant X_OFS : integer := 30;
    constant Y_OFS : integer := 6;
    constant LCD_VIS_X : integer := 96;
    constant LCD_VIS_Y : integer := 64;
    constant PIXEL_SIZE : integer := 6;

    constant MON_START_X : integer := 64;
    constant MON_START_Y : integer := 397;
    constant MON_WIDTH : integer := 512;
    constant MON_HEIGHT : integer := 64;

    signal blank : std_logic;
    signal gmem_col, mon_col, color : std_logic_vector(7 downto 0);	

    signal x_ld, xp_ld, xl_ld : std_logic;
    signal x_vga : unsigned(9 downto 0);
    signal xp : unsigned(2 downto 0);
    signal x_lcd : unsigned(6 downto 0);

    signal y_ld, yp_ld, yl_ld : std_logic;
    signal y_vga : unsigned(9 downto 0);
    signal yp : unsigned(2 downto 0);
    signal y_lcd : unsigned(5 downto 0);
begin
    x_ld <= bool_sl(x_vga = VGA_X-1);
    xv_cntr : cntr generic map(x_vga'length)
                   port map(clk, rst, ce, '1', x_ld,
                            to_unsigned(0, x_vga'length), x_vga);

    y_ld <= bool_sl(y_vga = VGA_Y-1);
    yv_cntr : cntr generic map(y_vga'length)
                   port map(clk, rst, ce, x_ld, y_ld,
                            to_unsigned(0, y_vga'length), y_vga);
    
    -- vga on lcd pixel
    xp_ld <= x_ld or bool_sl(xp = PIXEL_SIZE-1);
    xp_cntr : cntr generic map(xp'length)
                   port map(clk, rst, ce, '1', xp_ld,
                            to_unsigned(0, xp'length), xp);
    yp_ld <= y_ld or (bool_sl(yp = PIXEL_SIZE-1) and x_ld);
    yp_cntr : cntr generic map(yp'length)
                   port map(clk, rst, ce, x_ld, yp_ld,
                            to_unsigned(0, yp'length), yp);
    -- lcd pixels
    xl_ld <= bool_sl(x_vga = X_OFS-1) and xp_ld;
    xl_cntr : cntr generic map(x_lcd'length)
                   port map(clk, rst, ce, xp_ld, xl_ld,
                            to_unsigned(0, x_lcd'length), x_lcd);
    yl_ld <= bool_sl(y_vga = Y_OFS-1) and yp_ld;
    yl_cntr : cntr generic map(y_lcd'length)
                   port map(clk, rst, ce, yp_ld, yl_ld,
                            to_unsigned(0, y_lcd'length), y_lcd);

    Hsync <= '0' when x_vga > 656 and x_vga <= 752 else
             '1';
    Vsync <= '0' when y_vga > 490 and y_vga <= 492 else
             '1';
    blank <= '1' when x_vga >= VGA_VIS_X or y_vga >= VGA_VIS_Y else '0';

    gmem_col <= x"ff" when gmem_data = '1' else x"48";
    mon_col <= x"ff" when mon_data = '1' else x"00";

    color <= x"00"     when blank = '1' else
              gmem_col when x_vga >= X_OFS and
                            x_vga <  X_OFS + LCD_VIS_X*PIXEL_SIZE and
                            y_vga >= Y_OFS and
                            y_vga <  Y_OFS + LCD_VIS_Y*PIXEL_SIZE else
              mon_col  when x_vga >= MON_START_X and
                            x_vga <  MON_START_X + MON_WIDTH and
                            y_vga >= MON_START_Y and
                            y_vga <  MON_START_Y + MON_HEIGHT else
              x"00";
  
    mon_x <= std_logic_vector(resize(x_vga-MON_START_X, 9));
    mon_y <= std_logic_vector(resize(y_vga-MON_START_Y, 6));

    gmem_x <= std_logic_vector(x_lcd);
    gmem_y <= std_logic_vector(y_lcd);

    vgaRed 	    <= color(7 downto 5);
    vgaGreen    <= color(4 downto 2);
    vgaBlue 	<= color(1 downto 0);
end Behavioral;

