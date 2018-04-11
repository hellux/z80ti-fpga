library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity segment is port(
    clk, rst : in std_logic;
    seg : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0);
    value : in std_logic_vector(15 downto 0));
end segment;

architecture arch of segment is
	signal segments : std_logic_vector (6 downto 0);
	signal counter_r : unsigned(17 downto 0) := (others => '0');
	signal v : std_logic_vector (3 downto 0);
    signal dp : std_logic;
begin
    dp <= '1';
    seg <= (dp & segments);
     
    with counter_r(17 downto 16) select
        v <= value(15 downto 12) when "00",
             value(11 downto 8)  when "01",	
             value(7 downto 4)   when "10",
             value(3 downto 0)   when "11",
             "----"              when others;

    process(clk) begin
        if rising_edge(clk) then 
            counter_r <= counter_r + 1;

            case v is               --ABCDEFG
            when x"0" => segments <= "0000001";
            when x"1" => segments <= "1001111";
            when x"2" => segments <= "0010010";
            when x"3" => segments <= "0000110";
            when x"4" => segments <= "1001100";
            when x"5" => segments <= "0100100";
            when x"6" => segments <= "0100000";
            when x"7" => segments <= "0001111";
            when x"8" => segments <= "0000000";
            when x"9" => segments <= "0000100";
            when x"a" => segments <= "0001000";
            when x"b" => segments <= "1100000";
            when x"c" => segments <= "0110001";
            when x"d" => segments <= "1000010";
            when x"e" => segments <= "0110000";
            when x"f" => segments <= "0111000";
            when others => null;
            end case;

            case counter_r(17 downto 16) is
            when "00" => an <= "0111";
            when "01" => an <= "1011";
            when "10" => an <= "1101";
            when "11" => an <= "1110";
            when others => null;
            end case;
        end if;
    end process;
end arch;

