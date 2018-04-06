library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

-- TODO
--  ensure flags unaffected on some instructions
--  make sure all op codes are covered
--  replace x_op signal with single op type signal (assign with function)
--  remove x_set signals

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
-- IY, IX
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

entity alu is port(
    clk : in std_logic;
    op1, op2, flags_in : in std_logic_vector(7 downto 0);
    op : in std_logic_vector(7 downto 0);
    op_set : in instr_set_t;
    result, flags_out : out std_logic_vector(7 downto 0));
end alu;

architecture arch of alu is
    -- alias
    signal c_in : std_logic;
    signal low, high : std_logic_vector(3 downto 0);

    -- sets
    signal bit_set : std_logic; -- instr is bit instr
    signal mai_set : std_logic;
    signal ext_set : std_logic;
    -- ops
    signal add_op, adc_op : std_logic; -- opcode is add, adc
    signal sub_op, sbc_op : std_logic;
    signal cp_op : std_logic;
    signal inc_op, dec_op : std_logic;
    signal neg_op : std_logic;
    signal and_op, or_op, xor_op : std_logic;
    signal bit_op, res_op, set_op : std_logic;
    signal rlc_op, rl_op, sla_op, sll_op : std_logic;
    signal rrc_op, rr_op, sra_op, srl_op : std_logic;
    signal daa_op : std_logic;

    -- preprocess
    signal bit_select : std_logic_vector(2 downto 0) := "000";
    signal shift_instr : std_logic; -- instr is shift
    signal mask : std_logic_vector(7 downto 0); -- mask for bit set/reset
    signal edge : std_logic; -- lsb or msb when shift_instring
    signal right_left : std_logic; -- subtract/^add or right/^left
    signal op1_ext, op2_ext : signed(8 downto 0);
    signal op2sn : signed(8 downto 0); -- shift_instr/neg result

    -- calculation
    signal arith_instr : std_logic; -- instr is arithmetic
    signal add_instr, sub_instr : std_logic;
    signal logic_instr : std_logic; -- instr is logic instr
    signal with_carry : signed(8 downto 0); -- for add/sub with carry
    signal result_sum : signed(8 downto 0);
    signal result_xor, result_and, result_or : signed(8 downto 0);
    signal calc_result : signed(8 downto 0);
    signal result_buf : signed(7 downto 0);

    -- flags
    signal upd_c, upd_pv : std_logic;
    signal overflow, overflow_neg, parity : std_logic;
    signal S, Z, f5, H, f3, PV, N, C : std_logic;

