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
    p02_status.data <= '0' &    -- reset for ti83p/ti73, else set
                       '0' &    -- link assist available
                       p05_protect.data(2 downto 0) &
                       '0' &    -- flash unlocked TODO
                       '1' &    -- reset on ti73
                       '1';     -- batteries good
end arch;
