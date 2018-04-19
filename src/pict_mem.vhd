library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pict_mem is port (
    clk, rst : in std_logic;
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
    function rem24(num : integer) return integer is
        variable num_v : integer;
    begin
        num_v := num;
        for i in 0 to 4 loop
            if num_v < 24 then
                exit;
            end if;
            num_v := num_v - 24;
        end loop;
        return num_v;
    end rem24;

    signal clk_z80, clk_vga : std_logic;
    signal clk_z80_div : integer range 0 to 24;
    signal clk_vga_div : integer range 0 to 3;

    --120x64/24 = 320
    signal xl : integer range 0 to 63;
    signal yl : integer range 0 to 19;
    signal xv : integer range 0 to 119;
    signal yv : integer range 0 to 63;
    type mem_t is array(0 to 319) of std_logic_vector(0 to 23);
    signal mem : mem_t;
    signal tri_bit_lcd, tri_bit_lcd_8b, tri_bit_vga : integer range 0 to 23;
    signal tri_addr_lcd, tri_addr_lcd_8b : integer range mem'range;
    signal tri_addr_vga : integer range mem'range;
    signal tri_sel_lcd, tri_next : std_logic_vector(0 to 23);
begin
    xl <= to_integer(unsigned(x_lcd));
    yl <= to_integer(unsigned(y_lcd));
    xv <= to_integer(unsigned(x_vga));
    yv <= to_integer(unsigned(y_vga));

    -- clock sync
    process(clk) begin
        if rising_edge(clk) then
            if clk_z80_div = 24 then
                clk_z80_div <= 0;
            else
                clk_z80_div <= clk_z80_div + 1;
            end if;
            if clk_vga_div = 3 then
                clk_vga_div <= 0;
            else
                clk_vga_div <= clk_vga_div + 1;
            end if;
            if rst = '1' then
                clk_z80_div <= 0;
                clk_vga_div <= 0;
            end if;
        end if;
    end process;
    clk_z80 <= '1' when clk_z80_div = 0 else '0';
    clk_vga <= '1' when clk_vga_div = 0 else '0';

    -- tri_addr_vga = (xv+120*yv)/24 = xv/8/3 + 5*yv
    with xv/8 select tri_addr_vga <=
        5 + 5*yv    when 15,
        4 + 5*yv    when 12|13|14,
        3 + 5*yv    when 9|10|11,
        2 + 5*yv    when 6|7|8,
        1 + 5*yv    when 3|4|5,
        0 + 5*yv    when 0|1|2,
        0           when others;
    -- tri_addr_lcd_6b = (xl*120+6*yl)/24 = 5*xl + yl/4 (trivial)
    -- tri_addr_lcd_8b = (xl*120+8*yl)/24 = 5*xl + yl/3
    tri_addr_lcd <= tri_addr_lcd_8b when wl = '1' else 5*xl + yl/4;
    with yl select tri_addr_lcd_8b <=
        5*xl + 6    when 18|19,
        5*xl + 5    when 15|16|17,
        5*xl + 4    when 12|13|14,
        5*xl + 3    when  9|10|11,
        5*xl + 2    when  6| 7| 8,
        5*xl + 1    when  3| 4| 5,
        5*xl + 0    when  0| 1| 2,
        0           when others;
    -- tri_bit_lcd_6b = 6*(yl mod 24) (trivial)
    -- tri_bit_lcd_8b = 8*(yl mod 24)
    with yl select tri_bit_lcd_8b <=
        0  when 0| 3| 6| 9|12|15|18,
        8  when 1| 4| 7|10|13|16|19,
        16 when 2| 5| 8|11|14|17,
        0  when others;
    tri_bit_lcd <= tri_bit_lcd_8b when wl = '1' else yl mod 4;
    tri_bit_vga <= rem24(xv);

    process(tri_sel_lcd, tri_bit_lcd, rd, page_in, wl)
        variable tri_tmp : std_logic_vector(0 to 23);
    begin
        tri_tmp := tri_sel_lcd;
        if rd = '1' then
            if wl = '1' then
                tri_tmp(tri_bit_lcd to tri_bit_lcd+7) := page_in;
            else
                tri_tmp(tri_bit_lcd to tri_bit_lcd+5) := page_in(5 downto 0);
            end if;
        end if;
        tri_next <= tri_tmp;
    end process;

    lcd_in_out : process(clk) begin
        if rising_edge(clk) then
            if clk_z80 = '1' then
                if rst = '1' then
                    mem <= (others => x"000000");
                else
                    mem(tri_addr_lcd) <= tri_next;
                end if;
                tri_sel_lcd <= mem(tri_addr_lcd);
            end if;
        end if;
    end process;

    do_lcd <= tri_sel_lcd(tri_bit_lcd to tri_bit_lcd+7) when wl = '1' else
              "00" & tri_sel_lcd(tri_bit_lcd to tri_bit_lcd+5);

    vga_out : process(clk) begin
        if rising_edge(clk) then
            if clk_vga = '1' then
                do_vga <= mem(tri_addr_vga)(tri_bit_vga);
            end if;
        end if;
    end process;
end Behavioral;
