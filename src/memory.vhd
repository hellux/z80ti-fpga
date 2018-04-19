library ieee;
use ieee.std_logic_1164.all;
use work.cmp_comm.all;
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
        clk, rst : in std_logic;
        rd, wr, ce : in std_logic;
        addr : in std_logic_vector(13 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0));
    end component;

    signal rom_ce : std_logic;
    signal data_rom : std_logic_vector(7 downto 0);
begin
    -- static mapping
    rom_ce <= cbo.mreq and not addr(15) and not addr(14); -- 0-3fff

    rom : mem_rom port map(clk, rst, cbo.wr, cbo.rd, rom_ce,
                           addr(13 downto 0), data_in, data_rom);

    data_out <= data_rom;
end arch;
