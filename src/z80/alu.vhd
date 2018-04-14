library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

-- TODO
--  * daa
--  * scf, ccf
--  * rest of instructions

entity alu is port(
    clk : in std_logic;
    op1, op2, flags_in : in std_logic_vector(7 downto 0);
    op : in instr_t;
    bit_select : in integer range 0 to 7;
    result, flags_out : out std_logic_vector(7 downto 0));
end alu;

architecture arch of alu is
    -- preprocess
    signal mask : std_logic_vector(7 downto 0); -- mask for bit set/reset
    signal edge : std_logic; -- lsb or msb when shifting
    signal op1_ext, op2_ext : signed(8 downto 0);
    signal op2sn : signed(8 downto 0); -- shift/neg result

    -- calculation
    signal with_carry, daa_v : signed(8 downto 0);
    signal result_sum : signed(8 downto 0);
    signal result_xor, result_and, result_or : signed(8 downto 0);
    signal calc_result : signed(8 downto 0);
    signal result_buf : signed(7 downto 0);

    -- flags
    signal half_add, half_sub, half_daa : std_logic;
    signal overflow, overflow_neg, parity : std_logic;
begin
    -- preprocess
    mask_gen : process(bit_select) is
        variable m : std_logic_vector(7 downto 0);
    begin
        m := x"01";
        for i in 1 to bit_select loop
            m := m(6 downto 0) & '0';
        end loop;
        mask <= m;
    end process;

    daa_logic : process(op2, op2_ext, flags_in) is
	    variable res, v : signed(8 downto 0);
    begin
        v := (others => '0');
        if (op2_ext(7 downto 4) > "1001" or flags_in(H_f) = '1') then
            v := v + "000000110";
        end if;
        res := op2_ext + v;
        if (op2_ext(3 downto 0) > "1001" or 
            res(8) = '1' or
            flags_in(C_f) = '1')
        then
            v := v + "001100000";
        end if;
        if flags_in(N_f) = '1' then
            v := -v;
        end if;
        daa_v <= v;
    end process;

    with op select edge <=
        '0'             when sla_i|sll_i|srl_i,
        flags_in(C_f)   when rl_i|rr_i,
        op2(0)          when rrc_i,
        op2(7)          when rlc_i|sra_i,
        '-'             when others;
    with op select op1_ext <=
        to_signed(1, 9)     when inc_i,
        to_signed(-1, 9)    when dec_i,
        to_signed(0, 9)     when neg_i,
	    daa_v		        when daa_i,
        signed('0' & op1)   when others;
    op2_ext <= signed('0' & op2);
    with op select op2sn <=
        signed('0' & (not mask and op2))    when res_i,
        signed('0' & (mask or op2))         when set_i,
        op2_ext                             when bit_i,
        -op2_ext                            when sub_i|cp_i|neg_i,
        -op2_ext - with_carry               when sbc_i,
        op2_ext + with_carry                when adc_i,
        '0' & op2_ext(6 downto 0) & edge    when rlc_i|rl_i|sla_i|sll_i,
        '0' & edge & op2_ext(7 downto 1)    when rrc_i|rr_i|sra_i|srl_i,
        op2_ext                             when others;

    -- calculation
    with_carry <=
        to_signed(1, 9)
            when flags_in(C_f) = '1' and (op = adc_i or op = sbc_i) else
        to_signed(0, 9);
    result_and <= op1_ext and op2_ext;
    result_xor <= op1_ext xor op2_ext;
    result_or  <= op1_ext or  op2_ext;
    result_sum <= op1_ext + op2sn;
    with op select calc_result <=
        result_sum when add_i|adc_i|sub_i|sbc_i|cp_i|inc_i|dec_i|neg_i|daa_i,
        result_and when and_i,
        result_xor when xor_i,
        result_or  when or_i,
        op2sn      when others;
    result_buf <= calc_result(7 downto 0);
    with op select result <=
        not(op2)                     when cpl_i,
        op1                          when cp_i,
        std_logic_vector(result_buf) when others;

    -- flags
    calc_parity : process(result_buf)
        variable p : std_logic;
    begin
        p := '0';
        for i in result_buf'range loop
            p := p xor result_buf(i);
        end loop;
        parity <= not p;
    end process;
    with op select overflow <=
        (op1_ext(7) xnor op2_ext(7)) and (op1_ext(7) xor calc_result(7))
            when add_i|adc_i|inc_i|dec_i,
        (op1_ext(7) xor op2_ext(7)) and (op1_ext(7) xor calc_result(7))
            when sub_i|sbc_i|cp_i,
        '-' when others;
    overflow_neg <= '1' when op2 = x"80" else '0';
    half_add <= result_buf(4) xor op1_ext(4) xor op2sn(4);
    half_sub <= result_buf(4) xor op1_ext(4) xor op2_ext(4);
    with flags_in(N_f) select half_daa <=
        half_add when '0',
        half_sub when '1',
        '-'      when others;

    with op select flags_out(C_f) <=
    '0'                 when and_i|or_i|xor_i,
    calc_result(8)      when add_i|adc_i|sub_i|sbc_i|cp_i|neg_i|daa_i,
    op2(7)              when rlc_i|rl_i|sla_i|sll_i,
    op2(0)              when rrc_i|rr_i|sra_i|srl_i,
    '1'                 when scf_i,
    not flags_in(C_f)   when ccf_i,
    flags_in(C_f)       when others;

    with op select flags_out(N_f) <=
        '1'             when sub_i|sbc_i|cp_i|neg_i|cpl_i,
        flags_in(N_f)   when daa_i|res_i,
        '0'             when others;

    with op select flags_out(PV_f) <=
        overflow        when add_i|adc_i|sub_i|sbc_i|cp_i|inc_i|dec_i,
        overflow_neg    when neg_i,
        parity          when and_i|or_i|xor_i|bit_i|res_i|set_i|
                             rlc_i|rl_i|sla_i|sll_i|
                             rrc_i|rr_i|sra_i|srl_i|
                             daa_i,
        flags_in(PV_f)  when others;

    flags_out(f3_f) <= result_buf(3);

    with op select flags_out(H_f) <=
        half_add        when add_i|adc_i|inc_i|dec_i,
        half_sub        when sub_i|sbc_i|cp_i|neg_i,
        half_daa        when daa_i,
        flags_in(C_f)   when ccf_i,
        '0'             when scf_i|xor_i|or_i|
                             rlc_i|rl_i|sla_i|sll_i|
                             rrc_i|rr_i|sra_i|srl_i,
        '1'             when and_i|bit_i|cpl_i,
        flags_in(H_f)   when res_i,
        '-'             when others;

    flags_out(f5_f) <= result_buf(5);

    with op select flags_out(Z_f) <=
        not result_buf(bit_select)  when bit_i,
        flags_in(Z_f)               when scf_i|ccf_i|cpl_i|res_i,
        bool_sl(result_buf = 0)     when others;

    with op select flags_out(S_f) <= 
        flags_in(S_f) when scf_i|ccf_i|cpl_i|res_i,
        result_buf(7) when others;
end arch;
