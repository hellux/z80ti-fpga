library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ti_comm.all;
use work.cmp_comm.all;

-- MISSING / TODO
-- does not reset keys down on 0x00 p01 write

entity kbd_ctrl is port(
    keys_down : in keys_down_t;
    p01_kbd_o : in port_out_t;
    p01_kbd_i : out port_in_t;
-- debug
    dbg : out dbg_kbd_t);
end kbd_ctrl;

architecture arch of kbd_ctrl is
    signal grp : std_logic_vector(7 downto 0);
begin
    grp <= p01_kbd_o.data;

    and_groups : process(grp, keys_down)
        variable result : std_logic_vector(7 downto 0);
    begin
        result := (others => '1');
        for i in keys_down'range loop
            if grp(i) = '0' then
                result := result and keys_down(i);
            end if;
        end loop;
        p01_kbd_i <= (data => result);
    end process;

    dbg.grp <= grp;
end arch;
