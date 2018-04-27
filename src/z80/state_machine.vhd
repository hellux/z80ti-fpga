library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity state_machine is port(
    clk : in std_logic;
    cbi : in ctrlbus_in;
    flags : in std_logic_vector(7 downto 0);
    iff : in std_logic;
    ctrl : in id_ctrl_t;
    state_out : out state_t);
end state_machine;

architecture arch of state_machine is
    signal state : state_t;
begin 
    process(clk) begin
        if rising_edge(clk) then
            -- set t state
            if ctrl.cycle_end = '1' then
                state.t <= t1;
            elsif cbi.wt /= '1' then
                state.t <= state.t + 1;
            end if;

            -- set m state
            if ctrl.instr_end = '1' then
                state.m <= m1;
            elsif ctrl.cycle_end = '1' then
                state.m <= state.m + 1;
            end if;

            -- set mode
            if cbi.int = '1' then
                state.mode <= int;
            else
                state.mode <= ctrl.mode_next;
            end if;

            -- set prefix
            if ctrl.instr_end = '1' then
                state.prefix <= ctrl.prefix_next;
            end if;

            -- reset
            if cbi.reset = '1' then
                state.im <= 0;
                state.mode <= exec;
                state.prefix <= main;
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

    state.iff <= iff;

    state_out <= state;
end arch;
