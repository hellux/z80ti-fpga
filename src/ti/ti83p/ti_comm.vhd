library ieee;
use ieee.std_logic_1164.all;

package ti_comm is
    constant LCD_COLS : integer := 120;
    constant LCD_ROWS : integer := 64;

    type port_in_t is record
        data : std_logic_vector(7 downto 0);
    end record;

    type port_out_t is record
        data : std_logic_vector(7 downto 0);
        rd, wr : std_logic;
    end record;

    type ports_in_t is record
        p01_kbd : port_in_t;
        p02_status : port_in_t;
        p04_mmap_int : port_in_t;
        p10_lcd_status, p11_lcd_data : port_in_t;
    end record;

    type ports_out_t is record
        p01_kbd : port_out_t;
        p03_intmask : port_out_t;
        p04_mmap_int : port_out_t;
        p05_protect : port_out_t;
        p06_mempage_a, p07_mempage_b : port_out_t;
        p10_lcd_status, p11_lcd_data : port_out_t;
    end record;

    type keys_down_t is array(0 to 6) of std_logic_vector(7 downto 0);

    type int_dev_t is (none, on_key, hwt1, hwt2);

    type hwt_divs_t is array(0 to 3) of std_logic_vector(19 downto 0);

    constant HWT1_DIVS : hwt_divs_t :=
        (x"2b98a",  -- 560 Hz
         x"62719",  -- 248 Hz
         x"8f9ca",  -- 170 Hz
         x"cee61"); -- 118 Hz

    constant HWT2_DIVS : hwt_divs_t :=
        (x"0ae63",  -- 1120 Hz
         x"311f6",  -- 497 Hz
         x"46f89",  -- 344 Hz
         x"67730"); -- 236 Hz

    constant PO03_ON_KEY_INT    : natural := 0;
    constant PO03_HWT1_INT      : natural := 1;
    constant PO03_HWT2_INT      : natural := 2;

    constant PI04_ON_KEY_INT    : natural := 0;
    constant PI04_HWT1_INT      : natural := 1;
    constant PI04_HWT2_INT      : natural := 2;
    constant PI04_ON_KEY_DOWN   : natural := 3;
    constant PI04_LINK_INT      : natural := 4;
    constant PO04_HWT_FREQ_L    : natural := 2;
    constant PO04_HWT_FREQ_R    : natural := 1;
end ti_comm;
