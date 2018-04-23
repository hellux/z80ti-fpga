library ieee;
use ieee.std_logic_1164.all;

package cmp_comm is
    constant LCD_COLS : integer := 120;
    constant LCD_ROWS : integer := 64;

    type port_t is record
        data : std_logic_vector(7 downto 0);
        rd, wr : std_logic;
    end record;

    type io_ports_t is record
        p10_lcd_status, p11_lcd_data : port_t;
    end record;

    type io_data_t is record
        p10_lcd_status, p11_lcd_data : std_logic_vector(7 downto 0);
    end record;

    type keys_down_t is array(7 downto 0) of std_logic_vector(7 downto 0);
end cmp_comm;
