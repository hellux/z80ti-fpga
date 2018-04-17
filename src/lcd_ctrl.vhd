library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cmp_comm.all;

entity lcd_ctrl is port(
    clk : in std_logic;
    io_in : in std_logic_vector(7 downto 0);
    io_out : out std_logic_vector(7 downto 0);
    gmem_data : out std_logic_vector(7 downto 0);
    gmem_addr : out std_logic_vector(13 downto 0);
end lcd_ctrl;

architecture arch of lcd_ctrl is
begin
end arch;
