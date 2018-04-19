library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

architecture Behavioral of pict_mem is
    type gmem_state_t is (idle, load);
    signal bit_out, bit_in : integer range 0 to 7;
    signal pic_mem : std_logic_vector(0 to 7679);
    signal a_lcd, a_vga : integer range pic_mem'range;
    signal xl, yl, xv, yv : integer := 0;
    signal page_buf : std_logic_vector(7 downto 0);

    signal state : gmem_state_t;
begin
    xl <= to_integer(unsigned(x_lcd));
    yl <= to_integer(unsigned(y_lcd));
    xv <= to_integer(unsigned(x_vga));
    yv <= to_integer(unsigned(y_vga));
    a_lcd <= xl*120+yl*8 when wl = '1' else xl*120+yl*6;
    a_vga <= yv*120+xv;

    bram_in : process(clk) begin
        if rising_edge(clk) then
            if clk_z80 = '1' then
                if rd = '1' then
                    state <= load;
                    page_buf <= page_in;
                end if;
            end if;

            if state = load then
                pic_mem(a_lcd+bit_in) <= page_buf(7-bit_in);
                if (wl = '1' and bit_in = 7) or (wl = '0' and bit_in = 5) then
                    bit_in <= 0;
                    state <= idle;
                else
                    bit_in <= bit_in + 1;
                end if;
            end if;

            if rst = '1' then
                pic_mem <= (others => '0');
            end if;
        end if;
    end process;

    bram_out : process(clk) begin
        if rising_edge(clk) then
            if clk_vga = '1' then
                do_vga <= pic_mem(a_vga);
            else
                do_lcd(7-bit_out) <= pic_mem(a_lcd+bit_out);
                if wl = '1' and bit_out = 7 then
                    bit_out <= 0;
                elsif wl = '0' and bit_out = 5 then
                    bit_out <= 0;
                else
                    bit_out <= bit_out + 1;
                end if;
            end if;
        end if;
    end process;
end Behavioral;

