library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pict_mem is port (
    clk, rst : in std_logic;
    rd, wl : in std_logic;
    page_in : in std_logic_vector(7 downto 0);
    x : in std_logic_vector(3 downto 0);
    y : in std_logic_vector(4 downto 0);
    addr_vga : in std_logic_vector(12 downto 0);
    do_vga: out std_logic;
    do_lcd: out std_logic_vector(7 downto 0));
end pict_mem;

architecture Behavioral of pict_mem is
    type mem_t is array(0 to 480) of std_logic_vector(0 to 23);
    --120x64/24=6144
    signal mem : mem_t;
    signal tri_bit_lcd, tri_bit_vga : integer range 0 to 23;
    signal tri_addr_lcd, tri_addr_vga : integer range mem'range;
    signal tri_sel_lcd, tri_sel_vga, tri_next : std_logic_vector(0 to 23);
begin
    tri_addr_vga <= to_integer(unsigned(addr_vga)) / 24;
    tri_addr_lcd <=
        to_integer(unsigned(x)) * 5 + to_integer(unsigned(y)) / 3
            when wl = '1' else
        to_integer(unsigned(x)) * 5 + to_integer(unsigned(y)) / 4;
    tri_sel_lcd <= mem(tri_addr_lcd);
    tri_sel_vga <= mem(tri_addr_vga);
    tri_bit_lcd <= to_integer(unsigned(y)) rem 24;
    tri_bit_vga <= to_integer(unsigned(addr_vga)) rem 24;

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

    do_lcd <= x"00";
    do_vga <= mem(tri_addr_vga)(tri_bit_vga);
end Behavioral;

