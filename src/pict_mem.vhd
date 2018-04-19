library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pict_mem is port (
    clk_z80, clk_vga, rst : in std_logic;
    rd, wl : in std_logic;
    page_in : in std_logic_vector(7 downto 0);
    x_lcd : in std_logic_vector(5 downto 0); -- row
    y_lcd : in std_logic_vector(4 downto 0); -- column page
    x_vga : in std_logic_vector(6 downto 0); -- column
    y_vga : in std_logic_vector(5 downto 0); -- row
    do_vga: out std_logic;
    do_lcd: out std_logic_vector(7 downto 0));
end pict_mem;

architecture Behavioral of pict_mem is
    signal pic_mem : std_logic_vector(0 to 7679);
    signal a_lcd, a_vga : integer range pic_mem'range;
    signal xl, yl, xv, yv : integer := 0;
begin
    xl <= to_integer(unsigned(x_lcd));
    yl <= to_integer(unsigned(y_lcd));
    xv <= to_integer(unsigned(x_vga));
    yv <= to_integer(unsigned(y_vga));

    a_lcd <= xl*120+yl*8 when wl = '1' else xl*120+yl*6;
    a_vga <= yv*120+xv;

    lcd_rd_wr : process(clk_z80) begin
        if rising_edge(clk_z80) then
            if rst = '1' then
                pic_mem <= (others => '0');
            elsif rd = '1' then
                if wl = '1' then
                    pic_mem(a_lcd to a_lcd+7) <= page_in;
                else
                    pic_mem(a_lcd to a_lcd+5) <= page_in(5 downto 0);
                end if;
            end if;
            if wl = '1' then
                do_lcd <= pic_mem(a_lcd to a_lcd+7);
            else 
                do_lcd <= "00" & pic_mem(a_lcd to a_lcd+5);
            end if;
        end if;
    end process;

    vga_rd : process(clk_vga) begin
        if rising_edge(clk_vga) then
            do_vga <= pic_mem(a_vga);
        end if;
    end process;
end Behavioral;

