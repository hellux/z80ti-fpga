library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity mem_rom is port(
    clk, rst : in std_logic;
    rd, wr, ce : in std_logic;
    addr : in std_logic_vector(13 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0));
end mem_rom;


architecture arch of mem_rom is
    -- main instr
    constant nop        : std_logic_vector(7 downto 0) := x"00";
    constant djnz_n     : std_logic_vector(7 downto 0) := x"10";
    constant jr_nz_n    : std_logic_vector(7 downto 0) := x"20";
    constant jr_nc_n    : std_logic_vector(7 downto 0) := x"30";
    constant ld_bc_nn   : std_logic_vector(7 downto 0) := x"01";
    constant ld_de_nn   : std_logic_vector(7 downto 0) := x"11";
    constant ld_hl_nn   : std_logic_vector(7 downto 0) := x"21";
    constant ld_sp_nn   : std_logic_vector(7 downto 0) := x"31";
    constant ld_bcx_a   : std_logic_vector(7 downto 0) := x"02";
    constant ld_dex_a   : std_logic_vector(7 downto 0) := x"12";
    constant ld_nnx_hl  : std_logic_vector(7 downto 0) := x"22";
    constant ld_nnx_a   : std_logic_vector(7 downto 0) := x"32";
    constant inc_bc     : std_logic_vector(7 downto 0) := x"03";
    constant inc_de     : std_logic_vector(7 downto 0) := x"13";
    constant inc_hl     : std_logic_vector(7 downto 0) := x"23";
    constant inc_sp     : std_logic_vector(7 downto 0) := x"33";
    constant inc_b      : std_logic_vector(7 downto 0) := x"04";
    constant inc_d      : std_logic_vector(7 downto 0) := x"14";
    constant inc_h      : std_logic_vector(7 downto 0) := x"24";
    constant inc_hlx    : std_logic_vector(7 downto 0) := x"34";
    constant dec_b      : std_logic_vector(7 downto 0) := x"05";
    constant dec_d      : std_logic_vector(7 downto 0) := x"15";
    constant dec_h      : std_logic_vector(7 downto 0) := x"25";
    constant dec_hlx    : std_logic_vector(7 downto 0) := x"35";
    constant ld_b_n     : std_logic_vector(7 downto 0) := x"06";
    constant ld_d_n     : std_logic_vector(7 downto 0) := x"16";
    constant ld_h_n     : std_logic_vector(7 downto 0) := x"26";
    constant ld_hlx_n   : std_logic_vector(7 downto 0) := x"36";
    constant rlca       : std_logic_vector(7 downto 0) := x"07";
    constant rlad_n     : std_logic_vector(7 downto 0) := x"17";
    constant daa        : std_logic_vector(7 downto 0) := x"27";
    constant scf        : std_logic_vector(7 downto 0) := x"37";
    constant ex_af_af   : std_logic_vector(7 downto 0) := x"08";
    constant jr_n       : std_logic_vector(7 downto 0) := x"18";
    constant jr_z_n     : std_logic_vector(7 downto 0) := x"28";
    constant jr_c_n     : std_logic_vector(7 downto 0) := x"38";
    constant add_hl_bc  : std_logic_vector(7 downto 0) := x"09";
    constant add_hl_de  : std_logic_vector(7 downto 0) := x"19";
    constant add_hl_hl  : std_logic_vector(7 downto 0) := x"29";
    constant add_hl_sp  : std_logic_vector(7 downto 0) := x"39";
    constant ld_a_bcx   : std_logic_vector(7 downto 0) := x"0a";
    constant ld_a_dex   : std_logic_vector(7 downto 0) := x"1a";
    constant ld_hl_nnx  : std_logic_vector(7 downto 0) := x"2a";
    constant ld_a_nnx   : std_logic_vector(7 downto 0) := x"3a";
    constant dec_bc     : std_logic_vector(7 downto 0) := x"0b";
    constant dec_de     : std_logic_vector(7 downto 0) := x"1b";
    constant dec_hl     : std_logic_vector(7 downto 0) := x"2b";
    constant dec_sp     : std_logic_vector(7 downto 0) := x"3b";
    constant inc_c      : std_logic_vector(7 downto 0) := x"0c";
    constant inc_e      : std_logic_vector(7 downto 0) := x"1c";
    constant inc_l      : std_logic_vector(7 downto 0) := x"2c";
    constant inc_a      : std_logic_vector(7 downto 0) := x"3c";
    constant dec_c      : std_logic_vector(7 downto 0) := x"0d";
    constant dec_e      : std_logic_vector(7 downto 0) := x"1d";
    constant dec_l      : std_logic_vector(7 downto 0) := x"2d";
    constant dec_a      : std_logic_vector(7 downto 0) := x"3d";
    constant ld_c_n     : std_logic_vector(7 downto 0) := x"0e";
    constant ld_e_n     : std_logic_vector(7 downto 0) := x"1e";
    constant ld_l_n     : std_logic_vector(7 downto 0) := x"2e";
    constant ld_a_n     : std_logic_vector(7 downto 0) := x"3e";
    constant rrca       : std_logic_vector(7 downto 0) := x"0e";
    constant rra        : std_logic_vector(7 downto 0) := x"1e";
    constant cpl        : std_logic_vector(7 downto 0) := x"2e";
    constant ccf        : std_logic_vector(7 downto 0) := x"3e";
    constant ld_b_b     : std_logic_vector(7 downto 0) := x"40";
    constant ld_b_c     : std_logic_vector(7 downto 0) := x"41";
    constant ld_b_d     : std_logic_vector(7 downto 0) := x"42";
    constant ld_b_e     : std_logic_vector(7 downto 0) := x"43";
    constant ld_b_h     : std_logic_vector(7 downto 0) := x"44";
    constant ld_b_l     : std_logic_vector(7 downto 0) := x"45";
    constant ld_b_hlx   : std_logic_vector(7 downto 0) := x"46";
    constant ld_b_a     : std_logic_vector(7 downto 0) := x"47";
    constant ld_c_b     : std_logic_vector(7 downto 0) := x"48";
    constant ld_c_c     : std_logic_vector(7 downto 0) := x"49";
    constant ld_c_d     : std_logic_vector(7 downto 0) := x"4a";
    constant ld_c_e     : std_logic_vector(7 downto 0) := x"4b";
    constant ld_c_h     : std_logic_vector(7 downto 0) := x"4c";
    constant ld_c_l     : std_logic_vector(7 downto 0) := x"4d";
    constant ld_c_hlx   : std_logic_vector(7 downto 0) := x"4e";
    constant ld_c_a     : std_logic_vector(7 downto 0) := x"4f";
    constant ld_d_b     : std_logic_vector(7 downto 0) := x"50";
    constant ld_d_c     : std_logic_vector(7 downto 0) := x"51";
    constant ld_d_d     : std_logic_vector(7 downto 0) := x"52";
    constant ld_d_e     : std_logic_vector(7 downto 0) := x"53";
    constant ld_d_h     : std_logic_vector(7 downto 0) := x"54";
    constant ld_d_l     : std_logic_vector(7 downto 0) := x"55";
    constant ld_d_hlx   : std_logic_vector(7 downto 0) := x"56";
    constant ld_d_a     : std_logic_vector(7 downto 0) := x"57";
    constant ld_e_b     : std_logic_vector(7 downto 0) := x"58";
    constant ld_e_c     : std_logic_vector(7 downto 0) := x"59";
    constant ld_e_d     : std_logic_vector(7 downto 0) := x"5a";
    constant ld_e_e     : std_logic_vector(7 downto 0) := x"5b";
    constant ld_e_h     : std_logic_vector(7 downto 0) := x"5c";
    constant ld_e_l     : std_logic_vector(7 downto 0) := x"5d";
    constant ld_e_hlx   : std_logic_vector(7 downto 0) := x"5e";
    constant ld_e_a     : std_logic_vector(7 downto 0) := x"5f";
    constant ld_h_b     : std_logic_vector(7 downto 0) := x"60";
    constant ld_h_c     : std_logic_vector(7 downto 0) := x"61";
    constant ld_h_d     : std_logic_vector(7 downto 0) := x"62";
    constant ld_h_e     : std_logic_vector(7 downto 0) := x"63";
    constant ld_h_h     : std_logic_vector(7 downto 0) := x"64";
    constant ld_h_l     : std_logic_vector(7 downto 0) := x"65";
    constant ld_h_hlx   : std_logic_vector(7 downto 0) := x"66";
    constant ld_h_a     : std_logic_vector(7 downto 0) := x"67";
    constant ld_l_b     : std_logic_vector(7 downto 0) := x"68";
    constant ld_l_c     : std_logic_vector(7 downto 0) := x"69";
    constant ld_l_d     : std_logic_vector(7 downto 0) := x"6a";
    constant ld_l_e     : std_logic_vector(7 downto 0) := x"6b";
    constant ld_l_h     : std_logic_vector(7 downto 0) := x"6c";
    constant ld_l_l     : std_logic_vector(7 downto 0) := x"6d";
    constant ld_l_hlx   : std_logic_vector(7 downto 0) := x"6e";
    constant ld_l_a     : std_logic_vector(7 downto 0) := x"6f";
    constant ld_hlx_b   : std_logic_vector(7 downto 0) := x"70";
    constant ld_hlx_c   : std_logic_vector(7 downto 0) := x"71";
    constant ld_hlx_d   : std_logic_vector(7 downto 0) := x"72";
    constant ld_hlx_e   : std_logic_vector(7 downto 0) := x"73";
    constant ld_hlx_h   : std_logic_vector(7 downto 0) := x"74";
    constant ld_hlx_l   : std_logic_vector(7 downto 0) := x"75";
    constant halt       : std_logic_vector(7 downto 0) := x"76";
    constant ld_hlx_a   : std_logic_vector(7 downto 0) := x"77";
    constant ld_a_b     : std_logic_vector(7 downto 0) := x"78";
    constant ld_a_c     : std_logic_vector(7 downto 0) := x"79";
    constant ld_a_d     : std_logic_vector(7 downto 0) := x"7a";
    constant ld_a_e     : std_logic_vector(7 downto 0) := x"7b";
    constant ld_a_h     : std_logic_vector(7 downto 0) := x"7c";
    constant ld_a_l     : std_logic_vector(7 downto 0) := x"7d";
    constant ld_a_hlx   : std_logic_vector(7 downto 0) := x"7e";
    constant ld_a_a     : std_logic_vector(7 downto 0) := x"7f";
    constant add_b      : std_logic_vector(7 downto 0) := x"80";
    constant add_c      : std_logic_vector(7 downto 0) := x"81";
    constant add_d      : std_logic_vector(7 downto 0) := x"82";
    constant add_e      : std_logic_vector(7 downto 0) := x"83";
    constant add_h      : std_logic_vector(7 downto 0) := x"84";
    constant add_l      : std_logic_vector(7 downto 0) := x"85";
    constant add_hlx    : std_logic_vector(7 downto 0) := x"86";
    constant add_a      : std_logic_vector(7 downto 0) := x"87";
    constant adc_b      : std_logic_vector(7 downto 0) := x"88";
    constant adc_c      : std_logic_vector(7 downto 0) := x"89";
    constant adc_d      : std_logic_vector(7 downto 0) := x"8a";
    constant adc_e      : std_logic_vector(7 downto 0) := x"8b";
    constant adc_h      : std_logic_vector(7 downto 0) := x"8c";
    constant adc_l      : std_logic_vector(7 downto 0) := x"8d";
    constant adc_hlx    : std_logic_vector(7 downto 0) := x"8e";
    constant adc_a      : std_logic_vector(7 downto 0) := x"8f";
    constant sub_b      : std_logic_vector(7 downto 0) := x"90";
    constant sub_c      : std_logic_vector(7 downto 0) := x"91";
    constant sub_d      : std_logic_vector(7 downto 0) := x"92";
    constant sub_e      : std_logic_vector(7 downto 0) := x"93";
    constant sub_h      : std_logic_vector(7 downto 0) := x"94";
    constant sub_l      : std_logic_vector(7 downto 0) := x"95";
    constant sub_hlx    : std_logic_vector(7 downto 0) := x"96";
    constant sub_a      : std_logic_vector(7 downto 0) := x"97";
    constant sbc_b      : std_logic_vector(7 downto 0) := x"98";
    constant sbc_c      : std_logic_vector(7 downto 0) := x"99";
    constant sbc_d      : std_logic_vector(7 downto 0) := x"9a";
    constant sbc_e      : std_logic_vector(7 downto 0) := x"9b";
    constant sbc_h      : std_logic_vector(7 downto 0) := x"9c";
    constant sbc_l      : std_logic_vector(7 downto 0) := x"9d";
    constant sbc_hlx    : std_logic_vector(7 downto 0) := x"9e";
    constant sbc_a      : std_logic_vector(7 downto 0) := x"9f";
    constant and_b      : std_logic_vector(7 downto 0) := x"a0";
    constant and_c      : std_logic_vector(7 downto 0) := x"a1";
    constant and_d      : std_logic_vector(7 downto 0) := x"a2";
    constant and_e      : std_logic_vector(7 downto 0) := x"a3";
    constant and_h      : std_logic_vector(7 downto 0) := x"a4";
    constant and_l      : std_logic_vector(7 downto 0) := x"a5";
    constant and_hlx    : std_logic_vector(7 downto 0) := x"a6";
    constant and_a      : std_logic_vector(7 downto 0) := x"a7";
    constant xor_b      : std_logic_vector(7 downto 0) := x"a8";
    constant xor_c      : std_logic_vector(7 downto 0) := x"a9";
    constant xor_d      : std_logic_vector(7 downto 0) := x"aa";
    constant xor_e      : std_logic_vector(7 downto 0) := x"ab";
    constant xor_h      : std_logic_vector(7 downto 0) := x"ac";
    constant xor_l      : std_logic_vector(7 downto 0) := x"ad";
    constant xor_hlx    : std_logic_vector(7 downto 0) := x"ae";
    constant xor_a      : std_logic_vector(7 downto 0) := x"af";
    constant or_b       : std_logic_vector(7 downto 0) := x"b0";
    constant or_c       : std_logic_vector(7 downto 0) := x"b1";
    constant or_d       : std_logic_vector(7 downto 0) := x"b2";
    constant or_e       : std_logic_vector(7 downto 0) := x"b3";
    constant or_h       : std_logic_vector(7 downto 0) := x"b4";
    constant or_l       : std_logic_vector(7 downto 0) := x"b5";
    constant or_hlx     : std_logic_vector(7 downto 0) := x"b6";
    constant or_a       : std_logic_vector(7 downto 0) := x"b7";
    constant cp_b       : std_logic_vector(7 downto 0) := x"b8";
    constant cp_c       : std_logic_vector(7 downto 0) := x"b9";
    constant cp_d       : std_logic_vector(7 downto 0) := x"ba";
    constant cp_e       : std_logic_vector(7 downto 0) := x"bb";
    constant cp_h       : std_logic_vector(7 downto 0) := x"bc";
    constant cp_l       : std_logic_vector(7 downto 0) := x"bd";
    constant cp_hlx     : std_logic_vector(7 downto 0) := x"be";
    constant cp_a       : std_logic_vector(7 downto 0) := x"bf";
    constant ret_nz     : std_logic_vector(7 downto 0) := x"c0";
    constant ret_nc     : std_logic_vector(7 downto 0) := x"d0";
    constant ret_po     : std_logic_vector(7 downto 0) := x"e0";
    constant ret_p      : std_logic_vector(7 downto 0) := x"f0";
    constant pop_bc     : std_logic_vector(7 downto 0) := x"c1";
    constant pop_de     : std_logic_vector(7 downto 0) := x"d1";
    constant pop_hl     : std_logic_vector(7 downto 0) := x"e1";
    constant pop_af     : std_logic_vector(7 downto 0) := x"f1";
    constant jp_nz_nn   : std_logic_vector(7 downto 0) := x"c2";
    constant jp_nc_nn   : std_logic_vector(7 downto 0) := x"d2";
    constant jp_po_nn   : std_logic_vector(7 downto 0) := x"e2";
    constant jp_p_nn    : std_logic_vector(7 downto 0) := x"f2";
    constant jp_nn      : std_logic_vector(7 downto 0) := x"c3";
    constant out_n_a    : std_logic_vector(7 downto 0) := x"d3";
    constant ex_spx_hl  : std_logic_vector(7 downto 0) := x"e3";
    constant di         : std_logic_vector(7 downto 0) := x"f3";
    constant call_nz_nn : std_logic_vector(7 downto 0) := x"c4";
    constant call_nc_nn : std_logic_vector(7 downto 0) := x"d4";
    constant call_po_nn : std_logic_vector(7 downto 0) := x"e4";
    constant call_p_nn  : std_logic_vector(7 downto 0) := x"f4";
    constant push_bc    : std_logic_vector(7 downto 0) := x"c5";
    constant push_de    : std_logic_vector(7 downto 0) := x"d5";
    constant push_hl    : std_logic_vector(7 downto 0) := x"e5";
    constant push_af    : std_logic_vector(7 downto 0) := x"f5";
    constant add_n      : std_logic_vector(7 downto 0) := x"c6";
    constant sub_n      : std_logic_vector(7 downto 0) := x"d6";
    constant and_n      : std_logic_vector(7 downto 0) := x"e6";
    constant or_n       : std_logic_vector(7 downto 0) := x"f6";
    constant rst_00h    : std_logic_vector(7 downto 0) := x"c7";
    constant rst_10h    : std_logic_vector(7 downto 0) := x"d7";
    constant rst_20h    : std_logic_vector(7 downto 0) := x"e7";
    constant rst_30h    : std_logic_vector(7 downto 0) := x"f7";
    constant ret_z      : std_logic_vector(7 downto 0) := x"c8";
    constant ret_c      : std_logic_vector(7 downto 0) := x"d8";
    constant ret_pe     : std_logic_vector(7 downto 0) := x"e8";
    constant ret_m      : std_logic_vector(7 downto 0) := x"f8";
    constant ret        : std_logic_vector(7 downto 0) := x"c9";
    constant exx        : std_logic_vector(7 downto 0) := x"d9";
    constant jp_hl      : std_logic_vector(7 downto 0) := x"e9";
    constant ld_sp_hl   : std_logic_vector(7 downto 0) := x"f9";
    constant jp_z_nn    : std_logic_vector(7 downto 0) := x"ca";
    constant jp_c_nn    : std_logic_vector(7 downto 0) := x"da";
    constant jp_pe_nn   : std_logic_vector(7 downto 0) := x"ea";
    constant jp_m_nn    : std_logic_vector(7 downto 0) := x"fa";
    constant cb         : std_logic_vector(7 downto 0) := x"cb";
    constant in_a_n    : std_logic_vector(7 downto 0) := x"db";
    constant ex_de_hl   : std_logic_vector(7 downto 0) := x"eb";
    constant ei         : std_logic_vector(7 downto 0) := x"fb";
    constant call_z_nn  : std_logic_vector(7 downto 0) := x"cc";
    constant call_c_nn  : std_logic_vector(7 downto 0) := x"dc";
    constant call_pe_nn : std_logic_vector(7 downto 0) := x"ec";
    constant call_m_nn  : std_logic_vector(7 downto 0) := x"fc";
    constant call_nn    : std_logic_vector(7 downto 0) := x"cd";
    constant ix         : std_logic_vector(7 downto 0) := x"dd";
    constant ed         : std_logic_vector(7 downto 0) := x"ed";
    constant iy         : std_logic_vector(7 downto 0) := x"fd";
    constant adc_n      : std_logic_vector(7 downto 0) := x"ce";
    constant sbc_n      : std_logic_vector(7 downto 0) := x"de";
    constant xor_n      : std_logic_vector(7 downto 0) := x"ee";
    constant cp_n       : std_logic_vector(7 downto 0) := x"ff";
    constant rst_08h    : std_logic_vector(7 downto 0) := x"cf";
    constant rst_18h    : std_logic_vector(7 downto 0) := x"df";
    constant rst_28h    : std_logic_vector(7 downto 0) := x"ef";
    constant rst_38h    : std_logic_vector(7 downto 0) := x"ff";
    -- extended
    constant in_b_c     : std_logic_vector(7 downto 0) := x"40";
    constant in_d_c     : std_logic_vector(7 downto 0) := x"50";
    constant in_h_c     : std_logic_vector(7 downto 0) := x"60";
    constant in_c       : std_logic_vector(7 downto 0) := x"70";
    constant in_c_c     : std_logic_vector(7 downto 0) := x"48";
    constant in_e_c     : std_logic_vector(7 downto 0) := x"58";
    constant in_l_c     : std_logic_vector(7 downto 0) := x"68";
    constant in_a_c     : std_logic_vector(7 downto 0) := x"78";
    constant out_c_a    : std_logic_vector(7 downto 0) := x"79";
    
    -- bit instructions
    constant set_6_a    : std_logic_vector(7 downto 0) := x"f7";

    type mem_t is array(0 to 127) of std_logic_vector(7 downto 0);
    constant prgm_test : mem_t := (
        ld_c_n,
        x"10",
        ld_a_n,
        x"01",
        ed,
        out_c_a,
        ld_d_n,
        x"40",
        ld_b_n,
        x"0c",
        ld_a_n,
        x"07",
        out_c_a,
        ld_a_n,
        x"aa",
        out_n_a,
        x"11",
        dec_b,
        jp_nz_nn,
        x"0e",
        x"00",
        ld_a_n,
        x"05",
        out_c_a,
        in_a_n,
        x"11",
        ld_a_n,
        x"20",
        out_c_a,
        dec_d,
        jp_nz_nn,
        x"08",
        x"00",
        halt,
        others => nop);

    impure function file_to_mem(filename : string) return mem_t is
        use std.textio.all;
        type charfile is file of character;
        file file_p : charfile;
        variable word : character;
        variable mem : mem_t;
        use ieee.numeric_std.all;
    begin
        mem := (others => x"00");
        file_open(file_p, filename, READ_MODE);
        for i in mem_t'range loop
            if endfile(file_p) then exit; end if; 
            read(file_p, word);
            mem(i) := std_logic_vector(to_unsigned(character'pos(word), 8));
        end loop;
        file_close(file_p);
        return mem;
    end function;


    --signal mem : mem_t := file_to_mem("a.bin");
    signal mem : mem_t := prgm_test;
    signal word_out : std_logic_vector(7 downto 0);
    signal a : integer range 0 to 16383 := 0;
begin
    a <= to_integer(unsigned(addr));

    process(clk) begin
        if rising_edge(clk) then
            if ce = '1' then
                if rd = '1' then
                    if 0 <= a and a <= 127 then
                        mem(a) <= data_in;
                    end if;
                end if;
            end if;
            if 0 <= a and a <= 127 then
                word_out <= mem(a);
            else
                word_out <= x"ee";
            end if;
        end if;
    end process;

    data_out <= word_out when ce = '1' and wr = '1' else x"00";
end arch;
