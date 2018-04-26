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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dcntr is generic(bitwidth : integer); port(
    clk, rst : in std_logic;
    ld : in std_logic;
    ce1, ce2 : in std_logic;
    di : in std_logic_vector(bitwidth-1 downto 0);
    do : out std_logic_vector(bitwidth-1 downto 0);
    rc : out std_logic);
end dcntr;

architecture arch of dcntr is
    signal count : unsigned(bitwidth-1 downto 0);
begin
    process(clk) begin
        if rst = '1' then
            count <= (others => '0');
        elsif ld = '1' then
            count <= unsigned(di);
        elsif ce1 = '1' and ce2 = '1' then
            count <= count - 1;
        end if;
    end process;
    do <= std_logic_vector(count);
end arch;
