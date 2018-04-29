library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ti_comm.all;
use work.util.all;

-- TODO / MISSING
--  - power on/off
--  - contrast

entity lcd_ctrl is port(
    clk, rst : in std_logic;
    gmem_data_o : in std_logic_vector(7 downto 0);
    gmem_data_i : out std_logic_vector(7 downto 0);
    gmem_x : out std_logic_vector(5 downto 0);
    gmem_y : out std_logic_vector(4 downto 0);
    gmem_rst, gmem_rd, gmem_wl : out std_logic;
    p10_status_o, p11_data_o : in port_out_t;
    p10_status_i, p11_data_i : out port_in_t);
end lcd_ctrl;

architecture arch of lcd_ctrl is
    component udcntr generic(size : integer); port(
        clk, rst : in std_logic;
        ld : in std_logic;
        ud : in std_logic;
        ce1, ce2 : in std_logic;
        wrap : in integer range 0 to size-1;
        di : in integer range 0 to size-1;
        do : out integer range 0 to size-1);
    end component;

    component reg generic(size : integer); port(
        clk, rst : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;

    type lcd_mode_t is record
        inc : std_logic_vector(1 downto 0); -- 00 y--, 01 y++, 10 x--, 11 x++
        active : std_logic;
        wl : std_logic; -- 0: 6bit, 1: 8bit
        busy : std_logic;
    end record;

    -- ctrl interpret
    signal ptr_upd : std_logic;      -- increment/decrement pulse
    signal x_cnt, y_cnt : std_logic; -- x/y counter is selected
    signal x_ld, y_ld : std_logic;   -- load x/y counter
    signal z_ld : std_logic;

    signal x, x_in : integer range 0 to LCD_ROWS-1; -- row
    signal y, y_in, y_wrap : integer range 0 to LCD_COLS/6-1; -- column page
    signal z, z_in : std_logic_vector(5 downto 0);

    signal mode, mode_next : lcd_mode_t;
begin
    ptr_upd <= p11_data_o.rd or p11_data_o.wr;

    x_cnt <= not mode.inc(0);
    x_ld <= p10_status_o.wr and bool_sl(p10_status_o.data(7 downto 6) = "10");
    x_in <= to_integer(unsigned(p11_data_o.data(5 downto 0)));
    x_cntr : udcntr generic map(LCD_ROWS)
                    port map(clk, rst, x_ld, mode.inc(1), ptr_upd, x_cnt,
                             LCD_ROWS-1, x_in, x);

    y_cnt <= mode.inc(0);
    y_ld <= p10_status_o.wr and bool_sl(p10_status_o.data(7 downto 5) = "001");
    y_in <= to_integer(unsigned(p11_data_o.data(4 downto 0)));
    y_wrap <= LCD_COLS/6-1 when mode.wl = '1' else LCD_COLS/8-1;
    y_cntr : udcntr generic map(LCD_COLS/6)
                    port map(clk, rst, y_ld, mode.inc(1), ptr_upd, y_cnt,
                             y_wrap, y_in, y);

    z_ld <= p10_status_o.wr and bool_sl(p10_status_o.data(7 downto 6) = "01");
    z_in <= p11_data_o.data(5 downto 0);
    z_reg : reg generic map(6)
                port map(clk, rst, z_ld, z_in, z);

    gmem_data_i <= p11_data_o.data;
    gmem_x <= std_logic_vector(unsigned(z) + to_unsigned(x, gmem_x'length));
    gmem_y <= std_logic_vector(to_unsigned(y, gmem_y'length));
    gmem_rst <= rst;
    gmem_rd <= '1' when p11_data_o.wr = '1' else '0';
    gmem_wl <= mode.wl;

    p11_data_i <= (data => gmem_data_o);
    p10_status_i <= (data => mode.busy &
                             mode.wl &
                             mode.active &
                             "0--" &
                             mode.inc);

    update_mode : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                mode <= (inc => "00", others => '0');
            else
                mode <= mode_next;
            end if;
        end if;
    end process;

    next_mode : process(p10_status_o.data, p10_status_o.wr, mode)
        variable m : lcd_mode_t;
    begin
        m := mode;
        if p10_status_o.wr = '1' then
            case p10_status_o.data is
            when x"00"|x"01" => m.wl := p10_status_o.data(0);
            when x"02"|x"03" => m.active := p10_status_o.data(1);
            when x"04"|x"05"|x"06"|x"07" =>
                m.inc := p10_status_o.data(1 downto 0);
            when others => null; end case;
        end if;
        mode_next <= m;
    end process;
end arch;
