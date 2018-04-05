library IEEE;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

package z80_instr is
    type id_ctrl_t is record
        set_end : std_logic;        -- last state of current set
        cycle_end : std_logic;      -- last state of current cycle
        instr_end : std_logic;      -- last state of current instr
        overlap : std_logic;        -- fetch during this cycle while exec
        multi_word : std_logic;     -- fetch next word of multi-word instr
    end record;

    type id_state_t is record
        set : instr_set_t;
        m : integer;
        t : integer;
    end record;

    -- system
    procedure fetch_multi(signal state : in id_state_t;
                          signal ctrl : out id_ctrl_t);
    -- instr
    procedure nop(signal state : in id_state_t;
                  signal ctrl : out id_ctrl_t);
    procedure ex_af(signal state : in id_state_t;
                    signal ctrl : out id_ctrl_t;
                    signal cw : out ctrlword);
    procedure alu_a_r(signal state : in id_state_t;
                      signal ctrl : out id_ctrl_t;
                      signal cw : out ctrlword;
                      signal reg : in std_logic_vector(2 downto 0));
    procedure bit_r(signal state : id_state_t;
                    signal ctrl : out id_ctrl_t;
                    signal cw : out ctrlword;
                    signal reg : in std_logic_vector(2 downto 0));
end z80_instr;

package body z80_instr is
    procedure fetch_multi(
        signal state : in id_state_t;
        signal ctrl : out id_ctrl_t)
    is begin
        ctrl.multi_word <= '1';
        case state.m is
        when m1 =>
            case state.t is
            -- is 4 tstates for fetch required?
            when t4 =>
                ctrl.cycle_end <= '1';
            when others => null; end case;
        when others =>
            case state.t is
            -- is 4 tstates for fetch required?
            when t3 =>
                ctrl.set_end <= '1';
                ctrl.cycle_end <= '1';
            when others => null; end case;
        end case;
    end fetch_multi;

    procedure nop(
        signal state : in id_state_t;
        signal ctrl : out id_ctrl_t)
    is begin
        case state.t is
        when t4 =>
            ctrl.cycle_end <= '1';
            ctrl.instr_end <= '1';
        when others => null; end case;
    end nop;

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
                ctrl.cycle_end <= '1';
                ctrl.instr_end <= '1';
            when others => null; end case;
        when others => null; end case;
    end ex_af;

    procedure alu_a_r(
        signal state : in id_state_t;
        signal ctrl : out id_ctrl_t;
        signal cw : out ctrlword;
        signal reg : in std_logic_vector(2 downto 0))
    is begin
        case state.m is
        when m1 =>
            case state.t is
            when t4 =>
                cw.act_rd <= '1';           -- read from a to tmp accumulator
                cw.rf_addr <= '0' & reg;    -- select reg
                cw.rf_wrd <= '1';           -- place reg on dbus
                cw.tmp_rd <= '1';           -- read from dbus to tmp
                ctrl.cycle_end <= '1';      -- signal new cycle
            when others => null; end case;
        when m2 =>
            ctrl.overlap <= '1';            -- fetch next instr simultaneously
            case state.t is
            when t2 =>
                cw.alu_wr <= '1';           -- place result on dbus
                cw.f_rd <= '1';             -- read flags from alu
                cw.rf_addr <= "0111";       -- select the A reg
                cw.rf_rdd <= '1';           -- read alu output from dbus
                ctrl.instr_end <= '1';      -- signal instr is done
            when others => null; end case;
        when others => null; end case;
    end alu_a_r;

    procedure bit_r(signal state : id_state_t;
                    signal ctrl: out id_ctrl_t;
                    signal cw : out ctrlword;
                    signal reg : in std_logic_vector(2 downto 0))
    is begin
        case state.m is 
        when m2 =>
            case state.t is
            when t4 =>
                cw.rf_addr <= '0' & reg;
                cw.rf_wrd <= '1';
                cw.tmp_rd <= '1';
                ctrl.cycle_end <= '1';
            when others => null; end case;
        when m3 =>
            ctrl.overlap <= '1';
            case state.t is
            when t2 =>
                cw.alu_wr <= '1';
                cw.f_rd <= '1';
                cw.rf_addr <= '0' & reg;
                cw.rf_rdd <= '1';
                ctrl.instr_end <= '1';
            when others => null; end case;
        when others => null; end case;
    end bit_r;
end z80_instr;
