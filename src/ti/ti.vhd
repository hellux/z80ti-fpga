library ieee;
use ieee.std_logic_1164.all;
use work.cmp_comm.all;
use work.ti_comm.all;

entity ti is port(
    clk, rst, ce : in std_logic;
-- z80 buses
    int : out std_logic;
    cbo : in ctrlbus_out;
    addr_log : in std_logic_vector(15 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0);
-- kbd ext
    keys_down : in keys_down_t;
    on_key_down : in std_logic;
-- vga ext
    x_vga : in std_logic_vector(6 downto 0);
    y_vga : in std_logic_vector(5 downto 0);
    data_vga : out std_logic;
-- mem ext
    rd, wr : out std_logic;
    addr_phy : out std_logic_vector(19 downto 0);
-- debug
    dbg : out dbg_ti_t);
end ti;

architecture arch of ti is
    component asic port(
        clk, rst, ce : in std_logic;
        in_op, out_op : in std_logic;
        addr : in std_logic_vector(4 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        ports_in : in ports_in_t;
        ports_out : out ports_out_t;
        dbg : out dbg_asic_t);
    end component;

    component status port(
        p05_protect : in port_out_t;
        p02_status : out port_in_t);
    end component;

    component interrupt port(
        clk, rst, ce : in std_logic;
        p03_intmask_o : in port_out_t;
        p04_mmap_int_o : in port_out_t;
        p04_mmap_int_i : out port_in_t;
        hwt_fin : in std_logic_vector(1 to 2);
        on_key_down : in std_logic;
        int : out std_logic;
        dbg : out dbg_int_t);
    end component;

    component mem_ctrl port(
        cbo : in ctrlbus_out;
        p04_mmap_int, p06_mempage_a, p07_mempage_b : in port_out_t;
        addr_log : in std_logic_vector(15 downto 0);
        addr_phy : out std_logic_vector(19 downto 0);
        rd, wr : out std_logic;
        dbg : out dbg_memctrl_t);
    end component;

    component hw_timers port(
        clk, rst, ce : in std_logic;
        p03_intmask : port_out_t;
        p04_mmap_int : port_out_t;
        fin : out std_logic_vector(1 to 2);
        dbg : out dbg_hwt_t);
    end component;

    component kbd_ctrl port(
        keys_down : in keys_down_t;
        p01_kbd_o : in port_out_t;
        p01_kbd_i : out port_in_t;
        dbg : out dbg_kbd_t);
    end component;

    component t6a04 port(
        clk, rst, ce : in std_logic;
        gmem_lcd_data : in std_logic_vector(7 downto 0);
        lcd_gmem_data : out std_logic_vector(7 downto 0);
        gmem_x : out std_logic_vector(5 downto 0);
        gmem_y : out std_logic_vector(4 downto 0);
        gmem_rd, gmem_wl : out std_logic;
        p10_command, p11_data_o : in port_out_t;
        p10_status, p11_data_i : out port_in_t;
        dbg : out dbg_lcd_t);
    end component;

    component pict_mem port(
        clk : in std_logic;
        rd, wl : in std_logic;
        page_in : in std_logic_vector(7 downto 0);
        x_lcd : in std_logic_vector(5 downto 0); -- row
        y_lcd : in std_logic_vector(4 downto 0); -- column page
        x_vga : in std_logic_vector(6 downto 0); -- column
        y_vga : in std_logic_vector(5 downto 0); -- row
        do_vga: out std_logic;
        do_lcd: out std_logic_vector(7 downto 0));
    end component;

    -- ctrl
    signal in_op, out_op : std_logic;

    -- lcd ctrl <-> pict mem
    signal x_lcd : std_logic_vector(5 downto 0);
    signal y_lcd : std_logic_vector(4 downto 0);
    signal gmem_lcd_data, lcd_gmem_data : std_logic_vector(7 downto 0);
    signal gmem_rd, gmem_wl : std_logic;

    -- asic <-> controllers
    signal ports_out : ports_out_t;
    signal ports_in : ports_in_t;

    -- interrupt sources
    signal hwt_fin : std_logic_vector(1 to 2);
    signal int_on_key : std_logic;
begin
    -- interpret control bus
    in_op   <= cbo.iorq and not cbo.m1 and cbo.rd;
    out_op  <= cbo.iorq and not cbo.m1 and cbo.wr;

    asic_c : asic port map(clk, rst, ce,
                           in_op, out_op,
                           addr_log(4 downto 0), data_in, data_out,
                           ports_in, ports_out,
                           dbg.asic);

    stat : status port map(ports_out.p05_protect, ports_in.p02_status);

    inth : interrupt port map(clk, rst, ce,
                              ports_out.p03_intmask,
                              ports_out.p04_mmap_int,
                              ports_in.p04_mmap_int,
                              hwt_fin, on_key_down,
                              int,
                              dbg.int);

    mctrl : mem_ctrl port map(cbo,
                              ports_out.p04_mmap_int,
                              ports_out.p06_mempage_a,
                              ports_out.p07_mempage_b,
                              addr_log,
                              addr_phy, rd, wr,
                              dbg.memctrl);

    hwtim : hw_timers port map(clk, rst, ce, ports_out.p03_intmask,
                               ports_out.p04_mmap_int, hwt_fin);

    kbd : kbd_ctrl port map(keys_down, ports_out.p01_kbd, ports_in.p01_kbd,
                            dbg.kbd);

    lcd : t6a04 port map(clk, rst, ce,
        gmem_lcd_data, lcd_gmem_data, x_lcd, y_lcd,
        gmem_rd, gmem_wl,
        ports_out.p10_lcd_status, ports_out.p11_lcd_data,
        ports_in.p10_lcd_status, ports_in.p11_lcd_data,
        dbg.lcd);
    gmem : pict_mem port map(clk,
                             gmem_rd, gmem_wl,
                             lcd_gmem_data, x_lcd, y_lcd, x_vga, y_vga,
                             data_vga, gmem_lcd_data);
end arch;
