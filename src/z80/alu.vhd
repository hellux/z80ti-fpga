library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.util.all;

entity alu is port(
    op1, op2, flags_in : in std_logic_vector(7 downto 0);
    op : in instr_t;
    bit_select : in integer range 0 to 7;
    result, flags_out : out std_logic_vector(7 downto 0));
end alu;

architecture arch of alu is
    -- preprocess
    signal mask : std_logic_vector(7 downto 0); -- mask for bit, set, res
    signal edge : std_logic; -- lsb or msb when shifting
    signal arithl, arithr, c_in : signed(8 downto 0); -- arith ops, carry in

    -- calculation
    signal daa_v : signed(8 downto 0);
    signal arith_res : signed(8 downto 0);
    signal result_buf : std_logic_vector(7 downto 0);
    
    -- flags
    signal undef_res : std_logic_vector(7 downto 0); -- value for f3, f5
    signal daa_c : std_logic;
    signal half_carry, overflow, parity : std_logic;
begin
    -- preprocess
    mask_gen : process(bit_select) is
        variable m : std_logic_vector(7 downto 0);
    begin
        m := x"00";
        m(bit_select) := '1';
        mask <= m;
    end process;

    daa_logic : process(arithr, flags_in) is
	    variable res, v : signed(8 downto 0);
    begin
        daa_c <= '0';
        v := (others => '0');
        if (unsigned(arithr(3 downto 0)) > "1001" or flags_in(H_f) = '1') then
            v := v + ('0' & x"06");
        end if;
        res := arithr + v;
        if (unsigned(res(7 downto 4)) > "1001"
            or res(8) = '1'
            or flags_in(C_f) = '1')
        then
            v := v + ('0' & x"60");
            daa_c <= '1';
        end if;
        if flags_in(N_f) = '1' then
            v := -v;
        end if;
        daa_v <= v;
    end process;

    with op select arithl <=
        daa_v               when daa_i,
        signed('0' & op2)   when inc_i|dec_i,
        to_signed(0, 9)     when neg_i,
        signed('0' & op1)   when others;
    with op select arithr <=
        to_signed(1, 9)     when inc_i|dec_i,
        signed('0' & op2)   when others;

    c_in <= x"00" & flags_in(C_f);
    with op select arith_res <=
        arithl + arithr         when add_i|add16_i1|inc_i|daa_i,
        arithl + arithr + c_in  when adc_i|add16_i2|adc16_i1|adc16_i2,
        arithl - arithr         when sub_i|cp_i|dec_i|neg_i|
                                     cpi_i|cpir_i|cpd_i|cpdr_i,
        arithl - arithr - c_in  when sbc_i|sbc16_i1|sbc16_i2,
        (others => '0')         when others;

    with op select edge <=
        '0'             when sla_i|srl_i,
        '1'             when sll_i, -- undoc odd case
        flags_in(C_f)   when rl_i|rla_i|rr_i|rra_i,
        op2(0)          when rrc_i|rrca_i,
        op2(7)          when rlc_i|rlca_i|sra_i,
        '-'             when others;

    with op select result_buf <=
        op1 and op2                              when and_i,
        op1 or  op2                              when or_i,
        op1 xor op2                              when xor_i,
        op2(3 downto 0) & op1(3 downto 0)        when rld_i1,
        op1(7 downto 4) & op2(7 downto 4)        when rld_i2,
        op1(3 downto 0) & op2(7 downto 4)        when rrd_i1,
        op1(7 downto 4) & op2(3 downto 0)        when rrd_i2,
        not(op2)                                 when cpl_i,
        not mask and op2                         when res_i,
        mask or op2                              when set_i,
        op2 and mask                             when bit_i,
        op2(6 downto 0) & edge                   when rlc_i|rl_i|sla_i|sll_i|
                                                      rlca_i|rla_i,
        edge & op2(7 downto 1)                   when rrc_i|rr_i|sra_i|srl_i|
                                                      rrca_i|rra_i,
        op2                                      when ccf_i|scf_i,
        std_logic_vector(arith_res(7 downto 0))  when others;

    with op select result <=
        op1        when cp_i|cpi_i|cpd_i|cpir_i|cpdr_i,
        op2        when bit_i,
        result_buf when others;

    -- flags
    half_carry <= result_buf(4) xor arithl(4) xor arithr(4);
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
        (arithl(7) xnor arithr(7)) and (arithl(7) xor arith_res(7))
            when add_i|adc_i|inc_i|dec_i|add16_i2|adc16_i2,
        (arithl(7) xor arithr(7)) and (arithl(7) xor arith_res(7))
            when sub_i|sbc_i|cp_i|sbc16_i2,
        '-' when others;
    with op select undef_res <=
        op2         when cp_i,
        result_buf  when others;

    with op select flags_out(S_f) <= 
        flags_in(S_f) when ldi_i|ldir_i|ldd_i|lddr_i|
                           cpl_i|ccf_i|scf_i|
                           add16_i1|add16_i2|
                           rlca_i|rla_i|rrca_i|rra_i|
                           set_i|res_i,
        result_buf(7) when ld_i|
                           cpi_i|cpir_i|cpd_i|cpdr_i|
                           add_i|adc_i|sub_i|sbc_i|
                           and_i|or_i|xor_i|cp_i|
                           inc_i|dec_i|
                           daa_i|neg_i|
                           adc16_i2|sbc16_i2|
                           rlc_i|rl_i|rrc_i|rr_i|
                           sla_i|sra_i|srl_i|sll_i|
                           rld_i2|rrd_i2|
                           bit_i|
                           in_i,
        '-' when others;

    with op select flags_out(Z_f) <=
        flags_in(Z_f)               when ldi_i|ldir_i|ldd_i|lddr_i|
                                         cpl_i|ccf_i|scf_i|
                                         add16_i1|add16_i2|
                                         rlca_i|rla_i|rrca_i|rra_i|
                                         set_i|res_i,
        bool_sl(result_buf = x"00") when ld_i|
                                         cpi_i|cpir_i|cpd_i|cpdr_i|
                                         add_i|adc_i|sub_i|sbc_i|
                                         and_i|or_i|xor_i|cp_i|
                                         inc_i|dec_i|
                                         daa_i|neg_i|
                                         adc16_i1|sbc16_i1|
                                         rlc_i|rl_i|rrc_i|rr_i|
                                         sla_i|sra_i|srl_i|sll_i|
                                         rld_i2|rrd_i2|
                                         bit_i|
                                         in_i,
        flags_in(Z_f) and
        bool_sl(result_buf = x"00") when adc16_i2|sbc16_i2,
        '-' when others;

    with op select flags_out(f5_f) <=
        flags_in(f5_f)  when set_i|res_i,
        undef_res(5)    when others;

    with op select flags_out(H_f) <=
        flags_in(H_f)   when set_i|res_i,
        '0'             when ld_i|
                             ldi_i|ldir_i|ldd_i|lddr_i|
                             or_i|xor_i|
                             scf_i|
                             rlca_i|rla_i|rrca_i|rra_i|
                             rlc_i|rl_i|rrc_i|rr_i|
                             sla_i|sra_i|sll_i|srl_i|
                             rld_i2|rrd_i2|
                             in_i,
        '1'             when and_i|
                             cpl_i|
                             bit_i,
        half_carry      when cpi_i|cpir_i|cpd_i|cpdr_i|
                             add_i|adc_i|sub_i|sbc_i|
                             cp_i|inc_i|dec_i|
                             daa_i|neg_i|
                             add16_i2|adc16_i2| -- TODO check 16b
                             sbc16_i2,
        flags_in(C_f)   when ccf_i,
        '-'             when others;

    with op select flags_out(f3_f) <=
        flags_in(f3_f)  when set_i|res_i,
        undef_res(3)    when others;

    with op select flags_out(PV_f) <=
        flags_in(PV_f)       when cpl_i|ccf_i|scf_i|
                                  add16_i1|add16_i2|
                                  rlca_i|rla_i|rrca_i|rra_i|
                                  set_i|res_i,
        overflow             when add_i|adc_i|sub_i|sbc_i|cp_i|
                                  adc16_i2|sbc16_i2,
        parity               when and_i|or_i|xor_i|
                                  daa_i|
                                  rlc_i|rl_i|rrc_i|rr_i|
                                  sla_i|sra_i|sll_i|srl_i|
                                  rld_i2|rrd_i2|
                                  bit_i|
                                  in_i,
        bool_sl(op2 = x"7f") when inc_i,
        bool_sl(op2 = x"80") when dec_i|neg_i,
        '-'                  when others;

    with op select flags_out(N_f) <=
        flags_in(N_f)   when daa_i|
                             set_i|res_i,
        '0'             when ld_i|
                             ldi_i|ldir_i|ldd_i|lddr_i|
                             add_i|adc_i|and_i|or_i|xor_i|inc_i|
                             ccf_i|scf_i|
                             add16_i2|adc16_i2|
                             rlca_i|rla_i|rrca_i|rra_i|
                             rlc_i|rl_i|rrc_i|rr_i|
                             sla_i|sra_i|sll_i|srl_i|
                             rld_i2|rrd_i2|
                             bit_i|
                             in_i,
        '1'             when cpi_i|cpir_i|cpd_i|cpdr_i|
                             sub_i|sbc_i|cp_i|dec_i|
                             cpl_i|neg_i|
                             sbc16_i2,
        '-'             when others;

    with op select flags_out(C_f) <=
        flags_in(C_f)         when ld_i|
                                   ldi_i|ldir_i|ldd_i|lddr_i|
                                   cpi_i|cpir_i|cpd_i|cpdr_i|
                                   inc_i|dec_i|
                                   cpl_i|
                                   rld_i1|rld_i2|rrd_i1|rrd_i2|
                                   bit_i|set_i|res_i,
        not flags_in(C_f)     when ccf_i,
        '0'                   when and_i|or_i|xor_i,
        '1'                   when scf_i,
        op2(0)                when rrca_i|rra_i|rrc_i|rr_i|sra_i|srl_i,
        op2(7)                when rlca_i|rla_i|rlc_i|rl_i|sla_i|sll_i,
        arith_res(8)          when add_i|adc_i|sub_i|sbc_i|cp_i|
                                   add16_i1|add16_i2|adc16_i1|adc16_i2|
                                   sbc16_i1|sbc16_i2,
        bool_sl(op2 /= x"00") when neg_i,
        daa_c                 when daa_i,
        '-'                   when others;
end arch;
