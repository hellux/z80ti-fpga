library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pict_mem is port (
    clk, rst : in std_logic;
    rd : in std_logic;
    di : in std_logic_vector(7 downto 0);
    do_rd, do_wr : out std_logic_vector(7 downto 0);
    addr_rd	: in std_logic_vector(9 downto 0);
    addr_wr : in std_logic_vector(9 downto 0));
end pict_mem;

architecture Behavioral of pict_mem is
  type mem_t is array(0 to 767) of std_logic_vector(7 downto 0); --96x64/8=768
  signal pic_mem : mem_t;
  signal byte_next : std_logic_vector(7 downto 0);
  signal a_rd, a_wr : integer range mem_t'range;
begin
    process(clk)begin
        if rising_edge(clk) then
            if rst = '1' then
                pic_mem <= (others => x"00");
            else 
                pic_mem(a_rd) <= byte_next;
            end if;
        end if;
    end process;

    a_rd <= to_integer(unsigned(addr_rd));
    a_wr <= to_integer(unsigned(addr_wr));

    byte_next <= di when rd = '1' else pic_mem(a_rd);
    do_rd <= pic_mem(a_rd);
    do_wr <= pic_mem(a_wr);
end Behavioral;

