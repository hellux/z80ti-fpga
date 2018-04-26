library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cmp_comm.all;
use work.util.all;

entity kbd_ctrl is port(
    clk, rst : in std_logic;
    keys_down : in keys_down_t;
    kbd_in : in port_out_t;
    kbd_out : out port_in_t);
end kbd_ctrl;

-- kbd_in --
-- ff -> rst kbd
-- else -> bits 6-0 mask for selected groups (0 to enable group)
-- eg "0000_0001" to select only group 0

-- kbd_out --
-- keys pressed in selected groups (0 is pressed)

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
                  port map(clk, grp_rst, kbd_in.wr, kbd_in.data, grp);
    grp_rst <= rst or (kbd_in.wr and bool_sl(kbd_in.data = x"ff"));

    and_groups : process(grp, keys_down)
        variable result : std_logic_vector(7 downto 0);
    begin
        result := (others => '1');
        for i in keys_down'range loop
            if grp(i) = '0' then
                result := result and keys_down(i);
            end if;
        end loop;
        kbd_out <= (result, '0');
    end process;
end arch;
