library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- RSV control signals:
--  rsv res
--  000 sum
--  100 xor
--  010 and
--  111 or

-- INSTRUCTION SIGNALS (for instr decoder)
-- signal               options                     bits
-- sr                   ^reset/set                  6
-- shiftneg             none,neg,lshift,rshift      ??
-- instr                and,xor,sum,or              43

-- OPERATION SIGNALING
--  OP                  rsv sr shift op1
-- ARITH
--  add                 000    0-    op1
--  sub                 000    0-    op1
--  increment           000    0-    op1
--  decrement           000    0-    op1
--  compare             000    0-    op1
-- LOGIC
--  and                 010    0-    op1
--  or                  111    0-    op1
--  xor                 100    0-    op1
-- SHIFTS
--  lshift logic        000    10    -
--  rshift logic        000    11    -
--  lshift arith        000    10    -
--  rshift arith        000    11    -
-- BIT
--  set bit             000 1  0-    bs
--  reset bit           000 0  0-    bs
--  test bit            000    0-    bs

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
--  lshift logic        op2<=op2<<1, op1<=0, sum
--  rshift logic        op2<=op2>>1, op1<=0, sum
--  lshift arith        op2<=op2<<1, op1<=0, sum
--  rshift arith        op2<=op2>>1, op1<=0, sum
-- BIT
--  set bit             asic
--  reset bit           asic
--  test bit            asic

entity alu is port(
    clk, rst : in std_logic;
    op1, op2 : in std_logic_vector(7 downto 0);
    instr : in std_logic_vector(1 downto 0);
    shiftneg : in std_logic_vector(1 downto 0);
    shift : in std_logic_vector(1 downto 0);
    res, flags : out std_logic_vector(7 downto 0));
end alu;

architecture arch of alu is
    signal op1_int, op2_int : signed(7 downto 0);

    signal first, last : std_logic;
    signal op2sn : signed(7 downto 0);

    signal bs : std_logic_vector(2 downto 0);

    signal res_sum, res_xor, res_and, res_or : signed(7 downto 0);

    signal calc_res : signed(7 downto 0);
begin
    bs <= op1(2 downto 0);
    op1_int <= signed(op1);
    op2_int <= signed(op2);

    -- shift/neg
    first <= op2(0) and '0'; -- TODO subst 0 with rotate signal 
    last <= op2(7) and '0';
    with (shiftneg) select
        op2sn <= op2_int                            when "00", -- no shift
                 -op2_int                           when "01", -- negative
                 last & op2_int(5 downto 0) & first when "10", -- lshift 
                 last & op2_int(7 downto 1)         when "11", -- rshift
                 (others => '-')                when others; 
    -- right last can be op2(0), op2(7), carry, 0

    -- calculation
    process(clk) begin
        res_sum <= op1_int +    op2sn;
        res_xor <= op1_int xor  op2sn;
        res_and <= op1_int and  op2sn;
        res_or  <= op1_int or   op2sn;
    end process;
    with instr select
        calc_res <= res_and         when "00",
                    res_xor         when "01",
                    res_sum         when "10",
                    res_or          when "11",
                    (others => '-') when others;
end arch;
