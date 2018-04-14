library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity asic is port(
    clk, rst : in std_logic;
    cbi : out ctrlbus_in;
    cbo : in ctrlbus_out;
    addr : in std_logic_vector(15 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0));
end asic;

architecture arch of asic is
    signal port_rd_data : std_logic_vector(7 downto 0);
begin
    data_out <= port_rd_data when cbo.iorq = '1' and cbo.rd = '1' else x"00";
    with addr(7 downto 0) select port_rd_data <= 
        x"00"       when x"00",         -- lines
        x"00"       when x"01",         -- TODO keypad read keys
        x"e1"       when x"02",         -- battery level
        x"00"       when x"03",         -- TODO interrupt mask
        x"00"       when x"04",         -- TODO interrupt trigger device
        x"00"       when x"05",         -- TODO current RAM page
        x"00"       when x"06",         -- TODO mem page A
        x"00"       when x"07",         -- TODO mem page B
        x"00"       when x"08",         -- TODO link assist enable
        x"00"       when x"09",         -- TODO link assist status
        x"00"       when x"0a",         -- TODO link assist input buffer
        x"00"       when x"0b",         -- cpu speed 2 signal rate
        x"00"       when x"0c",         -- cpu speed 3 signal rate
        x"00"       when x"0d",         -- link assist output buffer
        x"00"       when x"0e",         -- TODO mem a high flash addr
        x"00"       when x"0f",         -- TODO mem b high flash addr
        x"00"       when x"10"|x"12",   -- TODO lcd status
        x"00"       when x"11"|x"13",   -- TODO current byte in lcd ram
        x"00"       when x"14",         -- flash control
        x"45"       when x"15",         -- asic version
        x"00"       when x"16",         -- flash page exclusion
        x"00"       when x"17",         -- ??, always reads 0
        x"00"       when x"18",         -- md5 always 0
        x"00"       when x"19",         -- md5 always 0
        x"00"       when x"1a",         -- md5 always 0
        x"00"       when x"1b",         -- md5 always 0
        x"00"       when x"1c",         -- TODO md5 value
        x"00"       when x"1d",         -- TODO md5 value >> 8
        x"00"       when x"1e",         -- TODO md5 value >> 16
        x"00"       when x"1f",         -- TODO md5 value >> 25
        x"00"       when x"20",         -- TODO cpu speed (set to 4MHz)
        x"00"       when x"21",         -- hardware type
        x"00"       when x"22",         -- TODO flash lower limit
        x"00"       when x"23",         -- TODO flash upper limit
        x"00"       when x"25",         -- TODO ram exec lower limit
        x"00"       when x"26",         -- TODO ram exec upper limit
        x"00"       when x"27",         -- TODO block mem map $c000
        x"00"       when x"28",         -- TODO block mem map 8000h
        x"00"       when x"29",         -- TODO lcd delay 6Mhz
        x"00"       when x"2a",         -- TODO lcd delay 15Mhz
        x"00"       when x"2b",         -- TODO lcd delay 15Mhz 02
        x"00"       when x"2c",         -- TODO lcd delay 15Mhz 03
        x"00"       when x"2d",         -- TODO crystal control
        x"00"       when x"2e",         -- TODO mem access delay
        x"00"       when x"2f",         -- TODO lcd wait delay
        x"00"       when x"30",         -- TODO timer 0 freq
        x"00"       when x"31",         -- TODO timer 0 status
        x"00"       when x"32",         -- TODO timer 0 value
        x"00"       when x"33",         -- TODO timer 1 freq
        x"00"       when x"34",         -- TODO timer 1 status
        x"00"       when x"35",         -- TODO timer 1 value
        x"00"       when x"36",         -- TODO timer 2 freq
        x"00"       when x"37",         -- TODO timer 2 status
        x"00"       when x"38",         -- TODO timer 2 value
        x"f0"       when x"39",         -- GPIO conf
        x"00"       when x"40",         -- TODO clock mode
        x"00"       when x"41",         -- TODO clock input
        x"00"       when x"42",         -- TODO clock input
        x"00"       when x"43",         -- TODO clock input
        x"00"       when x"44",         -- TODO clock input
        x"00"       when x"45"|x"46"|
                         x"47"|x"48",   -- TODO clock mode
        x"22"       when x"4c",         -- usb ctrl status
        x"a5"       when x"4d",         -- usb cable status (disconnected)
        x"1f"       when x"55",         -- usb interrupt state
        x"00"       when x"56",         -- usb line events
        x"50"       when x"57",         -- usb live event mask
        "--------"  when others;

    cbi.reset <= '0';
    cbi.wt <= '0';
    cbi.int <= '0';
    cbi.nmi <= '0';
    cbi.busrq <= '0';
end arch;
