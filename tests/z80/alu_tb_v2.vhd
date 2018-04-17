library ieee;
use work.util.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity alu_tb_v2 is
end alu_tb_v2;

architecture arch of alu_tb_v2 is
    component alu port(
        op1, op2, flags_in : in std_logic_vector(7 downto 0);
        op : in instr_t;
        bit_select : in integer range 0 to 7;
        result, flags_out : out std_logic_vector(7 downto 0));
    end component;

    procedure test(
        signal op1_s : out std_logic_vector(7 downto 0);
        signal op2_s : out std_logic_vector(7 downto 0);
        signal op_s : out instr_t;
        signal bit_select_s : out integer range 0 to 7;
        signal flags_in_s : out std_logic_vector(7 downto 0);
        signal flags_out_s : in std_logic_vector(7 downto 0);
        signal result_s : in std_logic_vector(7 downto 0);
        -- input
        constant op1 : std_logic_vector(7 downto 0);
        constant op2 : std_logic_vector(7 downto 0);
        constant op : instr_t;
        constant bit_select : integer range 0 to 7;
        constant flags_in : std_logic_vector(7 downto 0);
        -- assertions
        constant flags_out : std_logic_vector(7 downto 0);
        constant result : std_logic_vector(7 downto 0))
    is begin
        op1_s <= op1;
        op2_s <= op2;
        op_s <= op;
        flags_in_s <= flags_in;
        bit_select_s <= bit_select;
        wait for 5 ns;
        assert result_s = result and
               (flags_out(0) = '-' or (flags_out_s(0) = flags_out(0))) and
               (flags_out(1) = '-' or (flags_out_s(1) = flags_out(1))) and
               (flags_out(2) = '-' or (flags_out_s(2) = flags_out(2))) and
               (flags_out(3) = '-' or (flags_out_s(3) = flags_out(3))) and
               (flags_out(4) = '-' or (flags_out_s(4) = flags_out(4))) and
               (flags_out(5) = '-' or (flags_out_s(5) = flags_out(5))) and
               (flags_out(6) = '-' or (flags_out_s(6) = flags_out(6))) and
               (flags_out(7) = '-' or (flags_out_s(7) = flags_out(7)))
            report lf & 
            "index      76543210" & lf &
            "op1        " & vec_str(op1) & " " & 
                integer'image(to_integer(unsigned(op1))) & lf &
            "op2        " & vec_str(op2) & " " & 
                integer'image(to_integer(unsigned(op2))) & lf & lf &
            "res_actu:  " & vec_str(result_s) & " " &
                integer'image(to_integer(unsigned(result_s))) & lf &
            "res_want:  " & vec_str(result) & " " &
                integer'image(to_integer(unsigned(result))) & lf & lf &
            "flags      SZ-H-PNC" & lf &
            "flags_in   " & vec_str(flags_in) & lf &
            "flags_actu " & vec_str(flags_out_s) & lf &
            "flags_want " & vec_str(flags_out) & lf;
        wait for 5 ns;
    end procedure;

    signal clk : std_logic;
    signal op1, op2 : std_logic_vector(7 downto 0);
    signal flags_in : std_logic_vector(7 downto 0);
    signal op : instr_t;
    signal bit_select : integer range 0 to 7;
    signal result, flags_out : std_logic_vector(7 downto 0);
