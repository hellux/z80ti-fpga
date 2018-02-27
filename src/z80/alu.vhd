library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is port(
    clk, rst in std_logic;
    temp in std_logic(7 downto 0);
    a, f out std_logic(7 downto 0));
    -- need input to decide instruction
end alu;

architecture arch of alu is

begin

end arch;
