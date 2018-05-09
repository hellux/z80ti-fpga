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
-- ctrl
    rst, step, boot_ld, boot_done : out std_logic;
    break_addr : out std_logic_vector(15 downto 0);
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

-- buttons
    constant CTRL_STEP  : integer := 0;
    constant CTRL_RST   : integer := 1;
    constant CTRL_EDIT  : integer := 2;
    constant CTRL_BLLD  : integer := 3;
    constant CTRL_BLDN  : integer := 4;
    constant EDIT_DONE  : integer := 0;
    constant EDIT_INC   : integer := 1;
    constant EDIT_LEFT  : integer := 2;
    constant EDIT_DEC   : integer := 3;
    constant EDIT_RIGHT : integer := 4;
    
    signal btns_op, btns_s, btns_q : std_logic_vector(4 downto 1);

    type board_state_t is (ctrl, edit);
    type bp_addr_t is array(0 to 3) of unsigned(3 downto 0);

    signal state : board_state_t;
    signal dig_sel : unsigned(1 downto 0);
    signal bp_addr : bp_addr_t;
    signal bp_addr_merge : std_logic_vector(15 downto 0);

    signal seg_dots : std_logic_vector(3 downto 0);
begin
    process(clk) begin
        if rising_edge(clk) then
            btns_s <= btns(4 downto 1);
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
                if btns(CTRL_EDIT) = '1' then
                    state <= edit;
                end if;
            when edit =>
                if btns(EDIT_DONE) = '1' then
                    state <= edit;
                end if;
                if btns_op(EDIT_INC) = '1' then
                    bp_addr(ds) <= bp_addr(ds) + 1;
                end if;
                if btns_op(EDIT_DEC) = '1' then
                    bp_addr(ds) <= bp_addr(ds) - 1;
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

-- ctrl input
    rst       <= bool_sl(state = ctrl) and btns(CTRL_RST);
    step      <= bool_sl(state = ctrl) and btns(CTRL_STEP);
    boot_ld   <= bool_sl(state = ctrl) and btns(CTRL_BLLD);
    boot_done <= bool_sl(state = ctrl) and btns(CTRL_BLDN);

    bp_addr_merge <= std_logic_vector(bp_addr(0)) &
                     std_logic_vector(bp_addr(1)) &
                     std_logic_vector(bp_addr(2)) &
                     std_logic_vector(bp_addr(3));
    break_addr <= bp_addr_merge;

    with dig_sel select
        seg_dots <= "1000" when "00",
                    "0100" when "01",
                    "0010" when "10",
                    "0001" when "11",
                    "----" when others;

    smt : segment port map(clk, bp_addr_merge, seg_dots, seg, an);
end arch;
