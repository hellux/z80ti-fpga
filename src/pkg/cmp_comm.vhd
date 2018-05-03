library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

package cmp_comm is
    type dbg_cmp_t is record
        z80 : dbg_z80_t;
        scancode : std_logic_vector(7 downto 0);
        keycode : std_logic_vector(7 downto 0);
        on_key_down : std_logic;
        mem_rd, mem_wr : std_logic;
        data : std_logic_vector(7 downto 0);
        addr_log : std_logic_vector(15 downto 0);
        addr_phy : std_logic_vector(19 downto 0);
        cbi : ctrlbus_in;
        cbo : ctrlbus_out;
    end record;
end cmp_comm;