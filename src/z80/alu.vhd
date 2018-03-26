library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- TODO
--  implement inc, dec
--  implement long shifts rld, rrd, maybe outside alu?
--  ensure flags unaffected on some instructions
--  only require 1 cp for inputs (preserve signals 1 cp) 

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
--  set bit             op2(bs) <= '1'
--  reset bit           op2(bs) <= '0'
--  test bit            z <= not op2(bs)

-- FLAGS
-- 7  6  5  4  3  2  1  0
-- S  Z  f5 H f3 P/V N  C
-- f3: copy of bit 3
-- f5: copy of bit 5

-- INSTRUCTIONS -------

-- MAIN 
--   0-7 8-f
-- 8 add adc
-- 9 sub sbc
-- a and xor
-- b or  cp

-- EXTENDED
--      1   2   4   9   a   c
-- 4-7      sbc neg     adc neg
-- a    cpi         cpd
-- b    cpir        cpdr

-- IY
--   4-5 c-d
-- 8 add adc
-- 9 sub sbc
-- a and xor
-- b or  cp

-- CB, DDCB, FDCB: BIT INSTR, IX, IY
--   0-7    8-f
-- 0 rlc    rrc
-- 1 rl     rr
-- 2 sla    sra
-- 3 sll    srl
-- 4 bit0   bit1
-- 5 bit2   bit3
-- 6 bit4   bit5
-- 7 bit6   bit7
-- 8 res0   res1
-- 9 res2   res3
-- a res4   res5
-- b res6   res7
-- c set0   set1
-- d set2   set3
-- e set4   set5
-- f set6   set7

-- INSTRUCTION SET STATES
-- name         opcode      state
-- main                     000
-- extended     ED          011
-- bit          CB          100
-- ix           DD          001
-- ix bit       DDCB        101
-- iy           FD          010
-- iy bit       FDCB        110

entity alu is port(
    clk, rst : in std_logic;
    op1, op2, flags_in : in std_logic_vector(7 downto 0);
    op : in std_logic_vector(7 downto 0);
    op_set : in std_logic_vector(2 downto 0);
    result, flags_out : out std_logic_vector(7 downto 0));
end alu;

architecture arch of alu is
    signal c_in : std_logic;
    signal low, high : std_logic_vector(3 downto 0);

    -- preprocess
    signal bit_select : std_logic_vector(2 downto 0) := "000";
    signal op1_uint, op2_uint : signed(7 downto 0);
    signal bit_instr : std_logic; -- instr is bit instr
    signal shift : std_logic; -- instr is shift
    signal shift_op : std_logic_vector(2 downto 0); -- type of shift
    signal mask : std_logic_vector(7 downto 0); -- mask for bit set/reset
    signal bi_bit, bi_res, bi_set : std_logic; -- instr is bit/res/set
    signal edge : std_logic; -- lsb or msb when shifting
    signal right_left : std_logic; -- subtract/^add or right/^left
    signal op2sn : signed(7 downto 0); -- shift/neg result

    -- calculation
    signal arith_instr : std_logic; -- instr is arithmetic
    signal carry_instr : std_logic;
    signal add_instr : std_logic;
    signal sub_instr : std_logic;
    signal cp_instr : std_logic;
    signal inc_instr : std_logic; -- instr is inc
    signal dec_instr : std_logic; -- instr is dec
    signal logic_instr : std_logic; -- instr is logic instr
    signal logic_op : std_logic_vector(2 downto 0); -- type of logic instr
    signal use_carry : std_logic;
    signal with_carry : signed(8 downto 0); -- for add/sub with carry
    signal result_sum, result_xor, result_and, result_or : signed(8 downto 0);
    signal calc_result : signed(8 downto 0);
    signal result_buf : signed(7 downto 0);
    signal half_result : signed(4 downto 0);

    -- flags
    signal upd_c, upd_pv : std_logic;
    signal carry_sub, overflow, parity : std_logic;
    signal S, Z, f5, H, f3, PV, N, C : std_logic;

