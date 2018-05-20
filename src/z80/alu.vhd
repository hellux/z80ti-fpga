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
    signal mask : std_logic_vector(7 downto 0); -- mask for bit set/reset
    signal edge : std_logic; -- lsb or msb when shifting
    signal op1_ext, op2_ext : signed(8 downto 0);
    signal op2sn : signed(8 downto 0); -- shift/neg result

    -- calculation
    signal daa_v : signed(8 downto 0);
    signal result_sum : signed(8 downto 0);
    signal result_buf : std_logic_vector(7 downto 0);
    
    -- flags
    signal undef_res : std_logic_vector(7 downto 0); -- value for f3, f5
    signal half_add, half_sub, half_daa : std_logic;
    signal daa_c : std_logic;
    signal overflow, parity : std_logic;
begin
    -- preprocess
    mask_gen : process(bit_select) is
        variable m : std_logic_vector(7 downto 0);
    begin
        m := x"00";
        m(bit_select) := '1';
        mask <= m;
    end process;

    daa_logic : process(op2_ext, flags_in) is
	    variable res, v : signed(8 downto 0);
    begin
        daa_c <= '0';
        v := (others => '0');
        if (unsigned(op2_ext(3 downto 0)) > "1001" or flags_in(H_f) = '1') then
            v := v + ('0' & x"06");
        end if;
        res := op2_ext + v;
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

    with op select op1_ext <=
        to_signed(1, 9)     when inc_i,
        to_signed(-1, 9)    when dec_i,
        to_signed(0, 9)     when neg_i,
        daa_v               when daa_i,
        signed('0' & op1)   when others;
    op2_ext <= signed('0' & op2);
    with op select edge <=
        '0'             when sla_i|srl_i,
        '1'             when sll_i, -- undoc odd case
        flags_in(C_f)   when rl_i|rla_i|rr_i|rra_i,
        op2(0)          when rrc_i|rrca_i,
        op2(7)          when rlc_i|rlca_i|sra_i,
        '-'             when others;
    with op select op2sn <=
        signed('0' & (not mask and op2))        when res_i,
        signed('0' & (mask or op2))             when set_i,
        -op2_ext                                when sub_i|
                                                     cp_i|neg_i|
                                                     cpi_i|cpir_i|
                                                     cpd_i|cpdr_i,
        -op2_ext - ("00000000" & flags_in(C_f)) when sbc_i|sbc16_i1|sbc16_i2,
         op2_ext + ("00000000" & flags_in(C_f)) when adc_i|add16_i2|
                                                     adc16_i1|adc16_i2,
        '0' & op2_ext(6 downto 0) & edge        when rlc_i|rl_i|sla_i|sll_i|
                                                     rlca_i|rla_i,
        '0' & edge & op2_ext(7 downto 1)        when rrc_i|rr_i|sra_i|srl_i|
                                                     rrca_i|rra_i,
         op2_ext                                when bit_i,
        op2_ext                                 when others;

    result_sum <= op1_ext + op2sn;
    
    with op select result_buf <=
        op2(3 downto 0) & op1(3 downto 0)        when rld_i1,
        op1(7 downto 4) & op2(7 downto 4)        when rld_i2,
        op1(3 downto 0) & op2(7 downto 4)        when rrd_i1,
        op1(7 downto 4) & op2(3 downto 0)        when rrd_i2,
        op1 and op2                              when and_i,
        op1 xor op2                              when xor_i,
        op1 or  op2                              when or_i,
        std_logic_vector(result_sum(7 downto 0)) when add_i|adc_i|
                                                      sub_i|sbc_i|
                                                      inc_i|dec_i|
                                                      neg_i|cp_i|daa_i|
                                                      cpi_i|cpd_i|
                                                      cpir_i|cpdr_i|
                                                      add16_i1|add16_i2|
                                                      adc16_i1|adc16_i2|
                                                      sbc16_i1|sbc16_i2,
        op2 and mask                             when bit_i,
        std_logic_vector(op2sn(7 downto 0))      when others;
    with op select result <=
        not(op2)   when cpl_i,
        op1        when cp_i|cpi_i|cpd_i|cpir_i|cpdr_i,
        op2        when bit_i,
        result_buf when others;

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
        (op1_ext(7) xnor op2_ext(7)) and (op1_ext(7) xor result_sum(7))
            when add_i|adc_i|inc_i|dec_i|add16_i2|adc16_i2,
        (op1_ext(7) xor op2_ext(7)) and (op1_ext(7) xor result_sum(7))
            when sub_i|sbc_i|cp_i|sbc16_i2,
        '-' when others;
    half_add <= result_buf(4) xor op1_ext(4) xor op2sn(4);
    half_sub <= result_buf(4) xor op1_ext(4) xor op2_ext(4);
    with flags_in(N_f) select half_daa <=
        half_add when '0',
        half_sub when '1',
        '-'      when others;
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
        flags_in(Z_f)                     when ldi_i|ldir_i|ldd_i|lddr_i|
                                               cpl_i|ccf_i|scf_i|
                                               add16_i1|add16_i2|
                                               rlca_i|rla_i|rrca_i|rra_i|
                                               set_i|res_i,
        bool_sl(unsigned(result_buf) = 0) when ld_i|
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
        bool_sl(unsigned(result_buf) = 0) when adc16_i2|sbc16_i2,
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
        half_add        when add_i|adc_i|inc_i|dec_i| -- dec uses (-1) + op2
                             add16_i2|adc16_i2, -- TODO check 16b
        half_sub        when cpi_i|cpir_i|cpd_i|cpdr_i|
                             sub_i|sbc_i|cp_i|
                             neg_i|
                             sbc16_i2,
        half_daa        when daa_i,
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
        '0'                 when and_i|or_i|xor_i,
        result_sum(8)       when add_i|adc_i|sub_i|sbc_i|cp_i|neg_i|
                                 add16_i1|add16_i2|adc16_i1|adc16_i2|
                                 sbc16_i1|sbc16_i2,
        daa_c               when daa_i,
        op2(7)              when rlc_i|rl_i|sla_i|sll_i|rlca_i|rla_i,
        op2(0)              when rrc_i|rr_i|sra_i|srl_i|rrca_i|rra_i,
        '1'                 when scf_i,
        not flags_in(C_f)   when ccf_i,
        flags_in(C_f)       when ldi_i|ldir_i|ldd_i|lddr_i|
                                 cpi_i|cpir_i|cpd_i|cpdr_i|
                                 rrd_i1|rrd_i2|rld_i1|rld_i2|
                                 cpl_i|ld_i|
                                 set_i|res_i,
        flags_in(C_f)       when others;
end arch;
