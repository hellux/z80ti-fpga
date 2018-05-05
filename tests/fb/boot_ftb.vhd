library ieee;
use ieee.std_logic_1164.all;

entity boot_ftb is
end boot_ftb;

architecture arch of boot_ftb is
    component boot_fb port(
        clk : in std_logic;
        maddr : out std_logic_vector(25 downto 0);
        mdata : inout std_logic_vector(15 downto 0);
        mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
        mlb_c, mub_c : out std_logic;
        rx : in std_logic;
        btns : in std_logic_vector(4 downto 0);
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    component m45 port(
        clk : in std_logic;
        maddr : in std_logic_vector(25 downto 0);
        mdata : inout std_logic_vector(15 downto 0);
        mclk, madv_c, mcre, mce_c, moe_c, mwe_c : in std_logic;
        mlb_c, mub_c : in std_logic);
    end component;

    signal clk : std_logic;

    signal maddr : std_logic_vector(25 downto 0);
    signal mdata : std_logic_vector(15 downto 0);
    signal mclk, madv_c, mcre, mce_c, moe_c, mwe_c : std_logic;
    signal mlb_c, mub_c : std_logic;

    signal btns : std_logic_vector(4 downto 0) := (others => '0');
    signal seg : std_logic_vector(7 downto 0);
    signal an : std_logic_vector(3 downto 0);
    signal rx : std_logic;
begin
    rx <= '1';

    fb : boot_fb port map(clk,
                          maddr, mdata, mclk, madv_c, mcre, mce_c,
                          moe_c, mwe_c, mlb_c, mub_c,
                          rx,
                          btns, seg, an);
    m : m45 port map(clk,
                     maddr, mdata, mclk, madv_c, mcre, mce_c,
                     moe_c, mwe_c, mlb_c, mub_c);
    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    process begin
        wait for 200 ns;
        btns(3) <= '1';
        wait for 2000 ns;
        btns(3) <= '0';
        wait for 2000 ms;
    end process;
end arch;
