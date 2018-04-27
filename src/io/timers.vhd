library ieee;
use ieee.std_logic_1164.all;
use work.io_comm.all;

entity timers is port(
    clk, clk_z80, rst : in std_logic;
    t1_fo, t1_so, t1_do : in port_out_t;
    t1_fi, t1_si, t1_di : out port_in_t;
    t2_fo, t2_so, t2_do : in port_out_t;
    t2_fi, t2_si, t2_di : out port_in_t;
    t3_fo, t3_so, t3_do : in port_out_t;
    t3_fi, t3_si, t3_di : out port_in_t;
    cry_fin : out std_logic_vector(1 to 3));
end timers;

architecture arch_timers of timers is
    component cntr generic(size : integer); port(
        clk, rst : in std_logic;
        ce : in std_logic;
        do : out integer range 0 to size-1);
    end component;
    component timer port(
        clk, clk_cry, clk_z80, rst : in std_logic;
        freq, status, count : in port_out_t;
        freq_i, status_i, count_i : out port_in_t;
        finished : out std_logic);
    end component;

    constant CLK_DIV : integer := 3052; -- 100Mhz / 3052 ~= 32768Hz
    signal clk_cnt : integer range 0 to CLK_DIV-1;
    signal clk_cry : std_logic; 
begin
    -- crystal clk
    clk_cntr : cntr generic map(CLK_DIV) port map(clk, rst, '1', clk_cnt);
    clk_cry <= '1' when clk_cnt = 0 else '0';

    t1 : timer port map(clk, clk_cry, clk_z80, rst,
                        t1_fo, t1_so, t1_do,
                        t1_fi, t1_si, t1_di, cry_fin(1));
    t2 : timer port map(clk, clk_cry, clk_z80, rst,
                        t2_fo, t2_so, t2_do,
                        t2_fi, t2_si, t2_di, cry_fin(2));
    t3 : timer port map(clk, clk_cry, clk_z80, rst,
                        t3_fo, t3_so, t3_do,
                        t3_fi, t3_si, t3_di, cry_fin(3));
end arch_timers;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.io_comm.all;

entity timer is port(
    clk, clk_cry, clk_z80, rst : in std_logic;
    freq, status, count : in port_out_t;
    freq_i, status_i, count_i : out port_in_t;
    finished : out std_logic);
end timer;

architecture arch_timer of timer is
    component reg generic(size : integer); port(
        clk, rst : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;
    component cntr generic(size : integer); port(
        clk, rst : in std_logic;
        ce : in std_logic;
        do : out integer range 0 to size-1);
    end component;
    component dcntr generic(bitwidth : integer); port(
        clk, rst : in std_logic;
        ld : in std_logic;
        ce1, ce2 : in std_logic;
        di : in std_logic_vector(bitwidth-1 downto 0);
        do : out std_logic_vector(bitwidth-1 downto 0);
        rc : out std_logic);
    end component;
    component ff port(
        clk, rst : in std_logic;
        rd : in std_logic;
        di : in std_logic;
        do : out std_logic);
    end component;

    signal cnt_cry : integer range 0 to 4095;
    signal cnt_z80: integer range 0 to 63;
    signal clk_timer, clk_timer_cry, clk_timer_z80 : std_logic;
    signal tim_current : std_logic_vector(7 downto 0);
    signal tim_active : std_logic;
    signal tim_finish, tim_overflow : std_logic;

    -- flags
    signal finished_f : std_logic;  -- timer expired >= once since mode set
    signal overflow_f : std_logic;  -- timer expired >= twice since mode set
    signal loop_f : std_logic;      -- loop when cntr reach 0
    signal int_f : std_logic;       -- interrupt when finish

    signal freq_buf, count_buf : std_logic_vector(7 downto 0);
    signal sel_cntr : std_logic; -- 0 crystal, 1 z80
    signal div : integer range 1 to 4096;
begin
    -- clock for timer
    cry_cntr : cntr generic map(4096)
                    port map(clk, clk_timer_cry, clk_cry, cnt_cry);
    z80_cntr : cntr generic map(64)
                    port map(clk, clk_timer_z80, clk_z80, cnt_z80);
    clk_timer_cry <= '1' when cnt_cry = div-1 else '0';
    clk_timer_z80 <= '1' when cnt_z80 = div-1 else '0';
    clk_timer <= clk_timer_z80 when sel_cntr = '1' else clk_timer_cry;

    -- timer
    timer_cntr : dcntr generic map(8)
                       port map(clk, rst, count.wr, tim_active, clk_timer,
                                count_buf, tim_current);
    tim_finish <= '1' when tim_current = x"00" and
                           tim_active = '1' and
                           clk_timer = '1' else '0';
    tim_overflow <= tim_finish and finished_f;
    tim_active <= (freq_buf(7) or freq_buf(6)) and (not finished_f or loop_f);

    -- flags
    finished_ff : ff port map(clk, count.wr, tim_finish,   '1', finished_f);
    overflow_ff : ff port map(clk, count.wr, tim_overflow, '1', overflow_f);
    loop_ff : ff port map(clk_z80, rst, status.wr, status.data(0), loop_f);
    int_ff : ff port map(clk, rst, status.wr, status.data(1), int_f);

    -- port freq
    freq_reg : reg generic map(8)
                   port map(clk_z80, rst, freq.wr, freq.data, freq_buf);
    count_reg : reg generic map(8)
                    port map(clk_z80, rst, count.wr, count.data, count_buf);
    sel_cntr <= freq_buf(7);
    with freq_buf select div <=
        3       when x"40",     -- 10925.4 Hz
        33      when x"41",     -- 993.2 Hz
        328     when x"42",     -- 99.9 Hz
        3277    when x"43",     -- 10.0 Hz
        1       when x"44",     -- 32776.1 Hz
        16      when x"45",     -- 2048.5 Hz
        256     when x"46",     -- 128.0 Hz
        4096    when x"47",     -- 8.0 Hz
        1       when x"80",
        2       when x"81",
        4       when x"82",
        8       when x"84",
        16      when x"88",
        32      when x"90",
        64      when x"a0",
        1       when others;

    -- outputs
    finished <= finished_f;
    freq_i <= (freq_buf, '0');
    status_i <= ("00000" & overflow_f & int_f & loop_f, int_f and tim_finish);
    count_i <= (count_buf, '0');
end arch_timer;
