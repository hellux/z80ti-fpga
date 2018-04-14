library ieee;
use ieee.std_logic_1164.all;

entity id_fb_tb is
end id_fb_tb;

architecture arch of id_fb_tb is
    component id_fb port(
        clk, rst : in std_logic;
        seg, led : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    signal clk, rst : std_logic;
    signal seg, led : std_logic_vector(7 downto 0);
    signal an : std_logic_vector(3 downto 0);
begin
    id : id_fb port map(clk, rst, seg, led, an);
    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    process begin
        rst <= '0';
        wait for 1515 ns;
        rst <= '1';
        wait for 348 ns;
        rst <= '0';
        wait for 100 us;
    end process;
end arch;
