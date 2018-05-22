library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ti_comm.all;

entity pict_mem is port (
    clk : in std_logic;
    -- lcd -> gmem
    rd, wl : in std_logic;
    page_in : in std_logic_vector(7 downto 0);
    x_lcd : in std_logic_vector(5 downto 0); -- row
    y_lcd : in std_logic_vector(4 downto 0); -- column page
    -- vga -> gmem
    x_vga : in std_logic_vector(6 downto 0); -- column
    y_vga : in std_logic_vector(5 downto 0); -- row
    -- gmem -> lcd/vga
    do_vga: out std_logic;
    do_lcd: out std_logic_vector(7 downto 0));
end pict_mem;

architecture arch of pict_mem is
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

    signal gmem_we_lcd : std_logic;
    signal gmem_di_lcd : std_logic_vector(0 downto 0);
    signal gmem_do_lcd, gmem_do_vga : std_logic_vector(0 downto 0);
    signal gmem_a_lcd, gmem_a_vga : std_logic_vector(12 downto 0);
    signal page_buf : std_logic_vector(7 downto 0);
    signal x_buf : std_logic_vector(5 downto 0);
    signal y_buf : std_logic_vector(4 downto 0);
    signal bit_sel : integer range 0 to 7;
    signal state : gmem_state_t;
begin
    gmem : bram generic map(1, LCD_COLS*LCD_ROWS, 13)
        port map(clk, 
                 gmem_we_lcd, '0',
                 gmem_a_lcd, gmem_a_vga,
                 gmem_di_lcd, "0", 
                 gmem_do_lcd, gmem_do_vga);

    process(x_buf, y_buf, wl, bit_sel)
        variable xl : integer range 0 to LCD_ROWS-1;
        variable yl : integer range 0 to LCD_COLS/6-1;
        variable wordl : integer range 6 to 8;
    begin
        xl := to_integer(unsigned(x_buf));
        yl := to_integer(unsigned(y_buf));
        if wl = '1' then wordl := 8; else wordl := 6; end if;
        gmem_a_lcd <= std_logic_vector(to_unsigned(
            xl*LCD_COLS+yl*wordl + bit_sel, 13
        ));
    end process;

    process(x_vga, y_vga)
        variable xv : integer range 0 to 128;
        variable yv : integer range 0 to 64;
    begin
        xv := to_integer(unsigned(x_vga));
        yv := to_integer(unsigned(y_vga));
        gmem_a_vga <= std_logic_vector(to_unsigned(yv*LCD_COLS+xv, 13));
    end process;

    gmem_we_lcd <= '1' when state = load else '0';
    gmem_di_lcd(0) <= page_buf(7-bit_sel) when wl = '1' else
                      page_buf(5-bit_sel) when bit_sel < 6 else
                      '-';
    do_vga <= gmem_do_vga(0);

    lcd : process(clk) begin
        if rising_edge(clk) then
            if bit_sel = 7 then
                bit_sel <= 0;
            else
                bit_sel <= bit_sel + 1;
            end if;

            case state is
            when load =>
                if (wl = '1' and bit_sel = 7) or
                   (wl = '0' and bit_sel = 5)
                then
                    bit_sel <= 0;
                    state <= idle;
                end if;
            when idle =>
                do_lcd(bit_sel) <= gmem_do_lcd(0);

                if rd = '1' then
                    state <= load;
                    page_buf <= page_in;
                    x_buf <= x_lcd;
                    y_buf <= y_lcd;
                    bit_sel <= 0;
                end if;
            end case;
        end if;
    end process;
end arch;
