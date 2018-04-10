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
    type mem_t is array(0 to 65535) of std_logic_vector(7 downto 0);
    signal mem_s : mem_t :=
        (x"b1", -- or b
         x"cb", -- bit instr
         x"f7", -- set 6, a
         x"00", -- nop
         x"47", -- ld b, a
         x"87", -- add a
         x"08", -- ex af, af'
         x"3e", -- ld a, n
         x"05", -- n
         x"3d", -- dec a
         x"c2", -- jp nz, nn
         x"09", -- n
         x"00", -- n
         x"d9", -- exx
         x"b1", -- or b
         x"00", -- nop
         x"28", -- jr z, d
         x"03", -- d
         x"00",
         x"00",
         x"00",
         x"21", -- ld hl, nn
         x"15",
         x"00",
         x"46", -- ld b, (hl)
         x"e9", -- jp (hl)
         others => x"00");
begin
    data <= mem_s(to_integer(unsigned(addr))) when cbo.rd = '1'
        else (others => 'Z');
end arch;
