library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- TODO do_lcd

entity pict_mem is port (
    clk, clk_z80, clk_vga, rst : in std_logic;
    rd, wl : in std_logic;
    page_in : in std_logic_vector(7 downto 0);
    x_lcd : in std_logic_vector(5 downto 0); -- row
    y_lcd : in std_logic_vector(4 downto 0); -- column page
    x_vga : in std_logic_vector(6 downto 0); -- column
    y_vga : in std_logic_vector(5 downto 0); -- row
    do_vga: out std_logic;
    do_lcd: out std_logic_vector(7 downto 0));
end pict_mem;

architecture arch of pict_mem is
    component bram generic(
        dwidth : integer;
        size : integer;
        awidth : integer); port(
        clk, rst : in std_logic;
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
    signal bit_out, bit_in : integer range 0 to 7;
    signal state : gmem_state_t;
begin
    gmem : bram generic map(1, 7679, 13) port map(clk, rst,
                                                 gmem_we_lcd, '0',
                                                 gmem_a_lcd, gmem_a_vga,
                                                 gmem_di_lcd, "0", 
                                                 gmem_do_lcd, gmem_do_vga);

    process(x_lcd, y_lcd, wl, bit_in)
        variable xl : integer range 0 to 63;
        variable yl : integer range 0 to 19;
    begin
        xl := to_integer(unsigned(x_lcd));
        yl := to_integer(unsigned(y_lcd));
        if wl = '1' then
            gmem_a_lcd <= std_logic_vector(to_unsigned(
                          xl*120+yl*8 + bit_in,
                          13));
        else
            gmem_a_lcd <= std_logic_vector(to_unsigned(
                          xl*120+yl*6 + bit_in,
                          13));
        end if;
    end process;

    process(x_vga, y_vga)
        variable xv : integer range 0 to 119;
        variable yv : integer range 0 to 63;
    begin
        xv := to_integer(unsigned(x_vga));
        yv := to_integer(unsigned(y_vga));
        gmem_a_vga <= std_logic_vector(to_unsigned(yv*120+xv, 13));
    end process;

    gmem_we_lcd <= '1' when state = load else '0';
    gmem_di_lcd(0) <= page_buf(7-bit_in);
    do_vga <= gmem_do_vga(0);

    lcd : process(clk) begin
        if rising_edge(clk) then
            if clk_z80 = '1' then
                if rd = '1' then
                    state <= load;
                    page_buf <= page_in;
                end if;
            end if;

            if bit_out = 7 then
                bit_out <= 0;
            else
                bit_out <= bit_out + 1;
            end if;

            if state = load then
                if (wl = '1' and bit_in = 7) or (wl = '0' and bit_in = 5) then
                    bit_in <= 0;
                    state <= idle;
                else
                    bit_in <= bit_in + 1;
                end if;
            end if;
        end if;
    end process;
end arch;
