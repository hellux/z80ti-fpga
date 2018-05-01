library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ti_comm.all;
use work.util.all;

entity interrupt is port(
    clk, rst : in std_logic;
-- ports
    p03_intmask_o, p04_mmap_int_o : in port_out_t;
    p04_mmap_int_i : out port_in_t;
-- interrupt sources
    hwt_fin : in std_logic_vector(1 to 2);
    on_key_down : in std_logic;
-- cpu comm
    int_ack : in std_logic;
    int : out std_logic);
end interrupt;

architecture arch of interrupt is
    signal int_on_key : std_logic;
    signal hwt_int : std_logic_vector(1 to 2); -- hardware timers will trigger

    signal int_dev : int_dev_t; -- interrupt device
begin
    -- interrupt enable
    int_on_key <= p03_intmask_o.data(PO03_ON_KEY_INT);
    hwt_int(1) <= p03_intmask_o.data(PO03_HWT1_INT);
    hwt_int(2) <= p03_intmask_o.data(PO03_HWT2_INT);

    -- interrupt report
    p04_mmap_int_i.data <= (
        PI04_ON_KEY_INT  => bool_sl(int_dev = on_key),
        PI04_HWT1_INT    => bool_sl(int_dev = hwt1),
        PI04_HWT2_INT    => bool_sl(int_dev = hwt2),
        PI04_LINK_INT    => '0',
        PI04_ON_KEY_DOWN => on_key_down,
        others => '0');

    int <= bool_sl(int_dev /= none);
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                int_dev <= none;
            elsif int_dev = none then
                if on_key_down = '1' and int_on_key = '1' then
                    int_dev <= on_key;
                elsif hwt_int(1) = '1' and hwt_fin(1) = '1' then
                    int_dev <= hwt1;
                elsif hwt_int(1) = '1' and hwt_fin(2) = '1' then
                    int_dev <= hwt2;
                end if;
            elsif int_ack = '1' then
                -- don't bother sending address to dbus, appears to be random
                int_dev <= none;
            end if;
        end if;
    end process;
end arch;
