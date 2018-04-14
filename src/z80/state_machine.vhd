library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity state_machine is port(
    clk : in std_logic;
    cbi : in ctrlbus_in;
    instr, flags : in std_logic_vector(7 downto 0);
    ctrl : in id_ctrl_t;
    state_out : out state_t);
end state_machine;

architecture arch of state_machine is
    signal state : state_t;
begin 
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

    state.cc(NZ_c) <= flags(Z_F) = '0';
    state.cc(Z_c)  <= flags(Z_f) = '1';
    state.cc(NC_c) <= flags(C_f) = '0';
    state.cc(C_c)  <= flags(C_f) = '1';
    state.cc(PO_c) <= flags(PV_f) = '0';
    state.cc(PE_c) <= flags(PV_f) = '1';
    state.cc(P_c)  <= flags(S_f) = '0';
    state.cc(M_c)  <= flags(S_f) = '1';

    state_out <= state;
end arch;