library ieee;
use ieee.std_logic_1164.all;
use work.cmp_comm.all;
use work.ti_comm.all;

--         TI83p MEMORY LAYOUT
--
--  One page is 0x4000 bytes = 16 KB
--  32 ROM pages : 00-1f * 0x4000 = 512 KB
--  2  RAM pages : 0-1   * 0x4000 = 32 KB
--  Memory avail : 1 MB * 16      = 16384 KB
--
--     EXTERNAL/PHYSICAL MEMORY LAYOUT
--  place rom 0-512KB then ram immediately after:
--  start         page          end
--           ______________
-- 0x00000  |____ROM_00____|  0x03fff
-- 0x04000  |____ROM_01____|  0x07fff
--   :      |       :      |    :
--   :      |_______:______|    :
-- 0x78000  |____ROM_1e____|  0x7bfff
-- 0x7c000  |____ROM_1f____|  0x7ffff
-- 0x80000  |____RAM_0_____|  0x83fff
-- 0x84000  |____RAM_1_____|  0x87fff
-- 0x88000  |____unused____|
--          |____unused____|
--          |       :      |
--          |       :      |
--          |_______:______|  0xfffff
--
--       LOGICAL->PHYSICAL MEMORY MAPPING
--        mode 0                  mode 1
--    ______________          ______________
--   |              | 0x0000 |              |
--   |    ROM 00    |   :    |    ROM 00    |
--   |______________| 0x3fff |______________|
--   |              | 0x4000 |              |
--   |  MEM PAGE A  |   :    |  MEM PAGE A  |
--   |______________| 0x7fff |__(even page)_|
--   |              | 0x8000 |              |
--   |  MEM PAGE B  |   :    |  MEM PAGE A  |
--   |______________| 0xbfff |______________|
--   |              | 0xc000 |              |
--   |    RAM  0    |   :    |  MEM PAGE B  |
--   |______________| 0xffff |______________|

entity mem_ctrl is port(
    cbo : in ctrlbus_out;
    p04_mmap_int, p06_mempage_a, p07_mempage_b : in port_out_t;
    addr_log : in std_logic_vector(15 downto 0);
    addr_phy : out std_logic_vector(19 downto 0);
    rd, wr : out std_logic;
    -- debug
    dbg : out dbg_memctrl_t);
end mem_ctrl;

architecture arch of mem_ctrl is
    constant ROM_START : std_logic_vector(19 downto 0) := x"00000";
    constant RAM_START : std_logic_vector(19 downto 0) := x"80000";

    signal mode : std_logic; -- memory mode 0 or 1
    signal ram_rom_a, ram_rom_b : std_logic; -- 0: rom, 1: ram
    signal ram_page_a, ram_page_b : std_logic;
    signal rom_page_a, rom_page_b : std_logic_vector(4 downto 0);

    signal page0, page1, page2, page3 : std_logic_vector(5 downto 0);
    signal page_a, page_b : std_logic_vector(5 downto 0);
    signal page_sel : std_logic_vector(5 downto 0);
begin
    -- interpret ports
    mode <= p04_mmap_int.data(0);
    ram_rom_a <= p06_mempage_a.data(6);
    rom_page_a <= p06_mempage_a.data(4 downto 0);
    ram_page_a <= p06_mempage_a.data(0);
    ram_rom_b <= p07_mempage_b.data(6);
    rom_page_b <= p07_mempage_b.data(4 downto 0);
    ram_page_b <= p07_mempage_b.data(0);

    -- logical -> physical address
    with ram_rom_a select page_a <=
        ROM_START(19)           & rom_page_a when '0',
        RAM_START(19 downto 15) & ram_page_a when '1',
        (others => '0')                      when others;
    with ram_rom_b select page_b <=
        ROM_START(19)           & rom_page_b when '0',
        RAM_START(19 downto 15) & ram_page_b when '1',
        (others => '0')                    when others;

    page0 <= ROM_START(19 downto 14);
    page1 <= page_a when mode = '0' else page_a(5 downto 1) & '0';
    page2 <= page_b when mode = '0' else page_a;
    page3 <= RAM_START(19 downto 14) when mode = '0' else page_b;

    with addr_log(15 downto 14) select page_sel <=
        page0           when "00",
        page1           when "01",
        page2           when "10",
        page3           when "11",
        (others => '0') when others;

    addr_phy <= page_sel & addr_log(13 downto 0);

    -- determine ctrl signals
    rd <= cbo.mreq and cbo.rd; -- TODO check pc no exec mask
    wr <= cbo.mreq and cbo.wr; -- TODO check flash protection

    -- debug
    dbg.sec_ram_rom <= page1(5);
    dbg.sec_page <= page1(4 downto 0) when page1(5) = '1' else x"0" & page1(0);
    dbg.thi_ram_rom <= page2(5);
    dbg.thi_page <= page2(4 downto 0) when page2(5) = '1' else x"0" & page2(0);
    dbg.fou_ram_rom <= page3(5);
    dbg.fou_page <= page3(4 downto 0) when page3(5) = '1' else x"0" & page3(0);
end arch;
