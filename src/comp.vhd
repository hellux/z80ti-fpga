library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

entity comp is port(
    clk, rst : in std_logic;
    btns : in std_logic;
    seg : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0));
end comp;

architecture arch of comp is
    component z80 port(
        clk : in std_logic;
        cbi : in ctrlbus_in;
        cbo : out ctrlbus_out;
        addr : out std_logic_vector(15 downto 0);
        data : inout std_logic_vector(7 downto 0);
    -- debug
        dbg : out dbg_z80_t);
    end component;

    component mem port(
        clk, rst : in std_logic;
        cbi : out ctrlbus_in;
        cbo : in ctrlbus_out;
        addr : in std_logic_vector(15 downto 0);
        data : inout std_logic_vector(7 downto 0));
    end component;

    component segment is port(
        clk, rst : in std_logic;
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0);
        value : in std_logic_vector(15 downto 0));
    end component;

    signal cbi : ctrlbus_in;
    signal cbo : ctrlbus_out;
    signal addr : std_logic_vector(15 downto 0);
    signal data : std_logic_vector(7 downto 0);
    signal dbg_z80 : dbg_z80_t;
    signal clk_z80 : std_logic;
    signal clk_div : integer range 0 to 25;
begin
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                clk_div <= 0;
            elsif clk_div = 25 then
                clk_div <= 0;
            else
                clk_div <= clk_div + 1;
            end if;
        end if;
    end process;

    clk_z80 <= '1' when clk_div = 0 else '0'; -- 4 MHz

    cbi.reset <= rst;
    cpu : z80 port map(clk_z80, cbi, cbo, addr, data, dbg_z80);
    ram : mem port map(clk_z80, rst, cbi, cbo, addr, data);
    smt : segment port map(clk, rst, seg, an, dbg_z80.regs.AF);
end arch;
