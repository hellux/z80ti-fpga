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
    function div24(num : integer) return integer is
        variable q, num_v : integer;
    begin
        num_v := num;
        q := 0;
        for i in 0 to 319 loop
            if num_v < 24 then
                exit;
            end if;
            num_v := num_v - 24;
            q := q + 1;
        end loop;
        return q;
    end div24;
    function rem24(num : integer) return integer is
        variable q, num_v : integer;
    begin
        num_v := num;
        for i in 0 to 319 loop
            if num_v < 24 then
                exit;
            end if;
            num_v := num_v - 24;
        end loop;
        return num_v;
    end rem24;

    --120x64/24=480
    type mem_t is array(0 to 480) of std_logic_vector(0 to 23);
    signal mem : mem_t;
    signal tri_bit_lcd, tri_bit_vga : integer range 0 to 23;
    signal tri_addr_lcd, tri_addr_vga : integer range mem'range;
    signal tri_sel_lcd, tri_next : std_logic_vector(0 to 23);
begin
    tri_addr_vga <= div24(to_integer(unsigned(x_vga)) +
                          to_integer(unsigned(y_vga)*120));
    tri_addr_lcd <= 
        div24(to_integer(unsigned(x_lcd))*120+to_integer(unsigned(y_lcd))*8)
            when wl = '1' else
        div24(to_integer(unsigned(x_lcd))*120+to_integer(unsigned(y_lcd))*6);
    tri_sel_lcd <= mem(tri_addr_lcd);
    tri_bit_lcd <= rem24(to_integer(unsigned(y_lcd))*8) when wl = '1' else
                   rem24(to_integer(unsigned(y_lcd))*6) when wl = '0' else
                   0;
    tri_bit_vga <= rem24(to_integer(unsigned(x_vga)));

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
        end if;
    end process;

    do_lcd <= tri_sel_lcd(tri_bit_lcd to tri_bit_lcd+7) when wl = '1' else
              tri_sel_lcd(tri_bit_lcd to tri_bit_lcd+5) & "00";
    do_vga <= mem(tri_addr_vga)(tri_bit_vga);
end Behavioral;
