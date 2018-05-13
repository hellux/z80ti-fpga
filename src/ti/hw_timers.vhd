library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ti_comm.all;

entity hw_timers is port(
    clk, rst, ce : in std_logic;
    p03_intmask : port_out_t;
    p04_mmap_int : port_out_t;
    fin : out std_logic_vector(1 to 2);
    dbg : out dbg_hwt_t);
end hw_timers;

architecture arch of hw_timers is
    component dcntr generic(init : std_logic_vector;
                            bitwidth : integer); port(
        clk, rst, ce : in std_logic;
        cnten : in std_logic;
        ld : in std_logic;
        di : in std_logic_vector(bitwidth-1 downto 0);
        do : out std_logic_vector(bitwidth-1 downto 0));
    end component;

    -- helper
    signal freq_ctrl : integer range 0 to 3;

    -- timers
    signal hwt1_div, hwt2_div : std_logic_vector(19 downto 0);
    signal hwt1_val, hwt2_val : std_logic_vector(19 downto 0);
    signal hwt1_ld, hwt2_ld : std_logic;
    signal hwt1_finish, hwt2_finish : std_logic;
begin
    freq_ctrl <= to_integer(unsigned(p04_mmap_int.data(2 downto 1)));

    hwt1_div <= HWT1_DIVS(freq_ctrl);
    hwt1_finish <= '1' when hwt1_val = x"00000" else '0';
    hwt1_ld <= (p04_mmap_int.wr or hwt1_finish);
    hwt1 : dcntr generic map(HWT1_DIVS(3), 20)
                 port map(clk, rst, ce, '1', hwt1_ld, hwt1_div, hwt1_val);

    hwt2_div <= HWT2_DIVS(freq_ctrl);
    hwt2_finish <= '1' when hwt2_val = x"00000" else '0';
    hwt2_ld <= (p04_mmap_int.wr or hwt2_finish);
    hwt2 : dcntr generic map(HWT2_DIVS(3), 20)
                 port map(clk, rst, ce, '1', hwt2_ld, hwt2_div, hwt2_val);

    fin <= hwt1_finish & hwt2_finish;

    -- debug
    dbg.hwt1 <= hwt1_val;
    dbg.hwt2 <= hwt2_val;
end arch;
