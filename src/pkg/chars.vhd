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
    constant char7 : char_t := ("00000000",
                                "01111100",
                                "00000100",
                                "00001000",
                                "00010000",
                                "00100000",
                                "00100000",
                                "00100000");
    constant char8 : char_t := ("00000000",
                                "00111000",
                                "01000100",
                                "01000100",
                                "00111000",
                                "01000100",
                                "01000100",
                                "00111000");
    constant char9 : char_t := ("00000000",
                                "01111100",
                                "00000100",
                                "00001000",
                                "00010000",
                                "00100000",
                                "00100000",
                                "00100000");
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
    constant charC : char_t := ("00000000",
                                "01111100",
                                "00000100",
                                "00001000",
                                "00010000",
                                "00100000",
                                "00100000",
                                "00100000");
    constant charD : char_t := ("00000000",
                                "01111000",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01111000");
    constant charE : char_t := ("00000000",
                                "01111100",
                                "00000100",
                                "00001000",
                                "00010000",
                                "00100000",
                                "00100000",
                                "00100000");
    constant charF : char_t := ("00000000",
                                "01111100",
                                "00000100",
                                "00001000",
                                "00010000",
                                "00100000",
                                "00100000",
                                "00100000");
    constant charSPACE : char_t := ("00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000");

    constant char_arr : char_arr_t := (char0, char1, char2, char3,
                                       char4, char5, char6, char7,
                                       char8, char9, charA, charB,
                                       charC, charD, charE, charF,
                                       charSPACE);

    function chi(char : character) return integer;
end chars;

package body chars is
    function chi(char : character) return integer is begin
        case char is
            when '0' => return 0;
            when '1' => return 1;
            when '2' => return 2;
            when '3' => return 3;
            when '4' => return 4;
            when '5' => return 5;
            when '6' => return 6;
            when '7' => return 7;
            when '8' => return 8;
            when '9' => return 9;
            when 'A' => return 10;
            when 'B' => return 11;
            when 'C' => return 12;
            when 'D' => return 13;
            when 'E' => return 14;
            when 'F' => return 15;
            when ' ' => return 16;
        when others => return 0;
        end case;
    end chi;
end chars;
