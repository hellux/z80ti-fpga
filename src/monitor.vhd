library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

-- monitor displays registers and current state on FPGA leds, segment display
-- left/right button to select register/bus to display
-- dp:s indicate current selection (see mux below)
-- mstate leftmost bits of leds, tstate rightmost bits of leds

entity monitor is port(
    clk, rst : in std_logic;
    btns : in std_logic_vector(4 downto 0);
    sw : in std_logic_vector(7 downto 0);
    dbg : in dbg_z80_t;
    seg, led : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0));
end monitor;

architecture arch of monitor is
    component segment is port(
        clk, rst : in std_logic;
        value : in std_logic_vector(15 downto 0);
        dp_num : in unsigned(3 downto 0);
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    signal selected : unsigned(3 downto 0) := (others => '0');
    signal seg_value : std_logic_vector(15 downto 0);
    signal abus_src, dbus_src : std_logic_vector(7 downto 0);
begin
    smt : segment port map(clk, btns(1), seg_value, selected, seg, an);

    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                selected <= (others => '0');
            elsif btns(2) = '1' then
                selected <= selected - 1;
            elsif btns(4) = '1' then
                selected <= selected + 1;
            end if;
        end if;
    end process;

    with dbg.abus_src select abus_src <= 
        x"f" when none,
        x"1" when rf_o,
        x"2" when tmpa_o,
        x"3" when pc_o,
        x"4" when dis_o;
    with dbg.dbus_src select dbus_src <= 
        x"f" when none,
        x"1" when rf_o,
        x"2" when tmp_o,
        x"3" when ext_o,
        x"4" when alu_o;

    with selected select seg_value <=
        dbg.regs.bc                 when "0000",
        dbg.regs.de                 when "0001",
        dbg.regs.hl                 when "0010",
        dbg.regs.af                 when "0011",
        dbg.regs.wz                 when "0100",
        dbg.regs.sp                 when "0101",
        dbg.regs.ix                 when "0110",
        dbg.regs.iy                 when "0111",
        dbg.act & dbg.tmp           when "1000",
        dbg.ir & dbg.dbus           when "1001",
        dbg.abus                    when "1010",
        dbg.pc                      when "1011",
        dbus_src & abus_src & x"00" when "1100",
        x"0123"                     when others;

    led(7 downto 5) <= std_logic_vector(to_unsigned(dbg.id.state.m, 3));
    led(4) <= dbg.id.ctrl.cycle_end;
    led(3) <= dbg.id.ctrl.instr_end;
    led(2 downto 0) <= std_logic_vector(to_unsigned(dbg.id.state.t, 3));
end arch;
