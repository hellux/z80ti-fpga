library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

package z80_instr is
    -- container for out signals
    type id_frame_t is record
        ct : id_ctrl_t;
        cb : ctrlbus_out;
        cw : ctrlword;
    end record;

    function during_t(signal state : in id_state_t; constant t : in integer)
    return std_logic;
    -- t1: abus:addr -> t3: dbus:data
    procedure mem_rd(signal state : in id_state_t;
                     variable f : out id_frame_t);
    -- -> t3: dbus:data, pc++
    procedure mem_rd_pc(signal state : in id_state_t;
                        variable f : out id_frame_t);
    procedure mem_rd_instr(signal state : in id_state_t;
                           variable f : out id_frame_t);
    procedure mem_rd_multi(signal state : in id_state_t;
                           variable f : out id_frame_t);
    procedure mem_wr(signal state : in id_state_t;
                     variable f : out id_frame_t);

    -- INSTRUCTIONS
    procedure nop(signal state : in id_state_t;
                  variable f : out id_frame_t);
    procedure jp_nn(signal state : in id_state_t;
                    variable f : out id_frame_t);
    procedure jp_cc_nn(signal state : in id_state_t;
                       variable f : out id_frame_t;
                       cond : in integer range 0 to 7);
    procedure jp_hl(signal state : in id_state_t;
                    variable f : out id_frame_t);
    procedure jr_d(signal state : in id_state_t;
                   variable f : out id_frame_t);
    procedure jr_cc_d(signal state : in id_state_t;
                       variable f : out id_frame_t;
                       cond : in integer range 0 to 7);
    procedure ex(signal state : in id_state_t;
                 variable f : out id_frame_t;
                 constant swp : rf_swap_t);
    procedure alu_a_r(signal state : in id_state_t;
                      variable f : out id_frame_t;
                      constant op : in instr_t;
                      signal reg : in integer range 0 to 7);
    procedure alu_a_n(signal state : in id_state_t;
                      variable f : out id_frame_t;
                      constant op : in instr_t);
    procedure alu_r(signal state : in id_state_t;
                    variable f : out id_frame_t;
                    constant op : in instr_t;
                    signal reg : in integer range 0 to 7);
    procedure alu_af(signal state : in id_state_t;
                     variable f : out id_frame_t;
                     constant op : in instr_t);
    procedure bit_r(signal state : in id_state_t;
                    variable f : out id_frame_t;
                    constant op : in instr_t;
                    bs : in integer range 0 to 7;
                    signal reg : in integer range 0 to 7);
    procedure ld_r_r(signal state : in id_state_t;
                     variable f : out id_frame_t;
                     signal src, dst : in integer range 0 to 7);
    procedure ld_r_n(signal state : in id_state_t;
                     variable f : out id_frame_t;
                     signal reg: in integer range 0 to 7);
    procedure ld_r_hlx(signal state : in id_state_t;
                       variable f : out id_frame_t;
                       signal reg: in integer range 0 to 7);
    procedure ld_rp_nn(signal state : in id_state_t;
                       variable f : out id_frame_t;
                       reg: in integer range 0 to 7);
    procedure ld_sp_hl(signal state : in id_state_t;
                       variable f : out id_frame_t);
    procedure ld_rpx_a(signal state : in id_state_t;
                       variable f : out id_frame_t;
                       reg : integer range 0 to 15);
    procedure ld_nnx_a(signal state : in id_state_t;
                       variable f : out id_frame_t);
end z80_instr;

