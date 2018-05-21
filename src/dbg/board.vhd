library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.cmp_comm.all;
use work.util.all;

entity board is port(
    clk : in std_logic;
-- input
    btns : in std_logic_vector(4 downto 0);
    num_disp : in std_logic_vector(15 downto 0);
-- ctrl
    rst, step, trc_en, trc_di : out std_logic;
    num_sel : out std_logic_vector(15 downto 0);
    num_new : out std_logic;
-- segment
    seg : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0));
end board;

architecture arch of board is
    component segment is port(
        clk : in std_logic;
        value : in std_logic_vector(15 downto 0);
        dp_num : in std_logic_vector(3 downto 0);
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    constant BUTTON_MIDDLE : natural := 0;
    constant BUTTON_UP     : natural := 1;
    constant BUTTON_LEFT   : natural := 2;
    constant BUTTON_DOWN   : natural := 3;
    constant BUTTON_RIGHT  : natural := 4;

    constant CTRL_STEP     : natural := BUTTON_MIDDLE;
    constant CTRL_RST      : natural := BUTTON_UP;
    constant CTRL_EDIT     : natural := BUTTON_LEFT;
    constant CTRL_TRC_EN   : natural := BUTTON_RIGHT;
    constant CTRL_TRC_DI   : natural := BUTTON_DOWN;
    constant EDIT_DONE     : natural := BUTTON_MIDDLE;
    constant EDIT_INC      : natural := BUTTON_UP;
    constant EDIT_LEFT     : natural := BUTTON_LEFT;
    constant EDIT_DEC      : natural := BUTTON_DOWN;
    constant EDIT_RIGHT    : natural := BUTTON_RIGHT;

    constant COOLDOWN_TIME : natural := 1000; -- us
    constant CD_INIT : natural := SYS_FREQ/10**6 * COOLDOWN_TIME;
    
    type board_state_t is (ctrl, edit);
    type seg_num_t is array(0 to 3) of unsigned(3 downto 0);

    -- button one op
    signal btns_op, btns_s, btns_q : std_logic_vector(4 downto 0);

    -- board state
    signal state : board_state_t := ctrl;
    signal dig_sel : unsigned(1 downto 0) := "00";
    signal seg_num : seg_num_t := (x"9", x"d", x"9", x"5");

    -- convertion signals
    signal seg_num_merge : std_logic_vector(15 downto 0);
    signal seg_value : std_logic_vector(15 downto 0);
    signal seg_dots : std_logic_vector(3 downto 0);
begin
    process(clk) begin
        if rising_edge(clk) then
            btns_s <= btns;
            btns_q <= btns_s;
        end if;
    end process;
    btns_op <= btns_s and not btns_q;

    process(clk)
        variable ds : integer range 0 to 3;
    begin
        if rising_edge(clk) then
            ds := to_integer(dig_sel);

            case state is
            when ctrl =>
                num_new <= '0';
                if btns(CTRL_EDIT) = '1' then
                    state <= edit;
                end if;
            when edit =>
                if btns(EDIT_DONE) = '1' then
                    state <= ctrl;
                    num_new <= '1';
                end if;
                if btns_op(EDIT_INC) = '1' then
                    seg_num(ds) <= seg_num(ds) + 1;
                end if;
                if btns_op(EDIT_DEC) = '1' then
                    seg_num(ds) <= seg_num(ds) - 1;
                end if;
                if btns_op(EDIT_LEFT) = '1' then
                    dig_sel <= dig_sel - 1;
                end if;
                if btns_op(EDIT_RIGHT) = '1' then
                    dig_sel <= dig_sel + 1;
                end if;
            end case;
        end if;
    end process;

    -- ctrl signals
    rst    <= bool_sl(state = ctrl) and btns(CTRL_RST);
    step   <= bool_sl(state = ctrl) and btns(CTRL_STEP);
    trc_en <= bool_sl(state = ctrl) and btns(CTRL_TRC_EN);
    trc_di <= bool_sl(state = ctrl) and btns(CTRL_TRC_DI);

    -- addr
    seg_num_merge <= std_logic_vector(seg_num(0)) &
                     std_logic_vector(seg_num(1)) &
                     std_logic_vector(seg_num(2)) &
                     std_logic_vector(seg_num(3));
    num_sel <= seg_num_merge;

    -- segment display
    seg_dots <= "0000" when state /= edit else
                "1000" when dig_sel = "00" else
                "0100" when dig_sel = "01" else
                "0010" when dig_sel = "10" else
                "0001" when dig_sel = "11" else "----";
    seg_value <= seg_num_merge when state = edit else num_disp;
    smt : segment port map(clk, seg_value, seg_dots, seg, an);
end arch;
