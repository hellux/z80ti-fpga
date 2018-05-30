library ieee;
use ieee.std_logic_1164.all;

package z80_comm is
    type instr_t is (unknown, 
                     add_i, adc_i, sub_i, sbc_i, cp_i, inc_i, dec_i, neg_i,
                     add16_i1, add16_i2,
                     adc16_i1, adc16_i2,
                     sbc16_i1, sbc16_i2,
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
    type rf_swap_t is (none, af, reg, dehl, afwz);
    type addr_op_t is (inc, none, dec);
    type cond_t is array(0 to 7) of boolean;

    type id_prefix_t is (main, ed, cb, dd, ddcb, fd, fdcb, int);
    type id_mode_t is (exec, halt, interrupt);

    -- control signals for id
    type id_ctrl_t is record
        cycle_end : std_logic;      -- last state of current cycle
        set_m1 : std_logic;         -- reset machine cycle to m1
        instr_end : std_logic;      -- last state of current instr
        mode_next : id_mode_t;      -- mode for next cp
        im_next : integer range 0 to 2;  -- im for next cp
    end record;

    -- current state/context of cpu besides registers
    type state_t is record
        mode : id_mode_t;
        prefix : id_prefix_t;
        im : natural range 0 to 2;
        m : natural range 1 to 5;
        t : natural range 1 to 6;
    end record;

    type dbus_src_t is (none, zero_o,
                        pch_o, pcl_o,
                        ext_o, rf_o, tmp_o, alu_o,
                        i_o, r_o);
    type abus_src_t is (none, pc_o, rf_o, dis_o, ir_o, rst_o);
    type pv_src_t is (alu_f, iff_f, anz_f);

    type ctrlword is record 
        -- buses / registers
        dbus_src : dbus_src_t;           -- mux addr to dbus
        abus_src : abus_src_t;           -- mux addr to abus
        rf_daddr : std_logic_vector(4 downto 0); -- addr to reg rf <-> dbus
        rf_aaddr : std_logic_vector(3 downto 0); -- addr to reg rf <-> abus
        rf_rdd, rf_rda : std_logic;      -- rd to regfile from dbus/abus
        rf_swp : rf_swap_t;              -- swap regs in regfile
        f_rd : std_logic;                -- alu -> F
        pv_src : pv_src_t;               -- signal to use for pv flag
        i_rd, r_rdd, r_rda : std_logic;  -- dbus -> I, dbus -> R, abus -> R
        ir_rd : std_logic;               -- dbus -> IR
        pc_rd : std_logic;               -- addr_in -> pc
        pc_rdh : std_logic;              -- dbus -> pch
        pc_rdl : std_logic;              -- dbus -> pcl
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

    -- reg16 (rp)
    constant regBC  : std_logic_vector(3 downto 0) := "0000";
    constant regDE  : std_logic_vector(3 downto 0) := "0001";
    constant regHL  : std_logic_vector(3 downto 0) := "0010";
    constant regAF  : std_logic_vector(3 downto 0) := "0011";
    constant regWZ  : std_logic_vector(3 downto 0) := "0100";
    constant regSP  : std_logic_vector(3 downto 0) := "0101";
    constant regIX  : std_logic_vector(3 downto 0) := "0110";
    constant regIY  : std_logic_vector(3 downto 0) := "0111";
    constant regIR  : std_logic_vector(3 downto 0) := "1001";
    constant regPC  : std_logic_vector(3 downto 0) := "1010";
    -- reg8 (reg)
    constant regB   : std_logic_vector(4 downto 0) := "00000";
    constant regC   : std_logic_vector(4 downto 0) := "00001";
    constant regD   : std_logic_vector(4 downto 0) := "00010";
    constant regE   : std_logic_vector(4 downto 0) := "00011";
    constant regH   : std_logic_vector(4 downto 0) := "00100";
    constant regL   : std_logic_vector(4 downto 0) := "00101";
    constant regA   : std_logic_vector(4 downto 0) := "00110";
    constant regF   : std_logic_vector(4 downto 0) := "00111";
    constant regW   : std_logic_vector(4 downto 0) := "01000";
    constant regZ   : std_logic_vector(4 downto 0) := "01001";
    constant regSPh : std_logic_vector(4 downto 0) := "01010";
    constant regSPl : std_logic_vector(4 downto 0) := "01011";
    constant regIXh : std_logic_vector(4 downto 0) := "01100";
    constant regIXl : std_logic_vector(4 downto 0) := "01101";
    constant regIYh : std_logic_vector(4 downto 0) := "01110";
    constant regIYl : std_logic_vector(4 downto 0) := "01111";
    constant regI   : std_logic_vector(4 downto 0) := "10000";
    constant regR   : std_logic_vector(4 downto 0) := "10001";
    constant regPCh : std_logic_vector(4 downto 0) := "10010";
    constant regPCl : std_logic_vector(4 downto 0) := "10011";

    type dbg_id_t is record
        jump_beg, jump_end : std_logic;
    end record;
    type dbg_regs_t is record
        BC, DE, HL, AF, WZ, SP, IX, IY : std_logic_vector(15 downto 0);
    end record;
    type dbg_z80_t is record
        regs : dbg_regs_t;
        state : state_t;
        id : dbg_id_t;
        alu_op : instr_t;
        iff : std_logic;
        cycle_start, instr_start, int_start : std_logic;
        pc, abus : std_logic_vector(15 downto 0);
        ir, tmp, act, dbus : std_logic_vector(7 downto 0);
        dbufo, dbufi : std_logic_vector(7 downto 0);
    end record;
end z80_comm;