begin
    c_in <= flags_in(0);
    low <= op(3 downto 0);
    high <= op(7 downto 4);

    -- determine instr
    arith_instr <= add_instr or sub_instr or inc_instr or dec_instr;
    carry_instr <= op(3);
    add_instr <= '1' when bit_instr = '0' and
                    (high = x"8" or op = x"c6" or
                     (low = x"9" and high(3) = '0') or
                     (high(3) = '0' and low = x"a"))
                 else '0';
    sub_instr <= '1' when cp_instr = '1' or 
                 (bit_instr = '0' and 
                  ((high = x"9" or op = x"d6") or
                   (high(3) = '0' and low = x"2")))
                 else '0';
    cp_instr <= '1' when (bit_instr = '0' and high = x"b" and low(3) = '1') or
                         (op_set = "011" and high(3) = '1' and 
                          (low = x"1" or low = x"9")) or
                         op = x"fe"
                else '0';
    inc_instr <= '1' when 
                 bit_instr = '0' and
                 op(7 downto 6) = "00" and 
                 (low = x"3" or low = x"4" or low = x"c") else '0';
    dec_instr <= '1' when
                 bit_instr = '0' and
                 op(7 downto 6) = "00" and 
                 (low = x"5" or low = x"b" or low = x"d") else '0';
    logic_op <= op(5 downto 3);
    logic_instr <= '1' when bit_instr = '0' and op_set /= "011" and
                   (high = x"a" or (high = x"b" and low(3) = '0')) else
                   '0';

    bit_instr <= op_set(2);
    shift_op <= op(5 downto 3);
    shift <= '1' when bit_instr = '1' and op(7 downto 6) = "00" else '0';
    right_left <= op(3);
    bi_bit <= '1' when bit_instr = '1' and op(7 downto 6) = "01" else '0';
    bi_res <= '1' when bit_instr = '1' and op(7 downto 6) = "10" else '0';
    bi_set <= '1' when bit_instr = '1' and op(7 downto 6) = "11" else '0';

    -- op2 preprocess (shift / neg / bit instr)
    bit_select <= op(5 downto 3);
    process(bit_select) is
       variable m : std_logic_vector(7 downto 0);
    begin
        m := x"01";
        for i in 1 to to_integer(unsigned(bit_select)) loop
            m := m(6 downto 0) & '0';
        end loop;
        mask <= m;
    end process;

    with shift_op select
        edge <= op2(7) when "000", -- rlc
                c_in   when "010", -- rl
                '0'    when "100", -- sla
                '0'    when "110", -- sll
                op2(0) when "001", -- rrc
                c_in   when "011", -- rr
                op2(7) when "101", -- sra
                '0'    when "111", -- srl
                '-'    when others;
    op2sn <=
        signed(not mask and op2)    when bi_res = '1' else
        signed(mask or op2)         when bi_set = '1' else
        op2_uint                    when bi_bit = '1' else
        -op2_uint                   when sub_instr = '1' else
        op2_uint(6 downto 0) & edge when shift = '1' and right_left = '0' else
        edge & op2_uint(7 downto 1) when shift = '1' and right_left = '1' else
        op2_uint;

    -- calculation
    op1_uint <= "00000001"  when inc_instr = '1' else
                "11111111"  when dec_instr = '1' else
                signed(op1) when bit_instr = '0' else 
                "00000000";
    op2_uint <= signed(op2);
    use_carry <= c_in and carry_instr and 
                 (add_instr or sub_instr) and not cp_instr;
    with_carry <= "000000001" when use_carry = '1' and add_instr = '1' else
                  "011111111" when use_carry = '1' and sub_instr = '1' else
                  "000000000";
    result_and <= ('0' & op1_uint) and ('0' & op2_uint);
    result_xor <= ('0' & op1_uint) xor ('0' & op2_uint);
    result_or  <= ('0' & op1_uint) or  ('0' & op2_uint);
    result_sum <= ('0' & op1_uint) +   ('0' & op2sn) + with_carry;
    half_result <= ('0' & op1_uint(3 downto 0)) + 
                   ('0' & op2sn(3 downto 0)) + with_carry(4 downto 0);
    calc_result <= result_sum when logic_instr = '0' else
                   result_and when logic_op = "100"  else
                   result_xor when logic_op = "101"  else
                   result_or  when logic_op = "110";
    result_buf <= calc_result(7 downto 0);
    result <= std_logic_vector(result_buf) when cp_instr = '0' else op1;

    -- flags
    process(result_buf)
        variable p : std_logic;
    begin
        p := '0';
        for i in result_buf'range loop
            p := p xor result_buf(i);
        end loop;
        parity <= not p;
    end process;
    overflow <= (op1_uint(7) xor calc_result(7)) and   -- carry 6 into 7
                (op1_uint(7) xnor op2sn(7));  -- equal signs
    carry_sub <= '1' when op2 > op1 else '0';

    S <= result_buf(7);
    Z <= '1' when result_buf = 0 or
         (bi_bit = '1' and result_buf(to_integer(unsigned(bit_select))) = '0')
         else '0';
    f5 <= result_buf(5);
    H <= half_result(4) when arith_instr = '1' else '1';
    f3 <= result_buf(3);
    N <= sub_instr;
    PV <= parity when shift = '1' or logic_instr = '1' else
          overflow; 
    C <= '0'            when logic_instr = '1' else
         calc_result(8) when add_instr = '1' else
         carry_sub      when sub_instr = '1' else
         op2(7)         when shift = '1' and right_left = '0' else
         op2(0)         when shift = '1' and right_left = '1' else
         '-';

    upd_c <= logic_instr or shift or add_instr or sub_instr;
    upd_pv <= logic_instr or shift or arith_instr;

    flags_out(0) <= C when upd_c = '1' else flags_in(0);
    flags_out(1) <= N;
    flags_out(2) <= PV when upd_pv = '1' else flags_in(2);
    flags_out(3) <= f3;
    flags_out(4) <= H;
    flags_out(5) <= f5;
    flags_out(6) <= Z;
    flags_out(7) <= S;

end arch;
