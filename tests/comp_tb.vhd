library ieee;
use ieee.std_logic_1164.all;

entity comp_tb is
end comp_tb;

architecture arch of comp_tb is
    component comp port(
        clk, rst : in std_logic;
        seg: out std_logic_vector(7 downto 0));
    end component;
    signal clk : std_logic;
    signal seg : std_logic_vector(7 downto 0);
begin
    c : comp port map(clk, '0', seg);
    process begin
        clk <= '1';
        wait for 125 ns;
        clk <= '0';
        wait for 125 ns;
    end process;
end arch;
