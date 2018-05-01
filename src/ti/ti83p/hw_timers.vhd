library ieee;
use ieee.std_logic_1164.all;
use work.ti_comm.all;

entity hw_timers is port(
    clk, rst : in std_logic;
    p04_mmap_int : port_out_t;
    fin : out std_logic_vector(1 to 2));
end hw_timers;

architecture arch of hw_timers is
    component dcntr generic(bitwidth : integer); port(
        clk, rst : in std_logic;
        ld : in std_logic;
        ce1, ce2 : in std_logic;
        di : in std_logic_vector(bitwidth-1 downto 0);
        do : out std_logic_vector(bitwidth-1 downto 0));
    end component;

    signal freq_ctrl : std_logic_vector(1 downto 0);

    -- timers
    signal hwt1_div, hwt2_div : std_logic_vector(19 downto 0);
    signal hwt1_val, hwt2_val : std_logic_vector(19 downto 0);
    signal hwt1_finish, hwt2_finish : std_logic;
begin
    freq_ctrl <= p04_mmap_int.data(2 downto 1);

    with freq_ctrl select hwt1_div <=
        x"2b98a" when "00", -- 560 Hz
        x"62719" when "01", -- 248 Hz
        x"8f9ca" when "10", -- 170 Hz
        x"cee61" when "11", -- 118 Hz
        x"00000" when others;
    with freq_ctrl select hwt2_div <=
        x"15cc5" when "00", -- 1120 Hz
        x"311f6" when "01", -- 497 Hz
        x"46f89" when "10", -- 344 Hz
        x"67730" when "11", -- 236 Hz
        x"00000" when others;

    hwt1 : dcntr generic map(20)
                 port map(clk, rst, hwt1_finish, '1', '1', hwt1_div, hwt1_val);
    hwt2 : dcntr generic map(20)
                 port map(clk, rst, hwt2_finish, '1', '1', hwt2_div, hwt2_val);
    hwt1_finish <= '1' when hwt1_val = x"00000" else '0';
    hwt2_finish <= '1' when hwt2_val = x"00000" else '0';

    fin(1) <= hwt1_finish;
    fin(2) <= hwt2_finish;
end arch;
