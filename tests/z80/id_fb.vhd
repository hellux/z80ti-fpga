library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity id_fb is port(
    clk, clk_btn, rst : in std_logic;
    seg, led : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0));
end id_fb;

architecture arch of id_fb is
    component op_decoder port(
        clk : in std_logic;
        cbi : in ctrlbus_in;
        cbo : out ctrlbus_out;
        instr, flags : in std_logic_vector(7 downto 0);
        cw : out ctrlword;
        dbg_id : out dbg_id_t);
    end component;

    component segment is port(
        clk, rst : in std_logic;
        value : in std_logic_vector(15 downto 0);
        dp_num : in unsigned(3 downto 0);
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    constant LENGTH : integer := 30;

    type ir_c_t is array(0 to LENGTH) of std_logic_vector(7 downto 0);
    constant ir_c : ir_c_t :=
        (x"00",
         x"cb",
         x"f7",
         x"47", 
         x"87",
         others => x"00");

    signal ir : std_logic_vector(7 downto 0);
    signal seg_value : std_logic_vector(15 downto 0);
    signal cbi : ctrlbus_in;
    signal cbo : ctrlbus_out;
    signal cw : ctrlword;
    signal dbg : dbg_id_t;
    signal pc : integer := 0;
    signal ab_src, db_src : std_logic_vector(3 downto 0);
begin
    process(clk_btn) begin
        if rising_edge(clk_btn) then
            if rst = '1' then
                pc <= 0;
            elsif pc = LENGTH then
                pc <= 0;
            elsif cw.ir_rd = '1' then
                pc <= pc + 1;
            end if;
        end if;
    end process;

    ir <= ir_c(pc);
    cbi <= (reset => rst, others => '0');
    seg_value <= ir & db_src & ab_src;

    with cw.abus_src select ab_src <= 
        x"f" when none,
        x"1" when rf_o,
        x"2" when tmpa_o,
        x"3" when pc_o,
        x"4" when dis_o;
    with cw.dbus_src select db_src <= 
        x"f" when none,
        x"1" when rf_o,
        x"2" when tmp_o,
        x"3" when ext_o,
        x"4" when alu_o;

    id : op_decoder port map(clk, cbi, cbo, ir, x"00", cw, dbg);
    smt : segment port map(clk, rst, seg_value, x"0", seg, an);

    led(7) <= cw.pc_rd;
    led(6) <= cw.ir_rd;
    led(5) <= cw.addr_rd;
    led(4) <= dbg.ctrl.cycle_end;
    led(3) <= dbg.ctrl.instr_end;
    led(2 downto 0) <= std_logic_vector(to_unsigned(dbg.state.t, 3));
end arch;
