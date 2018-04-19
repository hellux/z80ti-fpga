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
    function div3(num : integer) return integer is
        variable q, num_v : integer;
    begin
        num_v := num;
        q := 0;
        for i in 1 to 6 loop
            if num_v < 3 then
                exit;
            end if;
            num_v := num_v - 3;
            q := q + 1;
        end loop;
        return q;
    end div3;

    function rem24(num : integer) return integer is
        variable q, num_v : integer;
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

    --120x64/24=480
    signal xl, yl, xv, yv : integer := 0;
    type mem_t is array(0 to 480) of std_logic_vector(0 to 23);
    signal mem : mem_t;
    signal tri_bit_lcd, tri_bit_vga : integer range 0 to 23;
    signal tri_addr_lcd, tri_addr_vga : integer range mem'range;
    signal tri_sel_lcd, tri_next : std_logic_vector(0 to 23);
begin
    xl <= to_integer(unsigned(x_lcd));
    yl <= to_integer(unsigned(y_lcd));
    xv <= to_integer(unsigned(x_vga));
    yv <= to_integer(unsigned(y_vga));

    tri_addr_vga <= div3(xv/8) + 5*yv;
    tri_addr_lcd <= xl*5 + div3(yl) when wl = '1' else
                    xl*5 + yl/4;
    tri_sel_lcd <= mem(tri_addr_lcd);
    tri_bit_lcd <= yl mod 4 when wl = '0' else
                   0        when yl = 0 or
                                 yl = 3 or
                                 yl = 6 or
                                 yl = 9 or
                                 yl = 12 or 
                                 yl = 15 or 
                                 yl = 18 else
                   8        when yl = 1 or
                                 yl = 4 or
                                 yl = 7 or
                                 yl = 10 or
                                 yl = 13 or 
                                 yl = 16 or 
                                 yl = 19 else
                   16       when yl = 2 or
                                 yl = 5 or
                                 yl = 8 or
                                 yl = 11 or
                                 yl = 14 or 
                                 yl = 17 or 
                                 yl = 20 else
                   0;
    tri_bit_vga <= rem24(xv);

    next_tri : process(tri_sel_lcd, tri_bit_lcd, page_in)
        variable tri_tmp : std_logic_vector(0 to 23);
    begin
        tri_tmp := tri_sel_lcd;
        if wl = '1' then
            tri_tmp(tri_bit_lcd to tri_bit_lcd+7) := page_in;
        else
            tri_tmp(tri_bit_lcd to tri_bit_lcd+5) := page_in(5 downto 0);
        end if;
        tri_next <= tri_tmp;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                mem <= (others => x"000000");
            else
                mem(tri_addr_lcd) <= tri_next;
            end if;
            if wl = '1' then
                do_lcd <= tri_sel_lcd(tri_bit_lcd to tri_bit_lcd+7);
            else
                do_lcd <= tri_sel_lcd(tri_bit_lcd to tri_bit_lcd+5) & "00";
            end if;
            do_vga <= mem(tri_addr_vga)(tri_bit_vga);
        end if;
    end process;

end Behavioral;
