library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.cmp_comm.all;

entity state_machine is port(
    clk, ce : in std_logic;
    cbi : in ctrlbus_in;
    flags : in std_logic_vector(7 downto 0);
    iff : in std_logic;
    ctrl : in id_ctrl_t;
    ir_rd : in std_logic;
    instr : in std_logic_vector(7 downto 0);
    state_out : out state_t);
end state_machine;

architecture arch of state_machine is
    signal state : state_t;
begin 
    process(clk) begin
        if rising_edge(clk) then
            if cbi.reset = '1' then
                state.im <= 0;
                state.mode <= exec;
                state.prefix <= main;
                state.m <= m1;
                state.t <= t1;
            elsif ce = '1' then
                -- set t state
                if ctrl.cycle_end = '1' then
                    state.t <= t1;
                else
                    state.t <= state.t + 1;
                end if;

                -- set m state
                if ctrl.set_m1 = '1' or ctrl.instr_end = '1' then
                    state.m <= m1;
                elsif ctrl.cycle_end = '1' then
                    state.m <= state.m + 1;
                end if;

                -- set mode
                if ctrl.instr_end = '1' and
                   state.iff = '1' and
                   cbi.int = '1'
                then
                    state.mode <= interrupt;
                else
                    state.mode <= ctrl.mode_next;
                end if;

                -- set prefix
                if ir_rd = '1' then
                    case state.prefix is
                    when main =>
                        case instr is
                        when x"ed"  => state.prefix <= ed;
                        when x"cb"  => state.prefix <= cb;
                        when x"dd"  => state.prefix <= dd;
                        when x"fd"  => state.prefix <= fd;
                        when others => state.prefix <= main;
                        end case;
                    when ed => state.prefix <= main;
                    when cb => state.prefix <= main;
                    when dd =>
                        case instr is
                        when x"cb"  => state.prefix <= ddcb;
                        when others => state.prefix <= main;
                        end case;
                    when fd =>
                        case instr is
                        when x"cb"  => state.prefix <= fdcb;
                        when others => state.prefix <= main;
                        end case;
                    when ddcb => state.prefix <= main;
                    when fdcb => state.prefix <= main;
                    when int => state.prefix <= main;
                    end case;

                    if state.mode = interrupt then
                        state.prefix <= int;
                    end if;
                end if;

                -- set im
                if ctrl.instr_end = '1' then
                    state.im <= ctrl.im_next;
                end if;
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

    state.iff <= iff;

    state_out <= state;
end arch;
