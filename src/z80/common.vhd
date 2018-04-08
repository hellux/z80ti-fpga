library ieee;
use ieee.std_logic_1164.all;

package z80_comm is
    type instr_t is (unknown, 
                     add_i, adc_i, sub_i, sbc_i, cp_i, inc_i, dec_i, neg_i,
                     and_i, or_i, xor_i,
                     bit_i, res_i, set_i,
                     rlc_i, rl_i, sla_i, sll_i,
                     rrc_i, rr_i, sra_i, srl_i,
                     daa_i, cpl_i, scf_i, ccf_i);
    type instr_set_t is (main, ed, cb, dd, ddcb, fd, fdcb);
    type rf_swap_t is (none, af, reg, dehl);

    type ctrlbus_in is record
        -- cpu control
        wt, int, nmi, reset : std_logic;
        -- cpu bus control
        busrq : std_logic;
    end record;

    type ctrlbus_out is record
        -- system control
        m1, mreq, iorq, rd, wr, rfsh : std_logic;
        -- cpu control
        halt : std_logic;
        -- cpu bus control
        busack : std_logic;
    end record;

    type ctrlword is record 
        -- regfile
        rf_addr : integer range 0 to 15;
        rf_rdd, rf_rda, rf_wrd, rf_wra : std_logic;
        rf_swp : rf_swap_t;
        f_rd : std_logic;
        -- alu
        alu_wr : std_logic;
        alu_set : instr_set_t;
        alu_op : instr_t;
        alu_bs : integer range 0 to 7;
        act_rd : std_logic;
        tmp_rd, tmp_wr : std_logic;
        -- control
        ir_rd : std_logic;
        pc_rd, pc_wr : std_logic;
        -- buffers
        data_rdi, data_wri, data_rdo, data_wro : std_logic;
        addr_rd, addr_wr : std_logic;
    end record;

    -- machine states
    constant m1 : integer := 1;
    constant m2 : integer := 2;
    constant m3 : integer := 3;
    constant m4 : integer := 4;
    constant m5 : integer := 5;
    constant m6 : integer := 6;
    constant t1 : integer := 1;
    constant t2 : integer := 2;
    constant t3 : integer := 3;
    constant t4 : integer := 4;
    constant t5 : integer := 5;

    -- reg16
    constant regBC : integer := 0;
    constant regDE : integer := 2;
    constant regHL : integer := 4;
    constant regAF : integer := 6;
    constant regWZ : integer := 8;
    constant regSP : integer := 10;
    constant regIX : integer := 12;
    constant regIY : integer := 14;
    -- reg8
    constant regB   : integer := 0;
    constant regC   : integer := 1;
    constant regD   : integer := 2;
    constant regE   : integer := 3;
    constant regH   : integer := 4;
    constant regL   : integer := 5;
    constant regA   : integer := 7;
    constant regW   : integer := 8;
    constant regZ   : integer := 9;
    constant regSPh : integer := 10;
    constant regSPl : integer := 11;
    constant regIXh : integer := 12;
    constant regIXl : integer := 13;
    constant regIYh : integer := 14;
    constant regIYl : integer := 15;
end z80_comm;
