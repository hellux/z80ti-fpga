library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cmp_comm.all;

entity kbd_ctrl is port(
    clk, rst : in std_logic;
    kbd_rd, kbd_wr : in std_logic;
    keys_down_t : in keys_down_t;
    kbd_in : in std_logic_vector(7 downto 0);
    kbd_out : out std_logic_vector(7 downto 0));
end lcd_ctrl;

architecture of kbd_ctrl is
    signal state : kbd_state_t;
    signal grp, grp_next : std_logic_vector(7 downto 0);
begin
    update : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                grp <= (others => '0');
            else
                grp <= grp_next;
            end if;
    end if;

    next_grp : process(kbd_wr, kbd_in) begin
        if kbd_rd = '1' then
            grp_next <= kbd_in;
        end if;
    end process;
end arch;
