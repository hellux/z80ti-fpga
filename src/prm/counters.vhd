library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dcntr is generic(init : std_logic_vector;
                        bitwidth : integer); port(
    clk, rst, ce : in std_logic;
    cnten : in std_logic;
    ld : in std_logic;
    di : in std_logic_vector(bitwidth-1 downto 0);
    do : out std_logic_vector(bitwidth-1 downto 0));
end dcntr;

architecture arch of dcntr is
    signal count : unsigned(bitwidth-1 downto 0) := unsigned(init);
    signal count_next : unsigned(bitwidth-1 downto 0);
begin
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                count <= unsigned(init);
            elsif ce = '1' then
                count <= count_next;
            end if;
        end if;
    end process;
    count_next <= unsigned(di) when ld = '1' else
                  count - 1    when cnten = '1' else
                  count;
    do <= std_logic_vector(count);
end arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cntr is generic(bitwidth : integer); port(
    clk, rst, ce : in std_logic;
    cnten : in std_logic;
    ld : in std_logic;
    di : in unsigned(bitwidth-1 downto 0);
    do : out unsigned(bitwidth-1 downto 0));
end cntr;

architecture arch of cntr is
    signal count : unsigned(bitwidth-1 downto 0) := (others => '0');
begin
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                count <= (others => '0');
            elsif ce = '1' then
                if ld = '1' then
                    count <= di;
                elsif cnten = '1' then
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;
    do <= count;
end arch;
