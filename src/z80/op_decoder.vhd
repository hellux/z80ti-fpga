library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.cmp_comm.all;

entity op_decoder is port(
    cpu_state : in state_t;
    iff : in std_logic;
    instr : in std_logic_vector(7 downto 0);
    flags : in std_logic_vector(7 downto 0);
    ctrl : out id_ctrl_t;
    cbo : out ctrlbus_out;
    cw : out ctrlword;
-- debug
    dbg : out dbg_id_t);
end op_decoder;

architecture arch of op_decoder is
    type id_frame_t is record
        ct : id_ctrl_t;
        cb : ctrlbus_out;
        cw : ctrlword;
        db : dbg_id_t;
    end record;

    type id_state_t is record
        mode : id_mode_t;
        prefix : id_prefix_t;
        im : natural range 0 to 2;
        m : natural range 1 to 5;
        t : natural range 1 to 6;
        iff : std_logic;
        cc : cond_t;
    end record;

    -- MACHINE CYCLES --

    function io_rd(state : id_state_t; f_in : id_frame_t)
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

    function io_wr(state : id_state_t; f_in : id_frame_t)
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

    function mem_rd(state : id_state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.t is
        when t1 =>
            f.cw.addr_rd := '1';    -- read from abus to buffer
        when t2 =>
            f.cw.data_rdi := '1';   -- store data to data buf
            f.cb.mreq := '1';       -- signal addr ready on bus
            f.cb.rd := '1';         -- read
        when t3 =>
            f.cw.dbus_src := ext_o; -- write byte to inner dbus from buf
        when others => null; end case;
        return f;
    end mem_rd;

    function mem_wr(state : id_state_t; f_in : id_frame_t)
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

    function mem_rd_pc(state : id_state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        f := mem_rd(state, f);
        case state.t is
        when t1 =>
            f.cw.rf_aaddr := regPC;
            f.cw.abus_src := rf_o;
        when t2 => -- increment pc
            f.cw.rf_aaddr := regPC;
            f.cw.abus_src := rf_o;
            f.cw.addr_op := inc;
            f.cw.rf_rda := '1';
        when others => null; end case;
        return f;
    end mem_rd_pc;

    function mem_rd_instr(state : id_state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        f := mem_rd_pc(state, f);
        f.cb.m1 := '1'; -- notify external of pc rd
        case state.t is
        when t3 =>
            f.cw.ir_rd := '1'; -- read instr from dbus to ir
        when others => null; end case;
        return f;
    end mem_rd_instr;

    function mem_rd_multi(state : id_state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        f := mem_rd_instr(state, f);
        case state.t is
        when t3 =>
            f.ct.set_m1 := '1'; -- return to m1
        when t4 =>
            f.ct.cycle_end := '1';
        when others => null; end case;
        return f;
    end mem_rd_multi;

    function mem_rd_xy_d(state : id_state_t; f_in : id_frame_t)
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
                f.cw.rf_daddr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd_instr(state, f);
            case state.t is
            when t3 =>
                f.ct.set_m1 := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end mem_rd_xy_d;

    -- INSTRUCTIONS --

    function nop(state : id_state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.t is
        when t4 =>
            f.ct.cycle_end := '1';
            f.ct.instr_end := '1';
        when others => null; end case;
        return f;
    end nop;

    function noni(state : id_state_t; f_in : id_frame_t;
                  instr : std_logic_vector(7 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        report "NONI: " & " (" &
                integer'image(to_integer(unsigned(instr))) & ")";
        f := f_in;
        case state.t is
        when t4 =>
            f.ct.mode_next := halt;
            f.ct.cycle_end := '1';
            f.ct.instr_end := '1';
        when others => null; end case;
        return f;
    end noni;

    function jp_nn(state : id_state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => 
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
                f.db.jump_beg := '1';
            when others => null; end case;
        when m2 => -- first byte -> z
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_daddr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- wz -> pc, second byte -> pch
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regPC;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_aaddr := regWZ;
                f.cw.rf_ldpc := '1';
            when t3 =>
                f.cw.rf_daddr := regPCh;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
                f.db.jump_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end jp_nn;

    function jp_cc_nn(state : id_state_t; f_in : id_frame_t;
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

    function jp_rp(state : id_state_t; f_in : id_frame_t;
                   rp : std_logic_vector(3 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_aaddr := rp;
                f.cw.rf_ldpc := '1'; -- ld pc with rp
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
                f.db.jump_beg := '1';
                f.db.jump_end := '1';
            when others => end case;
        when others => end case;
        return f;
    end jp_rp;

    function jr_d(state : id_state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
                f.db.jump_beg := '1';
            when others => null; end case;
        when m2 => -- fetch d, pc+d+1->pc
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regPC;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.rf_aaddr := regPC;
                f.cw.abus_src := dis_o;
                f.cw.addr_op := inc;
                f.cw.rf_rda := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            case state.t is
            when t1 =>
            when t2 =>
            when t3 =>
            when t4 =>
            when t5 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
                f.db.jump_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end jr_d;

    function jr_cc_d(state : id_state_t; f_in : id_frame_t;
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

    function ex(state : id_state_t; f_in : id_frame_t;
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

    function alu_a_r(state : id_state_t; f_in : id_frame_t;
                     op : instr_t; reg : std_logic_vector(4 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.act_rd := '1';     -- read from a to tmp accumulator
                f.cw.rf_daddr := reg;   -- select reg
                f.cw.dbus_src := rf_o;  -- place reg on dbus
                f.cw.tmp_rd := '1';     -- read from dbus to tmp
                f.ct.cycle_end := '1';  -- signal new cycle
                f.ct.instr_end := '1';
            when t2 => -- after, during overlap
                f.cw.alu_op := op;      -- tell alu operation
                f.cw.dbus_src := alu_o; -- place result on dbus
                f.cw.f_rd := '1';       -- read flags from alu
                f.cw.rf_daddr := regA;  -- select the A reg
                f.cw.rf_rdd := '1';     -- read alu output from dbus
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_a_r;

    function alu_a_n(state : id_state_t; f_in : id_frame_t;
                     op : instr_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.act_rd := '1';     -- read from a to tmp accumulator
                f.ct.cycle_end := '1';  -- signal new cycle
            when t2 => -- after, during overlap
                f.cw.alu_op := op;      -- tell alu operation
                f.cw.dbus_src := alu_o; -- place result on dbus
                f.cw.f_rd := '1';       -- read flags from alu
                f.cw.rf_daddr := regA;   -- select the A reg
                f.cw.rf_rdd := '1';     -- read alu output from dbus
            when others => null; end case;
        when m2 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 => 
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_a_n;

    function alu_r(state : id_state_t; f_in : id_frame_t;
                   op : instr_t; reg : std_logic_vector(4 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => 
            case state.t is
            when t4 =>
                f.cw.rf_daddr := reg;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when t2 => -- after, during overlap
                f.cw.alu_op := op;
                f.cw.dbus_src := alu_o;
                f.cw.f_rd := '1';
                f.cw.rf_daddr := reg;
                f.cw.rf_rdd := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_r;

    function alu_a_rpx(state : id_state_t; f_in : id_frame_t;
                       op : instr_t; rp : std_logic_vector(3 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => 
            case state.t is
            when t2 => -- during overlap
                f.cw.alu_op := op;
                f.cw.dbus_src := alu_o;
                f.cw.f_rd := '1';
                f.cw.rf_daddr := regA;
                f.cw.rf_rdd := '1';
            when t4 =>
                f.cw.act_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := rp;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_a_rpx;

    function alu_rpx(state : id_state_t; f_in : id_frame_t;
                     op : instr_t; rp : std_logic_vector(3 downto 0))
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
                f.cw.rf_aaddr := rp;
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
                f.cw.rf_aaddr := rp;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_rpx;

    function alu_af(state : id_state_t; f_in : id_frame_t;
                    op : instr_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => 
            case state.t is
            when t4 =>
                f.cw.rf_daddr := regA;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when t2 => -- after, during overlap
                f.cw.alu_op := op;
                f.cw.dbus_src := alu_o;
                f.cw.f_rd := '1';
                f.cw.rf_daddr := regA;
                f.cw.rf_rdd := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_af;
    
    function alu_rp_rp(state : id_state_t; f_in : id_frame_t;
                       op1 : instr_t;
                       op2 : instr_t;
                       rp1 : std_logic_vector(3 downto 0);
                       rp2 : std_logic_vector(3 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 => -- l1 -> tmp, afwz
                f.cw.rf_daddr := rp1 & '1';
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.cw.rf_swp := afwz;
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            case state.t is
            when t1 => -- tmp -> a
                f.cw.dbus_src := tmp_o;
                f.cw.rf_daddr := regA;
                f.cw.rf_rdd := '1';
            when t2 => -- a -> act, l2 -> tmp, afwz
                f.cw.act_rd := '1';
                f.cw.rf_daddr := rp2 & '1';
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.cw.rf_swp := afwz;
            when t3 => -- alu -> l1
                f.cw.alu_op := op1;
                f.cw.f_rd := '1';
                f.cw.dbus_src := alu_o;
                f.cw.rf_daddr := rp1 & '1';
                f.cw.rf_rdd := '1';
            when t4 => -- h1 -> tmp, afwz
                f.cw.rf_daddr := rp1 & '0';
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.cw.rf_swp := afwz;
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            case state.t is
            when t1 => -- tmp -> a
                f.cw.dbus_src := tmp_o;
                f.cw.rf_daddr := regA;
                f.cw.rf_rdd := '1';
            when t2 => -- a -> act, h2 -> tmp, afwz
                f.cw.act_rd := '1';
                f.cw.rf_daddr := rp2 & '0';
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.cw.rf_swp := afwz;
            when t3 => -- alu -> h1, afwz
                f.cw.alu_op := op2;
                f.cw.f_rd := '1';
                f.cw.dbus_src := alu_o;
                f.cw.rf_daddr := rp1 & '0';
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end alu_rp_rp;

    function bit_r(state : id_state_t; f_in : id_frame_t;
                   op : instr_t; bs : integer range 0 to 7;
                   reg : std_logic_vector(4 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is 
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_daddr := reg;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when t2 => -- after, during overlap
                f.cw.alu_op := op;
                f.cw.alu_bs := bs;
                f.cw.dbus_src := alu_o;
                f.cw.f_rd := '1';
                f.cw.rf_daddr := reg;
                f.cw.rf_rdd := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end bit_r;

    function bit_hlx(state : id_state_t; f_in : id_frame_t;
                     op : instr_t; bs : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- (hl) -> alu -> dbufo
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regHL;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.tmp_rd := '1';
            when t4 =>
                f.cw.alu_op := op;
                f.cw.alu_bs := bs;
                f.cw.f_rd := '1';
                f.cw.dbus_src := alu_o;
                f.cw.data_rdo := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- dbufo -> (hl)
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regHL;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end bit_hlx;

    function bit_xy_d(state : id_state_t; f_in : id_frame_t;
                      op : instr_t; bs : integer range 0 to 7;
                      rp : std_logic_vector(3 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
            when t5 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- (rp+z) -> tmp
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_daddr := regZ; -- z holds d from fetch
                f.cw.dbus_src := rf_o;
                f.cw.rf_aaddr := rp;
                f.cw.abus_src := dis_o;
            when t3 =>
                f.cw.tmp_rd := '1';
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- alu -> (rp+z)
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_daddr := regZ;
                f.cw.dbus_src := rf_o;
                f.cw.rf_aaddr := rp;
                f.cw.abus_src := dis_o;
            when t2 =>
                f.cw.alu_op := op;
                f.cw.alu_bs := bs;
                f.cw.f_rd := '1';
                f.cw.dbus_src := alu_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end bit_xy_d;
    
    function rld_rrd(state : id_state_t; f_in : id_frame_t;
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
                f.cw.rf_aaddr := regHL;
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
                f.cw.rf_aaddr := regHL;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.alu_op := op2;
                f.cw.f_rd := '1';
                f.cw.dbus_src := alu_o;
                f.cw.rf_daddr := regA;  
                f.cw.rf_rdd := '1';
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end rld_rrd;

    function inc_dec_rp(state : id_state_t; f_in : id_frame_t;
                        op : addr_op_t; rp : std_logic_vector(3 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is 
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_aaddr := rp;
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
    
    function bli_op(state : id_state_t; f_in : id_frame_t;
                    op : instr_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- fetch mem (hl) / port (c)
            case op is
            when ldi_i|ldir_i|ldd_i|lddr_i|
                 cpi_i|cpir_i|cpd_i|cpdr_i|
                 outi_i|otir_i|outd_i|otdr_i => 
                f := mem_rd(state, f);
            when ini_i|inir_i|ind_i|indr_i =>
                f := io_rd(state, f);
            when others => null; end case;
     
            case state.t is
            when t1 =>
                case op is
                when ldi_i|ldir_i|ldd_i|lddr_i|
                     cpi_i|cpir_i|cpd_i|cpdr_i|
                     outi_i|outd_i|otir_i|otdr_i =>
                    f.cw.rf_aaddr := regHL;
                    f.cw.abus_src := rf_o;
                when ini_i|inir_i|ind_i|indr_i =>
                    f.cw.rf_aaddr := regBC;
                    f.cw.abus_src := rf_o;
                when others => null; end case;
            when t3 => -- dbufi -> dbus -> dbufo
                case op is
                when ldi_i|ldir_i|ldd_i|lddr_i|
                     ini_i|inir_i|ind_i|indr_i|
                     outi_i|otir_i|outd_i|otdr_i =>
                    f.cw.data_rdo := '1';
                when cpi_i|cpir_i|cpd_i|cpdr_i  => 
                    f.cw.tmp_rd := '1';
                    f.cw.act_rd := '1';
                when others => null; end case;
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            case op is
            when ldi_i|ldir_i|ldd_i|lddr_i|
                 ini_i|inir_i|ind_i|indr_i =>
                f := mem_wr(state, f);
            when outi_i|otir_i|outd_i|otdr_i =>
                f := io_wr(state, f);
            when others => null; end case;
            
            case state.t is
            when t1 =>
                case op is
                when ldi_i|ldir_i|ldd_i|lddr_i =>
                    f.cw.rf_aaddr := regDE;
                    f.cw.abus_src := rf_o;
                when ini_i|inir_i|ind_i|indr_i =>
                    f.cw.rf_aaddr := regHL;
                    f.cw.abus_src := rf_o;
                when outi_i|outd_i|otir_i|otdr_i => 
                    f.cw.rf_aaddr := regBC;
                    f.cw.abus_src := rf_o;
                when others => null; end case;
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 =>
            case state.t is
            when t1 => -- inc/dec HL
                f.cw.rf_aaddr := regHL;
                f.cw.abus_src := rf_o;
                case op is
                when ldi_i|ldir_i|
                     cpi_i|cpir_i|
                     ini_i|inir_i|
                     outi_i|otir_i =>
                    f.cw.addr_op := inc;
                when ldd_i|lddr_i|
                     cpd_i|cpdr_i|
                     ind_i|indr_i|
                     outd_i|otdr_i =>
                    f.cw.addr_op := dec;
                when others => null; end case;
                f.cw.rf_rda := '1';
            when t2 => -- inc/dec/leave DE
                f.cw.rf_aaddr := regDE;
                f.cw.abus_src := rf_o;
                case op is
                when ldi_i|ldir_i => f.cw.addr_op := inc;
                when ldd_i|lddr_i => f.cw.addr_op := dec;
                when others       => f.cw.addr_op := none;
                end case;
                f.cw.rf_rda := '1';
            when t3 =>
                case op is
                when ldi_i|ldir_i|ldd_i|lddr_i|
                     cpi_i|cpir_i|cpd_i|cpdr_i => -- dec BC
                    f.cw.rf_aaddr := regBC;
                    f.cw.abus_src := rf_o;
                    f.cw.addr_op := dec;
                    f.cw.rf_rda := '1';
                    f.cw.pv_src := anz_f;
                    f.cw.alu_op := op;
                    f.cw.f_rd := '1';
                when ini_i|inir_i|ind_i|indr_i|
                     outi_i|otir_i|outd_i|otdr_i => -- b -> tmp
                    f.cw.rf_daddr := regB;
                    f.cw.dbus_src := rf_o;
                    f.cw.tmp_rd := '1';
                when others => null; end case;
            when t4 =>
                case op is
                when ini_i|inir_i|ind_i|indr_i|
                     outi_i|otir_i|outd_i|otdr_i => -- dec tmp -> b
                    f.cw.alu_op := dec_i;
                    f.cw.dbus_src := alu_o;
                    f.cw.rf_daddr := regB;
                    f.cw.rf_rdd := '1';
                    f.cw.f_rd := '1';
                when others => null; end case; 
            when t5 =>
                case op is
                when ldi_i|ldd_i|cpi_i|cpd_i|
                     ini_i|ind_i|outi_i|outd_i =>
                    f.ct.instr_end := '1';
                when ldir_i|lddr_i => -- end if bc=0
                    if state.cc(PO_c) then
                        f.ct.instr_end := '1';
                    end if;
                when cpir_i|cpdr_i =>  -- end if bc=0 or a=(hl)
                    if state.cc(PO_c) or state.cc(Z_c) then
                        f.ct.instr_end := '1';
                    end if;
                when inir_i|indr_i|otir_i|otdr_i => -- end if b=0
                    if state.cc(Z_c) then
                        f.ct.instr_end := '1';
                    end if;
                when others => null; end case;
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m5 => -- pc-2 -> pc
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regPC;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t2 =>
                f.cw.rf_aaddr := regPC;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t3 =>
            when t4 =>
            when t5 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end bli_op;

    function ld_a_i_r(state : id_state_t; f_in : id_frame_t;
                      reg : std_logic_vector(4 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 => -- i/r -> tmp
                f.cw.rf_daddr := reg;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            case state.t is
            when t1 => -- tmp -> a
                f.cw.rf_daddr := regA;
                f.cw.dbus_src := tmp_o;
                f.cw.rf_rdd := '1';
            when t2 => -- set flags with alu/iff
                f.cw.alu_op := ld_i;
                f.cw.f_rd := '1';
                f.cw.pv_src := iff_f; -- use iff as pv
            when t5 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_a_i_r;

    function ld_r_r(state : id_state_t; f_in : id_frame_t;
                    dst, src : std_logic_vector(4 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_daddr := src;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
            when t5 =>
                f.cw.rf_daddr := dst;
                f.cw.dbus_src := tmp_o;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_r_r;

    function ld_r_n(state : id_state_t; f_in : id_frame_t;
                   reg : std_logic_vector(4 downto 0))
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
                f.cw.rf_daddr := reg;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_r_n;

    function ld_r_rpx(state : id_state_t; f_in : id_frame_t;
                      reg : std_logic_vector(4 downto 0);
                      rp : std_logic_vector(3 downto 0))
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
                f.cw.rf_aaddr := rp;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.rf_daddr := reg;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_r_rpx;

    function ld_rp_nn(state : id_state_t; f_in : id_frame_t;
                      rp : std_logic_vector(3 downto 0))
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
                f.cw.rf_daddr := rp & '1'; -- store to low byte
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_daddr := rp & '0'; -- store to high byte
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_rp_nn;

    function ld_r_nnx(state : id_state_t; f_in : id_frame_t;
                      reg : std_logic_vector(4 downto 0))
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
                f.cw.rf_daddr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- b2 -> w
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_daddr := regW;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 => -- (wz) -> r
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regWZ;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.rf_daddr := reg;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_r_nnx;

    function ld_rp_nnx(state : id_state_t; f_in : id_frame_t;
                       rp : std_logic_vector(3 downto 0))
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
                f.cw.rf_daddr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- b2 -> w
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_daddr := regW;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 => -- (wz++) -> rpl
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regWZ;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
                f.cw.rf_rda := '1';
            when t3 =>
                f.cw.rf_daddr := rp & '1';
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m5 => -- (wz) -> rph
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regWZ;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.rf_daddr := rp & '0';
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_rp_nnx;

    function ld_sp_rp(state : id_state_t; f_in : id_frame_t;
                      rp : std_logic_vector(3 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 => -- reg high -> tmp
                f.cw.rf_daddr := rp & '1';
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
            when t5 => -- tmp -> sph
                f.cw.dbus_src := tmp_o;
                f.cw.rf_daddr := regSPl;
                f.cw.rf_rdd := '1';
            when t6 => -- reg low -> tmp
                f.cw.rf_daddr := rp & '0';
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when t1 => -- tmp -> spl
                f.cw.dbus_src := tmp_o;
                f.cw.rf_daddr := regSPh;
                f.cw.rf_rdd := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_sp_rp;

    function ld_rpx_r(state : id_state_t; f_in : id_frame_t;
                      rp : std_logic_vector(3 downto 0);
                      reg : std_logic_vector(4 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.cw.rf_daddr := reg;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';   -- store reg in data buffer
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 =>
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := rp;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_rpx_r;

    function ld_rpx_n(state : id_state_t; f_in : id_frame_t;
                      rp : std_logic_vector(3 downto 0))
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
                f.cw.rf_aaddr := rp;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_rpx_n;

    function ld_nnx_a(state : id_state_t; f_in : id_frame_t)
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
                f.cw.rf_daddr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_daddr := regW;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 =>
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regWZ;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_daddr := regA;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_nnx_a;

    function ld_nnx_rp(state : id_state_t; f_in : id_frame_t;
                       rp : std_logic_vector(3 downto 0))
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
                f.cw.rf_daddr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_daddr := regW;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 =>
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regWZ;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_daddr := rp & '1';
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 => -- increment WZ
                f.cw.rf_aaddr := regWZ;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
                f.cw.rf_rda := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m5 =>
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regWZ;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_daddr := rp & '0';
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_nnx_rp;
    
    -- ld r, (ix/iy+d)
    function ld_r_xy_d(state : id_state_t; f_in : id_frame_t; 
                        reg : std_logic_vector(4 downto 0);
                        rp : std_logic_vector(3 downto 0))
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
                f.cw.rf_aaddr := rp;
                f.cw.abus_src := dis_o;
            when t3 =>
                f.cw.rf_daddr := reg;
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
    
    function ld_xy_d_r(state : id_state_t; f_in : id_frame_t; 
                        rp : std_logic_vector(3 downto 0);
                        reg : std_logic_vector(4 downto 0))
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
                f.cw.rf_aaddr := rp;
                f.cw.abus_src := dis_o; 
            when t2 =>
                f.cw.rf_daddr := reg;
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
    
    function ld_xy_d_n(state : id_state_t; f_in : id_frame_t; 
                        rp : std_logic_vector(3 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => --Fetch displacement
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => --Fetch N
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_daddr := regZ;
                f.cw.rf_rdd := '1';
            when t5 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 => --Write N to IXY + d
            f := mem_wr(state, f);
            case state.t is
            when t1 =>   
                f.cw.dbus_src := tmp_o;
                f.cw.rf_aaddr := rp;
                f.cw.abus_src := dis_o; 
            when t2 =>
                f.cw.rf_daddr := regZ;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ld_xy_d_n;
    
    function alu_xy_d(state : id_state_t; f_in : id_frame_t;
                      op : instr_t;
                      rp : std_logic_vector(3 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- d -> tmp, z
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_daddr := regZ;
                f.cw.rf_rdd := '1';
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- (ix/y+tmp) -> tmp, alu -> w, z -> tmp
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.dbus_src := tmp_o; 
                f.cw.rf_aaddr := rp;
                f.cw.abus_src := dis_o;
            when t3 =>
                f.cw.tmp_rd := '1';
            when t4 =>
                f.cw.alu_op := op;
                f.cw.dbus_src := alu_o;
                f.cw.rf_daddr := regW;
                f.cw.rf_rdd := '1';
                f.cw.f_rd := '1';
            when t5 =>
                f.cw.rf_daddr := regZ;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 => -- w -> (ix/y+tmp)
            f := mem_wr(state, f);
            case state.t is
            when t1 =>   
                f.cw.dbus_src := tmp_o;
                f.cw.rf_aaddr := rp;
                f.cw.abus_src := dis_o; 
            when t2 =>
                f.cw.rf_daddr := regW;
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
    end alu_xy_d;

    
    function alu_a_xy_d(state : id_state_t; f_in : id_frame_t; 
                        op : instr_t;
                        rp : std_logic_vector(3 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => --Fetch displacement
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.tmp_rd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => --Fetch value of (IX/y+d)
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.dbus_src := tmp_o; 
                f.cw.rf_aaddr := rp;
                f.cw.abus_src := dis_o;
            when t3 =>
                f.cw.tmp_rd := '1';
                f.cw.act_rd := '1';
            when t4 =>
                f.cw.alu_op := op;
                f.cw.dbus_src := alu_o;
                f.cw.rf_daddr := regA;
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

    function ex_spx_rp(state : id_state_t; f_in : id_frame_t;
                       rp : std_logic_vector(3 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 => -- rp low -> dbufo
                f.cw.rf_daddr := rp & '1';
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- (SP) --> rp low
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.rf_daddr := rp & '1';
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- dbufo -> (sp++), rp high -> dbufo
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
                f.cw.rf_rda := '1';
            when t4 =>
                f.cw.rf_daddr := rp & '0';
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 => -- (sp) -> rp high
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.rf_daddr := rp & '0';
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m5 => -- tmp -> (sp--)
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t5 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ex_spx_rp;

    function in_c(state : id_state_t; f_in : id_frame_t)
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
                f.cw.rf_aaddr := regBC;
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

    function in_r_c(state : id_state_t; f_in : id_frame_t;
                    reg : std_logic_vector(4 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        f := in_c(state, f);
        case state.m is
        when m2 =>
            case state.t is
            when t3 =>
                f.cw.rf_daddr := reg;
                f.cw.rf_rdd := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end in_r_c;

    function in_a_n(state : id_state_t; f_in : id_frame_t)
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
                f.cw.rf_daddr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := io_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regWZ;
                f.cw.abus_src := rf_o;
            when t3 =>
                f.cw.rf_daddr := regA;
                f.cw.rf_rdd := '1';
                f.cw.tmp_rd := '1';
            when t4 =>
                f.cw.alu_op := in_i;
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end in_a_n;

    function out_n_a(state : id_state_t; f_in : id_frame_t)
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
                f.cw.rf_daddr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 =>
            f := io_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regWZ;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_daddr := regA;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t4 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end out_n_a;

    function out_c_r(state : id_state_t; f_in : id_frame_t;
                     reg : std_logic_vector(4 downto 0))
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
                f.cw.rf_aaddr := regBC;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_daddr := reg;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t4 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end out_c_r;

    function out_c_0(state : id_state_t; f_in : id_frame_t)
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
                f.cw.rf_aaddr := regBC;
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

    function push_rp(state : id_state_t; f_in : id_frame_t;
                     rp : std_logic_vector(3 downto 0))
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => -- dec sp
            case state.t is
            when t4 =>
                f.cw.rf_aaddr := regSP;
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
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t2 =>
                if rp = regAF then -- special, does not match pattern
                    f.cw.rf_daddr := regA;
                else
                    f.cw.rf_daddr := rp & '0';
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
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
            when t2 =>
                if rp = regAF then
                    f.cw.rf_daddr := regF;
                else
                    f.cw.rf_daddr := rp & '1';
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

    function pop_rp(state : id_state_t; f_in : id_frame_t;
                    rp : std_logic_vector(3 downto 0))
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
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
                f.cw.rf_rda := '1';
            when t3 =>
                if rp = regAF then
                    f.cw.rf_daddr := regF;
                else
                    f.cw.rf_daddr := rp & '1';
                end if;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- read high, inc sp
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
                f.cw.rf_rda := '1';
            when t3 =>
                if rp = regAF then
                    f.cw.rf_daddr := regA;
                else
                    f.cw.rf_daddr := rp & '0';
                end if;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end pop_rp;

    function call_nn(state : id_state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        -- pcrf need rp->wz or wz mode
        f := f_in;
        case state.m is
        when m1 => 
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
                f.db.jump_beg := '1';
            when others => null; end case;
        when m2 => -- fetch low to z
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_daddr := regZ;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- fetch high to w
            f := mem_rd_pc(state, f);
            case state.t is
            when t3 =>
                f.cw.rf_daddr := regW;
                f.cw.rf_rdd := '1';
            when t4 => -- dec sp
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 => -- pch -> (sph--)
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t2 =>
                f.cw.rf_daddr := regPCh;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m5 => -- pcl -> (sph--), wz -> pc
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_daddr := regPCl;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.cw.rf_aaddr := regWZ;
                f.cw.rf_ldpc := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
                f.db.jump_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end call_nn;

    function call_cc_nn(state : id_state_t; f_in : id_frame_t;
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

    function rst(state : id_state_t; f_in : id_frame_t;
                 addr : integer range 0 to 7)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => -- dec sp
            case state.t is
            when t4 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
                f.db.jump_beg := '1';
            when t5 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- pch -> (sph--)
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t2 =>
                f.cw.rf_daddr := regPCh;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- pcl -> (sph--), rst_addr -> pc
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_daddr := regPCl;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.cw.rst_addr := std_logic_vector(to_unsigned(addr, 3));
                f.cw.abus_src := rst_o;
                f.cw.addr_op := none;
                f.cw.rf_aaddr := regPC;
                f.cw.rf_rda := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
                f.db.jump_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end rst;

    function ret(state : id_state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                f.ct.cycle_end := '1';
                f.db.jump_beg := '1';
            when others => null; end case;
        when m2 => -- read to low pc, inc sp
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
                f.cw.rf_rda := '1';
            when t3 =>
                f.cw.rf_daddr := regPCl;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- read to high pc, inc sp
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
                f.cw.rf_rda := '1';
            when t3 =>
                f.cw.rf_daddr := regPCh;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
                f.db.jump_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end ret;

    function ret_cc(state : id_state_t; f_in : id_frame_t;
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

    function djnz_d(state : id_state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => -- decrement b
            case state.t is
            when t4 =>
                f.cw.rf_daddr := regB;
                f.cw.dbus_src := rf_o;
                f.cw.tmp_rd := '1';
                f.cw.rf_swp := afwz; -- save old flags to z
                f.db.jump_beg := '1';
            when t5 =>
                f.cw.alu_op := dec_i;
                f.cw.dbus_src := alu_o;
                f.cw.f_rd := '1'; -- overwrite flags
                f.cw.rf_daddr := regB;
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
                f.cw.rf_swp := afwz; -- restore old flags after internal use
            when others => null; end case;
        when m3 => -- pc+d->pc
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regPC;
                f.cw.dbus_src := tmp_o;
                f.cw.abus_src := dis_o;
                f.cw.addr_op := none;
                f.cw.rf_rda := '1';
            when t2 =>
            when t3 =>
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
                f.db.jump_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end djnz_d;

    function unimp(state : id_state_t; f_in : id_frame_t;
                   instr : std_logic_vector(7 downto 0); op : string)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        report "UNIMPLEMENTED INSTRUCTION: " & op
            & " (" & integer'image(to_integer(unsigned((instr)))) & ")";
        case state.t is
        when t4 => 
            f.ct.mode_next := halt;
            f.ct.cycle_end := '1';
            f.ct.instr_end := '1';
        when others => null; end case;
        return f;
    end unimp;

    function halt(state : id_state_t; f_in : id_frame_t)
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

    function si(state : id_state_t; f_in : id_frame_t;
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

    function set_im(state : id_state_t; f_in : id_frame_t;
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

    function im1(state : id_state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => -- dec sp
            case state.t is
            when t4 =>
                f.cw.iff_next := '0'; -- turn off interrupts
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
                f.ct.cycle_end := '1';
                f.db.jump_beg := '1';
            when others => null; end case;
        when m2 => -- pch -> (sph--)
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t2 =>
                f.cw.rf_daddr := regPCh;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- pcl -> (sph--), rst_addr -> pc
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_daddr := regPCl;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.cw.rst_addr := "111"; -- "111" << 3 = 0x38
                f.cw.abus_src := rst_o;
                f.cw.addr_op := none;
                f.cw.rf_aaddr := regPC;
                f.cw.rf_rda := '1';
                f.ct.mode_next := exec;
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
                f.db.jump_end := '1';
            when others => null; end case;
        when others => null; end case;
        return f;
    end im1;

    function im2(state : id_state_t; f_in : id_frame_t)
    return id_frame_t is variable f : id_frame_t; begin
        f := f_in;
        case state.m is
        when m1 => -- dec SP
            case state.t is
            when t4 =>
                f.cw.iff_next := '0'; -- turn off interrupts
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m2 => -- write pch to stack, dec SP
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t2 =>
                f.cw.rf_daddr := regPCh;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m3 => -- write pcl to stack
            f := mem_wr(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regSP;
                f.cw.abus_src := rf_o;
            when t2 =>
                f.cw.rf_daddr := regPCl;
                f.cw.dbus_src := rf_o;
                f.cw.data_rdo := '1';
            when t3 =>
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m4 => -- (ir++) -> pcl
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
                f.cw.rf_aaddr := regIR;
                f.cw.rf_rda := '1';
                f.db.jump_beg := '1';
            when t3 =>
                f.cw.rf_daddr := regPCl;
                f.cw.rf_rdd := '1';
                f.ct.cycle_end := '1';
            when others => null; end case;
        when m5 => -- (ir--) -> pch
            f := mem_rd(state, f);
            case state.t is
            when t1 =>
                f.cw.rf_aaddr := regIR;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := dec;
                f.cw.rf_rda := '1';
            when t3 =>
                f.cw.rf_daddr := regPCh;
                f.cw.rf_rdd := '1';
                f.ct.mode_next := exec;
                f.ct.cycle_end := '1';
                f.ct.instr_end := '1';
                f.db.jump_end := '1';
            when others => null; end case;
        when others => null; end case;
            f := mem_rd(state, f);
        return f;
    end im2;

    type instr_tbl_t is array(integer range <>) of instr_t;
    type instr_mtx_t is array(integer range <>, integer range <>) of instr_t;
    type reg_tbl_t is array(integer range <>) of std_logic_vector(4 downto 0);
    type reg_mtx_t is array(integer range <>,
                            integer range <>) of std_logic_vector(4 downto 0);
    type rp_tbl_t is array(integer range <>) of std_logic_vector(3 downto 0);
    type rp_mtx_t is array(integer range <>,
                           integer range <>) of std_logic_vector(3 downto 0);
    type im_tbl_t is array(0 to 7) of integer range 0 to 2;

    constant bli : instr_mtx_t(4 to 7, 0 to 3) :=
        ((ldi_i,  cpi_i,  ini_i,  outi_i), (ldd_i,  cpd_i,  ind_i,  outd_i),
         (ldir_i, cpir_i, inir_i, otir_i), (lddr_i, cpdr_i, indr_i, otdr_i));
    constant alu : instr_tbl_t(0 to 7) := (add_i, adc_i,
                                           sub_i, sbc_i,
                                           and_i, xor_i,
                                           or_i, cp_i);
    constant afi : instr_tbl_t(0 to 7) := (rlca_i, rrca_i,
                                           rla_i,  rra_i,
                                           daa_i,  cpl_i,
                                           scf_i,  ccf_i);
    constant rot : instr_tbl_t(0 to 7) := (rlc_i, rrc_i,
                                           rl_i,  rr_i,
                                           sla_i, sra_i,
                                           sll_i, srl_i);

    constant r : reg_tbl_t(0 to 7) := (regB, regC, regD, regE,
                                       regH, regL, regF, regA);
    constant rp  : rp_tbl_t(0 to 3) := (regBC, regDE, regHL, regSP);
    constant rp2 : rp_tbl_t(0 to 3) := (regBC, regDE, regHL, regAF);
    constant ixy : rp_tbl_t(0 to 1) := (regIX, regIY);
    constant ixyh : reg_tbl_t(0 to 1) := (regIXh, regIYh);
    constant ixyl : reg_tbl_t(0 to 1) := (regIXl, regIYl);
    constant r_xy : reg_mtx_t(0 to 1, 0 to 7) :=
        ((regB, regC, regD, regE, regIXh, regIXl, regF, regA),
         (regB, regC, regD, regE, regIYh, regIYl, regF, regA));
    constant rp_xy : rp_mtx_t(0 to 1, 0 to 3) :=
        ((regBC, regDE, regIX, regSP),
         (regBC, regDE, regIY, regSP));

    constant im : im_tbl_t := (0, 1, 1, 2, 0, 1, 1, 2);
begin
    process(instr, cpu_state, iff, flags)
        -- instruction split
        variable x, p : integer range 0 to 3;
        variable y, z : integer range 0 to 7;
        variable q : integer range 0 to 1;
        -- ix/iy instr
        variable xy : integer range 0 to 1;
        -- control signals frame
        variable f : id_frame_t;
        -- cpu state/iff/flags frame
        variable state : id_state_t;
    begin
        -- bind state frame
        state.mode := cpu_state.mode;
        state.prefix := cpu_state.prefix;
        state.im := cpu_state.im;
        state.m := cpu_state.m;
        state.t := cpu_state.t;
        state.iff := iff;
        state.cc(NZ_c) := flags(Z_F)  = '0';
        state.cc(Z_c)  := flags(Z_f)  = '1';
        state.cc(NC_c) := flags(C_f)  = '0';
        state.cc(C_c)  := flags(C_f)  = '1';
        state.cc(PO_c) := flags(PV_f) = '0';
        state.cc(PE_c) := flags(PV_f) = '1';
        state.cc(P_c)  := flags(S_f)  = '0';
        state.cc(M_c)  := flags(S_f)  = '1';

        -- helper variables
        --     | p | |q|
        -- |1 0|0 0| |0|1 1 1|
        -- | x |   y   |  z  |
        x := to_integer(unsigned(instr(7 downto 6)));
        y := to_integer(unsigned(instr(5 downto 3)));
        z := to_integer(unsigned(instr(2 downto 0)));
        p := to_integer(unsigned(instr(5 downto 4)));
        if instr(3) = '1' then q := 1; else q := 0; end if;
        if state.prefix = fd or
           state.prefix = fdcb
        then xy := 1;
        else xy := 0;
        end if;

        -- set all signals to defaults (overwrite sequentially below)
        f.ct := (mode_next => state.mode,
                 im_next => state.im,
                 others => '0');
        f.cb := (others => '0');
        f.cw := (dbus_src => none,
                 abus_src => none,
                 rst_addr => (others => '-'),
                 rf_daddr => (others => '-'),
                 rf_aaddr => (others => '-'),
                 rf_swp => none,
                 alu_op => unknown,
                 alu_bs => 0,
                 addr_op => inc,
                 pv_src => alu_f,
                 iff_next => state.iff,
                 others => '0');
        f.db := (others => '0');

        -- m1 cases
        if state.m = m1 then
            f.cb.m1 := '1';
            case state.t is
            when t3 => -- inc refresh register
                f.cw.rf_aaddr := regIR;
                f.cw.abus_src := rf_o;
                f.cw.addr_op := inc;
                f.cw.rf_rda := '1';
            when others => null; end case;
            case state.mode is
            when exec => -- fetch
                f := mem_rd_instr(state, f);
            when interrupt =>
                case state.t is
                when t3 => -- nop ir to update prefix to int
                    f.cw.dbus_src := zero_o;
                    f.cw.ir_rd := '1';
                when others => null; end case;
            when halt => null; -- stall
            end case;
        end if;

        case state.prefix is
        when int =>
            case state.im is
            when 0 => f := unimp(state, f, instr, "im0");
            when 1 => f := im1(state, f);
            when 2 => f := im2(state, f);
            end case;
        when main =>
            case x is
            when 0 =>
                case z is
                when 0 =>
                    case y is
                    when 0 => f := nop(state, f);
                    when 1 => f := ex(state, f, af);
                    when 2 => f := djnz_d(state, f);
                    when 3 => f := jr_d(state, f);
                    when 4|5|6|7 => f := jr_cc_d(state, f, y-4);
                    end case;
                when 1 =>
                    case q is
                    when 0 => f := ld_rp_nn(state, f, rp(p));
                    when 1 => f := alu_rp_rp(state, f, add16_i1, add16_i2,
                                             regHL, rp(p));
                    end case;
                when 2 =>
                    case y is
                    when 0 => f := ld_rpx_r(state, f, regBC, regA);
                    when 1 => f := ld_r_rpx(state, f, regA, regBC);
                    when 2 => f := ld_rpx_r(state, f, regDE, regA);
                    when 3 => f := ld_r_rpx(state, f, regA, regDE);
                    when 4 => f := ld_nnx_rp(state, f, regHL);
                    when 5 => f := ld_rp_nnx(state, f, regHL);
                    when 6 => f := ld_nnx_a(state, f);
                    when 7 => f := ld_r_nnx(state, f, regA);
                    end case;
                when 3 =>
                    case q is
                    when 0 => f := inc_dec_rp(state, f, inc, rp(p));
                    when 1 => f := inc_dec_rp(state, f, dec, rp(p));
                    end case;
                when 4 => 
                    case y is
                    when 6 => f := alu_rpx(state, f, inc_i, regHL);
                    when others => f := alu_r(state, f, inc_i, r(y));
                    end case;
                when 5 =>
                    case y is
                    when 6 => f := alu_rpx(state, f, dec_i, regHL);
                    when others => f := alu_r(state, f, dec_i, r(y));
                    end case;
                when 6 =>
                    case y is
                    when 6 => f := ld_rpx_n(state, f, regHL);
                    when others => f := ld_r_n(state, f, r(y));
                    end case;
                when 7 => f := alu_af(state, f, afi(y));
                end case;
            when 1 =>
                case z is
                when 6 =>
                    case y is
                    when 6 => f := halt(state, f);
                    when others => f := ld_r_rpx(state, f, r(y), regHL);
                    end case;
                when others =>
                    case y is
                    when 6 => f := ld_rpx_r(state, f, regHL, r(z));
                    when others => f := ld_r_r(state, f, r(y), r(z));
                    end case;
                end case;
            when 2 => 
                case z is
                when 6 => f := alu_a_rpx(state, f, alu(y), regHL);
                when others => f := alu_a_r(state, f, alu(y), r(z));
                end case;
            when 3 =>
                case z is
                when 0 => f := ret_cc(state, f, y);
                when 1 =>
                    case q is
                    when 0 => f := pop_rp(state, f, rp2(p));
                    when 1 =>
                        case p is
                        when 0 => f := ret(state, f);
                        when 1 => f := ex(state, f, reg);
                        when 2 => f := jp_rp(state, f, regHL);
                        when 3 => f := ld_sp_rp(state, f, regHL);
                        end case;
                    end case;
                when 2 => f := jp_cc_nn(state, f, y);
                when 3 =>
                    case y is
                    when 0 => f := jp_nn(state, f);
                    when 1 => f := mem_rd_multi(state, f);
                    when 2 => f := out_n_a(state, f);
                    when 3 => f := in_a_n(state, f);
                    when 4 => f := ex_spx_rp(state, f, regHL);
                    when 5 => f := ex(state, f, dehl);
                    when 6 => f := si(state, f, '0');
                    when 7 => f := si(state, f, '1');
                    end case;
                when 4 => f := call_cc_nn(state, f, y);
                when 5 =>
                    case q is
                    when 0 => f := push_rp(state, f, rp2(p));
                    when 1 =>
                        case p is
                        when 0 => f := call_nn(state, f);
                        when 1|2|3 => f := mem_rd_multi(state, f);
                        end case;
                    end case;
                when 6 => f := alu_a_n(state, f, alu(y));
                when 7 => f := rst(state, f, y);
                end case;
            end case;
        when ed =>
            case x is 
            when 1 =>
                case z is
                when 0 =>
                    case y is
                    when 6 => f := in_c(state, f);
                    when others => f := in_r_c(state, f, r(y));
                    end case;
                when 1 =>
                    case y is
                    when 6 => f := out_c_0(state, f);
                    when others => f := out_c_r(state, f, r(y));
                    end case;
                when 2 =>
                    case q is
                    when 0 => f := alu_rp_rp(state, f, sbc16_i1, sbc16_i2,
                                             regHL, rp(p));
                    when 1 => f := alu_rp_rp(state, f, adc16_i1, adc16_i2,
                                             regHL, rp(p));
                    end case;
                when 3 =>
                    case q is
                    when 0 => f := ld_nnx_rp(state, f, rp(p));
                    when 1 => f := ld_rp_nnx(state, f, rp(p));
                    end case;
                when 4 => f := alu_af(state, f, neg_i);
                when 5 => f := ret(state, f); -- reti=retn=ret
                when 6 => f := set_im(state, f, im(y));
                when 7 =>
                    case y is
                    when 0 => f := ld_r_r(state, f, regI, regA);
                    when 1 => f := ld_r_r(state, f, regR, regA);
                    when 2 => f := ld_a_i_r(state, f, regI);
                    when 3 => f := ld_a_i_r(state, f, regR);
                    when 4 => f := rld_rrd(state, f, rrd_i1, rrd_i2);
                    when 5 => f := rld_rrd(state, f, rld_i1, rld_i2);
                    when 6|7 => f := noni(state, f, instr);
                    end case;
                end case;
            when 2 =>
                case y is
                when 4|5|6|7 =>
                    case z is
                    when 0|1|2|3 => f := bli_op(state, f, bli(y, z));
                    when others => f := noni(state, f, instr);
                    end case;
                when others => f := noni(state, f, instr);
                end case;
            when 0|3 => f := noni(state, f, instr); end case;
        when cb =>
            case z is
            when 6 =>
                case x is
                when 0 => f := bit_hlx(state, f, rot(y), 0);
                when 1 => f := bit_hlx(state, f, bit_i, y);
                when 2 => f := bit_hlx(state, f, res_i, y);
                when 3 => f := bit_hlx(state, f, set_i, y);
                end case;
            when others =>
                case x is
                when 0 => f := bit_r(state, f, rot(y), 0, r(z));
                when 1 => f := bit_r(state, f, bit_i, y, r(z));
                when 2 => f := bit_r(state, f, res_i, y, r(z));
                when 3 => f := bit_r(state, f, set_i, y, r(z));
                end case;
            end case;
        when dd|fd =>
            case x is
            when 0 =>
                case z is
                when 0 => f := noni(state, f, instr);
                when 1 =>
                    case q is
                    when 0 =>
                        case p is
                        when 2 => f := ld_rp_nn(state, f, ixy(xy));
                        when others => f := noni(state, f, instr);
                        end case;
                    when 1 => f := alu_rp_rp(state, f, add16_i1, add16_i2,
                                             ixy(xy), rp_xy(xy, p));
                    end case;
                when 2 =>
                    case q is
                    when 0 => 
                        case p is
                        when 2 => f := ld_nnx_rp(state, f, ixy(xy));
                        when others => f := noni(state, f, instr);
                        end case;
                    when 1 =>
                        case p is
                        when 2 => f := ld_rp_nnx(state, f, ixy(xy));
                        when others => f := noni(state, f, instr);
                        end case;
                    end case;
                when 3 =>
                    case q is
                    when 0 =>
                        case p is
                        when 2 => f := inc_dec_rp(state, f, inc, ixy(xy));
                        when others => f := noni(state, f, instr);
                        end case;
                    when 1 =>
                        case p is
                        when 2 => f := inc_dec_rp(state, f, dec, ixy(xy));
                        when others => f := noni(state, f, instr);
                        end case;
                    end case;
                when 4 =>
                    case y is
                    when 4 => f := alu_r(state, f, inc_i, ixyh(xy));
                    when 5 => f := alu_r(state, f, inc_i, ixyl(xy));
                    when 6 => f := alu_xy_d(state, f, inc_i, ixy(xy));
                    when others => f := noni(state, f, instr);
                    end case;
                when 5 => 
                    case y is
                    when 4 => f := alu_r(state, f, dec_i, ixyh(xy));
                    when 5 => f := alu_r(state, f, dec_i, ixyl(xy));
                    when 6 => f := alu_xy_d(state, f, dec_i, ixy(xy));
                    when others => f := noni(state, f, instr);
                    end case;
                when 6 =>
                    case y is
                    when 4 => f := ld_r_n(state, f, ixyh(xy));
                    when 5 => f := ld_r_n(state, f, ixyl(xy));
                    when 6 => f := ld_xy_d_n(state, f, ixy(xy));
                    when others => f := noni(state, f, instr);
                    end case;
                when 7 => f := noni(state, f, instr);
                end case;
            when 1 =>
                case z is
                when 6 =>
                    case y is
                    when 6 => f := noni(state, f, instr);
                    when others => f := ld_r_xy_d(state, f, r(y), ixy(xy));
                    end case;
                when others => 
                    case y is
                    when 4 => f := ld_r_r(state, f, ixyh(xy), r_xy(xy, z));
                    when 5 => f := ld_r_r(state, f, ixyl(xy), r_xy(xy, z));
                    when 6 =>
                        case z is
                        when 6 => f := noni(state, f, instr);
                        when others => f := ld_xy_d_r(state, f, ixy(xy), r(z));
                        end case;
                    when others =>
                        case z is
                        when 4 =>
                            f := ld_r_r(state, f, r_xy(xy, y), ixyh(xy));
                        when 5 =>
                            f := ld_r_r(state, f, r_xy(xy, y), ixyl(xy));
                        when others => f := noni(state, f, instr);
                        end case;
                    end case;
                end case;
            when 2 => 
                case z is
                when 4 => f := alu_a_r(state, f, alu(y), ixyh(xy));
                when 5 => f := alu_a_r(state, f, alu(y), ixyl(xy));
                when 6 => f := alu_a_xy_d(state, f, alu(y), ixy(xy));
                when others => f := noni(state, f, instr);
                end case;
            when 3 =>
                case z is
                when 1 =>
                    case y is
                    when 4 => f := pop_rp(state, f, ixy(xy));
                    when 5 => f := jp_rp(state, f, ixy(xy));
                    when 7 =>
                        f := ld_sp_rp(state, f, ixy(xy));
                    when others => f := noni(state, f, instr);
                    end case;
                when 3 =>
                    case y is
                    when 1 => f := mem_rd_xy_d(state, f);
                    when 4 => f := ex_spx_rp(state, f, ixy(xy));
                    when others => f := noni(state, f, instr);
                    end case;
                when 5 =>
                    case y is
                    when 4 => f := push_rp(state, f, ixy(xy));
                    when others => f := noni(state, f, instr);
                    end case;
                when others => f := noni(state, f, instr);
                end case;
            end case;
        when ddcb|fdcb =>
            case x is
            when 0 =>
                case z is
                when 6 => f := bit_xy_d(state, f, rot(y), 0, ixy(xy));
                when others =>
                    f := unimp(state, f, instr, "ld r[z], rot[y] (IX/Y+d)");
                end case;
            when 1 => f := bit_xy_d(state, f, bit_i, y, ixy(xy));
            when 2 =>
                case z is
                when 6 => f := bit_xy_d(state, f, res_i, y, ixy(xy));
                when others =>
                    f := unimp(state, f, instr, "ld r[z], res y, (IX/Y+d)");
                end case;
            when 3 =>
                case z is
                when 6 => f := bit_xy_d(state, f, set_i, y, ixy(xy));
                when others =>
                    f := unimp(state, f, instr, "ld r[z], set y, (IX/Y+d)");
                end case;
            end case;
        end case;

        cw <= f.cw;
        cbo <= f.cb;
        ctrl <= f.ct;
        dbg <= f.db;
    end process;
 end arch;
