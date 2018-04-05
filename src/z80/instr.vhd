library IEEE;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

package z80_instr is
    type id_ctrl_t is record
        new_instr : std_logic;      -- new instr arrived from ir
        finish_cycle : std_logic;   -- last state of current cycle
        finish_instr : std_logic;   -- last state of current instr
        overlap : std_logic;        -- fetch during this cycle while exec
        multi_word : std_logic;     -- fetch next word of multi-word instr
    end record;

    type id_state_t is record
        set : instr_set_t;
        m : integer;
        t : integer;
    end record;

    procedure ex_af(
        signal state : in id_state_t;
        signal ctrl : out id_ctrl_t;
        signal cw : out ctrlword
    );
    procedure alu_r(
        signal state : in id_state_t;
        signal ctrl : out id_ctrl_t;
        signal cw : out ctrlword;
        signal reg : in std_logic_vector(2 downto 0)
    );
end z80_instr;

package body z80_instr is
    procedure ex_af(
        signal state : in id_state_t;
        signal ctrl : out id_ctrl_t;
        signal cw : out ctrlword)
    is begin
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                cw.rf_swp <= "01";
                ctrl.finish_cycle <= '1';
                ctrl.finish_instr <= '1';
            when others => null; end case;
        when others => null; end case;
    end ex_af;

    procedure alu_r(
        signal state : in id_state_t;
        signal ctrl : out id_ctrl_t;
        signal cw : out ctrlword;
        signal reg : in std_logic_vector(2 downto 0))
    is begin
        report "alu_r reacheeeeed";
        case state.m is
        when m1 =>
            report "m1";
            case state.t is
            when 4 =>
                report "m1t4";
                cw.act_rd <= '1'; -- read from a to tmp accumulator
                cw.rf_addr <= '0' & reg; -- select reg
                cw.rf_wrd <= '1'; -- place reg on dbus
                cw.tmp_rd <= '1'; -- read from dbus to tmp
                ctrl.finish_cycle <= '1'; -- signal new cycle
            when others => report "tstate: " & integer'image(state.t); end case;
        when m2 =>
            ctrl.overlap <= '1'; -- fetch next instr simultaneously
            case state.t is
            when t2 =>
                cw.alu_wr <= '1'; -- place result on dbus
                cw.f_rd <= '1'; -- read flags from alu
                cw.rf_addr <= "0111"; -- select a reg
                cw.rf_rdd <= '1'; -- read alu output from dbus
                ctrl.finish_instr <= '1'; -- signal instr is done
            when others => null; end case;
        when others => null; end case;
    end alu_r;
end z80_instr;
