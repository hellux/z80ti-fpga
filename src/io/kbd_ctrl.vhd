library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.io_comm.all;
use work.util.all;

entity kbd_ctrl is port(
    clk, rst : in std_logic;
    keys_down : in keys_down_t;
    on_key_down : in std_logic;
    int_on_key : in std_logic;
    kbd_o : in port_out_t;
    kbd_i : out port_in_t);
end kbd_ctrl;

architecture arch of kbd_ctrl is
    component reg generic(size : integer); port(
        clk, rst : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;

    signal grp : std_logic_vector(7 downto 0);
    signal grp_rst : std_logic;
begin
    grp_reg : reg generic map(8)
                  port map(clk, grp_rst, kbd_o.wr, kbd_o.data, grp);
    grp_rst <= rst or (kbd_o.wr and bool_sl(kbd_o.data = x"ff"));

    kbd_i.int <= int_on_key and on_key_down;
    and_groups : process(grp, keys_down)
        variable result : std_logic_vector(7 downto 0);
    begin
        result := (others => '1');
        for i in keys_down'range loop
            if grp(i) = '0' then
                result := result and keys_down(i);
            end if;
        end loop;
        kbd_i.data <= result;
    end process;
end arch;
