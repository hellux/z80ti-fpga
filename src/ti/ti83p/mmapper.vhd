library ieee;
use ieee.std_logic_1164.all;

--         TI83p MEMORY LAYOUT
--
--  One page is 0x4000 bytes
--  32 ROM pages : 00-1f * 0x4000 = 512 KB
--  2  RAM pages : 0-1   * 0x4000 = 32 KB
--  Memory avail : 1 MB * 16      = 16384 KB
--
--       EXTERNAL MEMORY LAYOUT
--  place rom 0-512KB then ram immediately after:
--  start         page          end
--           ______________
-- 0x00000  |____ROM_00____|  0x03fff
-- 0x04000  |____ROM_01____|  0x07fff
--   :      |       :      |    :
--   :      |_______:______|    :
-- 0x78000  |____ROM_1e____|  0x7bfff
-- 0x74000  |____ROM_1f____|  0x7ffff
-- 0x88000  |____RAM_0_____|  0x8bfff
-- 0x8c000  |____RAM_1_____|  0x8ffff
-- 0x90000  |____unused____|
--          |____unused____|
--          |       :      |
--          |       :      |
--          |_______:______|  0xfffff
--
--            INTERNAL MEMORY LAYOUTS
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

entity mmapper is port(
    signal ctrl_mmap : in std_logic_vector(7 downto 0);
    signal ctrl_page_a, ctrl_page_b : in std_logic_vector(7 downto 0);
    signal addr_z80 : in std_logic_vector(15 downto 0);
    signal addr_ext : out std_logic_vector(19 downto 0));
end mmapper;

architecture arch of mmapper is
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
    -- interpret control signals
    mode <= ctrl_mmap(0);
    ram_rom_a <= ctrl_page_a(6);
    rom_page_a <= ctrl_page_a(4 downto 0);
    ram_page_a <= ctrl_page_a(0);
    ram_rom_b <= ctrl_page_b(6);
    rom_page_b <= ctrl_page_b(4 downto 0);
    ram_page_b <= ctrl_page_b(0);

    -- map address
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

    with addr_z80(15 downto 14) select page_sel <=
        page0           when "00",
        page1           when "01",
        page2           when "10",
        page3           when "11",
        (others => '0') when others;

    addr_ext <= page_sel & addr_z80(13 downto 0);
end arch;
