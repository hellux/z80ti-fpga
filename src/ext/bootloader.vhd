library ieee;
use ieee.std_logic_1164.all;

entity bootloader is port(
    clk, rst : std_logic;
-- bootloader <-> memory interface
    mem_wr : std_logic;
    mem_data_in : in std_logic_vector(7 downto 0);
    mem_data_out : out std_logic_vector(7 downto 0);
-- bootloader <-> 
end bootloader;
