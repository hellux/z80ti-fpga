library ieee;
use ieee.std_logic_1164.all;

package z80_comm is
    type instr_t is (unknown, 
                     add_i, adc_i, sub_i, sbc_i, cp_i, inc_i, dec_i, neg_i,
                     add16_i1, add16_i2,
                     and_i, or_i, xor_i,
                     bit_i, res_i, set_i,
                     rlc_i, rl_i, sla_i, sll_i,
                     rrc_i, rr_i, sra_i, srl_i,
                     rlca_i, rrca_i, rla_i, rra_i,
                     daa_i, cpl_i, scf_i, ccf_i,
                     in_i, ld_i,
                     rld_i1, rld_i2, rrd_i1, rrd_i2,
                     ldi_i, cpi_i, ini_i, outi_i,
                     ldd_i, cpd_i, ind_i, outd_i,
                     ldir_i, cpir_i, inir_i, otir_i,
                     lddr_i, cpdr_i, indr_i, otdr_i);
    type rf_swap_t is (none, af, reg, dehl);
    type addr_op_t is (inc, none, dec);
    type cond_t is array(0 to 7) of boolean;

    type id_prefix_t is (main, ed, cb, dd, ddcb, fd, fdcb, ddcb_d, fdcb_d);
    type id_mode_t is (exec, wz, halt, int);

    -- control signals for id
    type id_ctrl_t is record
        cycle_end : std_logic;      -- last state of current cycle
        instr_end : std_logic;      -- last state of current instr
        mode_next : id_mode_t;      -- mode for next cp
        prefix_next : id_prefix_t;  -- prefix for next cp
        im_next : integer range 0 to 2;  -- im for next cp
    end record;

    -- current state/context of cpu
    type state_t is record
        mode : id_mode_t;
        prefix : id_prefix_t;
        im : integer range 0 to 2;
        iff : std_logic;
        cc : cond_t;
        m : integer range 1 to 6;
        t : integer range 1 to 6;
    end record;

    type dbus_src_t is (none, zero_o,
                        pch_o, pcl_o,
                        ext_o, rf_o, tmp_o, alu_o,
                        i_o, r_o);
    type abus_src_t is (none, pc_o, rf_o, tmpa_o, dis_o, int_o, rst_o);
    type pv_src_t is (alu_f, iff_f, anz_f);

    type ctrlword is record 
        -- buses / registers
        dbus_src : dbus_src_t;           -- mux addr to dbus
        abus_src : abus_src_t;           -- mux addr to abus
        rf_addr : integer range 0 to 15; -- addr to reg in regfile
        rf_rdd, rf_rda : std_logic;      -- rd to regfile from dbus/abus
        rf_swp : rf_swap_t;              -- swap regs in regfile
        f_rd : std_logic;                -- alu -> F
        fi_rd : std_logic;               -- alu -> internal flags
        pv_src : pv_src_t;               -- signal to use for pv flag
        i_rd, r_rd : std_logic;          -- dbus -> I, dbus -> R
        ir_rd : std_logic;               -- dbus -> IR
        tmpa_rd : std_logic;             -- addr_in -> tmpa
        pc_rd : std_logic;               -- add_in -> pc
        addr_op : addr_op_t;             -- op for addr_in
        rst_addr : std_logic_vector(2 downto 0); -- addr >> 3 for RST
        iff_next : std_logic;            -- next value for iff
        -- alu
        alu_op : instr_t;                -- op for alu
        alu_bs : integer range 0 to 7;   -- bit select for alu
        act_rd : std_logic;              -- a -> act
        act_rd_dbus : std_logic;         -- dbus -> act
        tmp_rd : std_logic;              -- dbus -> tmp
        -- buffers
        data_rdi, data_rdo : std_logic;  -- data->dbufi, dbus->dbufo
        data_wro : std_logic;            -- dbufo->data
        addr_rd : std_logic;             -- abus->abuf
    end record;

    -- flags
    constant  C_f : integer := 0;   -- carry
    constant  N_f : integer := 1;   -- subtract instr
    constant PV_f : integer := 2;   -- parity/overflow
    constant f3_f : integer := 3;   -- copy of bit 3
    constant  H_f : integer := 4;   -- half carry
    constant f5_f : integer := 5;   -- copy of bit 5
    constant  Z_f : integer := 6;   -- zero
    constant  S_f : integer := 7;   -- sign

    -- conditions
    constant NZ_c : integer := 0;   -- non-zero
    constant  Z_c : integer := 1;   -- zero
    constant NC_c : integer := 2;   -- no carry
    constant  C_c : integer := 3;   -- carry
    constant PO_c : integer := 4;   -- parity odd
    constant PE_c : integer := 5;   -- parity even
    constant  P_c : integer := 6;   -- sign positive
    constant  M_c : integer := 7;   -- sign negative

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
    constant t6 : integer := 6;

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
    constant regF   : integer := 6;
    constant regA   : integer := 7;
    constant regW   : integer := 8;
    constant regZ   : integer := 9;
    constant regSPh : integer := 10;
    constant regSPl : integer := 11;
    constant regIXh : integer := 12;
    constant regIXl : integer := 13;
    constant regIYh : integer := 14;
    constant regIYl : integer := 15;

    type dbg_regs_t is record
        BC, DE, HL, AF, WZ, SP, IX, IY : std_logic_vector(15 downto 0);
    end record;
    type dbg_z80_t is record
        regs : dbg_regs_t;
        state : state_t;
        ct : id_ctrl_t;
        cw : ctrlword;
        pc, abus, tmpa : std_logic_vector(15 downto 0);
        ir, tmp, act, dbus : std_logic_vector(7 downto 0);
    end record;
end z80_comm;
