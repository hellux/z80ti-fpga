library ieee;
use ieee.std_logic_1164.all;

entity comp_tb is
end comp_tb;

architecture arch of comp_tb is
    component comp port(
        clk, rst : in std_logic;
        btns : in std_logic;
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;
    signal clk, rst : std_logic;
    signal seg : std_logic_vector(7 downto 0);
    signal an : std_logic_vector(3 downto 0);
begin
    c : comp port map(clk, rst, clk, seg, an);
    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    process begin
        rst <= '0';
        wait for 40 us;
        rst <= '1';
        wait for 40 us;
    end process;
end arch;
