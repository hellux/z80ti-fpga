library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

-- TODO
--  -flash
--  -pages
--  -split rom/ram

entity memory is port(
    clk, rst : in std_logic;
    cbi : out ctrlbus_in;
    cbo : in ctrlbus_out;
    addr : in std_logic_vector(15 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0));
end memory;

architecture arch of memory is
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
    signal data_rom : std_logic_vector(7 downto 0);
begin
    route <= none  when cbo.mreq = '0' else
             rom_r when addr(15 downto 14) = "00" else -- 0-3fff
             none;

    rom_addr <= addr(13 downto 0) when route = rom_r else (others => '0');
    rom_ce <= '1' when route = rom_r else '0';

    rom : mem_rom port map(clk, cbo.wr, cbo.rd, rom_ce,
                           rom_addr, data_in, data_rom);

    data_out <= data_rom;

    cbi <= (others => '0');
end arch;
