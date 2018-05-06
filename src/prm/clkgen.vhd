library ieee;
use ieee.std_logic_1164.all;

entity clkgen is generic(div : natural); port(
    clk : in std_logic;
    clk_out : out std_logic);
end clkgen;

architecture arch of clkgen is
    signal clk_div : natural range 0 to div-1;
begin
    process(clk) begin
        if rising_edge(clk) then
            if clk_div = div-1 then
                clk_div <= 0;
            else
                clk_div <= clk_div + 1;
            end if;
        end if;
    end process;

    clk_out <= '1' when clk_div = 0 else '0';
end arch;

library ieee;
use ieee.std_logic_1164.all;

entity clkgen_meta is generic(div : natural); port(
    clk : in std_logic;
    clk_in : in std_logic;
    clk_out : out std_logic);
end clkgen_meta;

architecture arch of clkgen_meta is
    signal clk_div : natural range 0 to div-1;
begin

    process(clk) begin
        if rising_edge(clk) then
            if clk_in = '1' then
                if clk_div = div-1 then
                    clk_div <= 0;
                else
                    clk_div <= clk_div + 1;
                end if;
            end if;
        end if;
    end process;

    clk_out <= '1' when clk_div = 0 and clk_in = '1' else '0';
end arch;
