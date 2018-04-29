library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ti_comm.all;

entity asic is port(
    clk, rst : in std_logic;
-- ctrl
    in_op, out_op : in std_logic;
-- buses
    addr : in std_logic_vector(7 downto 0);
    data_in : in std_logic_vector(7 downto 0);   -- from dbus
    data_out : out std_logic_vector(7 downto 0); -- to dbus
-- asic <-> controllers
    ports_in : in ports_in_t;                    -- (port -> cpu) from ctrl
    ports_out : out ports_out_t);                -- (cpu -> port) to ctrl 
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

    type ctrl_state_t is (idle, pulse, stall);

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

    -- array of input/output to external ports
    signal parr_out : ports_out_array_t;
    signal parr_in : ports_in_array_t;

    -- pulse rd / wr signal
    signal ctrl_state : ctrl_state_t;
    signal ctrl_pulse : std_logic;

    -- port buffers
    signal p01_kbd_out : port_out_t;
    signal p01_kbd_buf : std_logic_vector(7 downto 0);

    signal p03_intmask_out : port_out_t;
    signal p03_intmask_buf : std_logic_vector(7 downto 0);

    signal p04_mmap_int_out : port_out_t;
    signal p04_mmap_int_buf : std_logic_vector(7 downto 0);

    signal p06_mempage_a_out : port_out_t;
    signal p06_mempage_a_buf : std_logic_vector(7 downto 0);

    signal p07_mempage_b_out : port_out_t;
    signal p07_mempage_b_buf : std_logic_vector(7 downto 0);

    signal p10_lcd_status_out : port_out_t;
    signal p10_lcd_status_buf : std_logic_vector(7 downto 0);

    signal p11_lcd_data_out : port_out_t;
    signal p11_lcd_data_buf : std_logic_vector(7 downto 0);
begin
    -- one pulse delay rd/wr signals
    ctrl_pulse <= '1' when ctrl_state = pulse else '0';
    process(clk) begin
        if rising_edge(clk) then
            case ctrl_state is
            when idle =>
                if in_op = '1' or out_op = '1' then
                    ctrl_state <= pulse;
                end if;
            when pulse =>
                ctrl_state <= stall;
            when stall =>
                if in_op = '0' and out_op = '1' then
                    ctrl_state <= idle;
                end if;
            end case;
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
                        rd => in_op and ctrl_pulse,
                        wr => out_op and ctrl_pulse);
    end process;

    -- data bus -> ports
    -- TODO port 00/08 link ctrl (possibly respond to request)
    p01_kbd_out         <= mp(parr_out, 16#01#, 16#01#, 16#01#, 16#09#);
    p03_intmask_out     <= mp(parr_out, 16#03#, 16#03#, 16#03#, 16#0b#);
    p04_mmap_int_out    <= mp(parr_out, 16#04#, 16#04#, 16#04#, 16#0c#);
    -- TODO port 05/0d linkport byte (possibly respond to request)
    p06_mempage_a_out   <= mp(parr_out, 16#06#, 16#06#, 16#06#, 16#0e#);
    p07_mempage_b_out   <= mp(parr_out, 16#07#, 16#07#, 16#07#, 16#0f#);
    p10_lcd_status_out  <= mp(parr_out, 16#10#, 16#12#, 16#18#, 16#1a#);
    p11_lcd_data_out    <= mp(parr_out, 16#11#, 16#13#, 16#19#, 16#1b#);
    -- TODO port 14/15 flash lock
    -- TODO port 16/17 no exec mask

    -- ports -> data bus
    parr_in <= (
        16#00# => (data => x"00"),          -- link port lines
        16#08# => (data => x"00"),
        16#01# => ports_in.p01_kbd,
        16#09# => ports_in.p01_kbd,
        16#02# => (data => x"e1"),          -- battery level
        16#0a# => (data => x"e1"),
        16#03# => (data => p03_intmask_buf),
        16#0b# => (data => p03_intmask_buf),
        16#04# => ports_in.p04_mmap_int,
        16#0c# => ports_in.p04_mmap_int,
        16#05# => (data => x"00"),          -- current linkport byte
        16#0d# => (data => x"00"),
        16#06# => (data => p06_mempage_a_buf),
        16#0e# => (data => p06_mempage_a_buf),
        16#07# => (data => p07_mempage_b_buf),
        16#0f# => (data => p07_mempage_b_buf),
        16#10# => ports_in.p10_lcd_status,
        16#12# => ports_in.p10_lcd_status,
        16#18# => ports_in.p10_lcd_status,
        16#1a# => ports_in.p10_lcd_status,
        16#11# => ports_in.p11_lcd_data,
        16#13# => ports_in.p11_lcd_data,
        16#19# => ports_in.p11_lcd_data,
        others => (data => x"00"));

    -- out data -> buffers (for controllers)
    p01_buf : reg generic map(8)
                  port map(clk, rst, p01_kbd_out.wr,
                           p01_kbd_out.data, p01_kbd_buf);
    ports_out.p01_kbd <= (p01_kbd_buf, 
                          p01_kbd_out.rd, p01_kbd_out.wr);

    p03_buf : reg generic map(8)
                  port map(clk, rst, p03_intmask_out.wr,
                           p03_intmask_out.data, p03_intmask_buf);
    ports_out.p03_intmask <= (p03_intmask_buf,
                              p03_intmask_out.rd, p03_intmask_out.wr);

    p04_buf : reg generic map(8)
                  port map(clk, rst, p04_mmap_int_out.wr,
                           p04_mmap_int_out.data, p04_mmap_int_buf);
    ports_out.p04_mmap_int <= (p04_mmap_int_buf,
                               p04_mmap_int_out.rd, p04_mmap_int_out.wr);

    p06_buf : reg generic map(8)
                  port map(clk, rst, p06_mempage_a_out.wr,
                           p06_mempage_a_out.data, p06_mempage_a_buf);
    ports_out.p06_mempage_a <= (p06_mempage_a_buf,
                                p06_mempage_a_out.rd, p06_mempage_a_out.wr);

    p07_buf : reg generic map(8)
                  port map(clk, rst, p07_mempage_b_out.wr,
                           p07_mempage_b_out.data,
                           p07_mempage_b_buf);
    ports_out.p07_mempage_b <= (p07_mempage_b_buf,
                                p07_mempage_b_out.rd, p07_mempage_b_out.wr);

    p10_buf : reg generic map(8)
                  port map(clk, rst, p10_lcd_status_out.wr,
                           p10_lcd_status_out.data,
                           p10_lcd_status_buf);
    ports_out.p10_lcd_status <= (p10_lcd_status_buf,
                                 p10_lcd_status_out.rd, p10_lcd_status_out.wr);

    p11_buf : reg generic map(8)
                  port map(clk, rst, p11_lcd_data_out.wr,
                           p11_lcd_data_out.data,
                           p11_lcd_data_buf);
    ports_out.p11_lcd_data <= (p11_lcd_data_buf,
                               p11_lcd_data_out.rd, p11_lcd_data_out.wr);
end arch;
