library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;
use work.ti_comm.all;

package cmp_comm is
    constant SYS_FREQ : integer := 100*10**6;

    constant DIV_Z80 : integer := 17; -- SYS_FREQ/6MHz = 16.7
    constant DIV_VGA : integer := SYS_FREQ/(25*10**6);

    constant DIV_1000HZ : integer := SYS_FREQ/DIV_Z80/1000;
    constant DIV_100KHZ : integer := SYS_FREQ/DIV_Z80/(100*10**3);

    type ctrlbus_in is record
        -- cpu control
        int, reset : std_logic;
    end record;

    type ctrlbus_out is record
        -- system control
        m1, mreq, iorq, rd, wr : std_logic;
        -- cpu control
        halt : std_logic;
    end record;

    type keys_down_t is array(0 to 6) of std_logic_vector(7 downto 0);

    type dbg_cmp_t is record
        z80 : dbg_z80_t;
        ti : dbg_ti_t;
        data : std_logic_vector(7 downto 0);
        addr_log : std_logic_vector(15 downto 0);
        addr_phy : std_logic_vector(19 downto 0);
        cbi : ctrlbus_in;
        cbo : ctrlbus_out;
    end record;
end cmp_comm;
