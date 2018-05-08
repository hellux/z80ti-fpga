library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

package chars is
    constant CHAR_ROWS : integer := 8;
    constant CHAR_COLS : integer := 8;
    constant CHAR_COUNT : integer := 17;
    type char_t is array(0 to CHAR_ROWS-1) of
                   std_logic_vector(0 to CHAR_COLS-1);
    type char_arr_t is array(0 to CHAR_COUNT-1) of char_t;
                   
    constant char0 : char_t := ("00000000",
                                "00111000",
                                "01000100",
                                "01001100",
                                "01010100",
                                "01100100",
                                "01000100",
                                "00111000");
    constant char1 : char_t := ("00000000",
                                "00010000",
                                "00110000",
                                "00010000",
                                "00010000",
                                "00010000",
                                "00010000",
                                "00111000");
    constant char2 : char_t := ("00000000",
                                "00111000",
                                "01000100",
                                "00000100",
                                "00001000",
                                "00010000",
                                "00100000",
                                "01111100");
    constant char3 : char_t := ("00000000",
                                "01111100",
                                "00001000",
                                "00010000",
                                "00001000",
                                "00000100",
                                "01000100",
                                "00111000");
    constant char4 : char_t := ("00000000",
                                "00001000",
                                "00011000",
                                "00101000",
                                "01001000",
                                "01111100",
                                "00001000",
                                "00001000");
    constant char5 : char_t := ("00000000",
                                "01111100",
                                "01000000",
                                "01111000",
                                "00000100",
                                "00000100",
                                "01000100",
                                "00111000");
    constant char6 : char_t := ("00000000",
                                "00011000",
                                "00100000",
                                "01000000",
                                "01111000",
                                "01000100",
                                "01000100",
                                "00111000");
    constant charA : char_t := ("00000000",
                                "00111000",
                                "01000100",
                                "01000100",
                                "01111100",
                                "01000100",
                                "01000100",
                                "01000100");
    constant charB : char_t := ("00000000",
                                "01111000",
                                "01000100",
                                "01000100",
                                "01111000",
                                "01000100",
                                "01000100",
                                "01111000");
    constant charD : char_t := ("00000000",
                                "01111000",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01111000");
    constant charSPACE : char_t := ("00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000");

    constant char_arr : char_arr_t := (char0, char1, char2, char3,
                                       char4, char5, char6, char0,
                                       char0, char0, charA, charB,
                                       char0, char0, char0, char0,
                                       charSPACE);

    function chi(char : character) return integer;
end chars;

package body chars is
    function chi(char : character) return integer is begin
        case char is
            when 'a' => return 10;
        when others => return 0;
        end case;
    end chi;
end chars;
