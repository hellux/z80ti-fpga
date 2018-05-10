library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.cmp_comm.all;
use work.util.all;

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

    -- CYCLES --

    function int_rd(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.t is
        when t1 =>
            f.cb.iorq := '1';
        when t2 =>
            f.cw.data_rdi := '1';
            f.cb.iorq := '1';
        when t3 =>
            f.cw.dbus_src := ext_o;
        when others => null; end case;
        return f;
    end int_rd;

    function io_rd(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.t is
        when t1 =>
            f.cw.addr_rd := '1';    -- read from abus to buffer
            f.cb.iorq := '1';
        when t2 =>
            f.cw.data_rdi := '1';   -- store instr to data buf
            f.cb.iorq := '1';       -- keep request until byte retrieved
            f.cb.rd := '1';         -- read
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
            f.cb.iorq := '1';
        when t2 =>
        when t3 =>
            f.cb.iorq := '1';       -- signal addr ready on bus
            f.cb.wr := '1';         -- signal write
            f.cw.data_wro := '1';   -- send data
        when others => null; end case;
        return f;
    end io_wr;

    function mem_rd(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.t is
        when t1 =>
            f.cw.addr_rd := '1';    -- read from abus to buffer
        when t2 =>
            f.cw.data_rdi := '1';   -- store instr to data buf
            f.cb.mreq := '1';       -- signal addr ready on bus
            f.cb.rd := '1';         -- read
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
            f.cw.addr_rd := '1';    -- read from abus to buffer
        when t2 =>
            f.cb.mreq := '1';       -- signal addr is ready on abus
        when t3 =>
            f.cb.mreq := '1';
            f.cb.wr := '1';         -- write byte to mem
            f.cw.data_wro := '1';   -- send data
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
            f.cw.addr_op := inc;
            f.cw.pc_rd := '1';
        when others => null; end case;
        return f;
    end mem_rd_pc;

    function mem_rd_instr(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        f := mem_rd(state, f);
        f.cb.m1 := '1'; -- notify external of pc/instr rd
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
                f.ct.mode_next := exec; -- go back to exec mode
            else 
                f.cw.abus_src := pc_o; -- keep pc on abus
            end if;
            f.cw.addr_op := inc;
            f.cw.pc_rd := '1';      -- read incremented address to pc
        when t3 =>
            f.cw.ir_rd := '1';      -- read instr from dbus to ir
        when others => null; end case;
        return f;
    end mem_rd_instr;

    function mem_rd_multi(state : state_t; f_in : id_frame_t;
                          prefix : id_prefix_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        f := mem_rd_instr(state, f);
        case state.t is
        when t3 =>
            f.ct.prefix_next := prefix;
            f.ct.instr_end := '1'; -- return to m1 / update prefix
        when t4 =>
            f.ct.cycle_end := '1';
        when others => null; end case;
        return f;
    end mem_rd_multi;

    function mem_rd_xy_d(state : state_t; f_in : id_frame_t;
                         prefix : id_prefix_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        f := mem_rd_pc(state, f);
        f.cb.m1 := '1';
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            case state.t is
            when t3 =>
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd_instr(state, f);
            case state.t is
            when t3 =>
                f.ct.prefix_next := prefix;
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end mem_rd_xy_d;

    -- INSTRUCTIONS --

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

    function noni(state : state_t; f_in : id_frame_t;
                  instr : std_logic_vector(7 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        report "NONI: " & " (" & vec_str(instr) & ")";
        f := f_in;
        case state.t is
        when t4 =>
            f.ct.cycle_end := '1';
            f.ct.instr_end := '1';
        when others => null; end case;
        return f;
    end noni;

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
                f.cw.rf_rdd := '1';
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

    function jp_rp(state : state_t; f_in : id_frame_t;
                   reg : integer range 0 to 15)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := reg; -- place rp on abus
                f.cw.abus_src := rf_o;
                f.cw.addr_op := none; -- no inc to addr
                f.cw.pc_rd := '1'; -- store addr in pc
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => end case;
        when others => end case;
        return f;
    end jp_rp;

    function jr_d(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- load displacement to tmp, pc->wz
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.abus_src := pc_o;
            when t3 =>
                f.cw.tmp_rd := '1';
                f.cw.abus_src := pc_o;
                f.cw.rf_addr := regWZ;
                f.cw.addr_op := none;
                f.cw.rf_rda := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- wz+d+1->pc
            case state.t is
            when t1 =>
                f.cw.dbus_src := tmp_o;
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := dis_o;
                f.cw.addr_op := inc;
                f.cw.pc_rd := '1';
            when t2 =>
            when t3 =>
            when t4 =>
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
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 => 
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd_instr(state, f); -- fetch next instr simultaneously
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

    function alu_a_rpx(state : state_t; f_in : id_frame_t;
                       op : instr_t; reg : integer range 0 to 15)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => 
            case state.t is
            when t4 =>
                f.cw.act_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := reg;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
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
    end alu_a_rpx;

    function alu_rpx(state : state_t; f_in : id_frame_t;
                     op : instr_t; reg : integer range 0 to 15)
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
                f.cw.rf_addr := reg;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.tmp_rd := '1';
            when t4 =>
                f.cw.alu_op := op;
                f.cw.dbus_src := alu_o;
                f.cw.f_rd := '1';
                f.cw.data_rdo := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := reg;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_rpx;

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
    
    function alu_rp_rp(state : state_t; f_in : id_frame_t;
                       op1 : instr_t;
                       op2 : instr_t;
                       reg1 : integer range 0 to 15;
                       reg2 : integer range 0 to 15)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            case state.t is
            when t1 =>
                f.cw.rf_addr := reg1 + 1;
                f.cw.dbus_src := rf_o;
                f.cw.act_rd_dbus := '1';
            when t2 =>
                f.cw.rf_addr := reg2 + 1;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';     
            when t4 =>
                f.cw.alu_op := op1;
                f.cw.dbus_src := alu_o;
                f.cw.rf_addr := reg1 + 1;
                f.cw.rf_rdd := '1';
                f.cw.f_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            case state.t is
            when t1 =>
                f.cw.rf_addr := reg1;
                f.cw.dbus_src := rf_o;
                f.cw.act_rd_dbus := '1';
            when t2 =>
                f.cw.rf_addr := reg2;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';     
            when t3 =>
                f.cw.alu_op := op2;
                f.cw.dbus_src := alu_o;
                f.cw.rf_addr := reg1;
                f.cw.rf_rdd := '1';
                f.cw.f_rd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_rp_rp;

    function bit_r(state : state_t; f_in : id_frame_t;
                   op : instr_t; bs : integer range 0 to 7;
                   reg : integer range 0 to 7)
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

    function bit_xy_d(state : state_t; f_in : id_frame_t;
                      op : instr_t; bs : integer range 0 to 7;
                      reg : integer range 0 to 15)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => -- store displaced addr to tmpa
            case state.t is
            when t4 =>
                f.cw.rf_addr := reg;
                f.cw.dbus_src := tmp_o; -- tmp holds d
                f.cw.abus_src := dis_o;
                f.cw.addr_op := none;
                f.cw.tmpa_rd := '1';
            when t5 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- fetch byte to tmp, located at displaced addr
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.abus_src := tmpa_o;
            when t3 =>
                f.cw.tmp_rd := '1';
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- perform bit op, write res to mem
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.abus_src := tmpa_o;
                f.cw.alu_op := op;
                f.cw.alu_bs := bs;
                f.cw.dbus_src := alu_o;
                f.cw.rf_addr := regW;
                f.cw.rf_rdd := '1';
                f.cw.f_rd := '1';
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end bit_xy_d;
    
    function rld_rrd(state : state_t; f_in : id_frame_t;
                     op1 : instr_t; op2 : instr_t)
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
                f.cw.tmp_rd := '1';
                f.cw.act_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
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
                f.ct.instr_end := '1';
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
    
    function bli_op(state : state_t; f_in : id_frame_t;
                    op : instr_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            case op is
            when ldi_i|cpi_i|ldd_i|cpd_i|outi_i|outd_i|
                 ldir_i|lddr_i|cpir_i|cpdr_i|otir_i|otdr_i => 
                f := mem_rd(state, f);
            when ini_i|ind_i|inir_i|indr_i =>
                f := io_rd(state, f);
            when others => null; end case;
     
            case state.t is
            when t1 =>
                case op is
                when ldi_i|ldd_i|cpi_i|cpd_i|outi_i|outd_i|
                     ldir_i|lddr_i|cpir_i|cpdr_i|otir_i|otdr_i => 
                    -- Load (HL)
                    f.cw.rf_addr := regHL;
                    f.cw.abus_src := rf_o;
                when ini_i|ind_i|inir_i|indr_i =>
                    f.cw.rf_addr := regBC;
                    f.cw.abus_src := rf_o;
                when others => null; end case;
            when t3 =>
                case op is
                when ldi_i|ldd_i|ini_i|ind_i|outi_i|outd_i|
                     ldir_i|lddr_i|inir_i|indr_i|otir_i|otdr_i => 
                    f.cw.rf_addr := regZ;
                    f.cw.rf_rdd := '1';
                when cpi_i|cpd_i|cpir_i|cpdr_i  => 
                    f.cw.tmp_rd := '1';
                    f.cw.act_rd := '1';
                when others => null; end case;
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            case op is
            when ldi_i|cpi_i|ldd_i|cpd_i|ini_i|ind_i|
                 ldir_i|cpir_i|lddr_i|cpdr_i|inir_i|indr_i =>
                f := mem_wr(state, f);
            when outi_i|outd_i|otir_i|otdr_i =>
                f := io_wr(state, f);
            when others => null; end case;
            
            case state.t is
            when t1 =>
                case op is
                when ldi_i|ldd_i|ldir_i|lddr_i => 
                    -- Store Z to (DE)
                    f.cw.rf_addr := regDE;
                    f.cw.abus_src := rf_o;
                when cpi_i|cpd_i|cpir_i|cpdr_i =>
                    f.cw.alu_op := cpi_i;
                    f.cw.dbus_src := alu_o;
                    f.cw.f_rd := '1';
                when ini_i|ind_i|inir_i|indr_i =>
                    f.cw.rf_addr := regHL;
                    f.cw.abus_src := rf_o;
                when outi_i|outd_i|otir_i|otdr_i => 
                    f.cw.rf_addr := regBC;
                    f.cw.abus_src := rf_o;
                when others => null; end case;
            when t2 =>
                case op is
                when ldi_i|ldd_i|ini_i|ind_i|outi_i|outd_i|
                     ldir_i|lddr_i|inir_i|indr_i|otir_i|otdr_i => 
                    f.cw.rf_addr := regZ;
                    f.cw.dbus_src := rf_o;
                    f.cw.data_rdo := '1';    
                when others => null; end case;
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 =>
            case state.t is
            when t1 =>
                -- inc HL
                f.cw.rf_addr := regHL;
                f.cw.abus_src := rf_o;
                case op is
                when ldi_i|cpi_i|ini_i|outi_i|ldir_i|cpir_i|inir_i|otir_i =>
                    f.cw.addr_op := inc;
                when ldd_i|cpd_i|ind_i|outd_i|lddr_i|cpdr_i|indr_i|otdr_i =>
                    f.cw.addr_op := dec;
                when others =>
                    f.cw.addr_op := none;
                end case;
                f.cw.pv_src := anz_f;
                f.cw.rf_rda := '1';
            when t2 =>
                -- inc DE
                f.cw.rf_addr := regDE;
                f.cw.abus_src := rf_o;
                case op is
                when ldi_i|ldir_i =>
                    f.cw.addr_op := inc;
                when ldd_i|lddr_i =>
                    f.cw.addr_op := dec;
                when others =>
                    f.cw.addr_op := none;
                end case;
                f.cw.pv_src := anz_f;
                f.cw.rf_rda := '1';
            when t3 =>
                f.cw.rf_addr := regBC;
                f.cw.abus_src := rf_o;
                case op is
                when cpi_i|cpd_i|cpir_i|cpdr_i =>
                    -- dec BC
                    f.cw.addr_op := dec;
                    f.cw.pv_src := anz_f; --addr not zero flag
                    f.cw.fi_rd := '1';
                when ldi_i|ldd_i|ldir_i|lddr_i =>
                    -- dec BC
                    f.cw.addr_op := dec;
                    f.cw.pv_src := anz_f; --addr not zero flag
                    f.cw.f_rd := '1';
                when ini_i|outi_i|ind_i|outd_i|inir_i|otir_i|indr_i|otdr_i =>
                    --ld b => tmp
                    f.cw.addr_op := none;
                    f.cw.rf_addr := regB;
                    f.cw.dbus_src := rf_o;
                    f.cw.tmp_rd := '1';
                when others =>
                    f.cw.addr_op := none;
                end case;
                f.cw.rf_rda := '1';
            when t4 =>
                case op is -- dec B
                when ini_i|outi_i|ind_i|outd_i|inir_i|otir_i|indr_i|otdr_i =>
                    f.cw.alu_op := dec_i;
                    f.cw.dbus_src := alu_o;
                    f.cw.rf_addr := regB;
                    f.cw.rf_rdd := '1';
                    f.cw.f_rd := '1';
                when others => null; end case; 
            when t5 =>
                case op is
                when ldi_i|ldd_i|cpi_i|cpd_i|ini_i|ind_i|outi_i|outd_i =>
                    f.ct.instr_end := '1';
                when ldir_i|lddr_i|cpir_i|cpdr_i =>
                    if state.cc(PO_c) then
                        f.ct.instr_end := '1';
                    end if;
                when inir_i|indr_i|otir_i|otdr_i =>
                    if state.cc(Z_c) then
                        f.ct.instr_end := '1';
                    end if;
                when others => null; end case;
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m5 =>
            case state.t is
            when t1 =>
                f.cw.pc_rd := '1';
                f.cw.abus_src := pc_o;
                f.cw.addr_op := dec;
            when t2 =>
                f.cw.pc_rd := '1';
                f.cw.abus_src := pc_o;
                f.cw.addr_op := dec;
            when t3 =>
                f.cw.addr_op := none;
            when t4 =>
                f.cw.alu_op := op;
                f.cw.f_rd := '1'; 
            when t5 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end bli_op;

    function ld_i_a(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := regA;
                f.cw.dbus_src := rf_o;
                f.cw.i_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            case state.t is
            when t5 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_i_a;

    function ld_r_a(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := regA;
                f.cw.dbus_src := rf_o;
                f.cw.r_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            case state.t is
            when t5 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_r_a;

    function ld_a_i_r(state : state_t; f_in : id_frame_t;
                      src : dbus_src_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.dbus_src := src;
                f.cw.rf_addr := regA;
                f.cw.rf_rdd := '1';
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            case state.t is
            when t1 =>
                f.cw.alu_op := ld_i;
                f.cw.f_rd := '1';
                f.cw.pv_src := iff_f; -- use iff2 as pv
            when t5 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_a_i_r;

    function ld_r_r(state : state_t; f_in : id_frame_t;
                    dst, src : integer range 0 to 7)
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

    function ld_r_rpx(state : state_t; f_in : id_frame_t;
                      reg : integer range 0 to 7; rp : integer range 0 to 15)
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
                f.cw.rf_addr := rp;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_r_rpx;

    function ld_rp_nn(state : state_t; f_in : id_frame_t;
                      reg : integer range 0 to 15)
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

    function ld_r_nnx(state : state_t; f_in : id_frame_t;
                      reg : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- b1 -> z
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- b2 -> w
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regW;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 => -- (wz) -> r
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_r_nnx;

    function ld_rp_nnx(state : state_t; f_in : id_frame_t;
                       reg : integer range 0 to 15)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- b1 -> z
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- b2 -> w
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regW;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 => -- (wz++) -> rpl
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
                f.cw.rf_rda := '1';
            when t3 =>
                f.cw.rf_addr := reg+1;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m5 => -- (wz) -> rph
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_rp_nnx;

    function ld_sp_rp(state : state_t; f_in : id_frame_t;
                      reg : integer range 0 to 15)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_addr := reg;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := none;
                f.cw.tmpa_rd := '1';
            when t5 =>
                f.cw.abus_src := tmpa_o;
                f.cw.rf_addr := regSP;
                f.cw.addr_op := none;
                f.cw.rf_rda := '1';
            when t6 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_sp_rp;

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

    function ld_rpx_n(state : state_t; f_in : id_frame_t;
                      rp : integer range 0 to 15)
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
                f.cw.data_rdo := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
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
    end ld_rpx_n;

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

    function ld_nnx_rp(state : state_t; f_in : id_frame_t;
                       reg : integer range 0 to 15)
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
                f.cw.rf_addr := reg+1;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 => -- increment WZ
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
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
                f.cw.rf_addr := reg;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_nnx_rp;
    
    function ld_r_xy_d(state : state_t; f_in : id_frame_t; 
                        r : integer range 0 to 7;
                        rp : integer range 0 to 15)
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
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.dbus_src := tmp_o; 
                f.cw.rf_addr := rp;
                f.cw.abus_src := dis_o;
            when t3 =>
                f.cw.rf_addr := r;
                f.cw.rf_rdd := '1';
            when t5 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 =>
            case state.t is
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_r_xy_d;
    
    function ld_xy_d_r(state : state_t; f_in : id_frame_t; 
                        rp : integer range 0 to 15;
                        r : integer range 0 to 7)
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
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_wr(state, f);
            case state.t is
            when t1 =>   
                f.cw.dbus_src := tmp_o;
                f.cw.rf_addr := rp;
                f.cw.abus_src := dis_o; 
            when t2 =>
                f.cw.rf_addr := r;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t5 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 =>
            case state.t is
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_xy_d_r;
    
    function ld_xy_d_n(state : state_t; f_in : id_frame_t; 
                        rp : integer range 0 to 15)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            --Fetch displacement
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            --Fetch N
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regZ;
                f.cw.rf_rdd := '1';
            when t5 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 =>
            --Write N to IXY + d
            f := mem_wr(state, f);
            case state.t is
            when t1 =>   
                f.cw.dbus_src := tmp_o;
                f.cw.rf_addr := rp;
                f.cw.abus_src := dis_o; 
            when t2 =>
                f.cw.rf_addr := regZ;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_xy_d_n;
    
    function inc_dec_xy_d(state : state_t; f_in : id_frame_t;
                        op : instr_t; rp : integer range 0 to 15)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            --Fetch displacement
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regZ;
                f.cw.rf_rdd := '1';
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                --Fetch value of (ix/y + d)
                f.cw.dbus_src := tmp_o; 
                f.cw.rf_addr := rp;
                f.cw.abus_src := dis_o;
            when t3 =>
                f.cw.tmp_rd := '1';
            when t4 =>
                --Perform inc/dec
                f.cw.alu_op := op;
                f.cw.dbus_src := alu_o;
                f.cw.rf_addr := regW;
                f.cw.rf_rdd := '1';
                f.cw.f_rd := '1';
            when t5 =>
                --Move displacement Z => tmp
                f.cw.rf_addr := regZ;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 =>
            --Write N to IXY + d
            f := mem_wr(state, f);
            case state.t is
            when t1 =>   
                f.cw.dbus_src := tmp_o;
                f.cw.rf_addr := rp;
                f.cw.abus_src := dis_o; 
            when t2 =>
                f.cw.rf_addr := regW;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when t5 =>
            case state.t is
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end inc_dec_xy_d;

    
    function alu_a_xy_d(state : state_t; f_in : id_frame_t; 
                        op : instr_t;
                        rp : integer range 0 to 15)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            --Fetch displacement
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                --Fetch value of (IX/y+d)
                f.cw.dbus_src := tmp_o; 
                f.cw.rf_addr := rp;
                f.cw.abus_src := dis_o;
            when t3 =>
                f.cw.tmp_rd := '1';
                f.cw.act_rd := '1';
            when t4 =>
                f.cw.alu_op := op;
                f.cw.dbus_src := alu_o;
                f.cw.rf_addr := regA;
                f.cw.rf_rdd := '1';
                f.cw.f_rd := '1';
            when t5 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 =>
            case state.t is
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_a_xy_d;

    function ex_spx_rp(state : state_t; f_in : id_frame_t;
                       reg : integer range 0 to 15)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 => -- L -> dbufo
                f.cw.rf_addr := reg+1;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- (SP) --> L
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.rf_addr := reg+1;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- dbufo -> (SP), SP+1 -> tmpa, H -> dbufo
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
                f.cw.tmpa_rd := '1';
            when t4 =>
                f.cw.rf_addr := reg;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 => -- (tmpa) -> H
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.abus_src := tmpa_o;
            when t3 =>
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m5 => -- tmp -> (tmpa)
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.abus_src := tmpa_o;
            when t5 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ex_spx_rp;

    function in_c(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := io_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regBC;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.tmp_rd := '1';
            when t4 =>
                f.cw.alu_op := in_i;
                f.cw.f_rd := '1';
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
        when m2 =>
            case state.t is
            when t3 =>
                f.cw.rf_addr := reg;
                f.cw.rf_rdd := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end in_r_c;

    function in_a_n(state : state_t; f_in : id_frame_t)
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
            f := io_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.rf_addr := regA;
                f.cw.rf_rdd := '1';
                f.cw.tmp_rd := '1';
            when t4 =>
                f.cw.alu_op := in_i;
                f.cw.f_rd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end in_a_n;

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

    function out_c_r(state : state_t; f_in : id_frame_t;
                     reg : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 => f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := io_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regBC;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_addr := reg;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t4 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end out_c_r;

    function out_c_0(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 => f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := io_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regBC;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.dbus_src := zero_o;
                f.cw.data_rdo := '1';
            when t4 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end out_c_0;

    function push_rp(state : state_t; f_in : id_frame_t;
                      reg : integer range 0 to 15)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => -- dec sp
            case state.t is
            when t4 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t5 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- write high, dec sp
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t2 =>
                if reg = regAF then -- special, does not match pattern
                    f.cw.rf_addr := regA;
                else
                    f.cw.rf_addr := reg;
                end if;
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
            when t2 =>
                if reg = regAF then
                    f.cw.rf_addr := regF;
                else
                    f.cw.rf_addr := reg+1;
                end if;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end push_rp;

    function pop_rp(state : state_t; f_in : id_frame_t;
                    reg : integer range 0 to 15)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- read low, inc sp
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
                f.cw.rf_rda := '1';
            when t3 =>
                if reg = regAF then
                    f.cw.rf_addr := regF;
                else
                    f.cw.rf_addr := reg+1;
                end if;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- read high, inc sp
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
                f.cw.rf_rda := '1';
            when t3 =>
                if reg = regAF then
                    f.cw.rf_addr := regA;
                else
                    f.cw.rf_addr := reg;
                end if;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end pop_rp;

    function call_nn(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => 
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- fetch low to z
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- fetch high to w
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_addr := regW;
                f.cw.rf_rdd := '1';
            when t4 => -- dec sp
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 => -- pch -> (sph--)
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t2 =>
                f.cw.dbus_src := pch_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m5 => -- pcl -> (sph--)
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.dbus_src := pcl_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.mode_next := wz;
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end call_nn;

    function call_cc_nn(state : state_t; f_in : id_frame_t;
                        cond : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.cc(cond) is
        when true => f := call_nn(state, f);
        when false =>
            case state.m is
            when m1 =>
                case state.t is
                when t4 =>
                    f.ct.cycle_end := '1';
                when others => null; end case;
            when m2 => -- inc pc
                f := mem_rd_pc(state, f);
                case state.t is
                when t3 =>
                    f.ct.cycle_end := '1';
                when others => null; end case;
            when m3 => -- inc pc
                f := mem_rd_pc(state, f);
                case state.t is
                when t3 =>
                    f.ct.cycle_end := '1';
                    f.ct.instr_end := '1';
                when others => null; end case;
            when others => null; end case;
        end case;
        return f;
    end call_cc_nn;

    function rst(state : state_t; f_in : id_frame_t;
                 addr : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => -- dec sp
            case state.t is
            when t4 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t5 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- pch -> (sph--)
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t2 =>
                f.cw.dbus_src := pch_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- pcl -> (sph--), rst_addr -> wz
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.dbus_src := pcl_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.cw.abus_src := rst_o;
                f.cw.rst_addr := std_logic_vector(to_unsigned(addr, 3));
                f.cw.rf_addr := regWZ;
                f.cw.addr_op := none;
                f.cw.rf_rda := '1';
                f.ct.mode_next := wz;
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end rst;

    function ret(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        f := pop_rp(state, f, regWZ);
        case state.m is
        when m3 =>
            case state.t is
            when t3 =>
                f.ct.mode_next := wz; -- use wz instead of pc
            when others => null; end case;
        when others => null; end case;
        return f;
    end ret;

    function ret_cc(state : state_t; f_in : id_frame_t;
                    cond : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.cc(cond) is
        when true => f := ret(state, f);
        when false =>
            case state.m is
            when m1 =>
                case state.t is
                when t5 =>
                    f.ct.cycle_end := '1';
                    f.ct.instr_end := '1';
                when others => null; end case;
            when others => null; end case;
        end case;
        return f;
    end ret_cc;

    function djnz_d(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => -- decrement b
            case state.t is
            when t4 =>
                f.cw.rf_addr := regB;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
            when t5 =>
                f.cw.alu_op := dec_i;
                f.cw.dbus_src := alu_o;
                f.cw.fi_rd := '1'; -- read to internal flags only
                f.cw.rf_addr := regB;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- fetch d to tmp
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
                if state.cc(Z_c) then
                    f.ct.instr_end := '1';
                end if;
            when others => null; end case;
        when m3 => -- load pc+d to pc
            case state.t is
            when t1 => -- pc -> wz
                f.cw.abus_src := pc_o;
                f.cw.rf_addr := regWZ;
                f.cw.addr_op := none;
                f.cw.rf_rda := '1';
            when t2 => -- wz + d -> pc
                f.cw.rf_addr := regWZ;
                f.cw.dbus_src := tmp_o;
                f.cw.abus_src := dis_o;
                f.cw.addr_op := none;
                f.cw.pc_rd := '1';
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end djnz_d;

    function unimp(state : state_t; f_in : id_frame_t;
                   instr : std_logic_vector(7 downto 0); op : string)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        report "UNIMPLEMENTED INSTRUCTION: " & op
                & " (" & vec_str(instr) & ")";
        case state.t is
        when t4 => 
            f.ct.mode_next := halt;
            f.ct.cycle_end := '1';
            f.ct.instr_end := '1';
        when others => null; end case;
        return f;
    end unimp;

    function halt(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        f.cb.halt := '1';
        case state.t is
        when t4 => 
            f.ct.mode_next := halt;
            f.ct.cycle_end := '1';
            f.ct.instr_end := '1';
        when others => null; end case;
        return f;
    end halt;

    function si(state : state_t; f_in : id_frame_t;
                iff : std_logic)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.t is
        when t4 => 
            f.cw.iff_next := iff;
            f.ct.cycle_end := '1';
            f.ct.instr_end := '1';
        when others => null; end case;
        return f;
    end si;

    function set_im(state : state_t; f_in : id_frame_t;
                    mode : integer range 0 to 2)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.t is
        when t4 => 
            f.ct.im_next := mode;
            f.ct.cycle_end := '1';
            f.ct.instr_end := '1';
        when others => null; end case;
        return f;
    end set_im;

    function im1(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => -- dec sp, int ack
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
                f.cb.iorq := '1'; -- acknowledge interrupt
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- pch -> (sph--)
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t2 =>
                f.cw.dbus_src := pch_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- pcl -> (sph--), rst_addr -> pc
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.dbus_src := pcl_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.cw.abus_src := rst_o;
                f.cw.rst_addr := "111"; -- "111" << 3 = 0x38
                f.cw.addr_op := none;
                f.cw.pc_rd := '1';
                f.cw.iff_next := '0'; -- turn off interrupts
                f.ct.mode_next := exec;
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end im1;

    function im2(state : state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => -- dec SP, PC->WZ, data->tmp
            f := int_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t3 =>
                f.cw.tmp_rd := '1';
                f.cw.rf_addr := regWZ;
                f.cw.abus_src := pc_o;
                f.cw.addr_op := none;
                f.cw.rf_rda := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- write w to stack, dec SP
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t2 =>
                f.cw.rf_addr := regW;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- write z to stack
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_addr := regSP;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_addr := regZ;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 => -- i & tmp + 1 -> tmpa, (i & tmp) -> Z (lower byte)
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.dbus_src := tmp_o;
                f.cw.abus_src := int_o;
                f.cw.addr_op := inc;
                f.cw.tmpa_rd := '1';
            when t3 =>
                f.cw.rf_addr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m5 => -- (tmpa) -> W (upper byte)
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.abus_src := tmpa_o;
            when t3 =>
                f.cw.rf_addr := regW;
                f.cw.rf_rdd := '1';
                f.cw.iff_next := '0'; -- turn off interrupts
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
                f.ct.mode_next := wz;
            when others => null; end case;
        when others => null; end case;
            f := mem_rd(state, f);
        return f;
    end im2;

    type bli_row_t is array(0 to 3) of instr_t;
    type bli_table_t is array(4 to 7) of bli_row_t;
    type r_table_t is array(0 to 7) of integer range 0 to 15;
    type rp_table_t is array(0 to 3) of integer range 0 to 15;
    type alu_table_t is array(0 to 7) of instr_t;
    type xy_table_t is array(0 to 1) of integer range 0 to 15;
    type xyhl_table_t is array(0 to 1) of r_table_t;
    type im_table_t is array(0 to 7) of integer range 0 to 2;
    type prefix_table_t is array(0 to 1) of id_prefix_t;

    constant bli4 : bli_row_t := (ldi_i, cpi_i, ini_i, outi_i);
    constant bli5 : bli_row_t := (ldd_i, cpd_i, ind_i, outd_i);
    constant bli6 : bli_row_t := (ldir_i, cpir_i, inir_i, otir_i);
    constant bli7 : bli_row_t := (lddr_i, cpdr_i, indr_i, otdr_i);
    constant bli : bli_table_t := (bli4, bli5, bli6, bli7);
    constant rp  : rp_table_t := (regBC, regDE, regHL, regSP);
    constant rp2 : rp_table_t := (regBC, regDE, regHL, regAF);
    constant alu : alu_table_t := (add_i, adc_i, sub_i, sbc_i,
                                   and_i, xor_i, or_i, cp_i);
    constant rot : alu_table_t := (rlc_i, rrc_i, rl_i, rr_i,
                                   sla_i, sra_i, sll_i, srl_i);
    constant afi : alu_table_t := (rlca_i, rrca_i, rla_i, rra_i,
                                   daa_i, cpl_i, scf_i, ccf_i);
    constant im : im_table_t := (0, 1, 1, 2, 0, 1, 1, 2);
    constant rxy : xy_table_t := (regIX, regIY);
    constant rxhl : r_table_t := (regB, regC, regD, regE,
                                  regIXh, regIXl, regF, regA);
    constant ryhl : r_table_t := (regB, regC, regD, regE,
                                  regIYh, regIYl, regF, regA);
    constant rxyhl : xyhl_table_t := (rxhl, ryhl);
    constant pxy : prefix_table_t := (ddcb, fdcb);

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
        variable xy : integer range 0 to 1;
        variable f : id_frame_t;
    begin
        -- split for instruction
        s.x := to_integer(unsigned(instr(7 downto 6)));
        s.y := to_integer(unsigned(instr(5 downto 3)));
        s.z := to_integer(unsigned(instr(2 downto 0)));
        s.p := to_integer(unsigned(instr(5 downto 4)));
        if instr(3) = '1' then s.q := 1; else s.q := 0; end if;
        if state.prefix = fd or
           state.prefix = fdcb
        then
            xy := 1;
        else
            xy := 0;
        end if;

        -- set all signals to defaults (overwrite below)
        f.ct := (mode_next => state.mode,
                 im_next => state.im,
                 prefix_next => main,
                 others => '0');
        f.cb := (others => '0');
        f.cw := (dbus_src => none,
                 abus_src => none,
                 rst_addr => "000",
                 rf_addr => 0,
                 rf_swp => none,
                 alu_op => unknown,
                 alu_bs => 0,
                 addr_op => inc,
                 pv_src => alu_f,
                 iff_next => state.iff,
                 others => '0');

        if state.m = m1 then
            f.cb.m1 := '1';
        end if;

        if state.mode = int then
            case state.im is
            when 0 => f := unimp(state, f, instr, "im0");
            when 1 => f := im1(state, f);
            when 2 => f := im2(state, f);
            end case;
        else

        -- fetch phase
        if state.m = m1 and state.mode /= halt then
            f := mem_rd_instr(state, f);
        end if;

        case state.prefix is
        when main =>
            case s.x is
            when 0 =>
                case s.z is
                when 0 =>
                    case s.y is
                    when 0 => f := nop(state, f);
                    when 1 => f := ex(state, f, af);
                    when 2 => f := djnz_d(state, f);
                    when 3 => f := jr_d(state, f);
                    when 4|5|6|7 => f := jr_cc_d(state, f, s.y-4);
                    end case;
                when 1 =>
                    case s.q is
                    when 0 => f := ld_rp_nn(state, f, rp(s.p));
                    when 1 => f := alu_rp_rp(state, f, add16_i1, add16_i2,
                                             regHL, rp(s.p));
                    end case;
                when 2 =>
                    case s.q is
                    when 0 => 
                        case s.p is
                        when 0 => f := ld_rpx_r(state, f, regBC, regA);
                        when 1 => f := ld_rpx_r(state, f, regDE, regA);
                        when 2 => f := ld_nnx_rp(state, f, regHL);
                        when 3 => f := ld_nnx_a(state, f);
                        end case;
                    when 1 => 
                        case s.p is
                        when 0 => f := ld_r_rpx(state, f, regA, regBC);
                        when 1 => f := ld_r_rpx(state, f, regA, regDE);
                        when 2 => f := ld_rp_nnx(state, f, regHL);
                        when 3 => f := ld_r_nnx(state, f, regA);
                        end case;
                    end case;
                when 3 =>
                    case s.q is
                    when 0 => f := inc_dec_rp(state, f, inc, rp(s.p));
                    when 1 => f := inc_dec_rp(state, f, dec, rp(s.p));
                    end case;
                when 4 => 
                    case s.y is
                    when 6 => f := alu_rpx(state, f, inc_i, regHL);
                    when others => f := alu_r(state, f, inc_i, s.y);
                    end case;
                when 5 =>
                    case s.y is
                    when 6 => f := alu_rpx(state, f, dec_i, regHL);
                    when others => f := alu_r(state, f, dec_i, s.y);
                    end case;
                when 6 =>
                    case s.y is
                    when 6 => f := ld_rpx_n(state, f, regHL);
                    when others => f := ld_r_n(state, f, s.y);
                    end case;
                when 7 => f := alu_af(state, f, afi(s.y));
                end case;
            when 1 =>
                case s.z is
                when 6 =>
                    case s.y is
                    when 6 => f := halt(state, f);
                    when others => f := ld_r_rpx(state, f, s.y, regHL);
                    end case;
                when others =>
                    case s.y is
                    when 6 => f := ld_rpx_r(state, f, regHL, s.z);
                    when others => f := ld_r_r(state, f, s.y, s.z);
                    end case;
                end case;
            when 2 => 
                case s.z is
                when 6 => f := alu_a_rpx(state, f, alu(s.y), regHL);
                when others => f := alu_a_r(state, f, alu(s.y), s.z);
                end case;
            when 3 =>
                case s.z is
                when 0 => f := ret_cc(state, f, s.y);
                when 1 =>
                    case s.q is
                    when 0 => f := pop_rp(state, f, rp2(s.p));
                    when 1 =>
                        case s.p is
                        when 0 => f := ret(state, f);
                        when 1 => f := ex(state, f, reg);
                        when 2 => f := jp_rp(state, f, regHL);
                        when 3 => f := ld_sp_rp(state, f, regHL);
                        end case;
                    end case;
                when 2 => f := jp_cc_nn(state, f, s.y);
                when 3 =>
                    case s.y is
                    when 0 => f := jp_nn(state, f);
                    when 1 => f := mem_rd_multi(state, f, cb);
                    when 2 => f := out_n_a(state, f);
                    when 3 => f := in_a_n(state, f);
                    when 4 => f := ex_spx_rp(state, f, regHL);
                    when 5 => f := ex(state, f, dehl);
                    when 6 => f := si(state, f, '0');
                    when 7 => f := si(state, f, '1');
                    end case;
                when 4 => f := call_cc_nn(state, f, s.y);
                when 5 =>
                    case s.q is
                    when 0 => f := push_rp(state, f, rp2(s.p));
                    when 1 =>
                        case s.p is
                        when 0 => f := call_nn(state, f);
                        when 1 => f := mem_rd_multi(state, f, dd);
                        when 2 => f := mem_rd_multi(state, f, ed);
                        when 3 => f := mem_rd_multi(state, f, fd);
                        end case;
                    end case;
                when 6 => f := alu_a_n(state, f, alu(s.y));
                when 7 => f := rst(state, f, s.y);
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
                    when 6 => f := out_c_0(state, f);
                    when others => f := out_c_r(state, f, s.y);
                    end case;
                when 2 =>
                    case s.q is
                    when 0 => f :=
                        alu_rp_rp(state, f, sbc_i, sbc_i, regHL, rp(s.p));
                    when 1 => f :=
                        alu_rp_rp(state, f, adc_i, adc_i, regHL, rp(s.p));
                    end case;
                when 3 =>
                    case s.q is
                    when 0 => f := ld_nnx_rp(state, f, rp(s.p));
                    when 1 => f := ld_rp_nnx(state, f, rp(s.p));
                    end case;
                when 4 => f := alu_af(state, f, neg_i);
                when 5 =>
                    case s.y is
                    when 1 => f := ret(state, f); -- RETI int ack unused
                    when others => f := ret(state, f); -- RETN nmi not impl
                    end case;
                when 6 => f := set_im(state, f, im(s.y));
                when 7 =>
                    case s.y is
                    when 0 => f := ld_i_a(state, f);
                    when 1 => f := ld_r_a(state, f);
                    when 2 => f := ld_a_i_r(state, f, i_o);
                    when 3 => f := ld_a_i_r(state, f, r_o);
                    when 4 => f := rld_rrd(state, f, rrd_i1, rrd_i2);
                    when 5 => f := rld_rrd(state, f, rld_i1, rld_i2);
                    when 6|7 => f := noni(state, f, instr);
                    end case;
                end case;
            when 2 =>
                case s.y is
                when 4|5|6|7 => f := bli_op(state, f, bli(s.y)(s.z));
                when others => f := noni(state, f, instr);
                end case;
            when 0|3 => f := noni(state, f, instr); end case;
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
                when 6 => f := bit_xy_d(state, f, rot(s.y), 0, rxy(xy));
                when others =>
                    f := unimp(state, f, instr, "ld r[z], rot[y] (IX/Y+d)");
                end case;
            when 1 => f := bit_xy_d(state, f, bit_i, 0, rxy(xy));
            when 2 =>
                case s.z is
                when 6 => f := bit_xy_d(state, f, res_i, s.y, rxy(xy));
                when others =>
                    f := unimp(state, f, instr, "ld r[z], res y, (IX/Y+d)");
                end case;
            when 3 =>
                case s.z is
                when 6 => f := bit_xy_d(state, f, set_i, s.y, rxy(xy));
                when others =>
                    f := unimp(state, f, instr, "ld r[z], set y, (IX/Y+d)");
                end case;
            end case;
        when dd|fd =>
            case s.x is
            when 0 =>
                case s.z is
                when 0 => f := noni(state, f, instr);
                when 1 =>
                    case s.q is
                    when 0 =>
                        case s.p is
                        when 2 => f := ld_rp_nn(state, f, rxy(xy));
                        when others => f := noni(state, f, instr);
                        end case;
                    when 1 => f := alu_rp_rp(state, f, add16_i1, add16_i2,
                                             rxy(xy), rp(s.p));
                    end case;
                when 2 =>
                    case s.q is
                    when 0 => 
                        case s.p is
                        when 2 => f := ld_nnx_rp(state, f, rxy(xy));
                        when others => f := noni(state, f, instr);
                        end case;
                    when 1 =>
                        case s.p is
                        when 2 => f := ld_rp_nnx(state, f, rxy(xy));
                        when others => f := noni(state, f, instr);
                        end case;
                    end case;
                when 3 =>
                    case s.q is
                    when 0 => f := inc_dec_rp(state, f, inc, rxy(xy));
                    when 1 => f := inc_dec_rp(state, f, dec, rxy(xy));
                    end case;
                when 4 =>
                    case s.y is
                    when 4 => f := alu_r(state, f, inc_i, rxy(xy));
                    when 5 => f := alu_r(state, f, inc_i, rxy(xy)+1);
                    when 6 => f := inc_dec_xy_d(state, f, inc_i, rxy(xy));
                    when others => f := noni(state, f, instr);
                    end case;
                when 5 => 
                    case s.y is
                    when 4 => f := alu_r(state, f, dec_i, rxy(xy));
                    when 5 => f := alu_r(state, f, dec_i, rxy(xy)+1);
                    when 6 => f := inc_dec_xy_d(state, f, dec_i, rxy(xy));
                    when others => f := noni(state, f, instr);
                    end case;
                when 6 =>
                    case s.y is
                    when 4 => f := ld_r_n(state, f, rxy(xy));
                    when 5 => f := ld_r_n(state, f, rxy(xy)+1);
                    when 6 => f := ld_xy_d_n(state, f, rxy(xy));
                    when others => f := noni(state, f, instr);
                    end case;
                when 7 => f := noni(state, f, instr);
                end case;
            when 1 =>
                case s.z is
                when 6 =>
                    case s.y is
                    when 6 => f := noni(state, f, instr);
                    when others => f := ld_r_xy_d(state, f, s.y, rxy(xy));
                    end case;
                when others => 
                    case s.y is
                    when 6 => f := ld_xy_d_r(state, f, rxy(xy), s.z);
                    when others => f := ld_r_r(state, f, rxyhl(xy)(s.y),
                                               rxyhl(xy)(s.z));
                    end case;
                end case;
            when 2 => 
                case s.z is
                when 6 => f := alu_a_xy_d(state, f, alu(s.y), rxy(xy));
                when others => f := alu_a_r(state, f, alu(s.y),
                                            rxyhl(xy)(s.z));
                end case;
            when 3 =>
                case s.z is
                when 1 =>
                    case s.q is
                    when 0 =>
                        case s.p is
                        when 2 => f := pop_rp(state, f, rxy(xy));
                        when others => f := noni(state, f, instr);
                        end case;
                    when 1 =>
                        case s.p is
                        when 2 => f := jp_rp(state, f, rxy(xy));
                        when 3 => f := ld_sp_rp(state, f, rxy(xy));
                        when others => f := noni(state, f, instr);
                        end case;
                    end case;
                when 3 =>
                    case s.y is
                    when 1 => f := mem_rd_xy_d(state, f, pxy(xy));
                    when 4 => f := ex_spx_rp(state, f, rxy(xy));
                    when others => f := noni(state, f, instr);
                    end case;
                when 5 =>
                    case s.q is
                    when 0 =>
                        case s.p is
                        when 2 => f := push_rp(state, f, rxy(xy));
                        when others => f := noni(state, f, instr);
                        end case;
                    when others => f := noni(state, f, instr);
                    end case;
                when others => f := noni(state, f, instr);
                end case;
            end case;
        end case;
        end if;

        cw <= f.cw;
        cbo <= f.cb;
        ctrl <= f.ct;
    end process;
 end arch;
