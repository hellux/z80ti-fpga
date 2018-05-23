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
    z_lcd : in std_logic_vector(5 downto 0); -- row stride
    -- vga -> gmem
    x_vga : in std_logic_vector(6 downto 0); -- column
    y_vga : in std_logic_vector(5 downto 0); -- row
    -- gmem -> lcd/vga
    do_vga: out std_logic;
    do_lcd: out std_logic_vector(7 downto 0));
end pict_mem;


-- 8 bit mode
--
--   bit_sel 01234567
--           ________
--          |__X,Y___|
--       ________ ________ ________ ________
--      |__0,0___|__0,1___|  ...   |__0,12__|
--      |__1,0___|__1,1___|            :    |
--      |__2,0___|  ...      ...       :    |
--      |___:____                   ___:____|
--      |_64,0___|__...___|__...___|_64,12__|
--  

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
    signal x_buf : std_logic_vector(5 downto 0);
    signal y_buf : std_logic_vector(4 downto 0);
    signal bit_sel, page_bit : integer range 0 to 7; -- bit in mem byte, page
    signal state : gmem_state_t;
    signal word_length : integer range 6 to 8;
begin
    gmem : bram generic map(1, LCD_COLS*LCD_ROWS, 13)
        port map(clk, 
                 gmem_we_lcd, '0',
                 gmem_a_lcd, gmem_a_vga,
                 gmem_di_lcd, "0", 
                 gmem_do_lcd, gmem_do_vga);

    lcd_addr : process(x_buf, y_buf, z_lcd, word_length, bit_sel)
        variable xl, yl, zl : integer;
    begin
        xl := to_integer(unsigned(x_buf));
        yl := to_integer(unsigned(y_buf));
        zl := to_integer(unsigned(z_lcd));
        gmem_a_lcd <= std_logic_vector(to_unsigned(
            ((xl+zl) mod 64)*LCD_COLS + yl*word_length + bit_sel,
            13)
        );
    end process;

    vga_addr : process(x_vga, y_vga, z_lcd)
        variable xv, yv, zl : integer;
    begin
        xv := to_integer(unsigned(x_vga));
        yv := to_integer(unsigned(y_vga));
        zl := to_integer(unsigned(z_lcd));
        gmem_a_vga <= std_logic_vector(to_unsigned(
            ((yv+zl) mod 64)*LCD_COLS + xv,
            13)
        );
    end process;

    page_bit <= word_length-1-bit_sel when word_length-1-bit_sel >= 0 else 0;
    word_length <= 8 when wl = '1' else 6;

    --> gmem
    gmem_we_lcd <= '1' when state = load else '0';
    gmem_di_lcd(0) <= page_in(page_bit);

    --> vga
    do_vga <= gmem_do_vga(0);

    lcd : process(clk) begin
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
                do_lcd((page_bit+1) mod 8) <= gmem_do_lcd(0);
                x_buf <= x_lcd;
                y_buf <= y_lcd;
                if rd = '1' then
                    state <= load;
                    bit_sel <= 0;
                end if;
            end case;
        end if;
    end process;
end arch;
