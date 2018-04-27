library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;
use work.io_comm.all;

entity io is port(
    clk, clk_z80, clk_vga, rst : in std_logic;
-- buses
    int : out std_logic;
    cbo : in ctrlbus_out;
    addr : in std_logic_vector(7 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0);
-- external
    vga_red : out std_logic_vector(2 downto 0);
    vga_green : out std_logic_vector(2 downto 0);
    vga_blue : out std_logic_vector(2 downto 1);
    hsync, vsync : out std_logic);
end io;

architecture arch of io is
    component asic port(
        clk : in std_logic;
        int : out std_logic;
        cbo : in ctrlbus_out;
        addr : in std_logic_vector(7 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        ports_in : in ports_in_t;
        ports_out : out ports_out_t;
        on_key_down : in std_logic;
        cry_fin : in std_logic_vector(1 to 3));
    end component;

    component timers port(
        clk, clk_z80, rst : in std_logic;
        t1_fo, t1_so, t1_do : in port_out_t;
        t1_fi, t1_si, t1_di : out port_in_t;
        t2_fo, t2_so, t2_do : in port_out_t;
        t2_fi, t2_si, t2_di : out port_in_t;
        t3_fo, t3_so, t3_do : in port_out_t;
        t3_fi, t3_si, t3_di : out port_in_t;
        cry_fin : out std_logic_vector(1 to 3));
    end component;

    component kbd_ctrl port(
        clk, rst : in std_logic;
        keys_down : in keys_down_t;
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

    component vga_motor port(
         clk : in std_logic;
         data : in std_logic;
         rst : in std_logic;
         x : out std_logic_vector(6 downto 0);
         y : out std_logic_vector(5 downto 0);
         vgaRed	: out std_logic_vector(2 downto 0);
         vgaGreen : out std_logic_vector(2 downto 0);
         vgaBlue : out std_logic_vector(2 downto 1);
         Hsync : out std_logic;
         Vsync : out std_logic);
    end component;

    -- lcd ctrl <-> pict mem <-> vga motor
    signal x_vga : std_logic_vector(6 downto 0);
    signal y_vga : std_logic_vector(5 downto 0);
    signal x_lcd : std_logic_vector(5 downto 0);
    signal y_lcd : std_logic_vector(4 downto 0);
    signal gmem_lcd_data, lcd_gmem_data : std_logic_vector(7 downto 0);
    signal gmem_vga_data : std_logic;
    signal gmem_rst, gmem_rd, gmem_wl : std_logic;

    -- kbd ctrl <-> kbd_enc
    signal keys_down : keys_down_t;

    -- asic <-> controllers
    signal ports_out : ports_out_t;
    signal ports_in : ports_in_t;
    signal on_key_down : std_logic;
    signal cry_fin : std_logic_vector(1 to 3);
begin
    asic_c : asic port map(clk_z80, int, cbo,
                           addr, data_in, data_out,
                           ports_in, ports_out,
                           on_key_down, cry_fin);

    tim : timers port map(clk, clk_z80, rst,
     ports_out.p30_t1_freq, ports_out.p31_t1_status, ports_out.p32_t1_value,
      ports_in.p30_t1_freq,  ports_in.p31_t1_status,  ports_in.p32_t1_value,
     ports_out.p33_t2_freq, ports_out.p34_t2_status, ports_out.p35_t2_value,
      ports_in.p33_t2_freq,  ports_in.p34_t2_status,  ports_in.p35_t2_value,
     ports_out.p36_t3_freq, ports_out.p37_t3_status, ports_out.p38_t3_value,
      ports_in.p36_t3_freq,  ports_in.p37_t3_status,  ports_in.p38_t3_value,
                          cry_fin);

    kbd : kbd_ctrl port map(clk_z80, rst, keys_down,
                            ports_out.p01_kbd, ports_in.p01_kbd);

    lcd : lcd_ctrl port map(clk_z80, rst,
        gmem_lcd_data, lcd_gmem_data, x_lcd, y_lcd,
        gmem_rst, gmem_rd, gmem_wl,
        ports_out.p10_lcd_status, ports_out.p11_lcd_data,
        ports_in.p10_lcd_status, ports_in.p11_lcd_data);
    gmem : pict_mem port map(clk, clk_z80, gmem_rst, gmem_rd, gmem_wl,
                             lcd_gmem_data, x_lcd, y_lcd, x_vga, y_vga,
                             gmem_vga_data, gmem_lcd_data);
    vga : vga_motor port map(clk, gmem_vga_data, rst, x_vga, y_vga,
                             vga_red, vga_green, vga_blue, hsync, vsync);
end arch;