begin
    c_in <= flags_in(0);
    low <= op(3 downto 0);
    high <= op(7 downto 4);

    -- sets
    bit_set <= '1' when op_set = cb or op_set = ddcb or op_set = fdcb else '0';
    mai_set <= '1' when op_set = main else '0';
    ext_set <= '1' when op_set = ed else '0';
    -- groups
    arith_instr <= add_instr or sub_instr or inc_op or dec_op;
    add_instr <= add_op or adc_op;
    sub_instr <= sub_op or sbc_op or cp_op or neg_op;
    logic_instr <= and_op or xor_op or or_op;
    shift_instr <= '1' when bit_set = '1' and op(7 downto 6) = "00" else '0';

    -- determine op
    add_op <= '1' when
        (bit_set = '0' and high = x"8" and low(3) = '0')    --add r
     or (bit_set = '0' and low = x"9" and high(3) = '0')    --add rr,rr
     or (mai_set = '1' and op = x"c6")                      --add n
        else '0';
    adc_op <= '1' when
        (bit_set = '0' and high = x"8" and low(3) = '1') -- adc s
     or (ext_set = '1' and low = x"a" and high(3) = '0') -- adc rr,rr
     or (mai_set = '1' and op = x"ee")
        else '0';
    sub_op <= '1' when
        (bit_set = '0' and high = x"9" and low(3) = '0') --sub s
     or (mai_set = '1' and op = x"d6")                   --sub n
        else '0';
    sbc_op <= '1' when 
        (bit_set = '0' and high = x"9" and low(3) = '1') -- sbc s
     or (ext_set = '1' and low = x"2" and high(3) = '0') -- sbc rr,rr
     or (mai_set = '1' and op = x"de")
        else '0';
    cp_op <= '1' when 
        (bit_set = '0' and
         ext_set = '0' and high = x"b" and low(3) = '1') -- cp r
     or (ext_set = '1' and (low = x"1" or low = x"9"))   -- cpi,cpir,cpd,cpdr
     or (mai_set = '1' and op = x"fe")                   -- cp n
        else '0';
    inc_op <= '1' when 
        bit_set = '0' 
         and op(7 downto 6) = "00"
         and (low = x"3" or low = x"4" or low = x"c")
        else '0';
    dec_op <= '1' when
        bit_set = '0'
         and op(7 downto 6) = "00"
         and (low = x"5" or low = x"b" or low = x"d")
        else '0';
    neg_op <= '1' when
        ext_set = '1' and (low = x"4" or low = x"c")
        else '0';
    and_op <= '1' when
        (bit_set = '0' and 
         ext_set = '0' and high = x"a" and low(3) = '0') -- and s
     or (mai_set = '1' and op = x"e6")                   -- and n
        else '0';
    xor_op <= '1' when 
        (bit_set = '0' and 
         ext_set = '0' and high = x"a" and low(3) = '1') -- xor s
     or (mai_set = '1' and op = x"ee")                   -- xor n
        else '0';
    or_op <= '1' when
        (bit_set = '0' and high = x"b" and low(3) = '0') -- or s
     or (mai_set = '1' and op = x"f6")                   -- or n
        else '0';
    rlc_op <= '1' when
        (bit_set = '1' and high = x"0" and low(3) = '0') -- rlc s
     or (mai_set = '1' and op = x"07")                   -- rlca
        else '0';
    rrc_op <= '1' when
        (bit_set = '1' and high = x"0" and low(3) = '1') -- rrc s
     or (mai_set = '1' and op = x"0f")                   -- rrca
        else '0';
    rl_op <= '1' when
        (bit_set = '1' and high = x"1" and low(3) = '0') -- rl s
     or (mai_set = '1' and op = x"17")                   -- rla
        else '0';
    rr_op <= '1' when
        (bit_set = '1' and high = x"1" and low(3) = '1') -- rr s
     or (mai_set = '1' and op = x"1f")                   -- rra
        else '0';
    sla_op <= '1' when
        (bit_set = '1' and high = x"2" and low(3) = '0') -- sla s
        else '0';
    sra_op <= '1' when 
        (bit_set = '1' and high = x"2" and low(3) = '1') -- sra s
        else '0';
    sll_op <= '1' when
        (bit_set = '1' and high = x"3" and low(3) = '0') -- sll s
        else '0';
    srl_op <= '1' when 
        (bit_set = '1' and high = x"3" and low(3) = '1') -- srl s
        else '0';
    bit_op <= '1' when
        bit_set = '1' and op(7 downto 6) = "01"
        else '0';
    res_op <= '1' when
        bit_set = '1' and op(7 downto 6) = "10"
        else '0';
    set_op <= '1' when
        bit_set = '1' and op(7 downto 6) = "11"
        else '0';
    daa_op <= '1' when
        bit_set = '0' and op = x"27"
        else '0';

    -- op2 preprocess (shift_instr / neg / bit instr)
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

    edge <= op2(7) when rlc_op = '1' else
            c_in   when rl_op  = '1' else
            '0'    when sla_op = '1' else
            '0'    when sll_op = '1' else
            op2(0) when rrc_op = '1' else
            c_in   when rr_op  = '1' else
            op2(7) when sra_op = '1' else
            '0'    when srl_op = '1' else
            '-';
    right_left <= op(3);
    op1_ext <= "000000001"  when inc_op = '1' else
                "111111111"  when dec_op = '1' else
                "000000000" when neg_op = '1' else
                signed('0' & op1) when bit_set = '0' else 
                "000000000";
    op2_ext <= signed('0' & op2);
    op2sn <=
        signed('0' & (not mask and op2))    when res_op = '1' else
        signed('0' & (mask or op2))         when set_op = '1' else
        op2_ext                             when bit_op = '1' else
        -op2_ext                            when sub_instr = '1' else
        '0' & op2_ext(6 downto 0) & edge    when shift_instr = '1' 
                                             and right_left = '0' else
        '0' & edge & op2_ext(7 downto 1)    when shift_instr = '1'
                                             and right_left = '1' else
        op2_ext;

    -- calculation
    with_carry <= "000000001" when c_in = '1' and adc_op = '1' else
                  "111111111" when c_in = '1' and sbc_op = '1' else
                  "000000000";
    result_and <= op1_ext and op2_ext;
    result_xor <= op1_ext xor op2_ext;
    result_or  <= op1_ext or  op2_ext;
    result_sum <= op1_ext + op2sn + with_carry;
    calc_result <= result_sum       when logic_instr = '0' else
                   result_and when and_op = '1' else
                   result_xor when xor_op = '1' else
                   result_or  when or_op  = '1';
    result_buf <= calc_result(7 downto 0);
    result <= std_logic_vector(result_buf) when cp_op = '0' else op1;

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
    overflow <= (op1_ext(7) xor calc_result(7)) and   -- carry 6 into 7
                (op1_ext(7) xnor op2sn(7));  -- equal signs
    overflow_neg <= '1' when op2 = x"80" else '0';

    S <= result_buf(7);
    Z <= '1' when result_buf = 0 or
         (bit_op = '1' and result_buf(to_integer(unsigned(bit_select))) = '0')
         else '0';
    f5 <= result_buf(5);
    H <= result_buf(4) xor op1_ext(4) xor op2_ext(4)
         when arith_instr = '1' else '1';
    f3 <= result_buf(3);
    N <= sub_instr;
    PV <= overflow_neg  when neg_op = '1' else
          parity        when shift_instr = '1' or logic_instr = '1' else
          overflow; 
    C <= '0'            when logic_instr = '1' else
         calc_result(8) when arith_instr = '1' else
         op2(7)         when shift_instr = '1' and right_left = '0' else
         op2(0)         when shift_instr = '1' and right_left = '1' else
         '-';

    upd_c <= logic_instr or shift_instr or add_instr or sub_instr;
    upd_pv <= logic_instr or shift_instr or arith_instr;

    flags_out(0) <= C when upd_c = '1' else flags_in(0);
    flags_out(1) <= N;
    flags_out(2) <= PV when upd_pv = '1' else flags_in(2);
    flags_out(3) <= f3;
    flags_out(4) <= H;
    flags_out(5) <= f5;
    flags_out(6) <= Z;
    flags_out(7) <= S;
end arch;
