library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- RSV control signals:
--  rsv res
--  000 sum
--  100 xor
--  010 and
--  111 or

entity alu is port(
    clk, rst in std_logic;
    op1, op1 in std_logic_vector(7 downto 0);
    r, s, v in std_logic; -- control signals, select instr
    bit_select in std_logic(2 downto 0); -- bits 5-3 in bit instr
    res, flags out std_logic(7 downto 0));
    -- need input to decide instruction
end alu;

architecture arch of alu is
    signal res_sum, res_xor, res_and, res_or : std_logic_vector(7 downto 0);
begin
    process(clk) begin
        res_sum <= op1 + op2;
        res_xor <= op1 xor op2;
        res_and <= op1 and op2;
        res_or  <= op1 or op2;
    end;
    with (r & s & v) select 
        res <= res_sum when "000",
               res_xor when "100",
               res_and when "010",
               res_or  when "111";

end arch;