begin
    alu_comp : alu port map(
        op1 => op1,
        op2 => op2,
        flags_in => flags_in,
        op => op,
        bit_select => bit_select,
        result => result,
        flags_out => flags_out
    );

    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    process begin
        op1 <= x"00";
        op2 <= x"00";
        op <= unknown;
        flags_in <= x"00";

        wait for 20 ns;

        report "TB BEGIN";

        report "add";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"01", x"01", add_i, 0, "00000001", "00-0-000", x"02");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"01", x"01", add_i, 0, "00000000", "00-0-000", x"02");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"01", x"7f", add_i, 0, "00000000", "10-1-100", x"80");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"01", x"7f", add_i, 0, "00000000", "10-1-100", x"80");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"f1", x"7f", add_i, 0, "00000000", "00-1-001", x"70");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"23", x"33", add_i, 0, "00000000", "00-0-000", x"56");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"ff", x"7f", add_i, 0, "00000001", "00-1-001", x"7e");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"20", x"10", add_i, 0, x"20", x"20", x"30");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"30", x"04", add_i, 0, x"20", x"20", x"34");

        report "adc";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", adc_i, 0, "01101010", "01-0-000", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"ff", adc_i, 0, "01101010", "10-0-000", x"ff");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", adc_i, 0, "00000001", "00-0-000", x"01");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"01", x"01", adc_i, 0, "11111111", "00-0-000", x"03");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"01", x"7f", adc_i, 0, "00000000", "10-1-100", x"80");
        -- should below have no half carry?
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"7f", adc_i, 0, "00000001", "10-0-100", x"80");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"ff", adc_i, 0, "00000001", "01-0-001", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"7f", x"7f", adc_i, 0, "00000001", "10-0-100", x"ff");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"80", x"80", adc_i, 0, "00000001", "00-0-101", x"01");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"7f", x"81", adc_i, 0, "00000001", "00-1-001", x"01");

        report "sub";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"29", x"11", sub_i, 0, "00000001", "00-0-010", x"18");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"ff", x"ff", sub_i, 0, "11111111", "01-0-010", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"ff", x"7f", sub_i, 0, "11111111", "10-0-010", x"80");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"01", sub_i, 0, "11111111", "10-1-011", x"ff");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", sub_i, 0, "00000010", "01-0-010", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"7f", x"81", sub_i, 0, "00000010", "10-0-111", x"fe");

        report "sbc";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", sbc_i, 0, "11111110", "01-0-010", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"01", sbc_i, 0, "11111111", "10-1-011", x"fe");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", sbc_i, 0, "11111111", "10-1-011", x"ff");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"ff", x"ff", sbc_i, 0, "11111111", "10-1-011", x"ff");

        report "cp";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"ff", x"ff", cp_i, 0, "11111111", "01-0-010", x"ff");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", cp_i, 0, "00000000", "01-0-010", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"3c", x"c2", cp_i, 0, "00000000", "00-0-011", x"3c");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"10", x"0d", cp_i, 0, "00000000", "00-1-010", x"10");

        report "inc";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"ff", x"01", inc_i, 0, "00000000", "00-0-000", x"02");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"ff", x"ff", inc_i, 0, "00000000", "01-1-000", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"ff", x"ff", inc_i, 0, "00000001", "01-1-001", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", inc_i, 0, "00000001", "00-0-001", x"01");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"93", inc_i, 0, "11100110", "10-0-000", x"94");

        report "dec";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"ff", x"01", dec_i, 0, "00000000", "01-1-000", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"ff", x"00", dec_i, 0, "00000000", "10-0-000", x"ff");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"ff", x"00", dec_i, 0, "11111111", "10-0-001", x"ff");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"82", x"82", dec_i, 0, "11111111", "10-1-001", x"81");

        report "neg";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"98", x"ff", neg_i, 0, "00000000", "00-1-011", x"01");
        -- manual ex
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"98", neg_i, 0, "00000000", "00-1-011", x"68");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", neg_i, 0, "00000000", "01-0-010", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"80", neg_i, 0, "00000000", "10-0-111", x"80");

        report "cp";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", cp_i, 0, x"54", x"42", x"00");

        report "and";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", and_i, 0, "00000000", "01-1-100", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"ff", x"00", and_i, 0, "00000000", "01-1-100", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"ff", and_i, 0, "00000000", "01-1-100", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"0f", x"fe", and_i, 0, "00000000", "00-1-000", x"0e");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"0f", x"01", and_i, 0, "00000000", "00-1-000", x"01");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"e0", x"1f", and_i, 0, x"a0", x"54", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"2c", x"03", and_i, 0, x"18", x"54", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"e3", x"80", and_i, 0, x"6c", x"90", x"80");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"02", and_i, 0, x"90", x"54", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"77", x"3f", and_i, 0, x"54", x"30", x"37");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"e3", x"80", and_i, 0, x"bb", x"90", x"80");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"e1", x"02", and_i, 0, x"a8", x"54", x"00");

        report "xor";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"1f", x"ff", xor_i, 0, x"08", x"a0", x"e0");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"05", x"02", xor_i, 0, x"18", x"00", x"07");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"80", x"80", xor_i, 0, x"90", x"44", x"00");

        report "or";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"4a", x"4a", or_i, 0, x"bb", x"08", x"4a");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"0f", x"ac", or_i, 0, x"ac", x"ac", x"af");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"0f", x"ab", or_i, 0, x"ac", x"ac", x"af");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"0f", x"aa", or_i, 0, x"ac", x"ac", x"af");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"37", x"40", or_i, 0, x"30", x"24", x"77");

        report "sla";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"02", x"02", sla_i, 0, x"54", x"00", x"04");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"02", x"04", sla_i, 0, x"00", x"08", x"08");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"02", x"08", sla_i, 0, x"08", x"00", x"10");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"02", x"10", sla_i, 0, x"00", x"20", x"20");

        report "bit";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"f0", x"01", bit_i, 0, "00000001", "-0-1--01", x"01");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"f0", x"ff", bit_i, 2, "00000000", "-0-1--00", x"ff");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"f0", x"fd", bit_i, 1, "00000000", "-1-1--00", x"fd");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"f0", x"fd", bit_i, 3, "00000000", "-0-1--00", x"fd");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"f0", x"c8", bit_i, 4, "11111111", "-1-1--01", x"c8");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"0c", bit_i, 6, x"54", "-1-1--00", x"0c");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"0c", bit_i, 2, x"54", "-0-1--00", x"0c");

        report "res";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"26", x"4d", res_i, 6, x"10", "00-1-000", x"0d");
        
        report "daa";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"3C", daa_i, 0, "00000000", "00-1-100", x"42");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"42", daa_i, 0, "00000000", "00-0-100", x"42");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"C3", daa_i, 0, "00000000", "00-0-001", x"23");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"CC", daa_i, 0, "00000000", "00-1-001", x"32");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", daa_i, 0, "00000001", "00-0-100", x"60");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", daa_i, 0, "00010000", "00-0-100", x"06");
        
        report "scf";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", scf_i, 0, "00000000", "00-0-001", x"00"); 
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"3C", scf_i, 0, "00000000", "00-0-001", x"3C");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"1D", x"19", scf_i, 0, "00000000", "00-0-001", x"19");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"CD", x"AB", scf_i, 0, "11111110", "11-0-101", x"AB");
       
        report "ccf";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", ccf_i, 0, "00000000", "00-0-001", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"00", ccf_i, 0, "00000001", "00-1-000", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"AC", x"14", ccf_i, 0, "11000101", "11-1-100", x"14");

        report "cpl";
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"00", x"FF", cpl_i, 0, "00000000", "00-1-010", x"00");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"D2", x"B4", cpl_i, 0, "00000000", "00-1-010", x"4B");
        test(op1, op2, op, bit_select, flags_in, flags_out, result,
             x"D2", x"B4", cpl_i, 0, "00000000", "00-1-010", x"4B");
             assert false report "TB COMPLETE" severity failure;
     end process;

 end arch;
