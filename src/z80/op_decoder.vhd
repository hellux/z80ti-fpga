library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.z80_instr.all;

entity op_decoder is port(
    clk : in std_logic;
    cbi : in ctrlbus_in;
    cbo : out ctrlbus_out;
    instr, flags : in std_logic_vector(7 downto 0);
    cw : out ctrlword;
    -- debug
    dbg_id : out dbg_id_t);
end op_decoder;

architecture Behavioral of op_decoder is
    type id_split_t is record
        x, p : integer range 0 to 3;
        y, z : integer range 0 to 7;
        q : integer range 0 to 1;
    end record;
    type rp_table_t is array(0 to 3) of integer range 0 to 15;
    type alu_table_t is array(0 to 7) of instr_t;

    signal split : id_split_t;
    signal state : id_state_t := (mode => main, cc => (others => false),
                                  m => m1, t => t1);
    signal ctrl : id_ctrl_t;
    signal f : id_frame_t;

    constant rp  : rp_table_t := (regBC, regDE, regHL, regSP);
    constant rp2 : rp_table_t := (regBC, regDE, regHL, regAF);
    constant alu : alu_table_t := (add_i, adc_i, sub_i, sbc_i,
                                   and_i, xor_i, or_i, cp_i);
    constant rot : alu_table_t := (rlc_i, rrc_i, rl_i, rr_i,
                                   sla_i, sra_i, sll_i, srl_i);
    constant afi : alu_table_t := (rlc_i, rrc_i, rl_i, rr_i,
                                   daa_i, cpl_i, scf_i, ccf_i);

    function decode(signal state : id_state_t;
                    signal instr : std_logic_vector(7 downto 0);
                    signal cbi : ctrlbus_in;
                    signal s : id_split_t)
    return id_frame_t is
        variable f : id_frame_t;
    begin
        -- reset all signals to defaults (overwrite below)
        f.ct := (others => '0'); -- reset internal ctrl signals
        f.cb := (others => '0'); -- reset control bus out signals
        f.cw := (rf_addr => 0,
                 rf_swp => none,
                 alu_op => unknown,
                 alu_bs => 0,
                 addr_in_op => inc,
                 others => '0');

        -- fetch phase
         if state.m = m1 then
            f.cb.m1 := '1';
            fetch_instr(state, f);
        end if;

        -- exec phase
        case state.mode is
        when main =>
            case s.x is
            when 0 =>
                case s.z is
                when 0 =>
                    case s.y is
                    when 0 => nop(state, f); -- NOP
                    when 1 => ex(state, f, af); -- EX AF, AF'
                    when 2 => null; -- DJNZ d
                    when 3 => null; jr_d(state, f);
                    when 4|5|6|7 => jr_cc_d(state, f, s.y-4); -- JR cc[y-4] d
                    end case;
                when 1 =>
                    case s.q is
                    when 0 => ld_rp_nn(state, f, rp(s.p)); -- LD rp[p], nn
                    when 1 => null; -- ADD hl, rp[p]
                    end case;
                when 2 =>
                    case s.q is
                    when 0 => 
                        case s.p is
                        when 0 => null; -- LD (BC), A
                        when 1 => null; -- LD (DE), A
                        when 2 => null; -- LD (nn), HL
                        when 3 => null; -- LD (nn), A
                        end case;
                    when 1 => 
                        case s.p is
                        when 0 => null; -- LD A, (BC)
                        when 1 => null; -- LD A, (DE)
                        when 2 => null; -- LD HL, (nn)
                        when 3 => null; -- LD A, (nn)
                        end case;
                    end case;
                when 3 => -- INC/DEC rp[y];
                    case s.q is
                    when 0 => null; -- INC rp[y]
                    when 1 => null; -- DEC rp[y]
                    end case;
                when 4 => alu_r(state, f, inc_i, s.y); -- INC r[y]
                when 5 => alu_r(state, f, dec_i, s.y); -- DEC r[y]
                when 6 => ld_r_n(state, f, s.y); -- LD r[y], n
                when 7 => alu_af(state, f, afi(s.y));
                end case;
            when 1 =>
                case s.z is
                when 6 =>
                    case s.y is
                    when 6 => null; -- HALT
                    when others => ld_r_hlx(state, f, s.y); -- LD r[y], (hl)
                    end case;
                -- TODO LD (hl), r[z]
                when others => ld_r_r(state, f, s.z, s.y); --LD r[y], r[z]
                end case;
            when 2 => 
                case s.z is
                when 6 => null; -- alu[y] (hl)
                when others => alu_a_r(state, f, alu(s.y), s.z); -- alu[y] r[z]
                end case;
            when 3 =>
                case s.z is
                when 0 => null; -- RET cc[y]
                when 1 => null;
                    case s.q is
                    when 0 => null; -- POP rp2[p]
                    when 1 =>
                        case s.p is
                        when 0 => null; -- RET
                        when 1 => null; ex(state, f, reg); -- EXX
                        when 2 => null; jp_hl(state, f); -- JP HL
                        when 3 => null; -- LD SP, HL
                        end case;
                    end case;
                when 2 => jp_cc_nn(state, f, s.y); -- JP cc[y], nn
                when 3 =>
                    case s.y is
                    when 0 => jp_nn(state, f);
                    when 1 => fetch_multi(state, f); -- (CB/DDCD/FDCB)
                    when 2 => null; -- OUT (n), A
                    when 3 => null; -- IN A, (n)
                    when 4 => null; -- EX (SP), HL
                    when 5 => null; ex(state, f, dehl); -- EX DE, HL
                    when 6 => null; -- DI
                    when 7 => null; -- EI
                    end case;
                when 4 => null; -- CALL cc[y], nn
                when 5 => null;
                    case s.q is
                    when 0 => null; -- PUSH rp2[p]
                    when 1 =>
                        case s.p is
                        when 0 => null; -- CALL nn
                        when 1 => fetch_multi(state, f); -- (DD)
                        when 2 => fetch_multi(state, f); -- (ED)
                        when 3 => fetch_multi(state, f); -- (FD)
                        end case;
                    end case;
                when 6 => null; alu_a_n(state, f, alu(s.y)); -- alu[y] n
                when 7 => null; -- RST y*8
                end case;
            end case;
        when ed =>
            case s.x is 
            when 1 =>
                case s.z is
                when 0 =>
                    case s.y is
                    when 6 => null; -- IN (C)
                    when others => null; -- IN r[y], (C)
                    end case;
                when 1 =>
                    case s.y is
                    when 6 => null; -- OUT (C), 0
                    when others => null; -- OUT r[y], (C)
                    end case;
                when 2 =>
                    case s.q is
                    when 0 => null; -- SBC HL, rp[p]
                    when 1 => null; -- ADC HL, rp[p]
                    end case;
                when 3 =>
                    case s.q is
                    when 0 => null; -- LD (nn), rp[p]
                    when 1 => null; -- LD rp[p], (nn)
                    end case;
                when 4 => alu_af(state, f, neg_i) ; -- NEG;
                when 5 =>
                    case s.y is
                    when 1 => null; -- RETI
                    when others => null; -- RETN
                    end case;
                when 6 => null; -- IM im[y]
                when 7 =>
                    case s.y is
                    when 0 => null; -- LD I, A
                    when 1 => null; -- LD R, A
                    when 2 => null; -- LD A, I
                    when 3 => null; -- LD A, R
                    when 4 => null; -- RRD
                    when 5 => null; -- RLD
                    when 6|7 => nop(state, f);
                    end case;
                end case;
            when 2 =>
                case s.y is
                when 4|5|6|7 => null; -- bli[y,z]
                when others => null; -- NONI
                end case;
            when 0|3 => null; end case; -- NONI
        when cb =>
            case s.x is
            when 0 => bit_r(state, f, rot(s.y), 0, s.z);
            when 1 => bit_r(state, f, bit_i, s.y, s.z);
            when 2 => bit_r(state, f, res_i, s.y, s.z);
            when 3 => bit_r(state, f, set_i, s.y, s.z);
            end case;
        when ddcb|fdcb =>
            case s.x is
            when 0 =>
                case s.z is
                when 6 => -- rot[y] (IX/Y+d)
                when others => -- LD r[z], rot[y] (IX/Y+d)
                end case;
            when 1 => -- BIT y, (IX/Y+d)
            when 2 =>
                case s.z is
                when 6 => -- res y, (IX/Y+d)
                when others => -- LD r[z], res y, (IX/Y+d)
                end case;
            when 3 =>
                case s.z is
                when 6 => -- set y, (IX/Y+d)
                when others => -- LD r[z], set y, (IX/Y+d)
                end case;
            end case;
        when dd|fd => null; -- TODO
        when wz => null;
        end case;

        return f;
    end decode;
