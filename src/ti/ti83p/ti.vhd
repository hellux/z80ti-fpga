library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;
use work.ti_comm.all;

entity ti is port(
    clk, clk_z80, clk_vga, rst : in std_logic;
-- buses
    int : out std_logic;
    cbo : in ctrlbus_out;
    addr_z80 : in std_logic_vector(15 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0);
-- external
    keys_down : in keys_down_t;
    on_key_down : in std_logic;
    x_vga : in std_logic_vector(6 downto 0);
    y_vga : in std_logic_vector(5 downto 0);
    data_vga : out std_logic;
    addr_ext : out std_logic_vector(19 downto 0));
end ti;

architecture arch of ti is
    component asic port(
        clk, clk_z80, rst : in std_logic;
        int : out std_logic;
        cbo : in ctrlbus_out;
        addr : in std_logic_vector(7 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        ports_in : in ports_in_t;
        ports_out : out ports_out_t;
        on_key_down : in std_logic;
        int_on_key : out std_logic;
        hwt_freq : out std_logic_vector(1 downto 0);
        hwt_fin : in std_logic_vector(1 to 2));
    end component;

    component mmapper port(
        signal ctrl_mmap : in std_logic_vector(7 downto 0);
        signal ctrl_page_a, ctrl_page_b : in std_logic_vector(7 downto 0);
        signal addr_z80 : in std_logic_vector(15 downto 0);
        signal addr_ext : out std_logic_vector(19 downto 0));
    end component;

    component hw_timers port(
        clk, rst : in std_logic;
        freq : in std_logic_vector(1 downto 0);
        fin : out std_logic_vector(1 downto 0));
    end component;

    component kbd_ctrl port(
        clk, rst : in std_logic;
        keys_down : in keys_down_t;
        on_key_down : in std_logic;
        int_on_key : in std_logic;
        kbd_o : in port_out_t;
        kbd_i : out port_in_t);
    end component;

    component lcd_ctrl port(
        clk, rst : in std_logic;
        gmem_data_o : in std_logic_vector(7 downto 0);
        gmem_data_i : out std_logic_vector(7 downto 0);
        gmem_x : out std_logic_vector(5 downto 0);
        gmem_y : out std_logic_vector(4 downto 0);
        gmem_rst, gmem_rd, gmem_wl : out std_logic;
        status_o, data_o : in port_out_t;
        status_i, data_i : out port_in_t);
    end component;

    component pict_mem port(
        clk, clk_z80, rst : in std_logic;
        rd, wl : in std_logic;
        page_in : in std_logic_vector(7 downto 0);
        x_lcd : in std_logic_vector(5 downto 0); -- row
        y_lcd : in std_logic_vector(4 downto 0); -- column page
        x_vga : in std_logic_vector(6 downto 0); -- column
        y_vga : in std_logic_vector(5 downto 0); -- row
        do_vga: out std_logic;
        do_lcd: out std_logic_vector(7 downto 0));
    end component;

    -- lcd ctrl <-> pict mem
    signal x_lcd : std_logic_vector(5 downto 0);
    signal y_lcd : std_logic_vector(4 downto 0);
    signal gmem_lcd_data, lcd_gmem_data : std_logic_vector(7 downto 0);
    signal gmem_rst, gmem_rd, gmem_wl : std_logic;

    -- asic <-> controllers
    signal ports_out : ports_out_t;
    signal ports_in : ports_in_t;
    signal int_on_key : std_logic;
    signal hwt_fin : std_logic_vector(1 to 2);
    signal hwt_freq : std_logic_vector(1 downto 0);
begin
    asic_c : asic port map(clk, clk_z80, rst, int, cbo,
                           addr_z80(7 downto 0), data_in, data_out,
                           ports_in, ports_out,
                           on_key_down,
                           int_on_key,
                           hwt_freq, hwt_fin);

    mm : mmapper port map(ports_out.p04_mmap_int.data,
                          ports_out.p06_mempage_a.data,
                          ports_out.p07_mempage_b.data,
                          addr_z80, addr_ext);

    hwtim : hw_timers port map(clk, rst, hwt_freq, hwt_fin);

    kbd : kbd_ctrl port map(clk_z80, rst, keys_down, on_key_down, int_on_key,
                            ports_out.p01_kbd, ports_in.p01_kbd);

    lcd : lcd_ctrl port map(clk_z80, rst,
        gmem_lcd_data, lcd_gmem_data, x_lcd, y_lcd,
        gmem_rst, gmem_rd, gmem_wl,
        ports_out.p10_lcd_status, ports_out.p11_lcd_data,
        ports_in.p10_lcd_status, ports_in.p11_lcd_data);
    gmem : pict_mem port map(clk, clk_z80, gmem_rst, gmem_rd, gmem_wl,
                             lcd_gmem_data, x_lcd, y_lcd, x_vga, y_vga,
                             data_vga, gmem_lcd_data);
end arch;
