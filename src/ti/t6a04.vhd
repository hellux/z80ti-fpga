library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ti_comm.all;
use work.util.all;

-- TODO / MISSING
--  - power on/off
--  - contrast
--  - gmem reset

entity t6a04 is port(
    clk, rst, ce : in std_logic;
    gmem_lcd_data : in std_logic_vector(7 downto 0);
    lcd_gmem_data : out std_logic_vector(7 downto 0);
    gmem_x : out std_logic_vector(5 downto 0);
    gmem_y : out std_logic_vector(4 downto 0);
    gmem_rd, gmem_wl : out std_logic;
    p10_command, p11_data_o : in port_out_t;
    p10_status, p11_data_i : out port_in_t;
    dbg : out dbg_lcd_t);
end t6a04;

architecture arch of t6a04 is
    component reg generic(init : std_logic_vector; size : integer); port(
        clk, rst, ce : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;

    type lcd_mode_t is record
        up: std_logic; -- 0 dec, 1 inc
        counter : std_logic; -- 0 x, 1 y
        active : std_logic;
        wl : std_logic; -- 0: 6bit, 1: 8bit
    end record;

    -- ctrl interpret
    signal ptr_upd : std_logic; -- increment/decrement enable pulse
    signal x_cnten, y_cnten : std_logic; -- x/y count enable
    signal x_ld, y_ld : std_logic; -- load x/y counter
    signal z_ld : std_logic;

    signal x, x_in : unsigned(5 downto 0); -- row
    signal y, y_in : unsigned(4 downto 0); -- column page
    signal z, z_in : std_logic_vector(5 downto 0);

    constant MODE_INIT : lcd_mode_t :=
        (up => '1', counter => '0', wl => '1', active => '0');
    signal mode : lcd_mode_t := MODE_INIT;
begin
    ptr_upd <= p11_data_o.rd or p11_data_o.wr;

    x_cnten <= ptr_upd and not mode.counter;
    x_ld <= p10_command.wr and bool_sl(p10_command.data(7 downto 6) = "10");
    x_in <= unsigned(p10_command.data(5 downto 0));
    x_cntr : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                x <= (others => '0');
            elsif ce = '1' then
                if x_ld = '1' then
                    x <= x_in;
                elsif x_cnten = '1' then
                    if mode.up = '1' then
                        x <= x + 1;
                    else
                        x <= x - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    y_cnten <= ptr_upd and mode.counter;
    y_ld <= p10_command.wr and bool_sl(p10_command.data(7 downto 5) = "001");
    y_in <= unsigned(p10_command.data(4 downto 0));
    y_cntr : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                y <= (others => '0');
            elsif ce = '1' then
                if y_ld = '1' then
                    y <= y_in;
                elsif y_cnten = '1' then
                    if mode.up = '1' then
                        if (mode.wl = '1' and y >= LCD_COLS/8-1) or
                           (mode.wl = '0' and y >= LCD_COLS/6-1)
                        then
                            y <= (others => '0');
                        else
                            y <= y + 1;
                        end if;
                    else
                        if y = 0 then
                            if mode.wl = '1' then
                                y <= to_unsigned(LCD_COLS/8-1, 5);
                            else
                                y <= to_unsigned(LCD_COLS/6-1, 5);
                            end if;
                        else
                            y <= y - 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    z_ld <= p10_command.wr and bool_sl(p10_command.data(7 downto 6) = "01");
    z_in <= p10_command.data(5 downto 0);
    z_reg : reg generic map("000000", 6)
                port map(clk, rst, ce, z_ld, z_in, z);

    -- mode / ctrl
    set_mode : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                mode <= MODE_INIT;
            elsif ce = '1' then
                if p10_command.wr = '1' then
                    case p10_command.data is
                    when x"00"|x"01" => 
                        mode.wl <= p10_command.data(0);
                    when x"02"|x"03" =>
                        mode.active <= p10_command.data(1);
                    when x"04"|x"05"|x"06"|x"07" =>
                        mode.up <= p10_command.data(0);
                        mode.counter <= p10_command.data(1);
                    when others => null; end case;
                end if;
            end if;
        end if;
    end process;

    -- gmem <-> t6a04
    lcd_gmem_data <= p11_data_o.data;
    gmem_x <= std_logic_vector(unsigned(z) + x);
    gmem_y <= std_logic_vector(y);
    gmem_rd <= '1' when p11_data_o.wr = '1' else '0';
    gmem_wl <= mode.wl;

    -- t6a04 -> z80
    p11_data_i <= (data => gmem_lcd_data);
    p10_status.data <=
        (PI10_AUTO_INC_DEC   => mode.up,
         PI10_AUTO_Y_X       => mode.counter,
         PI10_RESET_STATE    => '0',
         PI10_LCD_ENABLED    => mode.active,
         PI10_WL_8_6         => mode.wl,
         PI10_LCD_BUSY       => '0',
         others              => '0');

    -- debug
    dbg.x <= std_logic_vector(x);
    dbg.y <= std_logic_vector(y);
    dbg.z <= z;
    dbg.up <= mode.up;
    dbg.counter <= mode.counter;
    dbg.active <= mode.active;
    dbg.wl <= mode.wl;
end arch;
