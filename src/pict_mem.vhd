library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pict_mem is port (
    clk, rst : in std_logic;
    rd, wl : in std_logic;
    di : in std_logic_vector(7 downto 0);
    do_vga: out std_logic;
    do_lcd: out std_logic_vector(7 downto 0);
    addr_rd	: in std_logic_vector(12 downto 0);
    addr_wr : in std_logic_vector(12 downto 0));
end pict_mem;

architecture Behavioral of pict_mem is
    type mem_t is array(0 to 6143) of std_logic; --96x64=6144
    signal pic_mem : mem_t;
    signal a_rd, a_wr : integer range mem_t'range;
    signal word_length : integer range 6 to 8;
begin
    a_rd <= to_integer(unsigned(addr_rd));
    a_wr <= to_integer(unsigned(addr_wr));
    word_length <= 8 when wl = '1' else 6;

    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                pic_mem <= (others => '0');
            else 
                for i in 0 to word_length-1 loop
                    pic_mem(a_rd+i) <= di(i);
                end loop;
            end if;
        end if;
    end process;

    process(a_wr, pic_mem) begin
        do_lcd <= (others => '0');
        for i in 0 to word_length-1 loop
            do_lcd(i) <= pic_mem(a_wr+i);
        end loop;
    end process;

    do_vga <= pic_mem(a_rd);
end Behavioral;

