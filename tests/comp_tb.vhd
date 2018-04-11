library ieee;
use ieee.std_logic_1164.all;

entity comp_tb is
end comp_tb;

architecture arch of comp_tb is
    component comp port(
        clk : in std_logic;
        btns : in std_logic_vector(4 downto 0);
        sw : in std_logic_vector(7 downto 0);
        seg, led : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;
    signal clk, rst : std_logic;
    signal seg, led : std_logic_vector(7 downto 0);
    signal an : std_logic_vector(3 downto 0);
    signal sw : std_logic_vector(7 downto 0);
    signal btns : std_logic_vector(4 downto 0);
begin
    c : comp port map(clk, btns, "00000000", seg, led, an);
    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    process begin
        btns <= "00000";
        wait for 15940 ns;
        btns <= "00100";
        wait for 123 ns;
        btns <= "00000";
    end process;
end arch;
