library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.io_comm.all;
use work.util.all;

entity asic is port(
    clk, clk_z80, rst : in std_logic;
-- buses
    int : out std_logic;
    cbo : in ctrlbus_out;
    addr : in std_logic_vector(7 downto 0);
    data_in : in std_logic_vector(7 downto 0);   -- from dbus
    data_out : out std_logic_vector(7 downto 0); -- to dbus
-- general inter io
    ports_in : in ports_in_t;                    -- (port -> cpu) from ctrl
    ports_out : out ports_out_t;                 -- (cpu -> port) to ctrl 
-- special inter io signals
    on_key_down : in std_logic;
    int_on_key : out std_logic;
    cry_fin : in std_logic_vector(1 to 3);
    hwt_freq : out std_logic_vector(1 downto 0);
    hwt_fin : in std_logic_vector(1 to 2));
end asic;

architecture arch of asic is
    component reg generic(size : integer); port(
        clk, rst : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;

    type ports_out_array_t is array(0 to 255) of port_out_t;
    type ports_in_array_t  is array(0 to 255) of port_in_t;
    type rw_array_t is array(0 to 255) of std_logic;

    -- merge ports (for ports with multiple out addresses)
    function mp(arr : ports_out_array_t;
                p1 : integer; p2 : integer; p3 : integer; p4 : integer)
    return port_out_t is
        variable p : port_out_t;
    begin
        p.data := arr(p1).data or arr(p2).data or arr(p3).data or arr(p4).data;
        p.rd := arr(p1).rd or arr(p2).rd or arr(p3).rd or arr(p4).rd;
        p.wr := arr(p1).wr or arr(p2).wr or arr(p3).wr or arr(p4).wr;
        return p;
    end mp;

    -- helpers
    signal a : integer range 0 to 255 := 0;
    signal int_ack, in_op, out_op : std_logic;

    -- array of input/output to external ports
    signal parr_out : ports_out_array_t;
    signal parr_in : ports_in_array_t;

    -- internal states
    signal mem_mode : std_logic; -- memory mode 0 or 1
    signal int_on_key_b : std_logic; -- on key will trigger interrupt
    signal hwt_int : std_logic_vector(1 to 2); -- hardware timers will trigger
    signal int_dev : int_dev_t; -- interrupt device

    -- internal asic ports
    signal p03_intmask : port_in_t;
    signal p03_intmask_out : port_out_t;
    signal p03_intmask_buf : std_logic_vector(7 downto 0);
    signal p04_mmap_int : port_in_t;
    signal p04_mmap_int_out : port_out_t;
    signal p04_mmap_int_buf : std_logic_vector(7 downto 0);
begin
    -- interpret control bus
    int_ack <= cbo.iorq and cbo.m1;
    in_op   <= cbo.iorq and not cbo.m1 and cbo.rd;
    out_op  <= cbo.iorq and not cbo.m1 and cbo.wr;

    -- internal ports in signals
    p03_intmask.data <= "---" &
                        '0' & -- linkport will gen interrupt (never)
                        "-" &
                        hwt_int(2) &
                        hwt_int(1) &
                        int_on_key_b;
    p03_intmask.int <= hwt_fin(1) and hwt_int(1);
    p04_mmap_int.data <= cry_fin(3) &
                         cry_fin(2) &
                         cry_fin(1) &
                         '0' & -- link caused int (never)
                         on_key_down &
                         bool_sl(int_dev = hwt2) &
                         bool_sl(int_dev = hwt1) &
                         bool_sl(int_dev = on_key);
    p04_mmap_int.int <= hwt_fin(2) and hwt_int(2);

    -- internal ports out ctrl
    p03_buf : reg generic map(8)
                  port map(clk_z80, rst, p03_intmask_out.wr,
                           p03_intmask_out.data, p03_intmask_buf);
    int_on_key_b <= p03_intmask_buf(0);
    int_on_key <= int_on_key_b;
    hwt_int(1) <= p03_intmask_buf(1);
    hwt_int(2) <= p03_intmask_buf(2);

    p04_buf : reg generic map(8)
                  port map(clk_z80, rst, p04_mmap_int_out.wr,
                           p04_mmap_int_out.data, p04_mmap_int_buf);
    mem_mode <= p04_mmap_int_buf(0);
    hwt_freq <= p04_mmap_int_buf(2 downto 1);

    -- interrupt handling (send int until acknowledgment)
    int <= bool_sl(int_dev /= none);
    process(clk) begin
        if rising_edge(clk) then
            if int_dev = none then
                for i in parr_in'range loop
                    if parr_in(i).int = '1' then
                        case i is
                        when 16#01# => int_dev <= on_key;
                        when 16#03# => int_dev <= hwt1;
                        when 16#04# => int_dev <= hwt2;
                        when 16#31# => int_dev <= cry1;
                        when 16#32# => int_dev <= cry2;
                        when 16#33# => int_dev <= cry3;
                        when others => null; end case;
                        exit;
                    end if;
                end loop;
            elsif int_ack = '1' then
                -- don't bother sending address to dbus, appears to be random
                int_dev <= none;
            end if;
        end if;
    end process;

    a <= to_integer(unsigned(addr));
    -- port(a) -> data bus
    data_out <= parr_in(a).data when in_op = '1' else x"00";
    -- data bus, rd/wr -> port(a), 0 -> rest
    port_array : process(a, data_in, in_op, out_op) begin
        for i in parr_out'range loop
            parr_out(i) <= (data => (others => '0'),
                            rd => '0',
                            wr => '0');
        end loop;
        parr_out(a) <= (data => data_in,
                        rd => in_op,
                        wr => out_op);
    end process;

    -- data bus -> ports
    -- TODO port 00/08 link ctrl (possibly respond to request)
    ports_out.p01_kbd        <= mp(parr_out, 16#01#, 16#01#, 16#01#, 16#09#);
    p03_intmask_out          <= mp(parr_out, 16#03#, 16#03#, 16#03#, 16#0b#);
    p04_mmap_int_out         <= mp(parr_out, 16#04#, 16#04#, 16#04#, 16#0c#);
    -- TODO port 05/0d linkport byte (possibly respond to request)
    -- TODO port 06/0e mem page a
    -- TODO port 07/0f mem page b
    ports_out.p10_lcd_status <= mp(parr_out, 16#10#, 16#12#, 16#18#, 16#1a#);
    ports_out.p11_lcd_data   <= mp(parr_out, 16#11#, 16#13#, 16#19#, 16#1b#);
    -- TODO port 14/15 flash lock
    -- TODO port 16/17 no exec mask
    ports_out.p30_t1_freq    <= mp(parr_out, 16#30#, 16#30#, 16#30#, 16#30#);
    ports_out.p31_t1_status  <= mp(parr_out, 16#31#, 16#31#, 16#31#, 16#31#);
    ports_out.p32_t1_value   <= mp(parr_out, 16#32#, 16#32#, 16#32#, 16#32#);
    ports_out.p33_t2_freq    <= mp(parr_out, 16#33#, 16#33#, 16#33#, 16#33#);
    ports_out.p34_t2_status  <= mp(parr_out, 16#34#, 16#34#, 16#34#, 16#34#);
    ports_out.p35_t2_value   <= mp(parr_out, 16#35#, 16#35#, 16#35#, 16#35#);
    ports_out.p36_t3_freq    <= mp(parr_out, 16#36#, 16#36#, 16#36#, 16#36#);
    ports_out.p37_t3_status  <= mp(parr_out, 16#37#, 16#37#, 16#37#, 16#37#);
    ports_out.p38_t3_value   <= mp(parr_out, 16#38#, 16#38#, 16#38#, 16#38#);

    -- ports -> data bus
    parr_in <= (
        16#00# => (x"00", '0'),          -- link port lines
        16#01# => ports_in.p01_kbd,
        16#02# => (x"e1", '0'),          -- battery level
        16#03# => p03_intmask,
        16#04# => p04_mmap_int,
        16#05# => (x"00", '0'),          -- current linkport byte
        16#06# => (x"00", '0'),          -- TODO mem page A
        16#07# => (x"00", '0'),          -- TODO mem page B
        16#08# => (x"00", '0'),          -- port 00 mirror
        16#09# => ports_in.p01_kbd,
        16#0a# => (x"e1", '0'),          -- port 02 mirror
        16#0b# => p03_intmask,           -- port 03 mirror
        16#0c# => p04_mmap_int,          -- port 04 mirror
        16#0d# => (x"00", '0'),          -- port 05 mirror
        16#0e# => (x"00", '0'),          -- port 06 mirror
        16#0f# => (x"00", '0'),          -- port 07 mirorr
        16#10# => ports_in.p10_lcd_status,
        16#11# => ports_in.p11_lcd_data,
        16#12# => ports_in.p10_lcd_status,
        16#13# => ports_in.p11_lcd_data,
        16#14# => (x"00", '0'),          -- ti84p: flash control
        16#15# => (x"45", '0'),          -- ti84p: asic version
        16#16# => (x"00", '0'),          -- ti84p: flash page exclusion
        16#17# => (x"00", '0'),          -- ti84p: ??, always reads 0
        16#18# => ports_in.p10_lcd_status,
        16#19# => ports_in.p11_lcd_data,
        16#1a# => ports_in.p10_lcd_status,
        16#1b# => ports_in.p11_lcd_data,
        16#1c# => (x"00", '0'),          -- ti84p: md5 value
        16#1d# => (x"00", '0'),          -- ti84p: md5 value >> 8
        16#1e# => (x"00", '0'),          -- ti84p: md5 value >> 16
        16#1f# => (x"00", '0'),          -- ti84p: md5 value >> 25
        16#20# => (x"00", '0'),          -- ti84p: cpu speed (set to 4MHz)
        16#21# => (x"00", '0'),          -- hardware type
        16#22# => (x"00", '0'),          -- ti84p: flash lower limit
        16#23# => (x"00", '0'),          -- ti84p: flash upper limit
        16#25# => (x"00", '0'),          -- ti84p: ram exec lower limit
        16#26# => (x"00", '0'),          -- ti84p: ram exec upper limit
        16#27# => (x"00", '0'),          -- ti84p: block mem map $c000
        16#28# => (x"00", '0'),          -- ti84p: block mem map 8000h
        16#29# => (x"00", '0'),          -- ti84p: lcd delay 6Mhz
        16#2a# => (x"00", '0'),          -- ti84p: lcd delay 15Mhz
        16#2b# => (x"00", '0'),          -- ti84p: lcd delay 15Mhz 02
        16#2c# => (x"00", '0'),          -- ti84p: lcd delay 15Mhz 03
        16#2d# => (x"00", '0'),          -- ti84p: crystal control
        16#2e# => (x"00", '0'),          -- ti84p: mem access delay
        16#2f# => (x"00", '0'),          -- ti84p: lcd wait delay
        16#30# => ports_in.p30_t1_freq,
        16#31# => ports_in.p31_t1_status,
        16#32# => ports_in.p32_t1_value,
        16#33# => ports_in.p33_t2_freq,
        16#34# => ports_in.p34_t2_status,
        16#35# => ports_in.p35_t2_value,
        16#36# => ports_in.p36_t3_freq,
        16#37# => ports_in.p37_t3_status,
        16#38# => ports_in.p38_t3_value,
        16#39# => (x"f0", '0'),          -- GPIO conf
        16#40# => (x"00", '0'),          -- ti84p: clock mode
        16#41# => (x"00", '0'),          -- ti84p: clock input
        16#42# => (x"00", '0'),          -- ti84p: clock input
        16#43# => (x"00", '0'),          -- ti84p: clock input
        16#44# => (x"00", '0'),          -- ti84p: clock input
        16#45# => (x"00", '0'),          -- ti84p: clock mode
        16#46# => (x"00", '0'),          -- ti84p: clock mode
        16#47# => (x"00", '0'),          -- ti84p: clock mode
        16#48# => (x"00", '0'),          -- ti84p: clock mode
        16#4c# => (x"22", '0'),          -- usb ctrl status
        16#4d# => (x"a5", '0'),          -- usb cable status (disconnected)
        16#55# => (x"1f", '0'),          -- usb interrupt state
        16#56# => (x"00", '0'),          -- usb line events
        16#57# => (x"50", '0'),          -- usb live event mask
        others => (x"00", '0'));
end arch;
