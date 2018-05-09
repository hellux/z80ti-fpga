library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity char_rom is port(
    clk : in std_logic;
    char : in std_logic_vector(5 downto 0);
    col, row : in std_logic_vector(2 downto 0);
    pixel : out std_logic);
end char_rom;

architecture arch of char_rom is
    constant CHAR_ROWS : integer := 8;
    constant CHAR_COLS : integer := 8;
    constant CHAR_COUNT : integer := 38;
    type char_arr_t is array(0 to CHAR_COUNT*CHAR_ROWS-1) of
                        std_logic_vector(0 to CHAR_COLS-1);

    signal char_arr : char_arr_t := (
        "00000000",
        "00111000",
        "01000100",
        "01001100",
        "01010100",
        "01100100",
        "01000100",
        "00111000",
        "00000000",
        "00010000",
        "00110000",
        "00010000",
        "00010000",
        "00010000",
        "00010000",
        "00111000",
        "00000000",
        "00111000",
        "01000100",
        "00000100",
        "00001000",
        "00010000",
        "00100000",
        "01111100",
        "00000000",
        "01111100",
        "00001000",
        "00010000",
        "00001000",
        "00000100",
        "01000100",
        "00111000",
        "00000000",
        "00001000",
        "00011000",
        "00101000",
        "01001000",
        "01111100",
        "00001000",
        "00001000",
        "00000000",
        "01111100",
        "01000000",
        "01111000",
        "00000100",
        "00000100",
        "01000100",
        "00111000",
        "00000000",
        "00011000",
        "00100000",
        "01000000",
        "01111000",
        "01000100",
        "01000100",
        "00111000",
        "00000000",
        "01111100",
        "00000100",
        "00001000",
        "00010000",
        "00100000",
        "00100000",
        "00100000",
        "00000000",
        "00111000",
        "01000100",
        "01000100",
        "00111000",
        "01000100",
        "01000100",
        "00111000",
        "00000000",
        "00111000",
        "01000100",
        "01000100",
        "00111100",
        "00000100",
        "00000100",
        "00111000",
        "00000000",
        "00111000",
        "01000100",
        "01000100",
        "01111100",
        "01000100",
        "01000100",
        "01000100",
        "00000000",
        "01111000",
        "01000100",
        "01000100",
        "01111000",
        "01000100",
        "01000100",
        "01111000",
        "00000000",
        "00111000",
        "01000100",
        "01000000",
        "01000000",
        "01000000",
        "01000100",
        "00111000",
        "00000000",
        "01111000",
        "01000100",
        "01000100",
        "01000100",
        "01000100",
        "01000100",
        "01111000",
        "00000000",
        "01111100",
        "01000000",
        "01000000",
        "01111000",
        "01000000",
        "01000000",
        "01111100",
        "00000000",
        "01111100",
        "01000000",
        "01000000",
        "01111000",
        "01000000",
        "01000000",
        "01000000",
        "00000000",
        "00111000",
        "01000100",
        "01000000",
        "01011100",
        "01000100",
        "01000100",
        "00111100",
        "00000000",
        "01000100",
        "01000100",
        "01000100",
        "01111100",
        "01000100",
        "01000100",
        "01000100",
        "00000000",
        "00111000",
        "00010000",
        "00010000",
        "00010000",
        "00010000",
        "00010000",
        "00111000",
        "00000000",
        "00011100",
        "00001000",
        "00001000",
        "00001000",
        "00001000",
        "01001000",
        "00110000",
        "00000000",
        "01000100",
        "01001000",
        "01010000",
        "01100000",
        "01010000",
        "01001000",
        "01000100",
        "00000000",
        "01000000",
        "01000000",
        "01000000",
        "01000000",
        "01000000",
        "01000000",
        "01111100",
        "00000000",
        "01000100",
        "01101100",
        "01010100",
        "01010100",
        "01000100",
        "01000100",
        "01000100",
        "00000000",
        "01000100",
        "01000100",
        "01100100",
        "01010100",
        "01001100",
        "01000100",
        "01000100",
        "00000000",
        "00111000",
        "01000100",
        "01000100",
        "01000100",
        "01000100",
        "01000100",
        "00111000",
        "00000000",
        "01111000",
        "01000100",
        "01000100",
        "01111000",
        "01000000",
        "01000000",
        "01000000",
        "00000000",
        "00111000",
        "01000100",
        "01000100",
        "01000100",
        "01010100",
        "01001000",
        "00110100",
        "00000000",
        "01111000",
        "01000100",
        "01000100",
        "01111000",
        "01010000",
        "01001000",
        "01000100",
        "00000000",
        "00111100",
        "01000000",
        "01000000",
        "00111000",
        "00000100",
        "00000100",
        "01111000",
        "00000000",
        "01111100",
        "00010000",
        "00010000",
        "00010000",
        "00010000",
        "00010000",
        "00010000",
        "00000000",
        "01000100",
        "01000100",
        "01000100",
        "01000100",
        "01000100",
        "01000100",
        "00111000",
        "00000000",
        "01000100",
        "01000100",
        "01000100",
        "01000100",
        "00101000",
        "00101000",
        "00010000",
        "00000000",
        "01000100",
        "01000100",
        "01000100",
        "01010100",
        "01010100",
        "01010100",
        "00101000",
        "00000000",
        "01000100",
        "01000100",
        "00101000",
        "00010000",
        "00101000",
        "01000100",
        "01000100",
        "00000000",
        "01000100",
        "01000100",
        "01000100",
        "00101000",
        "00010000",
        "00010000",
        "00010000",
        "00000000",
        "01111100",
        "00000100",
        "00001000",
        "00010000",
        "00100000",
        "01000000",
        "01111100",
        "00000000",
        "00110000",
        "00110000",
        "00000000",
        "00110000",
        "00110000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000");
begin
    process(clk)
        variable r, c : integer range 0 to 7;
        variable ch : integer;
    begin
        if rising_edge(clk) then
            r := to_integer(unsigned(row));
            c := to_integer(unsigned(col));
            ch := to_integer(unsigned(char));
            if ch >= CHAR_COUNT then ch := CHAR_COUNT-1; end if;

            pixel <= char_arr(ch*CHAR_ROWS+r)(c);
        end if;
    end process;
end arch;
