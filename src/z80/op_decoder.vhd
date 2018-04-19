library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity op_decoder is port(
    state : in state_t;
    instr : in std_logic_vector(7 downto 0);
    ctrl : out id_ctrl_t;
    cbo : out ctrlbus_out;
    cw : out ctrlword);
end op_decoder;

architecture arch of op_decoder is
    type id_frame_t is record
        ct : id_ctrl_t;
        cb : ctrlbus_out;
        cw : ctrlword;
    end record;

    function io_rd(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.t is
        when t1 =>
            f.cw.addr_rd := '1';    -- read from abus to buffer
            f.cb.iorq := '1';       -- signal addr is ready on abus
            f.cb.rd := '1';         -- request reading from io
        when t2 =>
            f.cw.data_rdi := '1';   -- store instr to data buf
            f.cb.iorq := '1';       -- keep request until byte retrieved
            f.cb.rd := '1';         -- keep reading
        when t3 =>
            f.cw.dbus_src := ext_o; -- write data to inner dbus from buf
        when others => null; end case;
        return f;
    end io_rd;

    function io_wr(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.t is
        when t1 =>
            f.cw.addr_rd := '1';    -- read from abus to buffer
            f.cb.iorq := '1';       -- signal addr is ready on abus
        when t2 =>
            f.cw.data_wro := '1';   -- send data
            f.cb.iorq := '1';       -- keep request until byte read
            f.cb.wr := '1';         -- signal write
        when t3 =>
            f.cw.data_wro := '1';   -- keep sending data
        when others => null; end case;
        return f;
    end io_wr;

    function mem_rd(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.t is
        when t1 =>
            f.cw.addr_rd := '1';    -- read from abus to buffer
            f.cb.mreq := '1';       -- signal addr is ready on abus
            f.cb.rd := '1';         -- request reading from memory
        when t2 =>
            f.cw.data_rdi := '1';   -- store instr to data buf
            f.cb.mreq := '1';       -- keep request until byte retrieved
            f.cb.rd := '1';         -- keep reading
        when t3 =>
            f.cw.dbus_src := ext_o; -- write byte to inner dbus from buf
        when others => null; end case;
        return f;
    end mem_rd;

    function mem_wr(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.t is
        when t1 =>
            f.cw.data_wro := '1';   -- send data to memory
            f.cw.addr_rd := '1';    -- read from abus to buffer
            f.cb.mreq := '1';       -- signal addr is ready on abus
        when t2 =>
            f.cw.data_wro := '1';   -- send data
            f.cb.mreq := '1';       -- keep request until byte read
            f.cb.wr := '1';         -- keep reading
        when t3 =>
            f.cw.data_wro := '1';   -- keep sending data
        when others => null; end case;
        return f;
    end mem_wr;

    function mem_rd_pc(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        f := mem_rd(state, f);
        case state.t is
        when t1 =>
            f.cw.abus_src := pc_o;
        when t2 =>
            f.cw.abus_src := pc_o;
            f.cw.pc_rd := '1';
        when others => null; end case;
        return f;
    end mem_rd_pc;

    function mem_rd_instr(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        f := mem_rd(state, f);
        case state.t is
        when t1 =>
            if state.mode = wz then
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := rf_o; -- use wz instead of pc
            else 
                f.cw.abus_src := pc_o; -- write pc to abus
            end if;
        when t2 =>
            if state.mode = wz then
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := rf_o; -- keep wz on abus for incr
                f.ct.mode_next := main; -- go back to main mode
            else 
                f.cw.abus_src := pc_o; -- keep pc on abus
            end if;
            f.cw.pc_rd := '1';      -- read incremented address to pc
        when t3 =>
            f.cw.ir_rd := '1';      -- read instr from dbus to ir
        when others => null; end case;
        return f;
    end mem_rd_instr;

    function mem_rd_multi(state : state_t; f_in : id_frame_t;
                          prefix : id_mode_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => 
            case state.t is
            when t4 => f.ct.cycle_end := '1'; -- end m1
            when others => null; end case;
        when others =>
            f := mem_rd_instr(state, f);     -- mem_rd next byte
            case state.t is
            when t3 =>
                f.ct.mode_next := prefix; -- update mode to prefix
                f.ct.cycle_end := '1';  -- end mcycle
            when others => null; end case;
        end case;
        return f;
    end mem_rd_multi;

    function nop(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.t is
        when t4 =>
            f.ct.cycle_end := '1';
            f.ct.instr_end := '1';
        when others => null; end case;
        return f;
    end nop;

    function jp_nn(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => 
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regW;
                f.ct.cycle_end := '1';
                f.ct.mode_next := wz;
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end jp_nn;

    function jp_cc_nn(state : state_t; f_in : id_frame_t;
                      cond : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.cc(cond) is
        when true => f := jp_nn(state, f);
        when false =>
            case state.m is
            when m1 =>
                case state.t is
                when t4 =>
                    f.ct.cycle_end := '1';
                when others => null; end case;
            when m2 =>
                f := mem_rd_pc(state, f); -- increment pc to skip nn
                case state.t is
                when t3 =>
                    f.ct.cycle_end := '1';
                when others => null; end case;
            when m3 =>
                f := mem_rd_pc(state, f);
                case state.t is
                when t3 =>
                    f.ct.cycle_end := '1';
                    f.ct.instr_end := '1';
                when others => null; end case;
            when others => null; end case;
        end case;
        return f;
    end jp_cc_nn;

    function jp_hl(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := regHL;   -- place hl on abus
                f.cw.abus_src := rf_o;
                f.cw.addr_op := none; -- make sure no inc to addr
                f.cw.pc_rd := '1';       -- store addr in pc
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => end case;
        when others => end case;
        return f;
    end jp_hl;

    function jr_d(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.abus_src := pc_o;
            when t2 => -- parce pc without increment
                f.cw.abus_src := pc_o;
            when t3 =>
                f.cw.pc_dis := '1';    -- send pc to displacer
                f.cw.abus_src := dis_o; -- write displaced addr (pc+z) to abus
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
        return f;
    end jr_d;

    function jr_cc_d(state : state_t; f_in : id_frame_t;
                     cond : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.cc(cond) is
        when true => f := jr_d(state, f);
        when false =>
            case state.m is
            when m1 =>
                case state.t is
                when t4 =>
                    f.ct.cycle_end := '1';
                when others => null; end case;
            when m2 =>
                f := mem_rd_pc(state, f); -- increment pc to skip nn
                case state.t is
                when t3 =>
                    f.ct.cycle_end := '1';
                    f.ct.instr_end := '1';
                when others => null; end case;
            when others => null; end case;
        end case;
        return f;
    end jr_cc_d;

    function ex(state : state_t; f_in : id_frame_t;
                swp : rf_swap_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_swp := swp;
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ex;

    function alu_a_r(state : state_t; f_in : id_frame_t;
                     op : instr_t; reg : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.act_rd := '1';     -- read from a to tmp accumulator
                f.cw.rf_addr := reg;    -- select reg
                f.cw.dbus_src := rf_o;  -- place reg on dbus
                f.cw.tmp_rd := '1';     -- read from dbus to tmp
                f.ct.cycle_end := '1';  -- signal new cycle
            when others => null; end case;
        when m2 =>
            f := mem_rd_instr(state, f); -- mem_rd next instr simultaneously
            case state.t is
            when t2 =>
                f.cw.alu_op := op;      -- tell alu operation
                f.cw.dbus_src := alu_o; -- place result on dbus
                f.cw.f_rd := '1';       -- read flags from alu
                f.cw.rf_addr := regA;   -- select the A reg
                f.cw.rf_rdd := '1';     -- read alu output from dbus
                f.ct.instr_end := '1';  -- signal instr is done
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_a_r;

    function alu_a_n(state : state_t; f_in : id_frame_t;
                     op : instr_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.act_rd := '1';     -- read from a to tmp accumulator
                f.ct.cycle_end := '1';  -- signal new cycle
            when others => null; end case;
        when m2 =>
            f := mem_rd(state, f);
            case state.t is
            when t3 => 
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd_instr(state, f); -- mem_rd next instr simultaneously
            case state.t is
            when t2 =>
                f.cw.alu_op := op;      -- tell alu operation
                f.cw.dbus_src := alu_o; -- place result on dbus
                f.cw.f_rd := '1';       -- read flags from alu
                f.cw.rf_addr := regA;   -- select the A reg
                f.cw.rf_rdd := '1';     -- read alu output from dbus
                f.ct.instr_end := '1';  -- signal instr is done
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_a_n;

    function alu_r(state : state_t; f_in : id_frame_t;
                   op : instr_t; reg : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => 
            case state.t is
            when t4 =>
                f.cw.rf_addr := reg;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := mem_rd_instr(state, f); -- overlap
            case state.t is
            when t2 =>
                f.cw.alu_op := op;
                f.cw.dbus_src := alu_o;
                f.cw.f_rd := '1';
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_r;

    function alu_af(state : state_t; f_in : id_frame_t;
                    op : instr_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => 
            case state.t is
            when t4 =>
                f.cw.rf_addr := regA;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := mem_rd_instr(state, f); -- overlap
            case state.t is
            when t2 =>
                f.cw.alu_op := op;
                f.cw.dbus_src := alu_o;
                f.cw.f_rd := '1';
                f.cw.rf_addr := regA;
                f.cw.rf_rdd := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_af;

    function bit_r(state : state_t; f_in : id_frame_t;
                   op : instr_t; bs : integer range 0 to 7;
                   reg : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is 
        when m2 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := reg;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd_instr(state, f); -- overlap
            case state.t is
            when t2 =>
                f.cw.alu_op := op;
                f.cw.alu_bs := bs;
                f.cw.dbus_src := alu_o;
                f.cw.f_rd := '1';
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end bit_r;

    function rld_rrd(state : state_t; f_in : id_frame_t;
                     op1 : instr_t; op2 : instr_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m2 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regHL;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.tmp_rd := '1';
                f.cw.act_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 =>
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.alu_op := op1;
                f.cw.dbus_src := alu_o;
                f.cw.data_rdo := '1';
                f.cw.rf_addr := regHL;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.alu_op := op2;
                f.cw.dbus_src := alu_o;
                f.cw.rf_addr := regA;  
                f.cw.rf_rdd := '1';
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end rld_rrd;

    function inc_dec_rp(state : state_t; f_in : id_frame_t;
                        op : addr_op_t; reg : integer range 0 to 15)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is 
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := reg;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := op;
                f.cw.rf_rda := '1';
            when t5 =>
            when t6 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end inc_dec_rp;

    function ld_r_r(state : state_t; f_in : id_frame_t;
                    src, dst : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := src;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
            when t5 =>
                f.cw.rf_addr := dst;
                f.cw.dbus_src := tmp_o;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_r_r;

    function ld_r_n(state : state_t; f_in : id_frame_t;
                   reg : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_r_n;

    function ld_r_hlx(state : state_t; f_in : id_frame_t;
                      reg : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => 
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regHL;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_r_hlx;

    function ld_rp_nn(state : state_t; f_in : id_frame_t;
                      reg : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := reg + 1; -- store to low byte
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := reg; -- store to high byte
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_rp_nn;

    function ld_sp_hl(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := regHL;
                f.cw.abus_src := rf_o;
                f.cw.tmpa_rd := '1';
            when t5 =>
                f.cw.abus_src := tmpa_o;
                f.cw.addr_op := none;
                f.cw.rf_addr := regSP;
                f.cw.rf_rda := '1';
            when t6 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_sp_hl;

    function ld_rpx_r(state : state_t; f_in : id_frame_t;
                      rp : integer range 0 to 15; r : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := r;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';   -- store reg in data buffer
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := rp;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_rpx_r;

    function ld_nnx_a(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regW;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 =>
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_addr := regA;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_nnx_a;

    function ld_nnx_hl(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regW;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 =>
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_addr := regL;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 => -- increment WZ
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := rf_o;
                f.cw.rf_rda := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m5 =>
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_addr := regH;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_nnx_hl;

    function in_c(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m2 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := io_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regBC;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.tmp_rd := '1';
            when t4 =>
                f.cw.f_rd := '1';
                f.cw.alu_op := in_i;
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end in_c;

    function in_r_c(state : state_t; f_in : id_frame_t;
                    reg : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        f := in_c(state, f);
        case state.m is
        when m3 =>
            case state.t is
            when t3 =>
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end in_r_c;

    function out_n_a(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 => f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := io_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_addr := regA;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t4 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end out_n_a;

    function push_rp2(state : state_t; f_in : id_frame_t;
                      reg : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 => -- dec SP
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- write high
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
            when t2 =>
                f.cw.rf_addr := reg;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- write low
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
            when t2 =>
                f.cw.rf_addr := reg+1;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end push_rp2;

    function halt(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 => 
                f.ct.mode_next := halt;
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end halt;

    type rp_table_t is array(0 to 3) of integer range 0 to 15;
    type alu_table_t is array(0 to 7) of instr_t;
    constant rp  : rp_table_t := (regBC, regDE, regHL, regSP);
    constant rp2 : rp_table_t := (regBC, regDE, regHL, regAF);
    constant alu : alu_table_t := (add_i, adc_i, sub_i, sbc_i,
                                   and_i, xor_i, or_i, cp_i);
    constant rot : alu_table_t := (rlc_i, rrc_i, rl_i, rr_i,
                                   sla_i, sra_i, sll_i, srl_i);
    constant afi : alu_table_t := (rlc_i, rrc_i, rl_i, rr_i,
                                   daa_i, cpl_i, scf_i, ccf_i);
    --     | p | |q|
    -- |1 0|0 0| |0|1 1 1|
    -- | x |   y   |  z  |
    type id_split_t is record
        x, p : integer range 0 to 3;
        y, z : integer range 0 to 7;
        q : integer range 0 to 1;
    end record;
begin
    process(state, instr)
        variable s : id_split_t;
        variable f : id_frame_t;
    begin
        -- split for instruction
        s.x := to_integer(unsigned(instr(7 downto 6)));
        s.y := to_integer(unsigned(instr(5 downto 3)));
        s.z := to_integer(unsigned(instr(2 downto 0)));
        s.p := to_integer(unsigned(instr(5 downto 4)));
        if instr(3) = '1' then s.q := 1; else s.q := 0; end if;

        -- set all signals to defaults (overwrite below)
        f.ct := (mode_next => state.mode, others => '0');
        f.cb := (others => '0');
        f.cw := (dbus_src => none,
                 abus_src => none,
                 rf_addr => 0,
                 rf_swp => none,
                 alu_op => unknown,
                 alu_bs => 0,
                 addr_op => inc,
                 others => '0');

        -- fetch phase
        if state.m = m1 then
            f.cb.m1 := '1';
            if state.mode /= halt then
                f := mem_rd_instr(state, f);
            end if;
        end if;

        -- exec phase
        case state.mode is
        when main =>
            case s.x is
            when 0 =>
                case s.z is
                when 0 =>
                    case s.y is
                    when 0 => f := nop(state, f);
                    when 1 => f := ex(state, f, af);
                    when 2 => f := nop(state, f); -- TODO DJNZ d
                    when 3 => f := jr_d(state, f);
                    when 4|5|6|7 => f := jr_cc_d(state, f, s.y-4);
                    end case;
                when 1 =>
                    case s.q is
                    when 0 => f := ld_rp_nn(state, f, rp(s.p));
                    when 1 => f := nop(state, f); -- TODO ADD hl, rp[p]
                    end case;
                when 2 =>
                    case s.q is
                    when 0 => 
                        case s.p is
                        when 0 => f := ld_rpx_r(state, f, regBC, regA);
                        when 1 => f := ld_rpx_r(state, f, regDE, regA);
                        when 2 => f := ld_nnx_hl(state, f);
                        when 3 => f := ld_nnx_a(state, f);
                        end case;
                    when 1 => 
                        case s.p is
                        when 0 => f := nop(state, f); -- TODO LD A, (BC)
                        when 1 => f := nop(state, f); -- TODO LD A, (DE)
                        when 2 => f := nop(state, f); -- TODO LD HL, (nn)
                        when 3 => f := nop(state, f); -- TODO LD A, (nn)
                        end case;
                    end case;
                when 3 =>
                    case s.q is
                    when 0 => f := inc_dec_rp(state, f, inc, rp(s.p));
                    when 1 => f := inc_dec_rp(state, f, dec, rp(s.p));
                    end case;
                when 4 => f := alu_r(state, f, inc_i, s.y);
                when 5 => f := alu_r(state, f, dec_i, s.y);
                when 6 => f := ld_r_n(state, f, s.y);
                when 7 => f := alu_af(state, f, afi(s.y));
                end case;
            when 1 =>
                case s.z is
                when 6 =>
                    case s.y is
                    when 6 =>
                        case s.z is
                        when 6 => f := halt(state, f);
                        when others => f := ld_rpx_r(state, f, regHL, s.z);
                        end case;
                    when others => f := ld_r_hlx(state, f, s.y);
                    end case;
                when others => f := ld_r_r(state, f, s.z, s.y);
                end case;
            when 2 => 
                case s.z is
                when 6 => null; -- TODO alu[y] (hl)
                when others => f := alu_a_r(state, f, alu(s.y), s.z);
                end case;
            when 3 =>
                case s.z is
                when 0 => f := nop(state, f); -- TODO RET cc[y]
                when 1 =>
                    case s.q is
                    when 0 => f := nop(state, f); -- TODO POP rp2[p]
                    when 1 =>
                        case s.p is
                        when 0 => f := nop(state, f); -- TODO RET
                        when 1 => f := ex(state, f, reg);
                        when 2 => f := jp_hl(state, f);
                        when 3 => f := ld_sp_hl(state, f);
                        end case;
                    end case;
                when 2 => f := jp_cc_nn(state, f, s.y);
                when 3 =>
                    case s.y is
                    when 0 => f := jp_nn(state, f);
                    when 1 => f := mem_rd_multi(state, f, cb);
                    when 2 => f := out_n_a(state, f); -- TODO OUT (n), A
                    when 3 => f := nop(state, f); -- TODO IN A, (n)
                    when 4 => f := nop(state, f); -- TODO EX (SP), HL
                    when 5 => f := ex(state, f, dehl);
                    when 6 => f := nop(state, f); -- TODO DI
                    when 7 => f := nop(state, f); -- TODO EI
                    end case;
                when 4 => f := nop(state, f); -- TODO CALL cc[y], nn
                when 5 =>
                    case s.q is
                    when 0 => f := push_rp2(state, f, rp2(s.p));
                    when 1 =>
                        case s.p is
                        when 0 => f := nop(state, f); -- TODO CALL nn
                        when 1 => f := mem_rd_multi(state, f, dd);
                        when 2 => f := mem_rd_multi(state, f, ed);
                        when 3 => f := mem_rd_multi(state, f, fd);
                        end case;
                    end case;
                when 6 => f := alu_a_n(state, f, alu(s.y));
                when 7 => f := nop(state, f); -- TODO RST y*8
                end case;
            end case;
        when ed =>
            case s.x is 
            when 1 =>
                case s.z is
                when 0 =>
                    case s.y is
                    when 6 => f := in_c(state, f);
                    when others => f := in_r_c(state, f, s.y);
                    end case;
                when 1 =>
                    case s.y is
                    when 6 => f := nop(state, f); -- TODO OUT (C), 0
                    when others => f := nop(state, f); -- TODO OUT r[y], (C)
                    end case;
                when 2 =>
                    case s.q is
                    when 0 => f := nop(state, f); -- TODO SBC HL, rp[p]
                    when 1 => f := nop(state, f); -- TODO ADC HL, rp[p]
                    end case;
                when 3 =>
                    case s.q is
                    when 0 => f := nop(state, f); -- TODO LD (nn), rp[p]
                    when 1 => f := nop(state, f); -- TODO LD rp[p], (nn)
                    end case;
                when 4 => f := alu_af(state, f, neg_i);
                when 5 =>
                    case s.y is
                    when 1 => f := nop(state, f); -- TODO RETI
                    when others => f := nop(state, f); -- TODO RETN
                    end case;
                when 6 => f := nop(state, f); -- TODO IM im[y]
                when 7 =>
                    case s.y is
                    when 0 => f := nop(state, f); -- TODO LD I, A
                    when 1 => f := nop(state, f); -- TODO LD R, A
                    when 2 => f := nop(state, f); -- TODO LD A, I
                    when 3 => f := nop(state, f); -- TODO LD A, R
                    when 4 => f := nop(state, f); -- TODO RRD
                    when 5 => f := nop(state, f); -- TODO RLD
                    when 6|7 => f := nop(state, f);
                    end case;
                end case;
            when 2 =>
                case s.y is
                when 4|5|6|7 => f := nop(state, f); -- TODO bli[y,z]
                when others => f := nop(state, f); -- NONI
                end case;
            when 0|3 => f := nop(state, f); end case; -- NONI
        when cb =>
            case s.x is
            when 0 => f := bit_r(state, f, rot(s.y), 0, s.z);
            when 1 => f := bit_r(state, f, bit_i, s.y, s.z);
            when 2 => f := bit_r(state, f, res_i, s.y, s.z);
            when 3 => f := bit_r(state, f, set_i, s.y, s.z);
            end case;
        when ddcb|fdcb =>
            case s.x is
            when 0 =>
                case s.z is
                when 6 => f := nop(state, f); -- TODO rot[y] (IX/Y+d)
                when others => f := nop(state, f); -- TODO LD r[z], rot[y] (IX/Y+d)
                end case;
            when 1 => f := nop(state, f); -- TODO BIT y, (IX/Y+d)
            when 2 =>
                case s.z is
                when 6 => f := nop(state, f); -- TODO res y, (IX/Y+d)
                when others => f := nop(state, f); -- TODO LD r[z], res y, (IX/Y+d)
                end case;
            when 3 =>
                case s.z is
                when 6 => f := nop(state, f); -- TODO set y, (IX/Y+d)
                when others => f := nop(state, f); -- TODO LD r[z], set y, (IX/Y+d)
                end case;
            end case;
        when dd|fd => f := nop(state, f); -- TODO
        when wz => null;
        when halt => f := nop(state, f);
        when int => null;
        end case;

        cw <= f.cw;
        cbo <= f.cb;
        ctrl <= f.ct;
    end process;
 end arch;
