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
    signal state : id_state_t := (main, m1, t1, '0', '0');
    signal ctrl : id_ctrl_t := ('0', '0', '0', '0', '0');
    signal f : id_frame_t;

    function determine_cword(signal state : id_state_t;
                             signal instr : std_logic_vector(7 downto 0);
                             signal cbi : ctrlbus_in;
                             signal s : id_split_t)
    return id_frame_t is
        variable f : id_frame_t;
    begin
        f := reset_frame(state, instr);

        if state.m = m1 then
            f.cb.m1 := '1';
        end if;

        if state.m = m1 or              -- always fetch during m1
           state.overlap = '1' or       -- fetch while exec if overlap
           state.multi_word = '1'       -- fetch if multi-word instr
        then
            case state.t is
            when t1 =>
                f.cw.pc_wr := '1';      -- write pc to abus
                f.cw.addr_rd := '1';    -- read from abus to buffer
                f.cw.addr_wr := '1';    -- write from buffer to outside abus
                f.cb.mreq := '1';       -- signal addr is ready on abus
                f.cb.rd := '1';         -- request reading from memory
            when t2 =>
                f.cw.pc_wr := '1';      -- keep pc on abus
                f.cw.addr_wr := '1';    -- keep writing addr to mem
                f.cw.data_rdi := '1';   -- store instr to data buf
                f.cw.pc_rd := '1';      -- read incremented address to pc
                f.cb.mreq := '1';       -- keep request until byte retrieved
                f.cb.rd := '1';         -- keep reading
            when t3 =>
                f.cw.data_wri := '1';   -- write instr to inner dbus from buf
                f.cw.ir_rd := '1';      -- read instr from dbus to ir
            when others => null; end case;
        end if;

        case state.set is
        when main =>
            case s.x is
            when "00" =>
                if (s.z = "000") then
                    if (s.y = "000") then nop(state, f); -- NOP
                    elsif (s.y = x"1") then ex_af(state, f); -- EX AF,AF'
                    elsif (s.y = x"2") then -- DJNZ d
                    elsif (s.y = x"3") then -- JR d
                    elsif (s.y >= x"4" and s.y <= x"7") then -- JR cc[y-4] d
                    end if;
                elsif (s.z = x"1") then
                    if (s.q = '0') then -- LD rp[p], nn
                    elsif (s.q = '1') then -- ADD HL, rp[p]
                    end if;
                elsif (s.z = x"2") then
                    if (s.q = '0') then
                        if (s.p = x"0") then -- LD (BC), A
                        elsif (s.p = x"1") then -- LD (DE), A
                        elsif (s.p = x"2") then -- LD (nn), HL
                        elsif (s.p = x"3") then -- LD (nn), A
                        end if;
                    elsif (s.q = '1') then
                        if (s.p = x"0") then -- LD A, (BC)
                        elsif (s.p = x"1") then -- LD A, (DE)
                        elsif (s.p = x"2") then -- LD HL, (nn)
                        elsif (s.p = x"3") then -- LD A, (nn)
                        end if;
                    end if;
                elsif (s.z = x"3") then
                    if (s.q = '0') then -- INC rp[y]
                    elsif (s.q = '1') then -- DEC rp[y]
                    end if;
                elsif (s.z = x"4") then -- INC r[y]
                elsif (s.z = x"5") then -- DEC r[y]
                elsif (s.z = x"6") then -- LD r[y]
                elsif (s.z = x"7") then
                    if (s.y = x"0") then -- RLCA
                    elsif (s.y = x"1") then -- RRCA
                    elsif (s.y = x"2") then -- RLA
                    elsif (s.y = x"3") then -- RRA
                    elsif (s.y = x"4") then -- DAA
                    elsif (s.y = x"5") then -- CPL
                    elsif (s.y = x"6") then -- SCF
                    elsif (s.y = x"7") then -- CCF
                    end if;
                end if;
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
                if (s.z = x"0") then -- RET cc[y]
                elsif (s.z = x"1") then
                    if (s.q = '0') then -- POP rp2[p]
                    elsif (s.q = '1') then
                        if (s.p = x"0") then -- RET
                        elsif (s.p = x"1") then -- EXX
                        elsif (s.p = x"2") then -- JP HL
                        elsif (s.p = x"3") then -- LD SP, HL
                        end if;
                    end if;
                elsif (s.z = x"2") then -- JP cc[y], nn
                elsif (s.z = "011") then
                    if (s.y = x"0") then -- JP nn
                    elsif (s.y = "001") then fetch_multi(state, f.ct); -- (CB)
                    elsif (s.y = x"2") then -- OUT (n), A
                    elsif (s.y = x"3") then -- IN A, (n)
                    elsif (s.y = x"4") then -- EX (SP), HL
                    elsif (s.y = x"5") then -- EX DE, HL
                    elsif (s.y = x"6") then -- DI
                    elsif (s.y = x"7") then -- EI
                    end if;
                elsif (s.z = x"4") then -- CALL cc[y], nn
                elsif (s.z = x"5") then
                    if (s.q = '0') then -- PUSH rp2[p]
                    elsif (s.q = '1') then
                        if (s.p = x"0") then -- CALL nn
                        elsif (s.p = x"1") then fetch_multi(state, f.ct); -- (DD)
                        elsif (s.p = x"2") then fetch_multi(state, f.ct); -- (ED)
                        elsif (s.p = x"3") then fetch_multi(state, f.ct); -- (FD)
                        end if;
                    end if;
                elsif (s.z = x"6") then -- alu[y] n
                elsif (s.z = x"7") then -- RST y*8
                end if;
            when others => null; end case;
        when ed =>
            case s.x is 
            when "00" => -- rot[y] r[z]
                if (s.z = x"0") then
                    if (s.y < x"6" or s.y = x"7") then -- IN r[y], (C)
                    elsif (s.y = x"6") then -- IN (C)
                    end if;
                elsif (s.z = x"1") then
                    if (s.y < x"6" or s.y = x"7") then -- OUT r[y], (C)
                    elsif (s.y = x"6") then -- OUT (C), 0
                    end if;
                elsif (s.z = x"2") then
                    if (s.q = '0') then -- SBC HL, rp[p]
                    elsif (s.q = '1') then -- ADC HL, rp[p]
                    end if;
                elsif (s.z = x"3") then
                    if (s.q = '0') then -- LD (nn), rp[p]
                    elsif (s.q = '1') then -- LD rp[p], (nn)
                    end if;
                elsif (s.z = x"4") then -- NEG
                elsif (s.z = x"5") then
                    if (s.y = x"0" or s.y > x"1") then -- RETN
                    elsif (s.y = x"1") then -- RETI
                    end if;
                elsif (s.z = x"6") then -- IM im[y]
                elsif (s.z = x"7") then
                    if (s.y = x"0") then -- LD I, A
                    elsif (s.y = x"1") then -- LD R, A
                    elsif (s.y = x"2") then -- LD A, I
                    elsif (s.y = x"3") then -- LD A, R
                    elsif (s.y = x"4") then -- RRD
                    elsif (s.y = x"5") then -- RLD
                    elsif (s.y = x"6") then -- NOP
                    elsif (s.y = x"7") then -- NOP
                    end if;
                end if;
            when "10" =>
                if (s.z <= x"3") then
                    if (s.y >= x"4") then -- bli[y,z]
                    end if;
                end if;
            when others => null; end case;
        when cb =>
            bit_r(state, f, s.z);
        when dd =>
            null; -- TODO
        when ddcb =>
            case s.z is
            when "110" => null; -- rot/bit/res/set[y] (IX+d)
            when others => null; -- LD r[z], rot/res/set[y] (IX+d)
            end case;
        when fd =>
            null; -- TODO
        when fdcb =>
            case s.z is
            when "110" => null; -- rot/bit/res/set[y] (IY+d)
            when others => null; -- LD r[z], rot/res/set[y] (IY+d)
            end case;
        end case;

        return f;
    end determine_cword;
begin
    --     | p | |q|
    -- |1 0|0 0| |0|1 1 1|
    -- | x |   y   |  z  |
    split.x <= instr(7 downto 6);
    split.y <= instr(5 downto 3);
    split.z <= instr(2 downto 0);
    split.p <= instr(5 downto 4);
    split.q <= instr(3);

    -- determine control word
    f <= determine_cword(state, instr, cbi, split);
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
            end if;
            if ctrl.instr_end = '1' then
                state.m <= m1;
                state.set <= main;
            end if;

            if cbi.reset = '1' then
                state.set <= main;
                state.m <= m1;
                state.t <= t1;
            elsif ctrl.set_end = '1' then
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
        end if;
    end process;
 end Behavioral;
