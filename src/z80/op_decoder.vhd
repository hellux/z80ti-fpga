library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.z80_instr.all;

entity op_decoder is port(
    clk : in std_logic;
    cbi : in ctrlbus_in;
    cbo : out ctrlbus_out;
    state : in state_t;
    instr : in std_logic_vector(7 downto 0);
    cw : out ctrlword;
    ctrl : out id_ctrl_t);
end op_decoder;

architecture Behavioral of op_decoder is
    type id_split_t is record
        x, p : integer range 0 to 3;
        y, z : integer range 0 to 7;
        q : integer range 0 to 1;
    end record;
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

    signal s : id_split_t;
begin
    -- split instruction as
    --     | p | |q|
    -- |1 0|0 0| |0|1 1 1|
    -- | x |   y   |  z  |
    s.x <= to_integer(unsigned(instr(7 downto 6)));
    s.y <= to_integer(unsigned(instr(5 downto 3)));
    s.z <= to_integer(unsigned(instr(2 downto 0)));
    s.p <= to_integer(unsigned(instr(5 downto 4)));
    s.q <= 1 when instr(3) = '1' else 0;

    -- decode and determine control word
    process(state, s)
        variable f : id_frame_t;
    begin
        -- reset all signals to defaults (overwrite below)
        f.ct := (others => '0'); -- reset internal ctrl signals
        f.cb := (others => '0'); -- reset control bus out signals
        f.cw := (dbus_src => ext_o,
                 abus_src => pc_o,
                 rf_addr => 0,
                 rf_swp => none,
                 alu_op => unknown,
                 alu_bs => 0,
                 addr_op => inc,
                 others => '0');

        -- mem_rd phase
         if state.m = m1 then
            f.cb.m1 := '1';
            mem_rd_instr(state, f);
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
                    when 2 => nop(state, f); -- DJNZ d
                    when 3 => jr_d(state, f);
                    when 4|5|6|7 => jr_cc_d(state, f, s.y-4); -- JR cc[y-4] d
                    end case;
                when 1 =>
                    case s.q is
                    when 0 => ld_rp_nn(state, f, rp(s.p)); -- LD rp[p], nn
                    when 1 => nop(state, f); -- ADD hl, rp[p]
                    end case;
                when 2 =>
                    case s.q is
                    when 0 => 
                        case s.p is
                        when 0 => ld_rpx_a(state, f, regBC); -- LD (BC), A
                        when 1 => ld_rpx_a(state, f, regDE); -- LD (DE), A
                        when 2 => ld_nnx_hl(state, f); -- LD (nn), HL
                        when 3 => ld_nnx_a(state, f); -- LD (nn), A
                        end case;
                    when 1 => 
                        case s.p is
                        when 0 => nop(state, f); -- LD A, (BC)
                        when 1 => nop(state, f); -- LD A, (DE)
                        when 2 => nop(state, f); -- LD HL, (nn)
                        when 3 => nop(state, f); -- LD A, (nn)
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
                when 0 => nop(state, f); -- RET cc[y]
                when 1 => nop(state, f);
                    case s.q is
                    when 0 => nop(state, f); -- POP rp2[p]
                    when 1 =>
                        case s.p is
                        when 0 => nop(state, f); -- RET
                        when 1 => ex(state, f, reg); -- EXX
                        when 2 => jp_hl(state, f); -- JP HL
                        when 3 => ld_sp_hl(state, f); -- LD SP, HL
                        end case;
                    end case;
                when 2 => jp_cc_nn(state, f, s.y); -- JP cc[y], nn
                when 3 =>
                    case s.y is
                    when 0 => jp_nn(state, f);
                    when 1 => mem_rd_multi(state, f); -- (CB/DDCD/FDCB)
                    when 2 => nop(state, f); -- OUT (n), A
                    when 3 => nop(state, f); -- IN A, (n)
                    when 4 => nop(state, f); -- EX (SP), HL
                    when 5 => ex(state, f, dehl); -- EX DE, HL
                    when 6 => nop(state, f); -- DI
                    when 7 => nop(state, f); -- EI
                    end case;
                when 4 => nop(state, f); -- CALL cc[y], nn
                when 5 =>
                    case s.q is
                    when 0 => null; -- PUSH rp2[p]
                    when 1 =>
                        case s.p is
                        when 0 => nop(state, f); -- CALL nn
                        when 1 => mem_rd_multi(state, f); -- (DD)
                        when 2 => mem_rd_multi(state, f); -- (ED)
                        when 3 => mem_rd_multi(state, f); -- (FD)
                        end case;
                    end case;
                when 6 => alu_a_n(state, f, alu(s.y)); -- alu[y] n
                when 7 => nop(state, f); -- RST y*8
                end case;
            end case;
        when ed =>
            case s.x is 
            when 1 =>
                case s.z is
                when 0 =>
                    case s.y is
                    when 6 => nop(state, f); -- IN (C)
                    when others => nop(state, f); -- IN r[y], (C)
                    end case;
                when 1 =>
                    case s.y is
                    when 6 => nop(state, f); -- OUT (C), 0
                    when others => nop(state, f); -- OUT r[y], (C)
                    end case;
                when 2 =>
                    case s.q is
                    when 0 => nop(state, f); -- SBC HL, rp[p]
                    when 1 => nop(state, f); -- ADC HL, rp[p]
                    end case;
                when 3 =>
                    case s.q is
                    when 0 => nop(state, f); -- LD (nn), rp[p]
                    when 1 => nop(state, f); -- LD rp[p], (nn)
                    end case;
                when 4 => alu_af(state, f, neg_i) ; -- NEG;
                when 5 =>
                    case s.y is
                    when 1 => nop(state, f); -- RETI
                    when others => nop(state, f); -- RETN
                    end case;
                when 6 => nop(state, f); -- IM im[y]
                when 7 =>
                    case s.y is
                    when 0 => nop(state, f); -- LD I, A
                    when 1 => nop(state, f); -- LD R, A
                    when 2 => nop(state, f); -- LD A, I
                    when 3 => nop(state, f); -- LD A, R
                    when 4 => nop(state, f); -- RRD
                    when 5 => nop(state, f); -- RLD
                    when 6|7 => nop(state, f);
                    end case;
                end case;
            when 2 =>
                case s.y is
                when 4|5|6|7 => nop(state, f); -- bli[y,z]
                when others => nop(state, f); -- NONI
                end case;
            when 0|3 => nop(state, f); end case; -- NONI
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
                when 6 => nop(state, f); -- rot[y] (IX/Y+d)
                when others => nop(state, f); -- LD r[z], rot[y] (IX/Y+d)
                end case;
            when 1 => nop(state, f); -- BIT y, (IX/Y+d)
            when 2 =>
                case s.z is
                when 6 => nop(state, f); -- res y, (IX/Y+d)
                when others => nop(state, f); -- LD r[z], res y, (IX/Y+d)
                end case;
            when 3 =>
                case s.z is
                when 6 => nop(state, f); -- set y, (IX/Y+d)
                when others => nop(state, f); -- LD r[z], set y, (IX/Y+d)
                end case;
            end case;
        when dd|fd => nop(state, f); -- TODO
        when wz => null;
        end case;

        cw <= f.cw;
        cbo <= f.cb;
        ctrl <= f.ct;
    end process;
 end Behavioral;
