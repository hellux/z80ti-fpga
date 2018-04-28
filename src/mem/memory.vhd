library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

-- TODO
--  -flash

entity memory is port(
    clk, rst : in std_logic;
    cbo : in ctrlbus_out;
    addr : in std_logic_vector(15 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0);
    mode : in std_logic; -- memory mode 0 or 1
    ram_rom_a, ram_rom_b : in std_logic; -- 0: rom, 1: ram
    ram_page_a, ram_page_b : in std_logic;
    rom_page_a, rom_page_b : in std_logic_vector(4 downto 0));
end memory;

--            MEMORY LAYOUT
--  32 RAM pages : 00-1f
--  2  ROM pages : 0-1
--  Each page is 0x4000 bytes
--
--       EXTERNAL MEMORY LAYOUT
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

architecture arch of memory is
    constant ROM_START : std_logic_vector(19 downto 0) := x"00000";
    constant RAM_START : std_logic_vector(19 downto 0) := x"80000";

    component mem_rom port(
        clk : in std_logic;
        rd, wr, ce : in std_logic;
        addr : in std_logic_vector(13 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0));
    end component;

    type mem_route_t is (none, rom_r);

    signal route : mem_route_t;
    signal rom_ce : std_logic;
    signal rom_addr : std_logic_vector(13 downto 0);

    -- tmp should be external
    signal addr_ext : std_logic_vector(19 downto 0);

    signal page0, page1, page2, page3 : std_logic_vector(5 downto 0);
    signal pagea, pageb : std_logic_vector(5 downto 0);
    signal page_sel : std_logic_vector(5 downto 0);
begin
    route <= none  when cbo.mreq = '0' else
             rom_r when addr(15 downto 14) = "00" else -- 0-3fff
             none;

    rom_addr <= addr(13 downto 0) when route = rom_r else (others => '0');
    rom_ce <= '1' when route = rom_r else '0';

    rom : mem_rom port map(clk, cbo.wr, cbo.rd, rom_ce,
                           rom_addr, data_in, data_out);
    
    -- memory mapping
    with ram_rom_a select pagea <=
        ROM_START(19) & rom_page_a         when '0',
        RAM_START(19) & "000" & ram_page_a when '1',
        (others => '0')                    when others;
    with ram_rom_b select pageb <=
        ROM_START(19) & rom_page_b         when '0',
        RAM_START(19) & "000" & ram_page_b when '1',
        (others => '0')                    when others;

    page0 <= ROM_START(19 downto 14);
    page1 <= pagea when mode = '0' else pagea(5 downto 1) & '0';
    page2 <= pageb when mode = '0' else pagea;
    page3 <= RAM_START(19 downto 14) when mode = '0' else pageb;

    with addr(15 downto 14) select page_sel <=
        page0           when "00",
        page1           when "01",
        page2           when "10",
        page3           when "11",
        (others => '0') when others;

    addr_ext <= page_sel & addr(13 downto 0);
end arch;
