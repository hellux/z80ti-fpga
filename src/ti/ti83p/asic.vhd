library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.ti_comm.all;
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
    signal hwt_int : std_logic_vector(1 to 2); -- hardware timers will trigger
    signal int_dev : int_dev_t; -- interrupt device

    -- internal asic ports
    signal p03_intmask : port_in_t;
    signal p03_intmask_out : port_out_t;
    signal p03_intmask_buf : std_logic_vector(2 downto 0);

    signal p04_mmap_int : port_in_t;
    signal p04_mmap_int_out : port_out_t;
    signal p04_mmap_int_buf : std_logic_vector(7 downto 0);

    signal p06_mempage_a : port_in_t;
    signal p06_mempage_a_out : port_out_t;
    signal p06_mempage_a_buf : std_logic_vector(7 downto 0);

    signal p07_mempage_b : port_in_t;
    signal p07_mempage_b_out : port_out_t;
    signal p07_mempage_b_buf : std_logic_vector(7 downto 0);
begin
    -- interpret control bus
    int_ack <= cbo.iorq and cbo.m1;
    in_op   <= cbo.iorq and not cbo.m1 and cbo.rd;
    out_op  <= cbo.iorq and not cbo.m1 and cbo.wr;

    -- internal ports in signals
    p03_intmask <= ("---0-" & p03_intmask_buf,
                    hwt_fin(1) and hwt_int(1));

    p04_mmap_int.data <= "---" &
                         '0' & -- link caused int (never)
                         on_key_down &
                         bool_sl(int_dev = hwt2) &
                         bool_sl(int_dev = hwt1) &
                         bool_sl(int_dev = on_key);
    p04_mmap_int.int <= hwt_fin(2) and hwt_int(2);

    p06_mempage_a <= (p06_mempage_a_buf, '0');
    p07_mempage_b <= (p07_mempage_b_buf, '0');

    -- internal ports out ctrl
    p03_buf : reg generic map(3)
                  port map(clk_z80, rst, p03_intmask_out.wr,
                           p03_intmask_out.data(2 downto 0),
                           p03_intmask_buf);
    int_on_key <= p03_intmask_buf(0);
    hwt_int(1) <= p03_intmask_buf(1);
    hwt_int(2) <= p03_intmask_buf(2);

    p04_buf : reg generic map(8)
                  port map(clk_z80, rst, p04_mmap_int_out.wr,
                           p04_mmap_int_out.data,
                           p04_mmap_int_buf);
    hwt_freq <= p04_mmap_int_buf(2 downto 1);
    ports_out.p04_mmap_int.data <= p04_mmap_int_buf;

    p06_buf : reg generic map(8)
                  port map(clk_z80, rst, p04_mmap_int_out.wr,
                           p06_mempage_a_out.data,
                           p06_mempage_a_buf);
    ports_out.p06_mempage_a.data <= p06_mempage_a_buf;

    p07_buf : reg generic map(8)
                  port map(clk_z80, rst, p04_mmap_int_out.wr,
                           p07_mempage_b_out.data,
                           p07_mempage_b_buf);
    ports_out.p07_mempage_b.data <= p07_mempage_b_buf;

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
    p06_mempage_a_out        <= mp(parr_out, 16#06#, 16#06#, 16#06#, 16#0e#);
    p07_mempage_b_out        <= mp(parr_out, 16#07#, 16#07#, 16#07#, 16#0f#);
    ports_out.p10_lcd_status <= mp(parr_out, 16#10#, 16#12#, 16#18#, 16#1a#);
    ports_out.p11_lcd_data   <= mp(parr_out, 16#11#, 16#13#, 16#19#, 16#1b#);
    -- TODO port 14/15 flash lock
    -- TODO port 16/17 no exec mask

    -- ports -> data bus
    parr_in <= (
        16#00# => (x"00", '0'),          -- link port lines
        16#08# => (x"00", '0'),
        16#09# => ports_in.p01_kbd,
        16#01# => ports_in.p01_kbd,
        16#02# => (x"e1", '0'),          -- battery level
        16#0a# => (x"e1", '0'),
        16#03# => p03_intmask,
        16#0b# => p03_intmask,
        16#04# => p04_mmap_int,
        16#0c# => p04_mmap_int,
        16#05# => (x"00", '0'),          -- current linkport byte
        16#0d# => (x"00", '0'),
        16#06# => p06_mempage_a,
        16#0e# => p06_mempage_a,
        16#07# => p07_mempage_b,
        16#0f# => p07_mempage_b,
        16#10# => ports_in.p10_lcd_status,
        16#12# => ports_in.p10_lcd_status,
        16#18# => ports_in.p10_lcd_status,
        16#1a# => ports_in.p10_lcd_status,
        16#11# => ports_in.p11_lcd_data,
        16#13# => ports_in.p11_lcd_data,
        16#19# => ports_in.p11_lcd_data,
        16#14# => p04_mmap_int,
        others => (x"00", '0'));
end arch;
