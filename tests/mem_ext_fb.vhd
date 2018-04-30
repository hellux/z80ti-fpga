library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity mem_ext_fb is port(
    clk : in std_logic;
-- memory
    maddr : out std_logic_vector(26 downto 0);
    mdata : inout std_logic_vector(15 downto 0);
    mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
    mlb_c, mub_c : out std_logic;
    mwait : in std_logic;
-- 7 segment
    seg : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0));
end mem_ext_fb;

architecture arch of mem_ext_fb is
    component reg generic(size : integer); port(
        clk, rst : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;

    component mem_ctrl port(
        clk, rst : in std_logic;
        cbo : in ctrlbus_out;
        addr_ext : in std_logic_vector(19 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
    -- external
        maddr : out std_logic_vector(26 downto 0);
        mdata : inout std_logic_vector(15 downto 0);
        mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
        mlb_c, mub_c : out std_logic;
        mwait : in std_logic);
    end component;
    
    component segment is port(
        clk : in std_logic;
        value : in std_logic_vector(15 downto 0);
        dp_num : in unsigned(3 downto 0);
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    constant INIT_TIME : integer := 20000; -- * 10 ns = 200us
    constant CYCLES : integer := 16;

    signal init_cnt : integer range 0 to INIT_TIME;
    signal clk_z80_div : integer range 0 to 16 := 0;
    signal clk_z80 : std_logic;
    
    signal cbo : ctrlbus_out;
    signal data, data_mem : std_logic_vector(7 downto 0);
    signal addr : std_logic_vector(19 downto 0);

    signal dreg_rd : std_logic;
    signal dreg_o : std_logic_vector(7 downto 0);
    signal t : integer range 0 to CYCLES-1 := 0;

    signal seg_value : std_logic_vector(15 downto 0);
begin
    -- clock sync
    process(clk) begin
        if rising_edge(clk) then
            if clk_z80_div = 16 then
                clk_z80_div <= 0;
            else
                clk_z80_div <= clk_z80_div + 1;
            end if;

            if init_cnt < INIT_TIME then
                init_cnt <= init_cnt + 1;
            end if;
        end if;
    end process;
    clk_z80 <= '1' when clk_z80_div = 0 else '0';


    mem : mem_ctrl port map(clk, '0', cbo, addr, data, data_mem,
                            maddr, mdata, mclk, madv_c, mcre, mce_c, moe_c,
                            mwe_c, mlb_c, mub_c, mwait);

    process(clk) begin
        if rising_edge(clk) then
            if clk_z80 = '1' then
                if init_cnt = INIT_TIME and t < CYCLES-1 then
                    t <= t + 1;
                end if;
            end if;
        end if;
    end process;

    dreg : reg generic map(8) port map(clk_z80, '0', dreg_rd, data_mem, dreg_o);

    process(t) begin
        cbo <= (others => '0');
        data <= (others => '0');
        addr <= (others => '0');
        dreg_rd <= '0';

        case t is
        when 0 => null; -- init
        when 1 =>
            addr <= x"00096";
            data <= x"55";
            cbo.mreq <= '1';
            cbo.wr <= '1';
        when 4 =>
            addr <= x"00096";
            cbo.mreq <= '1';
            cbo.rd <= '1';
            dreg_rd <= '1';
        when others => null;
        end case;
    end process;

    smt : segment port map(clk, seg_value, x"0", seg, an);
    seg_value <= dreg_o & x"cc";
end arch;
