library ieee;
use ieee.std_logic_1164.all;

entity cntr is generic(size : integer); port(
    clk, rst : in std_logic;
    ce : in std_logic;
    do : out integer range 0 to size-1);
end cntr;

architecture arch of cntr is
    signal count : integer range 0 to size-1;
begin
    process(clk) begin
        if rst = '1' then
            count <= 0;
        elsif ce = '1' then
            if count = size-1 then
                count <= 0;
            else
                count <= count + 1;
            end if;
        end if;
    end process;
    do <= count;
end arch;
