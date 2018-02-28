library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- RSV control signals:
--  rsv res
--  000 sum
--  100 xor
--  010 and
--  111 or

-- OPERATION SIGNALING
--  OP                  RSV 
-- ARITH
--  add                 000
--  sub                 000
--  increment           000
--  decrement           000
--  compare             000
-- LOGIC
--  and                 010
--  or                  111
--  xor                 100
-- SHIFTS
--  lshift logic        000
--  rshift logic        000
--  lshift arith        000
--  rshift arith        000
-- BIT
--  set bit             000
--  reset bit           000
--  test bit            000

-- OPERATION IMPLEMENTATIONS
-- ARITH
--  add                 sum
--  sub                 op2<=-op2, sum
--  increment           op2<=1, sum
--  decrement           op2<=-1, sum
--  compare             op2<=-op2, sum (skip output)
-- LOGIC
--  and                 and
--  or                  or
--  xor                 xor
-- SHIFTS
--  lshift logic        op1<=op1<<1, op2<=0, sum
--  rshift logic        op1<=op1>>1, op2<=0, sum
--  lshift arith        op1<=op1<<1, op2<=0, sum
--  rshift arith        op1<=op1>>1, op2<=0, sum
-- BIT
--  set bit             asic
--  reset bit           asic
--  test bit            asic

-- how does sub work if only sum exists, negate before?
-- if alu handles, how does alu know it should sub?
-- clock cycles are 4 for both add, sub

-- in general how does alu know which result to output

entity alu is port(
    clk, rst in std_logic;
    op1, op1 in std_logic_vector(7 downto 0);
    r, s, v in std_logic; -- control signals, select instr
    sub in std_logic;
    bs in std_logic(2 downto 0); -- bit select (bits 5-3 in bit instr)
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
