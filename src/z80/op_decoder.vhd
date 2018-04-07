library IEEE;
use ieee.std_logic_1164.all;
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

    function determine_cword(signal state : id_state_t;
                             signal instr : std_logic_vector(7 downto 0);
                             signal cbi : ctrlbus_in;
                             signal s : id_split_t)
    return id_frame_t is
        variable f : id_frame_t;
    begin
        -- reset all signals to defaults (overwrite below)
        f.ct := (others => '0'); -- reset internal ctrl signals
        f.cb := (others => '0'); -- reset control bus out signals
        f.cw := (rf_addr => "0000",
                 rf_swp => none,
                 alu_set => state.set,
                 alu_op => instr,
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
                    f.cw.rf_addr := "1000";
                    f.cw.rf_wra := '1'; -- use wz instead of pc
                else 
                    f.cw.pc_wr := '1';  -- write pc to abus
                end if;
            when t2 =>
                if state.jump_cycle = '1' then
                    f.cw.rf_addr := "1000";
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
            when "00" =>
                case s.z is
                when "000" =>
                    case s.y is
                    when "000" => nop(state, f);
                    when "001" => ex_af(state, f);
                    when "010" => null; -- DJNZ d
                    when "011" => null; -- JR d
                    when others => null; -- JR cc[y-4] d
                    end case;
                when "001" =>
                    case s.q is
                    when '0' => null; -- LD rp[p], nn
                    when '1' => null; -- ADD hl, rp[p]
                    when others => null; end case;
                when "010" =>
                    case s.q is
                    when '0' => 
                        case s.p is
                        when "00" => null; -- LD (BC), A
                        when "01" => null; -- LD (DE), A
                        when "10" => null; -- LD (nn), HL
                        when "11" => null; -- LD (nn), A
                        when others => null; end case;
                    when '1' => 
                        case s.p is
                        when "00" => null; -- LD A, (BC)
                        when "01" => null; -- LD A, (DE)
                        when "10" => null; -- LD HL, (nn)
                        when "11" => null; -- LD A, (nn)
                        when others => null; end case;
                    when others => null; end case;
                when "011" => -- INC/DEC rp[y];
                when "100"|"101" => -- alu_r(state, f, y); -- INC/DEC r[y]
                when "110" => null; -- LD r[y]
                when "111" => -- alu_af RRLCA/RRCA/RLA/RRA/DAA/CPL/SCF/CCF
                when others => null; end case;
            when "01" =>
                case s.z is
                when "110" =>
                    case s.y is
                    when "110" => null; -- HALT
                    when others => null; -- LD r[y], (hl)
                    end case;
                -- TODO LD (hl), r[z]
                when others => ld_r_r(state, f, s.z, s.y); --LD r[y], r[z]
                end case;
            when "10" => 
                case s.z is
                when "110" => null; -- alu[y] (hl)
                when others => alu_a_r(state, f, s.z); -- alu[y] r[z]
                end case;
            when "11" =>
                case s.z is
                when "000" => null; -- RET cc[y]
                when "001" => null;
                    case s.q is
                    when '0' => null; -- POP rp2[p]
                    when '1' =>
                        case s.p is
                        when "00" => null; -- RET
                        when "01" => null; -- EXX
                        when "10" => null; -- JP HL
                        when "11" => null; -- LD SP, HL
                        when others => null; end case;
                    when others => null; end case;
                when "010" => null; -- JP cc[y], nn
                when "011" =>
                    case s.y is
                    when "000" => jp_nn(state, f);
                    when "001" => fetch_multi(state, f); -- (CB/DDCD/FDCB)
                    when "010" => null; -- OUT (n), A
                    when "011" => null; -- IN A, (n)
                    when "100" => null; -- EX (SP), HL
                    when "101" => null; -- EX DE, HL
                    when "110" => null; -- DI
                    when "111" => null; -- EI
                    when others => null; end case;
                when "100" => null; -- CALL cc[y], nn
                when "101" => null;
                    case s.q is
                    when '0' => null; -- PUSH rp2[p]
                    when '1' =>
                        case s.p is
                        when "00" => null; -- CALL nn
                        when "01" => fetch_multi(state, f); -- (DD)
                        when "10" => fetch_multi(state, f); -- (ED)
                        when "11" => fetch_multi(state, f); -- (FD)
                        when others => null; end case;
                    when others => null; end case;
                when "110" => null; -- alu_a_n(state, f) -- alu[y] n
                when "111" => null; -- RST y*8
                when others => null; end case;
            when others => null; end case;
        when ed =>
            case s.x is 
            when "01" => -- rot[y] r[z]
                case s.z is
                when "000" =>
                    case s.y is
                    when "110" => null; -- IN (C)
                    when others => null; -- IN r[y], (C)
                    end case;
                when "001" =>
                    case s.y is
                    when "110" => null; -- OUT (C), 0
                    when others => null; -- OUT r[y], (C)
                    end case;
                when "010" =>
                    case s.q is
                    when '0' => null; -- SBC HL, rp[p]
                    when '1' => null; -- ADC HL, rp[p]
                    when others => null; end case;
                when "011" =>
                    case s.q is
                    when '0' => null; -- LD (nn), rp[p]
                    when '1' => null; -- LD rp[p], (nn)
                    when others => null; end case;
                when "100" => null; -- NEG;
                when "101" =>
                    case s.y is
                    when "001" => null; -- RETI
                    when others => null; -- RETN
                    end case;
                when "110" => null; -- IM im[y]
                when "111" =>
                    case s.y is
                    when "000" => null; -- LD I, A
                    when "001" => null; -- LD R, A
                    when "010" => null; -- LD A, I
                    when "011" => null; -- LD A, R
                    when "100" => null; -- RRD
                    when "101" => null; -- RLD
                    when others => nop(state, f);
                    end case;
                when others => null; end case;
            when "10" =>
                case s.y is
                when "100"|"101"|"110"|"111" => null; -- bli[y,z]
                when others => null; end case;
            when others => null; end case;
        when cb =>
            bit_r(state, f, s.z);
        when ddcb =>
            case s.z is
            when "110" => null; -- rot/bit/res/set (IX+d)
            when others => null; -- LD r[z], rot/res/set (IX+d)
            end case;
        when fdcb =>
            case s.z is
            when "110" => null; -- rot/bit/res/set (IY+d)
            when others => null; -- LD r[z], rot/res/set (IY+d)
            end case;
        end case;

        return f;
    end determine_cword;
begin
    -- split instruction as
    --     | p | |q|
    -- |1 0|0 0| |0|1 1 1|
    -- | x |   y   |  z  |
    split.x <= instr(7 downto 6);
    split.y <= instr(5 downto 3);
    split.z <= instr(2 downto 0);
    split.p <= instr(5 downto 4);
    split.q <= instr(3);

    -- determine control word (combinational lookup table)
    f <= determine_cword(state, instr, cbi, split);
    cw <= f.cw;
    cbo <= f.cb;
    ctrl <= f.ct;

    -- determine state (synchronously)
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