begin
    -- split instruction as
    --     | p | |q|
    -- |1 0|0 0| |0|1 1 1|
    -- | x |   y   |  z  |
    split.x <= to_integer(unsigned(instr(7 downto 6)));
    split.y <= to_integer(unsigned(instr(5 downto 3)));
    split.z <= to_integer(unsigned(instr(2 downto 0)));
    split.p <= to_integer(unsigned(instr(5 downto 4)));
    split.q <= 1 when instr(3) = '1' else 0;

    -- decode and determine control word
    f <= decode(state, instr, cbi, split);
    cw <= f.cw;
    cbo <= f.cb;
    ctrl <= f.ct;

    -- set conditions
    state.cc(NZ_c) <= flags(Z_F) = '0';
    state.cc(Z_c)  <= flags(Z_f) = '1';
    state.cc(NC_c) <= flags(C_f) = '0';
    state.cc(C_c)  <= flags(C_f) = '1';
    state.cc(PO_c) <= flags(PV_f) = '0';
    state.cc(PE_c) <= flags(PV_f) = '1';
    state.cc(P_c)  <= flags(S_f) = '0';
    state.cc(M_c)  <= flags(S_f) = '1';

    -- determine state
    process(clk) begin
        if rising_edge(clk) then
            if ctrl.cycle_end = '1' then
                state.t <= t1;
            elsif cbi.wt /= '1' then
                state.t <= state.t + 1;
            end if;

            if ctrl.instr_end = '1' then
                state.m <= m1;
                if ctrl.jump = '1' then
                    state.mode <= wz;
                else
                    state.mode <= main;
                end if;
            elsif ctrl.cycle_end = '1' then
                state.m <= state.m + 1;
            end if;

            if ctrl.mode_end = '1' then
                case state.mode is
                when main =>
                    case instr is
                    when x"ed" => state.mode <= ed;
                    when x"cb" => state.mode <= cb;
                    when x"dd" => state.mode <= dd;
                    when x"fd" => state.mode <= fd;
                    when others => null; end case;
                when dd =>
                    case instr is
                    when x"cb" => state.mode <= ddcb;
                    when others => null; end case;
                when fd =>
                    case instr is
                    when x"cb" => state.mode <= fdcb;
                    when others => null; end case;
                when wz =>
                    state.mode <= main;
                when others => null; end case;
            end if;

            if cbi.reset = '1' then
                state.mode <= main;
                state.m <= m1;
                state.t <= t1;
            end if;
        end if;
    end process;

    dbg_id.state <= state;
    dbg_id.ctrl <= ctrl;
 end Behavioral;
