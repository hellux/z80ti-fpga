library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.io_comm.all;
use work.util.all;

entity asic is port(
    clk, clk_z80 : in std_logic;
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
    cry_fin : in std_logic_vector(1 to 3));
end asic;

architecture arch of asic is
    type ports_out_array_t is array(0 to 255) of port_out_t;
    type ports_in_array_t  is array(0 to 255) of port_in_t;
    type rw_array_t is array(0 to 255) of std_logic;

    -- helpers
    signal a : integer range 0 to 255 := 0;
    signal int_ack, in_op, out_op : std_logic;

    -- array of input/output to external ports
    signal parr_out : ports_out_array_t;
    signal parr_in : ports_in_array_t;

    -- internal states
    signal mem_mode : std_logic; -- memory mode 0 or 1
    signal hwt_freq : std_logic_vector(1 downto 0);
    signal int_on_key : std_logic; -- on key will trigger interrupt
    signal int_hwt1, int_hwt2 : std_logic; -- hardware timers will trigger
    signal int_dev : int_dev_t; -- interrupt device

    -- internal asic ports
    signal p03_intmask : port_in_t;
    signal p04_mmap_int : port_in_t;
begin
    -- interpret control bus
    int_ack <= cbo.iorq and cbo.m1;
    in_op   <= cbo.iorq and not cbo.m1 and cbo.rd;
    out_op  <= cbo.iorq and not cbo.m1 and cbo.wr;

    -- internal ports in signals
    p03_intmask.data <= "---" &
                        '0' & -- linkport will gen interrupt (never)
                        "-" &
                        int_hwt2 &
                        int_hwt1 &
                        int_on_key;
    p03_intmask.int <= '0';
    p04_mmap_int.data <= cry_fin(3) &
                         cry_fin(2) &
                         cry_fin(1) &
                         '0' & -- link caused int (never)
                         on_key_down &
                         bool_sl(int_dev = hwt2) &
                         bool_sl(int_dev = hwt1) &
                         bool_sl(int_dev = on_key);
    p04_mmap_int.int <= '0';

    -- internal ports out ctrl
    p03 : process(clk_z80)
        variable p : port_out_t;
    begin
        p := parr_out(16#03#);
        if rising_edge(clk_z80) and p.wr = '1' then
            int_on_key <= p.data(0);
            int_hwt1 <= p.data(1);
            int_hwt2 <= p.data(2);
        end if;
    end process;
    p04 : process(clk_z80)
        variable p : port_out_t;
    begin
        p := parr_out(16#04#);
        if rising_edge(clk_z80) and p.wr = '1' then
            mem_mode <= p.data(0);
            hwt_freq <= p.data(2 downto 1);
        end if;
    end process;

    -- interrupt handling
    int <= '1' when int_dev /= none else '0';
    process(clk) begin
        if rising_edge(clk) then
            if int_dev = none then
                for i in parr_in'range loop
                    if parr_in(i).int = '1' then
                        case i is
                        when 16#31# => int_dev <= cry1;
                        when 16#32# => int_dev <= cry2;
                        when 16#33# => int_dev <= cry3;
                        when others => null; end case;
                        exit;
                    end if;
                end loop;
            elsif int_ack = '1' then
                -- TODO send address to dbus?
                case int_dev is
                when none => null;
                when on_key => null;
                when hwt1 => null;
                when hwt2 => null;
                when cry1 => null;
                when cry2 => null;
                when cry3 => null;
                end case;
                int_dev <= none;
            end if;
        end if;
    end process;

    -- port(a) -> data bus
    a <= to_integer(unsigned(addr));
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
    ports_out.p01_kbd           <= parr_out(16#01#);
    ports_out.p10_lcd_status    <= parr_out(16#10#);
    ports_out.p11_lcd_data      <= parr_out(16#11#);
    ports_out.p30_t1_freq       <= parr_out(16#30#);
    ports_out.p31_t1_status     <= parr_out(16#31#);
    ports_out.p32_t1_value      <= parr_out(16#32#);
    ports_out.p33_t2_freq       <= parr_out(16#33#);
    ports_out.p34_t2_status     <= parr_out(16#34#);
    ports_out.p35_t2_value      <= parr_out(16#35#);
    ports_out.p36_t3_freq       <= parr_out(16#36#);
    ports_out.p37_t3_status     <= parr_out(16#37#);
    ports_out.p38_t3_value      <= parr_out(16#38#);

    -- ports -> data bus
    parr_in <= (
        16#00# => (x"00", '0'),          -- lines
        16#01# => ports_in.p01_kbd,
        16#02# => (x"e1", '0'),          -- battery level
        16#03# => p03_intmask,
        16#04# => p04_mmap_int,
        16#05# => (x"00", '0'),          -- TODO current RAM page
        16#06# => (x"00", '0'),          -- TODO mem page A
        16#07# => (x"00", '0'),          -- TODO mem page B
        16#08# => (x"00", '0'),          -- TODO link assist enable
        16#09# => (x"00", '0'),          -- TODO link assist status
        16#0a# => (x"00", '0'),          -- TODO link assist input buffer
        16#0b# => (x"00", '0'),          -- cpu speed 2 signal rate
        16#0c# => (x"00", '0'),          -- cpu speed 3 signal rate
        16#0d# => (x"00", '0'),          -- link assist output buffer
        16#0e# => (x"00", '0'),          -- TODO mem a high flash addr
        16#0f# => (x"00", '0'),          -- TODO mem b high flash addr
        16#10# => ports_in.p10_lcd_status,
        16#11# => ports_in.p11_lcd_data,
        16#12# => ports_in.p10_lcd_status,
        16#13# => ports_in.p11_lcd_data,
        16#14# => (x"00", '0'),          -- flash control
        16#15# => (x"45", '0'),          -- asic version
        16#16# => (x"00", '0'),          -- flash page exclusion
        16#17# => (x"00", '0'),          -- ??, always reads 0
        16#18# => (x"00", '0'),          -- md5 always 0
        16#19# => (x"00", '0'),          -- md5 always 0
        16#1a# => (x"00", '0'),          -- md5 always 0
        16#1b# => (x"00", '0'),          -- md5 always 0
        16#1c# => (x"00", '0'),          -- TODO md5 value
        16#1d# => (x"00", '0'),          -- TODO md5 value >> 8
        16#1e# => (x"00", '0'),          -- TODO md5 value >> 16
        16#1f# => (x"00", '0'),          -- TODO md5 value >> 25
        16#20# => (x"00", '0'),          -- TODO cpu speed (set to 4MHz)
        16#21# => (x"00", '0'),          -- hardware type
        16#22# => (x"00", '0'),          -- TODO flash lower limit
        16#23# => (x"00", '0'),          -- TODO flash upper limit
        16#25# => (x"00", '0'),          -- TODO ram exec lower limit
        16#26# => (x"00", '0'),          -- TODO ram exec upper limit
        16#27# => (x"00", '0'),          -- TODO block mem map $c000
        16#28# => (x"00", '0'),          -- TODO block mem map 8000h
        16#29# => (x"00", '0'),          -- TODO lcd delay 6Mhz
        16#2a# => (x"00", '0'),          -- TODO lcd delay 15Mhz
        16#2b# => (x"00", '0'),          -- TODO lcd delay 15Mhz 02
        16#2c# => (x"00", '0'),          -- TODO lcd delay 15Mhz 03
        16#2d# => (x"00", '0'),          -- TODO crystal control
        16#2e# => (x"00", '0'),          -- TODO mem access delay
        16#2f# => (x"00", '0'),          -- TODO lcd wait delay
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
        16#40# => (x"00", '0'),          -- TODO clock mode
        16#41# => (x"00", '0'),          -- TODO clock input
        16#42# => (x"00", '0'),          -- TODO clock input
        16#43# => (x"00", '0'),          -- TODO clock input
        16#44# => (x"00", '0'),          -- TODO clock input
        16#45# => (x"00", '0'),          -- TODO clock mode
        16#46# => (x"00", '0'),          -- TODO clock mode
        16#47# => (x"00", '0'),          -- TODO clock mode
        16#48# => (x"00", '0'),          -- TODO clock mode
        16#4c# => (x"22", '0'),          -- usb ctrl status
        16#4d# => (x"a5", '0'),          -- usb cable status (disconnected)
        16#55# => (x"1f", '0'),          -- usb interrupt state
        16#56# => (x"00", '0'),          -- usb line events
        16#57# => (x"50", '0'),          -- usb live event mask
        others => (x"00", '0'));
end arch;
