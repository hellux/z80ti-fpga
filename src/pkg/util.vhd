library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package util is
    function vec_str(x : std_logic_vector) return string;
    function hex_str(x : std_logic_vector) return string;
    function bool_sl(b : boolean) return std_logic;
end util;

package body util is
    function vec_str(x : std_logic_vector) return string is
        variable res : string(x'range);
    begin
        for i in x'range loop
            res(i) := std_logic'image(x(i))(2);
        end loop;
        return res;
    end vec_str;

    function hex_str(x : std_logic_vector) return string is
        constant digs : string := "0123456789ABCDEF";
        variable len : natural;
        variable res : string(1 to 20);
        variable dig : natural range 0 to 15;
        variable int : natural;
    begin
        if x'length mod 4 = 0 then
            len := x'length/4;
        else
            len := x'length/4+1;
        end if;
        int := to_integer(unsigned(x));

        for i in len-1 downto 0 loop
            dig := int / 16**i;
            res(len-i) := digs(dig+1);
            int := int mod 16**i;
        end loop;
        return res(1 to len);
    end hex_str;

    function bool_sl(b : boolean) return std_logic is 
    begin
        if b then
            return '1';
        else
            return '0';
        end if;
    end bool_sl;
end util;
