library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.z80_instr.all;

entity op_decoder is port(
    clk, rst : in std_logic;
    instr : in std_logic_vector(7 downto 0);
    cw : out ctrlword);
end op_decoder;

architecture Behavioral of op_decoder is
    signal x, p : std_logic_vector(1 downto 0);
    signal y, z : std_logic_vector(2 downto 0);
    signal q : std_logic;
    signal state : id_state_t := (main, m1, t1);
    signal ctrl : id_ctrl_t := ('0', '0', '0', '0', '0');
 begin
    --     | p | |q|
    -- |1 0|0 0| |0|1 1 1|
    -- | x |   y   |  z  |
    x <= instr(7 downto 6);
    y <= instr(5 downto 3);
    z <= instr(2 downto 0);
    p <= instr(5 downto 4);
    q <= instr(3);

    -- determine set
    process(clk) begin
        if rising_edge(clk) then
            state.t <= state.t + 1;
            if ctrl.finish_instr = '1' then state.m <= m1; end if;
            if ctrl.finish_cycle = '1' then
                state.t <= t1;
                state.m <= state.m + 1;
            end if;

            if rst = '1' then
                state.set <= main;
                state.m <= m1;
                state.t <= t1;
            elsif ctrl.new_instr = '1' then
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

    -- TODO update below process with state, instr change
    --      (now middle of clock first time even though state changes?)
    -- determine control word
    process(clk, state, instr, ctrl) begin
        -- reset internal ctrl signals
        ctrl.overlap <= '0';
        ctrl.new_instr <= '0';
        ctrl.finish_instr <= '0';
        ctrl.finish_cycle <= '0';

        -- reset control word
        cw.rf_addr <= "0000";
        cw.rf_rdd <= '0';
        cw.rf_wrd <= '0';
        cw.rf_rda <= '0';
        cw.rf_wra <= '0';
        cw.rf_swp <= "00";
        cw.f_rd <= '0';
        cw.f_wr <= '0';
        cw.f_swp <= '0';
        cw.alu_wr <= '0';
        cw.alu_set <= state.set; -- may overwrite this for internal alu use
        cw.alu_op <= instr; -- same.
        cw.act_rd <= '0';
        cw.tmp_rd <= '0';
        cw.ir_rd <= '0';
        cw.pc_rd <= '0';
        cw.pc_wr <= '0';

        -- fetch
        if state.m = m1 or              -- always fetch during m1
           ctrl.overlap = '1' or        -- fetch while exec
           ctrl.multi_word = '1'        -- fetch multi-word instr
        then
            case state.t is
            when t1 =>
                cw.pc_wr <= '1';        -- write pc to abus
            when t2 =>
                cw.pc_wr <= '1';        -- keep pc on abus
                cw.pc_rd <= '1';        -- read incremented address to pc
            when t3 =>
                cw.ir_rd <= '1';        -- read instr from dbus to ir
            when t4 =>
                ctrl.new_instr <= '1';  -- signal new instr arrived 
                ctrl.multi_word <= '0';
            when others => null; end case;
        end if;

        -- execute
        case state.set is
        when main =>
            case x is
            when "00" =>
                if (z = x"0") then
                    if (y = x"0") then -- NOP
                    elsif (y = x"1") then ex_af(state, ctrl, cw); -- EX AF,AF'
                    elsif (y = x"2") then -- DJNZ d
                    elsif (y = x"3") then -- JR d
                    elsif (y >= x"4" and y <= x"7") then -- JR cc[y-4] d
                    end if;
                elsif (z = x"1") then
                    if (q = '0') then -- LD rp[p], nn
                    elsif (q = '1') then -- ADD HL, rp[p]
                    end if;
                elsif (z = x"2") then
                    if (q = '0') then
                        if (p = x"0") then -- LD (BC), A
                        elsif (p = x"1") then -- LD (DE), A
                        elsif (p = x"2") then -- LD (nn), HL
                        elsif (p = x"3") then -- LD (nn), A
                        end if;
                    elsif (q = '1') then
                        if (p = x"0") then -- LD A, (BC)
                        elsif (p = x"1") then -- LD A, (DE)
                        elsif (p = x"2") then -- LD HL, (nn)
                        elsif (p = x"3") then -- LD A, (nn)
                        end if;
                    end if;
                elsif (z = x"3") then
                    if (q = '0') then -- INC rp[y]
                    elsif (q = '1') then -- DEC rp[y]
                    end if;
                elsif (z = x"4") then -- INC r[y]
                elsif (z = x"5") then -- DEC r[y]
                elsif (z = x"6") then -- LD r[y]
                elsif (z = x"7") then
                    if (y = x"0") then -- RLCA
                    elsif (y = x"1") then -- RRCA
                    elsif (y = x"2") then -- RLA
                    elsif (y = x"3") then -- RRA
                    elsif (y = x"4") then -- DAA
                    elsif (y = x"5") then -- CPL
                    elsif (y = x"6") then -- SCF
                    elsif (y = x"7") then -- CCF
                    end if;
                end if;
            when "01" =>
                if (z /= x"6") then --LD r[y], r[z]
                elsif (z = x"6") then
                    if (y = x"6") then -- HALT
                    end if;
                end if;
            when "10" => 
                case z is
                when "110" => null; -- TODO alu_hl(state, ctrl, cw);
                when others => alu_r(state, ctrl, cw, z); -- alu[y] r[z]
                end case;
            when "11" =>
                if (z = x"0") then -- RET cc[y]
                elsif (z = x"1") then
                    if (q = '0') then -- POP rp2[p]
                    elsif (q = '1') then
                        if (p = x"0") then -- RET
                        elsif (p = x"1") then -- EXX
                        elsif (p = x"2") then -- JP HL
                        elsif (p = x"3") then -- LD SP, HL
                        end if;
                    end if;
                elsif (z = x"2") then -- JP cc[y], nn
                elsif (z = "011") then
                    if (y = x"0") then -- JP nn
                    elsif (y = "001") then -- (CB)
                        ctrl.finish_cycle <= '1';
                        ctrl.multi_word <= '1';
                    elsif (y = x"2") then -- OUT (n), A
                    elsif (y = x"3") then -- IN A, (n)
                    elsif (y = x"4") then -- EX (SP), HL
                    elsif (y = x"5") then -- EX DE, HL
                    elsif (y = x"6") then -- DI
                    elsif (y = x"7") then -- EI
                    end if;
                elsif (z = x"4") then -- CALL cc[y], nn
                elsif (z = x"5") then
                    if (q = '0') then -- PUSH rp2[p]
                    elsif (q = '1') then
                        if (p = x"0") then -- CALL nn
                        elsif (p = x"1") then ctrl.multi_word <= '1'; -- (DD)
                        elsif (p = x"2") then ctrl.multi_word <= '1'; -- (ED)
                        elsif (p = x"3") then ctrl.multi_word <= '1'; -- (FD)
                        end if;
                    end if;
                elsif (z = x"6") then -- alu[y] n
                elsif (z = x"7") then -- RST y*8
                end if;
            when others => null; end case;
        when ed =>
            case x is 
            when "00" => -- rot[y] r[z]
                if (z = x"0") then
                    if (y < x"6" or y = x"7") then -- IN r[y], (C)
                    elsif (y = x"6") then -- IN (C)
                    end if;
                elsif (z = x"1") then
                    if (y < x"6" or y = x"7") then -- OUT r[y], (C)
                    elsif (y = x"6") then -- OUT (C), 0
                    end if;
                elsif (z = x"2") then
                    if (q = '0') then -- SBC HL, rp[p]
                    elsif (q = '1') then -- ADC HL, rp[p]
                    end if;
                elsif (z = x"3") then
                    if (q = '0') then -- LD (nn), rp[p]
                    elsif (q = '1') then -- LD rp[p], (nn)
                    end if;
                elsif (z = x"4") then -- NEG
                elsif (z = x"5") then
                    if (y = x"0" or y > x"1") then -- RETN
                    elsif (y = x"1") then -- RETI
                    end if;
                elsif (z = x"6") then -- IM im[y]
                elsif (z = x"7") then
                    if (y = x"0") then -- LD I, A
                    elsif (y = x"1") then -- LD R, A
                    elsif (y = x"2") then -- LD A, I
                    elsif (y = x"3") then -- LD A, R
                    elsif (y = x"4") then -- RRD
                    elsif (y = x"5") then -- RLD
                    elsif (y = x"6") then -- NOP
                    elsif (y = x"7") then -- NOP
                    end if;
                end if;
            when "10" =>
                if (z <= x"3") then
                    if (y >= x"4") then -- bli[y,z]
                    end if;
                end if;
            when others => null; end case;
        when cb =>
            case x is
            when "00" => null; -- rot[y] r[z]
            when "01" => null; -- BIT y, r[z]
                report "bit reached";
            when "10" => null; -- RES y, r[z]
            when "11" => null; -- SET y, r[z]
            when others => null;
            end case;
        when dd =>
            null; -- TODO
        when ddcb =>
            case x is
            when "00" => 
                if (z < x"6" or z = x"7") then -- LD r[z], rot[y] (IX+d)
                elsif (z = x"6") then -- rot[y] (IX+d)
                end if;
            when "01" => null; -- BIT y, (IX+d)
            when "10" =>
                if (z < x"6" or z = x"7") then -- LD r[z], RES y, (IX+d)
                elsif (z = x"6") then -- RES y, (IX+d)
                end if;
            when "11" =>
                if (z < x"6" or z = x"7") then -- LD r[z], SET y, (IX+d)
                elsif (z = x"6") then -- SET y, (IX+d)
                end if;
            when others => null;
            end case;
        when fd =>
            null; -- TODO
        when fdcb =>
            case x is
            when "00" =>
                if (z < x"6" or z = x"7") then -- LD r[z], rot[y] (IY+d)
                elsif (z = x"6") then -- rot[y] (IY+d)
                end if;
            when "01" => null; -- BIT y, (IY+d)
            when "10" =>
                if (z < x"6" or z = x"7") then -- LD r[z], RES y, (IY+d)
                elsif (z = x"6") then -- RES y, (IY+d)
                end if;
            when "11" =>
                if (z < x"6" or z = x"7") then -- LD r[z], SET y, (IY+d)
                elsif (z = x"6") then -- SET y, (IY+d)
                end if;
            when others => null;
            end case;
        end case;
    end process;
 end Behavioral;
