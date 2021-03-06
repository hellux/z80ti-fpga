library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_ext_fb is port(
    clk : in std_logic;
-- memory
    maddr : out std_logic_vector(25 downto 0);
    mdata : inout std_logic_vector(15 downto 0);
    mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
    mlb_c, mub_c : out std_logic;
-- dbg in
    btns : in std_logic_vector(4 downto 0);
-- dbg out
    seg, led : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0));
end mem_ext_fb;

architecture arch of mem_ext_fb is
    component reg generic(init : std_logic_vector; size : integer); port(
        clk, rst : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;

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

    constant INIT_TIME : integer := 20000; -- * 10 ns = 200us
    constant Z80_DIV : integer := 16;
    constant CYCLES : integer := 16;

    signal init_cnt : integer range 0 to INIT_TIME;
    signal clk_z80_div : integer range 0 to Z80_DIV-1 := 0;
    signal clk_z80 : std_logic;
    
    signal data, data_mem : std_logic_vector(7 downto 0);
    signal addr : std_logic_vector(19 downto 0);
    signal rd, wr : std_logic;

    signal dreg_rd : std_logic;
    signal dreg_o : std_logic_vector(7 downto 0);
    signal t : integer range 0 to CYCLES-1 := 0;

    signal seg_value : std_logic_vector(15 downto 0);

    signal btns_sync, btns_q, btns_op : std_logic_vector(4 downto 0);
begin
    -- input sync
    op_btns : process(clk) begin
        if rising_edge(clk) then
            btns_sync <= btns;
            btns_q <= btns_sync;
        end if;
    end process;
    btns_op <= btns_sync and not btns_q;

    -- clock sync
    process(clk) begin
        if rising_edge(clk) then
            if clk_z80_div = Z80_DIV-1 then
                clk_z80_div <= 0;
            else
                clk_z80_div <= clk_z80_div + 1;
            end if;

            if init_cnt < INIT_TIME then
                init_cnt <= init_cnt + 1;
            end if;
        end if;
    end process;
    --clk_z80 <= '1' when clk_z80_div = 0 else '0';
    clk_z80 <= btns_op(0);


    mem : mem_if port map(clk, '0', rd, wr, addr, data, data_mem,
                          maddr, mdata, mclk, madv_c, mcre, mce_c, moe_c,
                          mwe_c, mlb_c, mub_c);

    process(clk) begin
        if rising_edge(clk) then
            if clk_z80 = '1' then
                if init_cnt = INIT_TIME and t < CYCLES-1 then
                    t <= t + 1;
                end if;
            end if;
        end if;
    end process;

    dreg : reg generic map(x"00", 8)
               port map(clk_z80, '0', dreg_rd, data_mem, dreg_o);

    process(t) begin
        rd <= '0';
        wr <= '0';
        data <= (others => '0');
        addr <= (others => '0');
        dreg_rd <= '0';

        case t is
        when 0 => null; -- init
        when 1 =>
            addr <= x"00096";
            data <= x"77";
            wr <= '1';
        when 4 =>
            addr <= x"00096";
            rd <= '1';
            dreg_rd <= '1';
        when others => null;
        end case;
    end process;

    led <= (0 => rd,
            1 => wr,
            2 => dreg_rd,
            others => '0');
    seg_value <= dreg_o & std_logic_vector(to_unsigned(t, 8));
    smt : segment port map(clk, seg_value, x"0", seg, an);
end arch;
