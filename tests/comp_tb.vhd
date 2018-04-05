library ieee;
use ieee.std_logic_1164.all;

entity comp_tb is
end comp_tb;

architecture arch of comp_tb is
    component comp port(
        signal clk : in std_logic);
    end component;
    signal clk : std_logic;
begin
    c : comp port map(clk);

    process begin
        clk <= '1';
        wait for 125 ns;
        clk <= '0';
        wait for 125 ns;
    end process;

end arch;
