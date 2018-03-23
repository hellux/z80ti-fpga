library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- TODO
--  implement long shifts rld, rrd, maybe outside alu?
--  ensure flags unaffected on some instructions

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
-- 7 bit6   bit6
-- 8 res0   res1
-- 9 res2   res3
-- a res4   res5
-- b res6   res6
-- c set0   set1
-- d set2   set3
-- e set4   set5
-- f set6   set6

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
    op1, op2 : in std_logic_vector(7 downto 0);
    c_in : in std_logic;
    instr : in std_logic_vector(7 downto 0);
    instr_set : in std_logic_vector(2 downto 0);
    res, flags : out std_logic_vector(7 downto 0));
end alu;

architecture arch of alu is
    -- preserve input signals
    signal op1_pres, op2_pres : std_logic_vector(7 downto 0);
    signal op2sn_pres : std_logic_vector(7 downto 0);

    -- shift/neg
    signal bit_select : std_logic_vector(2 downto 0) := "000";
    signal op2_set, op2_res : std_logic_vector(7 downto 0);
    signal op1_uint, op2_uint : signed(7 downto 0);
    signal mask : std_logic_vector(7 downto 0);
    signal bit_instr : std_logic;
    signal shift, bi_bit, bi_res, bi_set : std_logic; -- whether to shift
    signal edge : std_logic; -- lsb or msb when shifting
    signal sub_add, right_left : std_logic; -- subtract/^add or right/^left
    signal shift_op : std_logic_vector(2 downto 0);
    signal bit_instr_op : std_logic_vector(1 downto 0);
    signal op2sn : signed(7 downto 0); -- shift/neg result

    -- calculation
    signal logic_op : std_logic_vector(2 downto 0);
    signal use_carry : std_logic;
    signal with_carry : signed(8 downto 0); -- for sum with carry
    signal res_sum, res_xor, res_and, res_or : signed(8 downto 0);
    signal calc_res : signed(8 downto 0);

    signal res_buf : signed(7 downto 0);

    -- flags
    signal op_is_logic : std_logic;
    signal carry_sub, overflow, parity : std_logic;
    signal c_out, pv: std_logic;

begin
    op1_uint <= signed(op1) when shift = '0' else "00000000";
    op2_uint <= signed(op2);

    -- preserve operands 1 cp
    process(clk) begin
        if rising_edge(clk) then
            op1_pres <= op1;
            op2_pres <= op2;
            op2sn_pres <= std_logic_vector(op2sn);
        end if;
    end process;

    -- shift / neg / bit instr
    bit_instr <= instr_set(2);
    bit_instr_op <= instr(7 downto 6);
    sub_add <= instr(4);
    right_left <= instr(3);
    shift_op <= instr(5 downto 3);
    bit_select <= instr(5 downto 3);
    shift <= '1' when bit_instr = '1' and bit_instr_op = "00" else '0';
    bi_bit <= '1' when bit_instr = '1' and bit_instr_op = "01" else '0';
    bi_res <= '1' when bit_instr = '1' and bit_instr_op = "10" else '0';
    bi_set <= '1' when bit_instr = '1' and bit_instr_op = "11" else '0';

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
    op2_res <= not mask and op2;
    op2_set <= mask or op2;
    op2sn <=
        signed(op2_res)             when bi_res = '1' else
        signed(op2_set)             when bi_set = '1' else
        -op2_uint                   when shift = '0' and sub_add = '1' else
        op2_uint(6 downto 0) & edge when shift = '1' and right_left = '0' else
        edge & op2_uint(7 downto 1) when shift = '1' and right_left = '1' else
        op2_uint;

    -- calculation
    logic_op <= instr(5 downto 3) when bit_instr = '0' else "000";
    use_carry <= c_in and instr(3) and not shift;
    with_carry <= "000000001" when use_carry = '1' and sub_add = '0' else
                  "011111111" when use_carry = '1' and sub_add = '1' else
                  "000000000";
    process(clk) begin
        if rising_edge(clk) then
            res_and <= ('0' & op1_uint) and ('0' & op2_uint);
            res_xor <= ('0' & op1_uint) xor ('0' & op2_uint);
            res_or  <= ('0' & op1_uint) or  ('0' & op2_uint);
            res_sum <= ('0' & op1_uint) +   ('0' & op2sn) + with_carry;
        end if;
    end process;
    with logic_op select
        calc_res <= res_and         when "100",
                    res_xor         when "101",
                    res_or          when "110",
                    res_sum         when others;

    -- result
    res_buf <= calc_res(7 downto 0);
    res <= std_logic_vector(res_buf);

    -- flags
    op_is_logic <= '1' when  logic_op = "100" or
                             logic_op = "101" or
                             logic_op = "110" else '0';
    carry_sub <= '1' when op2_pres > op1_pres else '0';
    c_out <= '0'         when op_is_logic = '1' else
             calc_res(8) when shift = '0' and sub_add = '0' else
             carry_sub   when shift = '0' and sub_add = '1' else
             op2(7)      when shift = '1' and right_left = '0' else
             op2(0)      when shift = '1' and right_left = '1' else
             '-';

    process(res_buf)
        variable p : std_logic;
    begin
        p := '0';
        for i in res_buf'range loop
            p := p xor res_buf(i);
        end loop;
        parity <= not p;
    end process;

    overflow <= (op1_pres(7) xor calc_res(7)) and   -- carry 6 into 7
                (op1_pres(7) xnor op2sn_pres(7));  -- equal sign

    pv <= parity when shift = '1' or op_is_logic = '1' else
          overflow; 

    -- TODO make sure no output depends on input directly (is this bad?)
    flags(0) <= c_out;
    flags(1) <= '1' when shift = '0' and sub_add = '1' else '0';
    flags(2) <= pv;
    flags(3) <= res_buf(3);
    flags(4) <= '0';
    flags(5) <= res_buf(5);
    flags(6) <= '1' when res_buf = 0 else '0';
    flags(7) <= res_buf(7);

end arch;
