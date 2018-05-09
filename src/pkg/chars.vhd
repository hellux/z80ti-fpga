library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

entity chars is

end chars;

architecture arch of chars is
    constant CHAR_ROWS : integer := 8;
    constant CHAR_COLS : integer := 8;
    constant CHAR_COUNT : integer := 39;
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
                                "00111000",
                                "01000100",
                                "01000100",
                                "00111100",
                                "00000100",
                                "00000100",
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
    constant charC : char_t := ("00000000",
                                "00111000",
                                "01000100",
                                "01000000",
                                "01000000",
                                "01000000",
                                "01000100",
                                "00111000");
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
                                "01000000",
                                "01000000",
                                "01111000",
                                "01000000",
                                "01000000",
                                "01111100");
    constant charF : char_t := ("00000000",
                                "01111100",
                                "01000000",
                                "01000000",
                                "01111000",
                                "01000000",
                                "01000000",
                                "01000000");
    constant charG : char_t := ("00000000",
                                "00111000",
                                "01000100",
                                "01000000",
                                "01011100",
                                "01000100",
                                "01000100",
                                "00111100");
    constant charH : char_t := ("00000000",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01111100",
                                "01000100",
                                "01000100",
                                "01000100");
    constant charI : char_t := ("00000000",
                                "00111000",
                                "00010000",
                                "00010000",
                                "00010000",
                                "00010000",
                                "00010000",
                                "00111000");
    constant charJ : char_t := ("00000000",
                                "00011100",
                                "00001000",
                                "00001000",
                                "00001000",
                                "00001000",
                                "01001000",
                                "00110000");
    constant charK : char_t := ("00000000",
                                "01000100",
                                "01001000",
                                "01010000",
                                "01100000",
                                "01010000",
                                "01001000",
                                "01000100");
    constant charL : char_t := ("00000000",
                                "01000000",
                                "01000000",
                                "01000000",
                                "01000000",
                                "01000000",
                                "01000000",
                                "01111100");
    constant charM : char_t := ("00000000",
                                "01000100",
                                "01101100",
                                "01010100",
                                "01010100",
                                "01000100",
                                "01000100",
                                "01000100");
    constant charN : char_t := ("00000000",
                                "01000100",
                                "01000100",
                                "01100100",
                                "01010100",
                                "01001100",
                                "01000100",
                                "01000100");
    constant charO : char_t := ("00000000",
                                "00111000",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01000100",
                                "00111000");
    constant charP : char_t := ("00000000",
                                "01111000",
                                "01000100",
                                "01000100",
                                "01111000",
                                "01000000",
                                "01000000",
                                "01000000");
    constant charQ : char_t := ("00000000",
                                "00111000",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01010100",
                                "01001000",
                                "00110100");
    constant charR : char_t := ("00000000",
                                "01111000",
                                "01000100",
                                "01000100",
                                "01111000",
                                "01010000",
                                "01001000",
                                "01000100");
    constant charS : char_t := ("00000000",
                                "00111100",
                                "01000000",
                                "01000000",
                                "00111000",
                                "00000100",
                                "00000100",
                                "01111000");
    constant charT : char_t := ("00000000",
                                "01111100",
                                "00010000",
                                "00010000",
                                "00010000",
                                "00010000",
                                "00010000",
                                "00010000");
    constant charU : char_t := ("00000000",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01000100",
                                "00111000");
    constant charV : char_t := ("00000000",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01000100",
                                "00101000",
                                "00101000",
                                "00010000");
    constant charW : char_t := ("00000000",
                                "01000100",
                                "01000100",
                                "01000100",
                                "01010100",
                                "01010100",
                                "01010100",
                                "00101000");
    constant charX : char_t := ("00000000",
                                "01000100",
                                "01000100",
                                "00101000",
                                "00010000",
                                "00101000",
                                "01000100",
                                "01000100");
    constant charY : char_t := ("00000000",
                                "01000100",
                                "01000100",
                                "01000100",
                                "00101000",
                                "00010000",
                                "00010000",
                                "00010000");
    constant charZ : char_t := ("00000000",
                                "01111100",
                                "00000100",
                                "00001000",
                                "00010000",
                                "00100000",
                                "01000000",
                                "01111100");
    constant charUNDEF : char_t := ("00000000",
                                    "00111000",
                                    "01000100",
                                    "00000100",
                                    "00001000",
                                    "00010000",
                                    "00000000",
                                    "00010000");
    constant charCOLON : char_t := ("00000000",
                                    "00000000",
                                    "00110000",
                                    "00110000",
                                    "00000000",
                                    "00110000",
                                    "00110000",
                                    "00000000");
    constant charSPACE : char_t := ("00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000",
                                    "00000000");

    function ch(char : character) return integer;
end chars;

package body chars is
    function ch(char : character) return char_t is begin
        case char is
            when '0' => return char0;
            when '1' => return char1;
            when '2' => return char2;
            when '3' => return char3;
            when '4' => return char4;
            when '5' => return char5;
            when '6' => return char6;
            when '7' => return char7;
            when '8' => return char8;
            when '9' => return char9;
            when 'A' => return charA;
            when 'B' => return charB;
            when 'C' => return charC;
            when 'D' => return charD;
            when 'E' => return charE;
            when 'F' => return charF;
            when 'G' => return charG;
            when 'H' => return charH;
            when 'I' => return charI;
            when 'J' => return charJ;
            when 'K' => return charK;
            when 'L' => return charL;
            when 'M' => return charM;
            when 'N' => return charN;
            when 'O' => return charO;
            when 'P' => return charP;
            when 'Q' => return charQ;
            when 'R' => return charR;
            when 'S' => return charS;
            when 'T' => return charT;
            when 'U' => return charU;
            when 'V' => return charV;
            when 'W' => return charW;
            when 'X' => return charX;
            when 'Y' => return charY;
            when 'Z' => return charZ;
            when ':' => return charCOLON;
            when ' ' => return charSPACE;
            when others => return charUNDEF;
        end case;
    end ch;
end arch;
