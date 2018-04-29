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
        p04_mmap_int : port_in_t;
        p10_lcd_status, p11_lcd_data : port_in_t;
    end record;

    type ports_out_t is record
        p01_kbd : port_out_t;
        p03_intmask : port_out_t;
        p04_mmap_int : port_out_t;
        p06_mempage_a, p07_mempage_b : port_out_t;
        p10_lcd_status, p11_lcd_data : port_out_t;
    end record;

    type keys_down_t is array(0 to 6) of std_logic_vector(7 downto 0);

    type int_dev_t is (none, on_key, hwt1, hwt2);
end ti_comm;