package body z80_instr is
    function during_t(signal state : in id_state_t; constant t : in integer)
    return std_logic is
    begin
        if state.t = t then
            return '1';
        else
            return '0';
        end if;
    end during_t;

    procedure mem_rd(signal state : in id_state_t;
                     variable f : out id_frame_t)
    is begin
        case state.t is
        when t1 =>
            f.cw.addr_rd := '1';    -- read from abus to buffer
            f.cw.addr_wr := '1';    -- write from buffer to outside abus
            f.cb.mreq := '1';       -- signal addr is ready on abus
            f.cb.rd := '1';         -- request reading from memory
        when t2 =>
            f.cw.addr_wr := '1';    -- keep writing addr to mem
            f.cw.data_rdi := '1';   -- store instr to data buf
            f.cb.mreq := '1';       -- keep request until byte retrieved
            f.cb.rd := '1';         -- keep reading
        when t3 =>
            f.cw.data_wri := '1';   -- write instr to inner dbus from buf
        when others => null; end case;
    end mem_rd;

    procedure mem_rd_pc(signal state : in id_state_t;
                        variable f : out id_frame_t)
    is begin
        mem_rd(state, f);
        case state.t is
        when t1 =>
            f.cw.pc_wr := '1';
        when t2 =>
            f.cw.pc_wr := '1';
            f.cw.pc_rd := '1';
        when t3 =>
        when others => null; end case;
    end mem_rd_pc;

    procedure mem_rd_instr(signal state : in id_state_t;
                           variable f : out id_frame_t)
    is begin
        mem_rd(state, f);
        case state.t is
        when t1 =>
            if state.mode = wz then
                f.cw.rf_addr := regWZ;
                f.cw.rf_wra := '1'; -- use wz instead of pc
            else 
                f.cw.pc_wr := '1';  -- write pc to abus
            end if;
        when t2 =>
            if state.mode = wz then
                f.cw.rf_addr := regWZ;
                f.cw.rf_wra := '1'; -- keep wz on abus for incr
                f.ct.mode_end := '1'; -- go back to main mode
            else 
                f.cw.pc_wr := '1';  -- keep pc on abus
            end if;
            f.cw.pc_rd := '1';      -- read incremented address to pc
        when t3 =>
            f.cw.ir_rd := '1';      -- read instr from dbus to ir
        when others => null; end case;
    end mem_rd_instr;

    procedure mem_rd_multi(
        signal state : in id_state_t;
        variable f : out id_frame_t)
    is begin
        case state.m is
        when m1 => f.ct.cycle_end := during_t(state, t4); -- end m1
        when others =>
            mem_rd_instr(state, f);     -- mem_rd next byte
            case state.t is
            when t3 =>
                f.ct.mode_end := '1';   -- update mode to prefix
                f.ct.cycle_end := '1';  -- end mcycle
            when others => null; end case;
        end case;
    end mem_rd_multi;

    procedure mem_wr(signal state : in id_state_t;
                     variable f : out id_frame_t)
    is begin
        case state.t is
        when t1 =>
            f.cw.data_wro := '1';   -- send data to memory
            f.cw.addr_rd := '1';    -- read from abus to buffer
            f.cw.addr_wr := '1';    -- write from buffer to outside abus
            f.cb.mreq := '1';       -- signal addr is ready on abus
            f.cb.wr := '1';         -- signal addr is ready on abus
        when t2 =>
            f.cw.data_wro := '1';   -- keep sending data
            f.cw.addr_wr := '1';    -- keep writing addr to mem
            f.cb.mreq := '1';       -- keep request until byte read
            f.cb.wr := '1';         -- keep reading
        when t3 =>
            f.cw.addr_wr := '1';    -- keep writing addr
            f.cw.data_wro := '1';   -- keep sending data
        when others => null; end case;
    end mem_wr;

    procedure nop(
        signal state : in id_state_t;
        variable f : out id_frame_t)
    is begin
        case state.t is
        when t4 =>
            f.ct.cycle_end := '1';
            f.ct.instr_end := '1';
        when others => null; end case;
    end nop;

    procedure jp_nn(signal state : in id_state_t;
                    variable f : out id_frame_t)
    is begin
        case state.m is
        when m1 => f.ct.cycle_end := during_t(state, t4);
        when m2 =>
            mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regW;
                f.ct.cycle_end := '1';
                f.ct.jump := '1';
                f.ct.mode_end := '1'; -- switch to wz mode
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
    end jp_nn;

    procedure jp_cc_nn(signal state : in id_state_t;
                       variable f : out id_frame_t;
                       cond : in integer range 0 to 7)
    is begin
        case state.cc(cond) is
        when true => jp_nn(state, f);
        when false =>
            case state.m is
            when m1 =>
                f.ct.cycle_end := during_t(state, t4);
            when m2 =>
                mem_rd_pc(state, f); -- increment pc to skip nn
                f.ct.cycle_end := during_t(state, t3);
            when m3 =>
                mem_rd_pc(state, f);
                case state.t is
                when t3 =>
                    f.ct.cycle_end := '1';
                    f.ct.instr_end := '1';
                when others => null; end case;
            when others => null; end case;
        end case;
    end jp_cc_nn;

    procedure jp_hl(signal state : in id_state_t;
                    variable f : out id_frame_t)
    is begin
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := regHL;   -- place hl on abus
                f.cw.rf_wra := '1';
                f.cw.addr_in_op := none; -- make sure no inc to addr
                f.cw.pc_rd := '1';       -- store addr in pc
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => end case;
        when others => end case;
    end jp_hl;

    procedure jr_d(signal state : in id_state_t;
                   variable f : out id_frame_t)
    is begin
        case state.m is
        when m1 => f.ct.cycle_end := during_t(state, t4);
        when m2 =>
            mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.pc_wr := '1';
            when t2 =>
                f.cw.pc_wr := '1';
                -- no pc increment
            when t3 =>
                f.cw.pc_disp := '1';    -- send pc to displacer
                f.cw.dis_wr := '1';     -- write displaced addr (pc+z) to abus
                f.cw.pc_rd := '1';      -- write displaced+1 to pc
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            -- why does z80 use this cycle for 5 cp?
            case state.t is
            when t1 => -- chilla
            when t2 => -- gå på rast
            when t3 => -- ta kaffepaus i java
            when t4 => -- gå ut och ta lite frisk luft
            when t5 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
    end jr_d;

    procedure jr_cc_d(signal state : in id_state_t;
                       variable f : out id_frame_t;
                       cond : in integer range 0 to 7)
    is begin
        case state.cc(cond) is
        when true => jr_d(state, f);
        when false =>
            case state.m is
            when m1 =>
                f.ct.cycle_end := during_t(state, t4);
            when m2 =>
                mem_rd_pc(state, f); -- increment pc to skip nn
                case state.t is
                when t3 =>
                    f.ct.cycle_end := '1';
                    f.ct.instr_end := '1';
                when others => null; end case;
            when others => null; end case;
        end case;
    end jr_cc_d;

    procedure ex(signal state : in id_state_t;
                 variable f : out id_frame_t;
                 constant swp : rf_swap_t)
    is begin
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_swp := swp;
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
    end ex;

    procedure alu_a_r(
        signal state : in id_state_t;
        variable f : out id_frame_t;
        constant op : in instr_t;
        signal reg : in integer range 0 to 7)
    is begin
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.act_rd := '1';     -- read from a to tmp accumulator
                f.cw.rf_addr := reg;    -- select reg
                f.cw.rf_wrd := '1';     -- place reg on dbus
                f.cw.tmp_rd := '1';     -- read from dbus to tmp
                f.ct.cycle_end := '1';  -- signal new cycle
            when others => null; end case;
        when m2 =>
            mem_rd_instr(state, f);      -- mem_rd next instr simultaneously
            case state.t is
            when t2 =>
                f.cw.alu_op := op;      -- tell alu operation
                f.cw.alu_wr := '1';     -- place result on dbus
                f.cw.f_rd := '1';       -- read flags from alu
                f.cw.rf_addr := regA;   -- select the A reg
                f.cw.rf_rdd := '1';     -- read alu output from dbus
                f.ct.instr_end := '1';  -- signal instr is done
            when others => null; end case;
        when others => null; end case;
    end alu_a_r;

    procedure alu_a_n(signal state : in id_state_t;
                      variable f : out id_frame_t;
                      constant op : in instr_t)
    is begin
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.act_rd := '1';     -- read from a to tmp accumulator
                f.ct.cycle_end := '1';  -- signal new cycle
            when others => null; end case;
        when m2 =>
            mem_rd(state, f);
            case state.t is
            when t3 => 
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            mem_rd_instr(state, f);      -- mem_rd next instr simultaneously
            case state.t is
            when t2 =>
                f.cw.alu_op := op;      -- tell alu operation
                f.cw.alu_wr := '1';     -- place result on dbus
                f.cw.f_rd := '1';       -- read flags from alu
                f.cw.rf_addr := regA;   -- select the A reg
                f.cw.rf_rdd := '1';     -- read alu output from dbus
                f.ct.instr_end := '1';  -- signal instr is done
            when others => null; end case;
        when others => null; end case;
    end alu_a_n;

    procedure alu_r(signal state : in id_state_t;
                    variable f : out id_frame_t;
                    constant op : in instr_t;
                    signal reg : in integer range 0 to 7)
    is begin
        case state.m is
        when m1 => 
            case state.t is
            when t4 =>
                f.cw.rf_addr := reg;
                f.cw.rf_wrd := '1';
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            mem_rd_instr(state, f);
            case state.t is
            when t2 =>
                f.cw.alu_op := op;
                f.cw.alu_wr := '1';
                f.cw.f_rd := '1';
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
    end alu_r;

    procedure alu_af(signal state : in id_state_t;
                     variable f : out id_frame_t;
                     constant op : in instr_t)
    is begin
        case state.m is
        when m1 => 
            case state.t is
            when t4 =>
                f.cw.rf_addr := regA;
                f.cw.rf_wrd := '1';
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            mem_rd_instr(state, f);
            case state.t is
            when t2 =>
                f.cw.alu_op := op;
                f.cw.alu_wr := '1';
                f.cw.f_rd := '1';
                f.cw.rf_addr := regA;
                f.cw.rf_rdd := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
    end alu_af;

    procedure bit_r(signal state : in id_state_t;
                    variable f : out id_frame_t;
                    constant op : in instr_t;
                    bs : in integer range 0 to 7;
                    signal reg : in integer range 0 to 7)
    is begin
        case state.m is 
        when m2 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := reg;
                f.cw.rf_wrd := '1';
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            mem_rd_instr(state, f);
            case state.t is
            when t2 =>
                f.cw.alu_op := op;
                f.cw.alu_bs := bs;
                f.cw.alu_wr := '1';
                f.cw.f_rd := '1';
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
    end bit_r;

    procedure ld_r_r(signal state : in id_state_t;
                     variable f : out id_frame_t;
                     signal src, dst : in integer range 0 to 7)
    is begin
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := src;
                f.cw.rf_wrd := '1';
                f.cw.tmp_rd := '1';
            when t5 =>
                f.cw.rf_addr := dst;
                f.cw.tmp_wr := '1';
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
    end ld_r_r;

    procedure ld_r_n(signal state : in id_state_t;
                     variable f : out id_frame_t;
                     signal reg: in integer range 0 to 7)
    is begin
        case state.m is
        when m1 => f.ct.cycle_end := during_t(state, t4);
        when m2 =>
            mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
    end ld_r_n;

    procedure ld_r_hlx(signal state : in id_state_t;
                       variable f : out id_frame_t;
                       signal reg: in integer range 0 to 7)
    is begin
        case state.m is
        when m1 =>
            f.ct.cycle_end := during_t(state, t4);
        when m2 => 
            mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regHL;
                f.cw.rf_wra := '1';
            when t3 =>
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
    end ld_r_hlx;

    procedure ld_rp_nn(signal state : in id_state_t;
                       variable f : out id_frame_t;
                       reg: in integer range 0 to 7)
    is begin
        case state.m is
        when m1 => f.ct.cycle_end := during_t(state, t4);
        when m2 =>
            mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := reg + 1; -- store to low byte
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := reg; -- store to high byte
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
    end ld_rp_nn;

    procedure ld_sp_hl(signal state : in id_state_t;
                       variable f : out id_frame_t)
    is begin
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := regHL;
                f.cw.rf_wra := '1';
                f.cw.tmpa_rd := '1';
            when t5 =>
                f.cw.tmpa_wr := '1';
                f.cw.addr_in_op := none;
                f.cw.rf_addr := regSP;
                f.cw.rf_rda := '1';
            when t6 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
    end ld_sp_hl;

    procedure ld_rpx_a(signal state : in id_state_t;
                       variable f : out id_frame_t;
                       reg : integer range 0 to 15)
    is begin
        case state.m is
            when m1 =>
                case state.t is
                when t4 =>
                    f.cw.rf_addr := regA;
                    f.cw.rf_wrd := '1';
                    f.cw.data_rdo := '1';   -- store reg A in data buffer
                    f.ct.cycle_end := '1';
                when others => null; end case;
            when m2 =>
                mem_wr(state, f);
                case state.t is
                when t1 =>
                    f.cw.rf_addr := reg;
                    f.cw.rf_wra := '1';
                when t3 =>
                    f.ct.cycle_end := '1';
                    f.ct.instr_end := '1';
                when others => null; end case;
            when others => null; end case;
    end ld_rpx_a;

    procedure ld_nnx_a(signal state : in id_state_t;
                       variable f : out id_frame_t)
    is begin
        case state.m is
            when m1 => f.ct.cycle_end := during_t(state, t4);
            when m2 =>
                mem_rd_pc(state, f);
                case state.t is
                when t3 =>
                    f.cw.rf_addr := regZ;
                    f.cw.rf_rdd := '1';
                    f.ct.cycle_end := '1';
                when others => null; end case;
            when m3 =>
                mem_rd_pc(state, f);
                case state.t is
                when t3 =>
                    f.cw.rf_addr := regW;
                    f.cw.rf_rdd := '1';
                    f.ct.cycle_end := '1';
                when others => null; end case;
            when m4 =>
                mem_rd(state, f);
                case state.t is
                when t1 =>
                    f.cw.rf_addr := regWZ;
                    f.cw.rf_wra := '1';
                when t3 =>
                    f.cw.rf_addr := regA;
                    f.cw.rf_rdd := '1';
                    f.ct.cycle_end := '1';
                    f.ct.instr_end := '1';
                when others => null; end case;
            when others => null; end case;
    end ld_nnx_a;
end z80_instr;
