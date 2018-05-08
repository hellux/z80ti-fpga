library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.cmp_comm.all;
use work.chars.all;

entity monitor_vga is port(
    clk : in std_logic;
    dbg : in dbg_cmp_t;
    x : in std_logic_vector(9 downto 0);
    y : in std_logic_vector(6 downto 0);
    data_vga : out std_logic);
end monitor_vga;

architecture arch of monitor_vga is
begin
    data_vga <= '0';
end arch;
