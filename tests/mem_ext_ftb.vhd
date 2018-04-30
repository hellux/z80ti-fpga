library ieee;
use ieee.std_logic_1164.all;

entity mem_ext_ftb is
end mem_ext_ftb;

architecture arch of mem_ext_ftb is
    component mem_ext_fb port(
        clk : in std_logic;
    -- memory
        maddr : out std_logic_vector(26 downto 0);
        mdata : inout std_logic_vector(15 downto 0);
        mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
        mlb_c, mub_c : out std_logic;
        mwait : in std_logic;
    -- 7 segment, led
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    component m45 port(
        clk : in std_logic;
        maddr : in std_logic_vector(26 downto 0);
        mdata : inout std_logic_vector(15 downto 0);
        mclk, madv_c, mcre, mce_c, moe_c, mwe_c : in std_logic;
        mlb_c, mub_c : in std_logic;
        mwait : out std_logic);
    end component;

    signal clk : std_logic;

    signal maddr : std_logic_vector(26 downto 0);
    signal mdata : std_logic_vector(15 downto 0);
    signal mclk, madv_c, mcre, mce_c, moe_c, mwe_c : std_logic;
    signal mlb_c, mub_c : std_logic;
    signal mwait : std_logic;

    signal seg : std_logic_vector(7 downto 0);
    signal an : std_logic_vector(3 downto 0);
begin
    fb : mem_ext_fb port map(clk,
                      maddr, mdata, mclk, madv_c, mcre, mce_c,
                      moe_c, mwe_c, mlb_c, mub_c, mwait,
                      seg, an);
    m : m45 port map(clk,
                     maddr, mdata, mclk, madv_c, mcre, mce_c,
                     moe_c, mwe_c, mlb_c, mub_c, mwait);
    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;
end arch;
