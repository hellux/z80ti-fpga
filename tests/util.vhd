library ieee;
use ieee.std_logic_1164.all;

package util is
    function vec_str(x : std_logic_vector) return string;
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
end util;
