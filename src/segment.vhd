library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity segment is port(
    clk, rst : in std_logic;
    value : in std_logic_vector(15 downto 0);
    dp_num : in unsigned(3 downto 0);
    seg : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0));
end segment;

architecture arch of segment is
	signal segments : std_logic_vector (6 downto 0);
    signal index_cntr : unsigned(17 downto 0) := (others => '0');
	signal index : unsigned(1 downto 0) := (others => '0');
	signal digit : std_logic_vector(3 downto 0);
begin
    process(clk) begin
        if rising_edge(clk) then 
            if rst = '1' then
                index_cntr <= (others => '0');
            else
                index_cntr <= index_cntr + 1;
            end if;
        end if;
    end process;
     
    index <= index_cntr(17 downto 16);
    seg <= (not dp_num(3-to_integer(index)) & segments);

    with index select digit <=
        value(15 downto 12) when "00",
        value(11 downto 8)  when "01",	
        value(7 downto 4)   when "10",
        value(3 downto 0)   when "11",
        "----"              when others;

    with index select an <=
        "0111" when "00",
        "1011" when "01",
        "1101" when "10",
        "1110" when "11",
        "----" when others;

    with digit select segments <=
    --   ABCDEFG
        "0000001" when x"0",
        "1001111" when x"1",
        "0010010" when x"2",
        "0000110" when x"3",
        "1001100" when x"4",
        "0100100" when x"5",
        "0100000" when x"6",
        "0001111" when x"7",
        "0000000" when x"8",
        "0000100" when x"9",
        "0001000" when x"a",
        "1100000" when x"b",
        "0110001" when x"c",
        "1000010" when x"d",
        "0110000" when x"e",
        "0111000" when x"f",
        "1111110" when others;
end arch;
