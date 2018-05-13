library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cmp_comm.all;
use work.ti_comm.all;
use work.util.all;

entity mem_ctrl_tb is
end mem_ctrl_tb;

architecture arch of mem_ctrl_tb is
    component mem_ctrl port(
        cbo : in ctrlbus_out;
        p04_mmap_int, p06_mempage_a, p07_mempage_b : in port_out_t;
        addr_log : in std_logic_vector(15 downto 0);
        addr_phy : out std_logic_vector(19 downto 0);
        rd, wr : out std_logic;
        -- debug
        dbg : out dbg_memctrl_t);
    end component;

    procedure test_addr(
        signal p04_s, p06_s, p07_s : out port_out_t;
        signal addr_log_s : out std_logic_vector(15 downto 0);
        signal addr_phy_s : in std_logic_vector(19 downto 0);
    -- input
        constant addr_log : in std_logic_vector(15 downto 0);
        constant mem_mode : in std_logic;
        constant mem_page_a, mem_page_b : in std_logic_vector(7 downto 0);
    -- assertions
        constant addr_phy : in std_logic_vector(19 downto 0))
    is begin
        p04_s <= (data => "0000000" & mem_mode, others => '0');
        p06_s <= (data => mem_page_a, others => '0');
        p07_s <= (data => mem_page_b, others => '0');
        addr_log_s <= addr_log;

        wait for 1 ns;
        assert addr_phy_s = addr_phy
        report lf &
            "mode: " & std_logic'image(mem_mode) & lf &
            "page_a: " & hex_str(mem_page_a) & lf &
            "page_b: " & hex_str(mem_page_b) & lf &
            "log: " & hex_str(addr_log) & lf &
            "phy_actu: " & hex_str(addr_phy_s) & lf &
            "phy_want: " & hex_str(addr_phy);
    end procedure;
    
    signal rd, wr : std_logic;
    signal p04, p06, p07 : port_out_t;
    signal addr_log : std_logic_vector(15 downto 0);
    signal addr_phy : std_logic_vector(19 downto 0);
    signal dbg : dbg_memctrl_t;
begin
    mc : mem_ctrl port map((others => '0'), p04, p06, p07,
                           addr_log, addr_phy, rd, wr, dbg);

    process begin
        report "TB START";

        report "---- MODE 0 ----";
        report "page 0";
        --        addr_log mode pageA  pageB
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"0028", '0', x"07", x"40",
                  x"00028");
        report "page 1";
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"4523", '0', x"07", x"40",
                  x"1c523");
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"5508", '0', x"07", x"00",
                  x"1d508");
        report "page 2";
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"85aa", '0', x"07", x"40",
                  x"845aa");
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"95bc", '0', x"00", x"40",
                  x"855bc");
        report "page 3";
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"c134", '0', x"00", x"40",
                  x"80134");
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"ffff", '0', x"1f", x"40",
                  x"83fff");

        report "---- MODE 1 ----";
        report "page 0";
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"0028", '1', x"07", x"40",
                  x"00028");
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"3fff", '1', x"1f", x"41",
                  x"03fff");
        report "page 1";
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"7fff", '1', x"1f", x"41",
                  x"7bfff");
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"4000", '1', x"1f", x"00",
                  x"78000");
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"4000", '1', x"1e", x"00",
                  x"78000");
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"4000", '1', x"01", x"00",
                  x"00000");
        report "page 2";
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"8000", '1', x"1e", x"00",
                  x"78000");
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"8000", '1', x"1f", x"1f",
                  x"7c000");
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"9abc", '1', x"01", x"1f",
                  x"05abc");
        report "page 3";
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"c000", '1', x"01", x"1f",
                  x"7c000");
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"ffff", '1', x"01", x"41",
                  x"83fff");
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"ffff", '1', x"1f", x"40",
                  x"87fff");
        test_addr(p04, p06, p07, addr_log, addr_phy,
                  x"e123", '1', x"1f", x"40",
                  x"86123");


        assert false report "TB END" severity failure;
    end process;
              
end arch;
