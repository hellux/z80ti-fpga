library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cmp_comm.all;

-- monitor displays registers and current state on FPGA leds, segment display
-- left/right button to select register/bus to display
-- dp:s indicate current selection (see mux below)
-- mstate leftmost bits of leds, tstate rightmost bits of leds

entity monitor is port(
    clk : in std_logic;
    sw : in std_logic_vector(5 downto 0);
    dbg : in dbg_cmp_t;
    seg, led : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0));
end monitor;

architecture arch of monitor is
    component segment is port(
        clk : in std_logic;
        value : in std_logic_vector(15 downto 0);
        dp_num : in std_logic_vector(3 downto 0);
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    signal selected_val : std_logic_vector(3 downto 0);
    signal seg_value : std_logic_vector(15 downto 0);
    signal selected_dot : std_logic_vector(1 downto 0);
    signal seg_dots : std_logic_vector(3 downto 0);
begin
    smt : segment port map(clk, seg_value, seg_dots, seg, an);

    selected_dot <= sw(5 downto 4);
    selected_val <= sw(3 downto 0);

    with selected_dot select seg_dots <=
        dbg.cbi.int &
        dbg.on_key_down &
        dbg.mem_rd &
        dbg.mem_wr
            when "00",
        dbg.z80.ct.cycle_end &
        dbg.z80.ct.instr_end & 
        "00"
            when "01",
        "0000" when others;

    with selected_val select seg_value <=
        dbg.z80.regs.af                                 when "0000",
        dbg.z80.regs.bc                                 when "0001",
        dbg.z80.regs.de                                 when "0010",
        dbg.z80.regs.hl                                 when "0011",
        dbg.z80.regs.sp                                 when "0100",
        dbg.z80.regs.ix                                 when "0101",
        dbg.z80.regs.iy                                 when "0110",
        dbg.z80.regs.wz                                 when "0111",
        dbg.z80.act & "00" & dbg.addr_phy(19 downto 16) when "1000",
        dbg.z80.ir & dbg.z80.dbus                       when "1001",
        dbg.z80.abus                                    when "1010",
        dbg.z80.pc                                      when "1011",
        dbg.data & dbg.data_mem                         when "1100",
        dbg.addr_log                                    when "1101",
        dbg.addr_phy(15 downto 0)                       when "1110",
        dbg.scancode & dbg.keycode                      when "1111",
        x"0123"                                         when others;

    led(7 downto 5) <= std_logic_vector(to_unsigned(dbg.z80.state.m, 3));
    led(4) <= dbg.on_key_down;
    led(3) <= dbg.z80.ct.instr_end;
    led(2 downto 0) <= std_logic_vector(to_unsigned(dbg.z80.state.t, 3));
end arch;
