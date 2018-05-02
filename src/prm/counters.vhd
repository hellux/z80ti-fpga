library ieee;
use ieee.std_logic_1164.all;

entity udcntr is generic(size : integer); port(
    clk, rst : in std_logic;
    ld : in std_logic;
    ud : in std_logic; -- 0: down, 1: up
    ce1, ce2 : in std_logic;
    wrap : in integer range 0 to size-1;
    di : in integer range 0 to size-1;
    do : out integer range 0 to size-1);
end udcntr;

architecture arch of udcntr is
    signal count : integer range 0 to size-1;
begin
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                count <= 0;
            elsif ld = '1' then
                count <= di;
            elsif ce1 = '1' and ce2 = '1' then
                if ud = '1' then
                    if count = wrap then
                        count <= 0;
                    else
                        count <= count + 1;
                    end if;
                else
                    if count = 0 then
                        count <= wrap;
                    else
                        count <= count -1;
                    end if;
                end if;
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
    do : out std_logic_vector(bitwidth-1 downto 0));
end dcntr;

architecture arch of dcntr is
    signal count, count_next : unsigned(bitwidth-1 downto 0);
begin
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                count <= (others => '0');
            else
                count <= count_next;
            end if;
        end if;
    end process;
    count_next <= unsigned(di) when ld = '1' else
                  count - 1    when ce1 = '1' and ce2 = '1' else
                  count;
    do <= std_logic_vector(count);
end arch;
