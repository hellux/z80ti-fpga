library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.cmp_comm.all;

entity asic is port(
    clk : in std_logic;
    cbi : out ctrlbus_in;
    cbo : in ctrlbus_out;
    addr : in std_logic_vector(7 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0);
    ports_in : in io_data_t;
    ports_out : out io_ports_t);
end asic;

architecture arch of asic is
    type io_ports_array_t is array(0 to 255) of port_t;
    type data_array_t is array(0 to 255) of std_logic_vector(7 downto 0);
    type rw_array_t is array(0 to 255) of std_logic;

    signal a : integer range 0 to 255 := 0;
    signal darr_in, darr_out : data_array_t;
    signal parr_out : io_ports_array_t;
    signal rd_arr, wr_arr : rw_array_t;
    signal port_rd_data : std_logic_vector(7 downto 0);
begin
    a <= to_integer(unsigned(addr));
    data_out <= port_rd_data when cbo.iorq = '1' and cbo.rd = '1' else x"00";
    port_rd_data <= darr_in(a);

    process(darr_out, rd_arr, wr_arr) begin
        for i in parr_out'range loop
            parr_out(i) <= (data => darr_out(i),
                            rd => rd_arr(i),
                            wr => wr_arr(i));
        end loop;
    end process;

    process(a, data_in) begin
        darr_out <= (others => (others => '0'));
        darr_out(a) <= data_in;
    end process;

    process(a, cbo.rd) begin
        rd_arr <= (others => '-');
        rd_arr(a) <= cbo.iorq and cbo.rd;
    end process;

    process(a, cbo.wr) begin
        wr_arr <= (others => '0');
        wr_arr(a) <= cbo.iorq and cbo.wr;
    end process;

    cbi.reset <= '0';
    cbi.wt <= '0';
    cbi.int <= '0';
    cbi.nmi <= '0';
    cbi.busrq <= '0';

    ports_out.lcd_status <= parr_out(16);
    ports_out.lcd_data <= parr_out(17);

    darr_in <= (
        16#00# => x"00",               -- lines
        16#01# => x"00",               -- TODO keypad read keys
        16#02# => x"e1",               -- battery level
        16#03# => x"00",               -- TODO interrupt mask
        16#04# => x"00",               -- TODO interrupt trigger device
        16#05# => x"00",               -- TODO current RAM page
        16#06# => x"00",               -- TODO mem page A
        16#07# => x"00",               -- TODO mem page B
        16#08# => x"00",               -- TODO link assist enable
        16#09# => x"00",               -- TODO link assist status
        16#0a# => x"00",               -- TODO link assist input buffer
        16#0b# => x"00",               -- cpu speed 2 signal rate
        16#0c# => x"00",               -- cpu speed 3 signal rate
        16#0d# => x"00",               -- link assist output buffer
        16#0e# => x"00",               -- TODO mem a high flash addr
        16#0f# => x"00",               -- TODO mem b high flash addr
        16#10# => ports_in.lcd_status,
        16#11# => ports_in.lcd_data,
        16#12# => ports_in.lcd_status,
        16#13# => ports_in.lcd_data,
        16#14# => x"00",               -- flash control
        16#15# => x"45",               -- asic version
        16#16# => x"00",               -- flash page exclusion
        16#17# => x"00",               -- ??, always reads 0
        16#18# => x"00",               -- md5 always 0
        16#19# => x"00",               -- md5 always 0
        16#1a# => x"00",               -- md5 always 0
        16#1b# => x"00",               -- md5 always 0
        16#1c# => x"00",               -- TODO md5 value
        16#1d# => x"00",               -- TODO md5 value >> 8
        16#1e# => x"00",               -- TODO md5 value >> 16
        16#1f# => x"00",               -- TODO md5 value >> 25
        16#20# => x"00",               -- TODO cpu speed (set to 4MHz)
        16#21# => x"00",               -- hardware type
        16#22# => x"00",               -- TODO flash lower limit
        16#23# => x"00",               -- TODO flash upper limit
        16#25# => x"00",               -- TODO ram exec lower limit
        16#26# => x"00",               -- TODO ram exec upper limit
        16#27# => x"00",               -- TODO block mem map $c000
        16#28# => x"00",               -- TODO block mem map 8000h
        16#29# => x"00",               -- TODO lcd delay 6Mhz
        16#2a# => x"00",               -- TODO lcd delay 15Mhz
        16#2b# => x"00",               -- TODO lcd delay 15Mhz 02
        16#2c# => x"00",               -- TODO lcd delay 15Mhz 03
        16#2d# => x"00",               -- TODO crystal control
        16#2e# => x"00",               -- TODO mem access delay
        16#2f# => x"00",               -- TODO lcd wait delay
        16#30# => x"00",               -- TODO timer 0 freq
        16#31# => x"00",               -- TODO timer 0 status
        16#32# => x"00",               -- TODO timer 0 value
        16#33# => x"00",               -- TODO timer 1 freq
        16#34# => x"00",               -- TODO timer 1 status
        16#35# => x"00",               -- TODO timer 1 value
        16#36# => x"00",               -- TODO timer 2 freq
        16#37# => x"00",               -- TODO timer 2 status
        16#38# => x"00",               -- TODO timer 2 value
        16#39# => x"f0",               -- GPIO conf
        16#40# => x"00",               -- TODO clock mode
        16#41# => x"00",               -- TODO clock input
        16#42# => x"00",               -- TODO clock input
        16#43# => x"00",               -- TODO clock input
        16#44# => x"00",               -- TODO clock input
        16#45# => x"00",               -- TODO clock mode
        16#46# => x"00",               -- TODO clock mode
        16#47# => x"00",               -- TODO clock mode
        16#48# => x"00",               -- TODO clock mode
        16#4c# => x"22",               -- usb ctrl status
        16#4d# => x"a5",               -- usb cable status (disconnected)
        16#55# => x"1f",               -- usb interrupt state
        16#56# => x"00",               -- usb line events
        16#57# => x"50",               -- usb live event mask
        others => (x"00"));
end arch;
