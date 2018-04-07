library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.z80_instr.all;

entity op_decoder is port(
    clk : in std_logic;
    cbi : in ctrlbus_in;
    cbo : out ctrlbus_out;
    instr : in std_logic_vector(7 downto 0);
    cw : out ctrlword);
end op_decoder;

architecture Behavioral of op_decoder is
    signal split : id_split_t;
    signal state : id_state_t := (main, m1, t1, others => '0');
    signal ctrl : id_ctrl_t;
    signal f : id_frame_t;

    type rp_table_t is array(0 to 3) of integer;
    type alu_table_t is array(0 to 7) of instr_t;
    constant rp : rp_table_t := (regBC, regDE, regHL, regSP);
    constant rp2 : rp_table_t := (regBC, regDE, regHL, regAF);
    constant alu : alu_table_t := (add_i, adc_i, sub_i, sbc_i,
                                   and_i, xor_i, or_i, cp_i);
    constant rot : alu_table_t := (rlc_i, rrc_i, rl_i, rr_i,
                                   sla_i, sra_i, sll_i, srl_i);

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
                 alu_set => state.set,
                 alu_op => unknown,
                 alu_bs => 0,
                 others => '0');

        -- signal if m1 is active on control bus
        if state.m = m1 then
            f.cb.m1 := '1';
        end if;

        -- fetch phase
        if state.m = m1 or              -- always fetch during m1
           state.overlap = '1' or       -- fetch while exec if overlap
           state.multi_word = '1'       -- fetch if multi-word instr
        then
            fetch(state, f);
            case state.t is
            when t1 =>
                if state.jump_cycle = '1' then
                    f.cw.rf_addr := regWZ;
                    f.cw.rf_wra := '1'; -- use wz instead of pc
                else 
                    f.cw.pc_wr := '1';  -- write pc to abus
                end if;
            when t2 =>
                if state.jump_cycle = '1' then
                    f.cw.rf_addr := regWZ;
                    f.cw.rf_wra := '1'; -- keep wz on abus for incr
                else 
                    f.cw.pc_wr := '1';  -- keep pc on abus
                end if;
                f.cw.pc_rd := '1';      -- read incremented address to pc
            when t3 =>
                f.cw.ir_rd := '1';      -- read instr from dbus to ir
            when others => null; end case;
        end if;

        -- exec phase
        case state.set is
        when main|dd|fd =>
            case s.x is
            when 0 =>
                case s.z is
                when 0 =>
                    case s.y is
                    when 0 => nop(state, f);
                    when 1 => ex_af(state, f);
                    when 2 => null; -- DJNZ d
                    when 3 => null; -- JR d
                    when others => null; -- JR cc[y-4] d
                    end case;
                when 1 =>
                    case s.q is
                    when 0 => null; -- LD rp[p], nn
                    when 1 => null; -- ADD hl, rp[p]
                    when others => null; end case;
                when 2 =>
                    case s.q is
                    when 0 => 
                        case s.p is
                        when 0 => null; -- LD (BC), A
                        when 1 => null; -- LD (DE), A
                        when 2 => null; -- LD (nn), HL
                        when 3 => null; -- LD (nn), A
                        when others => null; end case;
                    when 1 => 
                        case s.p is
                        when 0 => null; -- LD A, (BC)
                        when 1 => null; -- LD A, (DE)
                        when 2 => null; -- LD HL, (nn)
                        when 3 => null; -- LD A, (nn)
                        when others => null; end case;
                    when others => null; end case;
                when 3 => -- INC/DEC rp[y];
                    case s.q is
                    when 0 => null; -- INC rp[y]
                    when 1 => null; -- DEC rp[y]
                    when others => end case;
                when 4 => -- alu_r(state, f, inc_i, y); -- INC r[y]
                when 5 => -- alu_r(state, f, dec_i, y); -- DEC r[y]
                when 6 => null; -- LD r[y]
                when 7 =>
                    case s.y is
                    when 0 => --alu_af(state, f, rrlc_i); -- RRLCA
                    when 1 => --alu_af(state, f, rrc_i); -- RRCA
                    when 2 => --alu_af(state, f, rla_i); -- RLA
                    when 3 => --alu_af(state, f, rra_i); -- RRA
                    when 4 => --alu_af(state, f, daa_i); -- DAA 
                    when 5 => --alu_af(state, f, cpl_i); -- CPL
                    when 6 => --alu_af(state, f, scf_i); -- SCF
                    when 7 => --alu_af(state, f, ccf_i); -- CCF
                    when others => null; end case;
                when others => null; end case;
            when 1 =>
                case s.z is
                when 6 =>
                    case s.y is
                    when 6 => null; -- HALT
                    when others => null; -- LD r[y], (hl)
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
                        when 1 => null; -- EXX
                        when 2 => null; -- JP HL
                        when 3 => null; -- LD SP, HL
                        when others => null; end case;
                    when others => null; end case;
                when 2 => null; -- JP cc[y], nn
                when 3 =>
                    case s.y is
                    when 0 => jp_nn(state, f);
                    when 1 => fetch_multi(state, f); -- (CB/DDCD/FDCB)
                    when 2 => null; -- OUT (n), A
                    when 3 => null; -- IN A, (n)
                    when 4 => null; -- EX (SP), HL
                    when 5 => null; -- EX DE, HL
                    when 6 => null; -- DI
                    when 7 => null; -- EI
                    when others => null; end case;
                when 4 => null; -- CALL cc[y], nn
                when 5 => null;
                    case s.q is
                    when 0 => null; -- PUSH rp2[p]
                    when 1 =>
                        case s.p is
                        when 0 => null; -- CALL nn
                        when 1 => fetch_multi(state, f); -- (DD)
                        when 2 => fetch_multi(state, f); -- (ED)
                        when 4 => fetch_multi(state, f); -- (FD)
                        when others => null; end case;
                    when others => null; end case;
                when 6 => null; -- alu_a_n(state, f) -- alu[y] n
                when 7 => null; -- RST y*8
                when others => null; end case;
            when others => null; end case;
        when ed =>
            case s.x is 
            when 1 => -- rot[y] r[z]
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
                    when others => null; end case;
                when 3 =>
                    case s.q is
                    when 0 => null; -- LD (nn), rp[p]
                    when 1 => null; -- LD rp[p], (nn)
                    when others => null; end case;
                when 4 => null; -- NEG;
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
                    when others => nop(state, f);
                    end case;
                when others => null; end case;
            when 2 =>
                case s.y is
                when 4|5|6|7 => null; -- bli[y,z]
                when others => null; end case;
            when others => null; end case;
        when cb =>
            case s.x is
            when 0 => bit_r(state, f, rot(s.y), 0, s.z);
            when 1 => bit_r(state, f, bit_i, s.y, s.z);
            when 2 => bit_r(state, f, res_i, s.y, s.z);
            when 3 => bit_r(state, f, set_i, s.y, s.z);
            when others => null; end case;
        when ddcb|fdcb =>
            case s.x is
            when 0 =>
                case s.z is
                when 6 => -- rot[y] (IX/Y+d)
                when others => -- LD r[z], rot[y] (IX/Y+d)
                end case;
            when 1 =>
                -- BIT y, (IX/Y+d)
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
            when others => null; end case;
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

    -- determine state
    state.overlap <= f.ct.overlap;
    state.multi_word <= f.ct.multi_word;
    process(clk) begin
        if rising_edge(clk) then
            if cbi.wt /= '1' then
                state.t <= state.t + 1;
            end if;

            if ctrl.cycle_end = '1' then
                state.t <= t1;
                state.m <= state.m + 1;
                state.jump_cycle <= ctrl.jump;
            end if;

            if ctrl.instr_end = '1' then
                state.m <= m1;
                state.set <= main;
            end if;

            if ctrl.set_end = '1' then
                case state.set is
                when main =>
                    case instr is
                    when x"ed" => state.set <= ed;
                    when x"cb" => state.set <= cb;
                    when x"dd" => state.set <= dd;
                    when x"fd" => state.set <= fd;
                    when others => null; end case;
                when dd =>
                    case instr is
                    when x"cb" => state.set <= ddcb;
                    when others => null; end case;
                when fd =>
                    case instr is
                    when x"cb" => state.set <= fdcb;
                    when others => null; end case;
                when others => null; end case;
            end if;

            if cbi.reset = '1' then
                state.set <= main;
                state.m <= m1;
                state.t <= t1;
            end if;
        end if;
    end process;
 end Behavioral;
