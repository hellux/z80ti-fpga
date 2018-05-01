library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ti_comm.all;
use work.util.all;

entity status is port(
    p05_protect : in port_out_t;
    p02_status : out port_in_t);
end status;

architecture arch of status is
begin
    p02_status.data <= (
        PO02_73_83              => '0',
        PO02_LINK_ASSIST        => '0',
        PO02_PROTECT_2          => p05_protect.data(2),
        PO02_PROTECT_1          => p05_protect.data(1),
        PO02_PROTECT_0          => p05_protect.data(0),
        PO02_FLASH_UNLOCKED     => '0', -- TODO
        PO02_NOT_73             => '1',
        PO02_BATTERY_GOOD       => '1');
end arch;
