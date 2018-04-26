library ieee;
use ieee.std_logic_1164.all;
use work.cmp_comm.all;

entity timers is port(
    clk, clk_z80, rst : in std_logic;
    t1_fi, t1_si, t1_di : in port_t;
    t2_fi, t2_si, t2_di : in port_t;
    t3_fi, t3_si, t3_di : in port_t;
    t1_do, t2_do, t3_do : out std_logic_vector(7 downto 0));
end timers;

architecture arch_timers of timers is
    component cntr generic(size : integer); port(
        clk, rst : in std_logic;
        ce : in std_logic;
        do : out integer range 0 to size-1);
    end component;

    constant CLK_FREQ : integer := 100*10**6;
    constant CLK_DIV : integer := 3052; -- 100Mhz / 3052 ~= 32768Hz
    signal clk_cnt : integer range 0 to CLK_DIV-1;
    signal clk_cry : std_logic; 
begin
    clk_cntr : cntr generic map(CLK_DIV) port map(clk, rst, '1', clk_cnt);
    clk_cry <= '1' when clk_cnt = 0 else '0';
end arch_timers;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cmp_comm.all;
use work.util.all;

entity timer is port(
    clk, clk_cry, clk_z80, rst : in std_logic;
    on_off, loop_ctrl, counter : in port_t);
end timer;

architecture arch_timer of timer is
    component cntr generic(size : integer); port(
        clk, rst : in std_logic;
        ce : in std_logic;
        do : out integer range 0 to size-1);
    end component;
    component ff port(
        clk, rst : in std_logic;
        rd : in std_logic;
        di : in std_logic;
        do : out std_logic);
    end component;

    signal active, active_sel : std_logic;
    signal sel_cntr, sel_cntr_sel : std_logic; -- 0 crystal, 1 z80
    signal div, div_sel, div_next : integer range 1 to 4096;
    signal cnt_cry : integer range 0 to 4095;
    signal cnt_z80: integer range 0 to 63;
    signal clk_timer, clk_timer_cry, clk_timer_z80 : std_logic; -- ripple carry 
    signal expired : std_logic; -- 0 exp, 1 not yet expired
begin
    cry_cntr : cntr generic map(4096) port map(clk_cry, rst, '1', cnt_cry);
    z80_cntr : cntr generic map(64) port map(clk_z80, rst, '1', cnt_z80);
    clk_timer_cry <= bool_sl(cnt_cry = div-1);
    clk_timer_z80 <= bool_sl(cnt_z80 = div-1);
    clk_timer <= clk_timer_z80 when sel_cntr = '1' else clk_timer_cry;

    -- port on off
    active_ff : ff port map(clk_z80, rst, on_off.wr, active_sel);
    sel_cntr_ff : ff port map(clk_z80, rst, on_off.wr, sel_cntr_sel);
    div_ff : ff port map(clk_z80, rst, on_off.wr, active_sel);
    with on_off.data select div_sel <=
        3       when x"40",
        33      when x"41",
        328     when x"42",
        3277    when x"43",
        1       when x"44",
        16      when x"45",
        256     when x"46",
        4096    when x"47",
        1       when x"80",
        2       when x"81",
        4       when x"82",
        8       when x"84",
        16      when x"88",
        32      when x"90",
        64      when x"a0",
        1       when others;
    active_sel <= on_off.data(7) or on_off.data(6);
    sel_cntr_sel <= on_off.data(7);
    div_reg : process(clk_z80) begin
        if rising_edge(clk_z80) then
            div <= div_next;
        end if;
    end process;
    div_next <= div_sel when on_off.wr = '1' else div;

    p_loop : process(clk_z80) begin
        
    end process;
end arch_timer;
