library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;
use work.ti_comm.all;

package cmp_comm is
    constant SYS_FREQ : integer := 100*10**6;

    constant DIV_10KHZ : integer := 10000;
    constant DIV_1MHZ : integer := 100;
    constant DIV_6MHZ : integer := 17;
    constant DIV_15MHZ : integer := 7;
    constant DIV_25MHZ : integer := 4;
    constant DIV_33MHZ : integer := 3;
    constant DIV_50MHZ : integer := 2;

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

    type dbg_trace_t is record
        enabled : std_logic;
        from_jump, to_jump : std_logic_vector(15 downto 0);
    end record;

    type dbg_cmp_t is record
        z80 : dbg_z80_t;
        ti : dbg_ti_t;
        data : std_logic_vector(7 downto 0);
        addr_log : std_logic_vector(15 downto 0);
        addr_phy : std_logic_vector(19 downto 0);
        cbi : ctrlbus_in;
        cbo : ctrlbus_out;
        trc_ptr : std_logic_vector(23 downto 0);
        trace : dbg_trace_t;
    end record;
end cmp_comm;
