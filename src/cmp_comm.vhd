library ieee;
use ieee.std_logic_1164.all;

package cmp_comm is
    type port_t is record
        data : std_logic_vector(7 downto 0);
        rd, wr : std_logic;
    end record;

    type io_ports_t is record
        lcd_data, lcd_status : port_t;
    end record;

    type io_data_t is record
        lcd_data, lcd_status : std_logic_vector(7 downto 0);
    end record;

    type keys_down_t is array of std_logic_vector(7 downto 0);
end cmp_comm;
