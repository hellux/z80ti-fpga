library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.cmp_comm.all;
use work.util.all;

entity monitor is port(
    clk : in std_logic;
    sel : in std_logic_vector(3 downto 0);
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

    signal dots_int : std_logic_vector(3 downto 0);
    signal dots_cbo : std_logic_vector(3 downto 0);
    signal dots_cond : std_logic_vector(3 downto 0);
    signal dots_prefix : std_logic_vector(3 downto 0);
    signal dots_mode : std_logic_vector(1 downto 0);
    signal dots_mem : std_logic_vector(1 downto 0);

    signal seg_value : std_logic_vector(15 downto 0);
    signal seg_dots : std_logic_vector(3 downto 0);
begin
    smt : segment port map(clk, seg_value, seg_dots, seg, an);

    dots_int <= dbg.cbi.int & dbg.z80.state.iff &
                std_logic_vector(to_unsigned(dbg.z80.state.im, 2));
    dots_cbo <= dbg.cbo.mreq & dbg.cbo.iorq & dbg.cbo.rd & dbg.cbo.wr;
    dots_cond <= bool_sl(dbg.z80.state.cc(1)) & -- ZERO
                 bool_sl(dbg.z80.state.cc(3)) & -- CARRY
                 bool_sl(dbg.z80.state.cc(5)) & -- PARITY / OVERFLOW
                 bool_sl(dbg.z80.state.cc(7));  -- SIGN NEGATIVE
    with dbg.z80.state.prefix select
        dots_prefix <= "0000" when main,
                       "0001" when ed,
                       "0010" when cb,
                       "0011" when dd,
                       "0100" when ddcb,
                       "0101" when fd,
                       "0110" when fdcb,
                       "0111" when ddcb_d,
                       "1000" when fdcb_d;
    with dbg.z80.state.mode select
        dots_mode <= "00" when exec,
                     "01" when wz,
                     "10" when halt,
                     "11" when int;
    dots_mem <= dbg.mem_rd & dbg.mem_wr;

    with sel select seg_dots <=
        dots_int                when "0000",
        dots_cbo                when "0001",
        dots_cond               when "0010",
        dots_prefix             when "0011",
        dots_mode & dots_mem    when "0100",
        "0000"                  when others;

    with sel select seg_value <=
        dbg.z80.regs.af                                 when "0000",
        dbg.z80.regs.bc                                 when "0001",
        dbg.z80.regs.de                                 when "0010",
        dbg.z80.regs.hl                                 when "0011",
        dbg.z80.regs.sp                                 when "0100",
        dbg.z80.regs.ix                                 when "0101",
        dbg.z80.regs.iy                                 when "0110",
        dbg.z80.regs.wz                                 when "0111",
        dbg.z80.act & dbg.z80.tmp                       when "1000",
        dbg.z80.ir & dbg.z80.dbus                       when "1001",
        dbg.z80.abus                                    when "1010",
        dbg.z80.pc                                      when "1011",
        dbg.data & x"0" & dbg.addr_phy(19 downto 16)    when "1100",
        dbg.addr_log                                    when "1101",
        dbg.addr_phy(15 downto 0)                       when "1110",
        dbg.scancode & dbg.keycode                      when "1111",
        x"0123"                                         when others;

    led(7 downto 5) <= std_logic_vector(to_unsigned(dbg.z80.state.m, 3));
    led(4) <= dbg.cbo.halt;
    led(3) <= dbg.cbo.m1;
    led(2 downto 0) <= std_logic_vector(to_unsigned(dbg.z80.state.t, 3));
end arch;
