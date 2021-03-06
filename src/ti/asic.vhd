library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ti_comm.all;

entity asic is port(
    clk, rst, ce : in std_logic;
-- ctrl
    in_op, out_op : in std_logic;
-- buses
    addr : in std_logic_vector(4 downto 0);
    data_in : in std_logic_vector(7 downto 0);   -- from dbus
    data_out : out std_logic_vector(7 downto 0); -- to dbus
-- asic <-> controllers
    ports_in : in ports_in_t;                    -- (port -> cpu) from ctrl
    ports_out : out ports_out_t;                 -- (cpu -> port) to ctrl 
-- dbg
    dbg : out dbg_asic_t);
end asic;

architecture arch of asic is
    component reg generic(init : std_logic_vector; size : integer); port(
        clk, rst, ce: in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;

    constant PORT_COUNT : integer := 32;

    type port_ctrl_t is record 
        rd, wr, buf : std_logic;
    end record;

    type ctrl_arr_t is array(0 to PORT_COUNT-1) of port_ctrl_t;
    type ports_in_arr_t is array(0 to PORT_COUNT-1) of port_in_t;

    type ctrl_state_t is (idle, hold_in, hold_out);

    function "or" (a : port_ctrl_t; b : port_ctrl_t) return port_ctrl_t is 
    begin
        return (rd => a.rd or b.rd,
                wr => a.wr or b.wr,
                buf => a.buf or b.buf);
    end function;

    -- helpers
    signal a : integer range 0 to PORT_COUNT-1 := 0;

    -- array of input/output to external ports
    signal carr : ctrl_arr_t;
    signal parr_in : ports_in_arr_t;

    -- pulse rd / wr signal
    signal ctrl_state : ctrl_state_t;
    signal ports_rd, ports_wr : std_logic;

    -- port buffers / ctrl signals -> controllers
    signal p01_kbd_ctrl : port_ctrl_t;
    signal p01_kbd_buf : std_logic_vector(7 downto 0);

    signal p02_status_ctrl : port_ctrl_t;
    signal p02_status_buf : std_logic_vector(7 downto 0);

    signal p03_intmask_ctrl : port_ctrl_t;
    signal p03_intmask_buf : std_logic_vector(7 downto 0);

    signal p04_mmap_int_ctrl : port_ctrl_t;
    signal p04_mmap_int_buf : std_logic_vector(7 downto 0);

    signal p05_protect_ctrl : port_ctrl_t;
    signal p05_protect_buf : std_logic_vector(7 downto 0);

    signal p06_mempage_a_ctrl : port_ctrl_t;
    signal p06_mempage_a_buf : std_logic_vector(7 downto 0);

    signal p07_mempage_b_ctrl : port_ctrl_t;
    signal p07_mempage_b_buf : std_logic_vector(7 downto 0);

    signal p10_lcd_status_ctrl : port_ctrl_t;
    signal p10_lcd_status_buf : std_logic_vector(7 downto 0);

    signal p11_lcd_data_ctrl : port_ctrl_t;
    signal p11_lcd_data_buf : std_logic_vector(7 downto 0);
begin
    -- one pulse delay rd/wr signals
    process(clk) begin
        if rising_edge(clk) then
            if ce = '1' then
                case ctrl_state is
                when idle =>
                    ports_rd <= '0';
                    ports_wr <= '0';

                    if in_op = '1' then
                        dbg.paddr <= addr;
                        dbg.rd_wr <= '0';
                        ctrl_state <= hold_in;
                    elsif out_op = '1' then
                        dbg.paddr <= addr;
                        dbg.rd_wr <= '1';
                        ctrl_state <= hold_out;
                    end if;
                when hold_in =>
                    if in_op = '0' then
                        ports_rd <= '1';
                        ctrl_state <= idle;
                    end if;
                when hold_out =>
                    if out_op = '0' then
                        ports_wr <= '1';
                        ctrl_state <= idle;
                    end if;
                end case;
            end if;
        end if;
    end process;

    a <= to_integer(unsigned(addr));
    -- port(a) -> data bus
    data_out <= parr_in(a).data when in_op = '1' else x"00";
    -- rd/wr
    port_array : process(a, ports_rd, ports_wr, out_op) begin
        for i in 0 to PORT_COUNT-1 loop
            carr(i) <= (others => '0');
        end loop;
        carr(a) <= (rd => ports_rd,
                    wr => ports_wr,
                    buf => out_op);
    end process;

    p01_kbd_ctrl         <= carr(16#01#) or carr(16#09#);
    p03_intmask_ctrl     <= carr(16#03#) or carr(16#0b#);
    p04_mmap_int_ctrl    <= carr(16#04#) or carr(16#0c#);
    p05_protect_ctrl     <= carr(16#05#) or carr(16#0d#);
    p06_mempage_a_ctrl   <= carr(16#06#) or carr(16#0e#);
    p07_mempage_b_ctrl   <= carr(16#07#) or carr(16#0f#);
    p10_lcd_status_ctrl  <= carr(16#10#) or carr(16#12#) or
                            carr(16#18#) or carr(16#1a#);
    p11_lcd_data_ctrl    <= carr(16#11#) or carr(16#13#) or
                            carr(16#19#) or carr(16#1b#);
    -- TODO port 14/15 flash lock
    -- TODO port 05 / 16/17 no exec mask

    -- out data -> buffers (for controllers)
    p01_buf : reg generic map(x"00", 8)
                  port map(clk, rst, ce, p01_kbd_ctrl.buf,
                           data_in, p01_kbd_buf);
    ports_out.p01_kbd <= (p01_kbd_buf, 
                          p01_kbd_ctrl.rd,
                          p01_kbd_ctrl.wr);

    p03_buf : reg generic map(x"0b", 8)
                  port map(clk, rst, ce, p03_intmask_ctrl.buf,
                           data_in, p03_intmask_buf);
    ports_out.p03_intmask <= (p03_intmask_buf,
                              p03_intmask_ctrl.rd,
                              p03_intmask_ctrl.wr);

    p04_buf : reg generic map(x"77", 8)
                  port map(clk, rst, ce, p04_mmap_int_ctrl.buf,
                           data_in, p04_mmap_int_buf);
    ports_out.p04_mmap_int <= (p04_mmap_int_buf,
                               p04_mmap_int_ctrl.rd,
                               p04_mmap_int_ctrl.wr);

    p05_buf : reg generic map(x"00", 8)
                  port map(clk, rst, ce, p05_protect_ctrl.buf,
                           data_in, p05_protect_buf);
    ports_out.p05_protect <= (p05_protect_buf,
                              p05_protect_ctrl.rd,
                              p05_protect_ctrl.wr);

    p06_buf : reg generic map(x"1f", 8)
                  port map(clk, rst, ce, p06_mempage_a_ctrl.buf,
                           data_in, p06_mempage_a_buf);
    ports_out.p06_mempage_a <= (p06_mempage_a_buf,
                                p06_mempage_a_ctrl.rd,
                                p06_mempage_a_ctrl.wr);

    p07_buf : reg generic map(x"1f", 8)
                  port map(clk, rst, ce, p07_mempage_b_ctrl.buf,
                           data_in, p07_mempage_b_buf);
    ports_out.p07_mempage_b <= (p07_mempage_b_buf,
                                p07_mempage_b_ctrl.rd,
                                p07_mempage_b_ctrl.wr);

    p10_buf : reg generic map(x"00", 8)
                  port map(clk, rst, ce, p10_lcd_status_ctrl.buf,
                           data_in, p10_lcd_status_buf);
    ports_out.p10_lcd_status <= (p10_lcd_status_buf,
                                 p10_lcd_status_ctrl.rd,
                                 p10_lcd_status_ctrl.wr);

    p11_buf : reg generic map(x"00", 8)
                  port map(clk, rst, ce, p11_lcd_data_ctrl.buf,
                           data_in, p11_lcd_data_buf);
    ports_out.p11_lcd_data <= (p11_lcd_data_buf,
                               p11_lcd_data_ctrl.rd,
                               p11_lcd_data_ctrl.wr);

    -- ports -> data bus
    parr_in <= (
        16#00# => (data => x"03"),          -- link port lines
        16#08# => (data => x"03"),
        16#01# => ports_in.p01_kbd,
        16#09# => ports_in.p01_kbd,
        16#02# => ports_in.p02_status,
        16#0a# => ports_in.p02_status,
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
        16#1b# => ports_in.p11_lcd_data,
        others => (data => x"00"));

    dbg.ce <= in_op or out_op;
    dbg.p01_kbd         <= parr_in(16#01#).data;
    dbg.p02_status      <= parr_in(16#02#).data;
    dbg.p03_intmask     <= parr_in(16#03#).data;
    dbg.p04_mmap_int    <= parr_in(16#04#).data;
    dbg.p06_mempage_a   <= parr_in(16#06#).data;
    dbg.p07_mempage_b   <= parr_in(16#07#).data;
    dbg.p10_lcd_status  <= parr_in(16#10#).data;
    dbg.p11_lcd_data    <= parr_in(16#11#).data;
end arch;
