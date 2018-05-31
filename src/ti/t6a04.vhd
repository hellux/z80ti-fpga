library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ti_comm.all;
use work.util.all;

-- MISSING
--  - contrast
--  - gmem reset
--  - grayscale

-- 8 bit mode
--
--   bit_sel 01234567          76543210
--  page_bit 76543210          01234567
--           ________          ________
--   page:  |__X,Y___|  byte: |________|
--       ________ ________ ________ ________
--      |__0,0___|__0,1___|  ...   |__0,12__|
--      |__1,0___|__1,1___|            :    |
--      |__2,0___|  ...      ...       :    |
--      |___:____                   ___:____|
--      |_64,0___|__...___|__...___|_64,12__|
--  
-- 6 bit mode
--
--   bit_sel 012345              543210
--  page_bit 543210              012345
--           ______            ________
--   page:  |__X,Y_|    byte: |XX______|
--       ______ ______ ______ ______
--      |__0,0_|__0,1_|  ... |__0,15|
--      |__1,0_|__1,1_|          :    |
--      |__2,0_|  ...    ...     :    |
--      |___:__               ___:__|
--      |_64,0_|__..._|__..._|_64,15|
--  

entity t6a04 is port(
    clk, rst, ce : in std_logic;
    -- lcd ctrl <-> cpu
    p10_command, p11_data_o : in port_out_t;
    p10_status, p11_data_i : out port_in_t;
    -- gmem <-> vga
    x_vga : in std_logic_vector(6 downto 0); -- column
    y_vga : in std_logic_vector(5 downto 0); -- row
    do_vga: out std_logic;
    -- debug
    dbg : out dbg_lcd_t);
end t6a04;

architecture arch of t6a04 is
    component reg generic(init : std_logic_vector; size : integer); port(
        clk, rst, ce : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;

    component bram generic(dwidth : integer;
                           size : integer;
                           awidth : integer); port(
        clk : in std_logic;
        wea, web : in std_logic;
        addra, addrb : in std_logic_vector(awidth-1 downto 0);
        data_ina, data_inb : in std_logic_vector(dwidth-1 downto 0);
        data_outa, data_outb : out std_logic_vector(dwidth-1 downto 0));
    end component;

    type gmem_state_t is (idle, load);

    type lcd_mode_t is record
        up: std_logic; -- 0 dec, 1 inc
        counter : std_logic; -- 0 x, 1 y
        active : std_logic;
        wl : std_logic; -- 0: 6bit, 1: 8bit
    end record;

    -- lcd ctrl
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

    -- gmem
    signal gmem_we_lcd : std_logic;
    signal gmem_di_lcd : std_logic_vector(0 downto 0);
    signal gmem_do_lcd, gmem_do_vga : std_logic_vector(0 downto 0);
    signal gmem_do_buf : std_logic_vector(7 downto 0);
    signal gmem_a_lcd, gmem_a_vga : std_logic_vector(12 downto 0);
    signal x_buf : unsigned(5 downto 0);
    signal y_buf : unsigned(4 downto 0);
    signal bit_sel, page_bit : integer range 0 to 7; -- bit in mem byte, page
    signal state : gmem_state_t;
    signal word_length : integer range 6 to 8;
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

    page_bit <= word_length-1-bit_sel when word_length-1-bit_sel >= 0 else 0;
    word_length <= 8 when mode.wl = '1' else 6;

    gmem_we_lcd <= '1' when state = load else '0';
    gmem_di_lcd(0) <= p11_data_o.data(page_bit);
    addr : process(x_buf, y_buf, z, x_vga, y_vga, word_length, bit_sel)
        variable xl, yl, zl, xv, yv, al, av : integer;
    begin
        xl := to_integer(x_buf);
        yl := to_integer(y_buf);
        zl := to_integer(unsigned(z));
        xv := to_integer(unsigned(x_vga));
        yv := to_integer(unsigned(y_vga));
        al := ((xl+zl) mod 64)*LCD_COLS + yl*word_length + bit_sel;
        av := ((yv+zl) mod 64)*LCD_COLS + xv;
        gmem_a_lcd <= std_logic_vector(to_unsigned(al, 13));
        gmem_a_vga <= std_logic_vector(to_unsigned(av, 13));
    end process;

    gmem : bram generic map(1, LCD_COLS*LCD_ROWS, 13)
                port map(clk, 
                         gmem_we_lcd, '0',
                         gmem_a_lcd, gmem_a_vga,
                         gmem_di_lcd, "0", 
                         gmem_do_lcd, gmem_do_vga);

    gmem_state : process(clk) begin
        if rising_edge(clk) then
            if bit_sel >= word_length-1
            then bit_sel <= 0;
            else bit_sel <= bit_sel + 1;
            end if;

            case state is
            when load =>
                if bit_sel >= word_length-1 then
                    state <= idle;
                end if;
            when idle =>
                -- +1 to sync addr, data (data for addr in comes next pulse)
                gmem_do_buf((page_bit+1) mod 8) <= gmem_do_lcd(0);
                -- update x, y (keep persistent during load)
                x_buf <= x;
                y_buf <= y;
                if p11_data_o.wr = '1' then
                    state <= load;
                    bit_sel <= 0;
                end if;
            end case;
        end if;
    end process;

    -- -> z80
    out_reg : reg generic map(x"00", 8)
                  port map(clk, rst, ce,
                           p11_data_o.rd, gmem_do_buf, p11_data_i.data);
    p10_status.data <=
        (PI10_AUTO_INC_DEC   => mode.up,
         PI10_AUTO_Y_X       => mode.counter,
         PI10_RESET_STATE    => '0',
         PI10_LCD_ENABLED    => mode.active,
         PI10_WL_8_6         => mode.wl,
         PI10_LCD_BUSY       => '0',
         others              => '0');

    --> vga
    do_vga <= gmem_do_vga(0) when mode.active = '1' else '0';

    -- debug
    dbg.x <= std_logic_vector(x);
    dbg.y <= std_logic_vector(y);
    dbg.z <= z;
    dbg.up <= mode.up;
    dbg.counter <= mode.counter;
    dbg.active <= mode.active;
    dbg.wl <= mode.wl;
end arch;
