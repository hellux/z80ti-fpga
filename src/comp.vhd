library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

entity comp is port(
    signal clk, rst : in std_logic;
    signal seg : out std_logic_vector(7 downto 0));
end comp;

architecture arch of comp is
    component z80 port(
        clk : in std_logic;
        cbi : in ctrlbus_in;
        cbo : out ctrlbus_out;
        addr : out std_logic_vector(15 downto 0);
        data : inout std_logic_vector(7 downto 0);
    -- debug
        dbg_z80 : out dbg_z80_t);
    end component;

    component mem port(
        clk : in std_logic;
        cbi : out ctrlbus_in;
        cbo : in ctrlbus_out;
        addr : in std_logic_vector(15 downto 0);
        data : inout std_logic_vector(7 downto 0));
    end component;

    signal cbi : ctrlbus_in;
    signal cbo : ctrlbus_out;
    signal addr : std_logic_vector(15 downto 0);
    signal data : std_logic_vector(7 downto 0);
    signal dbg_z80 : dbg_z80_t;
begin
    cbi.reset <= rst;
    cpu : z80 port map(clk, cbi, cbo, addr, data, dbg_z80);
    ram : mem port map(clk, cbi, cbo, addr, data);

    -- debug
    seg <= dbg_z80.regs.AF(15 downto 8);
end arch;
