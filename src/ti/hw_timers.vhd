library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ti_comm.all;

entity hw_timers is port(
    clk, rst, ce : in std_logic;
    p03_intmask : port_out_t;
    p04_mmap_int : port_out_t;
    fin : out std_logic_vector(1 to 2));
end hw_timers;

architecture arch of hw_timers is
    component dcntr generic(bitwidth : integer); port(
        clk, rst, ce1, ce2 : in std_logic;
        ld : in std_logic;
        di : in std_logic_vector(bitwidth-1 downto 0);
        do : out std_logic_vector(bitwidth-1 downto 0));
    end component;

    -- helper
    signal freq_ctrl : std_logic_vector(1 downto 0);

    -- timers
    signal hwt1_div, hwt2_div : std_logic_vector(19 downto 0);
    signal hwt1_val, hwt2_val : std_logic_vector(19 downto 0);
    signal hwt1_ld, hwt2_ld : std_logic;
    signal hwt1_finish, hwt2_finish : std_logic;
begin
    freq_ctrl <= p04_mmap_int.data(2 downto 1);

    hwt1_div <= HWT1_DIVS(to_integer(unsigned(freq_ctrl)));
    hwt1_finish <= '1' when hwt1_val = x"00000" else '0';
    hwt1_ld <= (p03_intmask.wr and p03_intmask.data(PO03_HWT1_INT)) or
               hwt1_finish;
    hwt1 : dcntr generic map(20)
                 port map(clk, rst, ce, '1', hhwt1_ld, wt1_div, hwt1_val);

    hwt2_div <= HWT2_DIVS(to_integer(unsigned(freq_ctrl)));
    hwt2_finish <= '1' when hwt2_val = x"00000" else '0';
    hwt2_ld <= (p03_intmask.wr and p03_intmask.data(PO03_HWT2_INT)) or
               hwt2_finish;
    hwt2 : dcntr generic map(20)
                 port map(clk, rst, ce, '1', hwt2_ld, hwt2_div, hwt2_val);

    fin <= hwt1_finish & hwt2_finish;
end arch;
