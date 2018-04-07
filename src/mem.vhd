library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity mem is port(
    clk : in std_logic;
    cbi : out ctrlbus_in;
    cbo : in ctrlbus_out;
    addr : in std_logic_vector(15 downto 0);
    data : inout std_logic_vector(7 downto 0));
end mem;

architecture arch of mem is
    type mem_t is array(0 to 15) of std_logic_vector(7 downto 0);
    signal mem_s : mem_t :=
        (x"00", -- nop
         x"00", -- nop
         x"cb", -- bit instr
         x"c7", -- set 0, a
         x"00", -- nop
         x"87", -- add a
         x"47", -- ld b, a
         x"08", -- ex af, af'
         x"c3", -- 
         x"02", -- jp 0002
         x"00", --
         x"00", -- nop
         x"00",
         x"00",
         x"00",
         x"00");
begin
    data <= mem_s(to_integer(unsigned(addr))) when cbo.rd = '1'
        else (others => 'Z');
end arch;
