library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pict_mem is port (
    clk, rst : in std_logic;
    rd, wl : in std_logic;
    di : in std_logic_vector(7 downto 0);
    do_vga: out std_logic;
    do_lcd: out std_logic_vector(7 downto 0);
    addr_lcd	: in std_logic_vector(12 downto 0);
    addr_vga : in std_logic_vector(12 downto 0));
end pict_mem;

architecture Behavioral of pict_mem is
    --type mem_t is array(0 to 1000) of std_logic; --96x64=6144
    signal pic_mem : std_logic_vector(0 to 6143);
    signal a_lcd, a_vga : integer range pic_mem'range;
    signal byte_next : std_logic_vector(7 downto 0);
    
    signal s_byte : std_logic_vector(7 downto 0);
begin
    a_lcd <= to_integer(unsigned(addr_lcd));
    a_vga <= to_integer(unsigned(addr_vga));
    
    s_byte <= std_logic_vector(pic_mem(a_lcd to a_lcd+7));
    byte_next <= s_byte when rd = '0' else
                 di     when wl = '1' else
                 s_byte(7 downto 6) & di(5 downto 0);

    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                pic_mem <= (others => '0');
            else
                for i in 0 to 7 loop
                    pic_mem(a_lcd+i) <= byte_next(i);
                end loop;
            end if;
        end if;
    end process;

    do_lcd <= di when wl = '1' else
              s_byte(7 downto 6) & di(5 downto 0);
    do_vga <= pic_mem(a_vga);
end Behavioral;

