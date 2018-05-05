library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity boot_fb is port(
    clk : in std_logic;
-- memory
    maddr : out std_logic_vector(25 downto 0);
    mdata : inout std_logic_vector(15 downto 0);
    mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
    mlb_c, mub_c : out std_logic;
-- uart
    rx : in std_logic;
-- dbg in
    btns : in std_logic_vector(4 downto 0);
-- dbg out
    seg : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0));
end boot_fb;

architecture arch of boot_fb is
    component mem_if port(
    -- ti/z80 <-> interface
        clk, rst : in std_logic;
        rd, wr : in std_logic;
        addr_phy : in std_logic_vector(19 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
    -- external memory <-> interface
        maddr : out std_logic_vector(25 downto 0);
        mdata : inout std_logic_vector(15 downto 0);
        mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
        mlb_c, mub_c : out std_logic);
    end component;
    
    component segment is port(
        clk : in std_logic;
        value : in std_logic_vector(15 downto 0);
        dp_num : in std_logic_vector(3 downto 0);
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    component bootloader port(
        clk, rst : in std_logic;
        ld, done : in std_logic;
        mem_wr : out std_logic;
        mem_data_in : in std_logic_vector(7 downto 0);
        mem_data_out : out std_logic_vector(7 downto 0);
        mem_addr : out std_logic_vector(19 downto 0);
        rx : in std_logic);
    end component;

    signal rd, wr : std_logic;
    signal ld, done : std_logic;
    signal rst : std_logic;
    signal boot_mem_data, mem_boot_data : std_logic_vector(7 downto 0);
    signal addr : std_logic_vector(19 downto 0);

    signal seg_val : std_logic_vector(15 downto 0);
begin
    ld <= btns(3);
    done <= btns(4);
    rd <= '0';
    seg_val <= x"00" & boot_mem_data;

    mem : mem_if port map(clk, '0', rd, wr, addr, boot_mem_data, mem_boot_data,
                          maddr, mdata, mclk, madv_c, mcre, mce_c, moe_c,
                          mwe_c, mlb_c, mub_c);

    boot : bootloader port map(clk, rst, ld, done,
                               wr, mem_boot_data, boot_mem_data, addr,
                               rx);

    smt : segment port map(clk, seg_val, x"0", seg, an);
end arch;
