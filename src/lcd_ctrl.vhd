library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cmp_comm.all;

-- TODO / MISSING
--  - power on/off
--  - rowshift (z register/counter)
--  - contrast

entity lcd_ctrl is port(
    clk, rst : in std_logic;
    gmem_data_in : in std_logic_vector(7 downto 0);
    gmem_data_out : out std_logic_vector(7 downto 0);
    gmem_x : out std_logic_vector(5 downto 0);
    gmem_y : out std_logic_vector(4 downto 0);
    gmem_rst, gmem_rd, gmem_wl : out std_logic;
    status_rd, data_rd : in std_logic;
    status_wr, data_wr : in std_logic;
    status_in, data_in : in std_logic_vector(7 downto 0);
    status_out, data_out : out std_logic_vector(7 downto 0));
end lcd_ctrl;

architecture arch of lcd_ctrl is
    type lcd_mode_t is record
        inc : std_logic_vector(1 downto 0); -- counter & up/down
        active : std_logic;
        wl : std_logic; -- 0: 6bit, 1: 8bit
        busy : std_logic;
    end record;

    -- helpers
    signal control : unsigned(7 downto 0);

    signal mode, mode_next : lcd_mode_t;
    signal x, x_next : integer range 0 to 63; -- row
    signal y, y_next : integer range 0 to 19; -- column page
begin
    control <= unsigned(status_in);

    gmem_data_out <= data_in;
    gmem_x <= std_logic_vector(to_unsigned(x, gmem_x'length));
    gmem_y <= std_logic_vector(to_unsigned(y, gmem_y'length));
    gmem_rst <= rst;
    gmem_rd <= '1' when data_wr = '1' else '0';
    gmem_wl <= mode.wl;

    data_out <= gmem_data_in;
    status_out <= mode.busy & mode.wl & mode.active & "0--" & mode.inc;

    update : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                mode <= (inc => "00", others => '0');
                x <= 0; y <= 0;
            else
                mode <= mode_next;
                x <= x_next; y <= y_next;
            end if;
        end if;
    end process;

    next_mode : process(control, status_wr, mode)
        variable m : lcd_mode_t;
    begin
        m := mode;
        if status_wr = '1' then
            case control is
            when x"00"|x"01" => m.wl := control(0);
            when x"02"|x"03" => m.active := control(1);
            when x"04"|x"05"|x"06"|x"07" =>
                m.inc := std_logic_vector(control(1 downto 0));
            when others => null; end case;
        end if;
        mode_next <= m;
    end process;

    next_ptr : process(data_rd, data_wr, status_wr, control, mode, x, y)
        variable x_tmp, y_tmp : integer;
    begin
        x_tmp := x; y_tmp := y;
        if data_rd = '1' or data_wr = '1' then
            -- inc/dec
            case mode.inc is
            when "00" => y_tmp := y - 1;
            when "01" => y_tmp := y + 1;
            when "10" => x_tmp := x - 1;
            when "11" => x_tmp := x + 1;
            when others => null; end case;
            -- limit (values from t6a04 data sheet)
            if mode.wl = '1' then
                if y_tmp > 14 then y_tmp := 0; end if;
                if y_tmp < 0 then y_tmp := 14; end if;
                if x_tmp > 63 then x_tmp := 0; end if;
                if x_tmp < 0 then x_tmp := 63; end if;
            else
                if y_tmp > 19 then y_tmp := 0; end if;
                if y_tmp < 0 then y_tmp := 19; end if;
                if x_tmp > 63 then x_tmp := 0; end if;
                if x_tmp < 0 then x_tmp := 63; end if;
            end if;
        elsif status_wr = '1' then
            if control(7 downto 5) = "001" then
                x_tmp := to_integer(control(4 downto 0));
            elsif control(7 downto 6) = "10" then
                y_tmp := to_integer(control(5 downto 0));
            end if;
        end if;
        x_next <= x_tmp; y_next <= y_tmp;
    end process;
end arch;
