library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;
use work.ti_comm.all;

entity comp is port(
    clk : in std_logic;
-- buttons
    btns : in std_logic_vector(4 downto 0);
-- keyboard
    ps2_kbd_clk : in std_logic;
    ps2_kbd_data : in std_logic;
-- vga monitor
    vga_red : out std_logic_vector(2 downto 0);
    vga_green : out std_logic_vector(2 downto 0);
    vga_blue : out std_logic_vector(2 downto 1);
    hsync, vsync : out std_logic;
-- memory
    maddr : out std_logic_vector(26 downto 0);
    mdata : inout std_logic_vector(15 downto 0);
    mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
    mlb_c, mub_c : out std_logic;
    mwait : in std_logic;
-- 7 segment, led
    seg, led : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0));
end comp;

architecture arch of comp is
    component z80 port(
        clk : in std_logic;
        cbi : in ctrlbus_in;
        cbo : out ctrlbus_out;
        addr : out std_logic_vector(15 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        dbg : out dbg_z80_t);
    end component;

    component ti port(
        clk, clk_z80, clk_vga, rst : in std_logic;
        int : out std_logic;
        cbo : in ctrlbus_out;
        addr_z80 : in std_logic_vector(15 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        keys_down : in keys_down_t;
        on_key_down : in std_logic;
        x_vga : in std_logic_vector(6 downto 0);
        y_vga : in std_logic_vector(5 downto 0);
        data_vga : out std_logic;
        addr_ext : out std_logic_vector(19 downto 0));
    end component;

    component mem_ctrl port(
        clk, clk_z80, rst : in std_logic;
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

    component vga_motor port(
         clk : in std_logic;
         data : in std_logic;
         rst : in std_logic;
         x : out std_logic_vector(6 downto 0);
         y : out std_logic_vector(5 downto 0);
         vgaRed	: out std_logic_vector(2 downto 0);
         vgaGreen : out std_logic_vector(2 downto 0);
         vgaBlue : out std_logic_vector(2 downto 1);
         Hsync : out std_logic;
         Vsync : out std_logic);
    end component;

    component memory port(
        clk, rst : in std_logic;
        cbo : in ctrlbus_out;
        addr : in std_logic_vector(15 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0));
    end component;

    component monitor port(
        clk : in std_logic;
        btns : in std_logic_vector(4 downto 0);
        dbg : in dbg_z80_t;
        seg, led : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    signal cbo : ctrlbus_out;
    signal addr : std_logic_vector(15 downto 0);
    signal cbi : ctrlbus_in;
    signal int : std_logic;
    signal data, data_z80, data_mem, data_ti : std_logic_vector(7 downto 0);

    signal rst : std_logic;
    signal clk_z80, clk_vga : std_logic;
    signal clk_z80_div : integer range 0 to 24;
    signal clk_vga_div : integer range 0 to 3;

    signal btns_sync, btns_q, btns_op : std_logic_vector(4 downto 0);

    signal dbg_z80 : dbg_z80_t;

    -- ti <-> external
    signal keys_down : keys_down_t;
    signal on_key_down : std_logic := '0';
    signal data_vga : std_logic;
    signal x_vga : std_logic_vector(6 downto 0);
    signal y_vga : std_logic_vector(5 downto 0);
    signal addr_ext : std_logic_vector(19 downto 0);
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
            if clk_z80_div = 24 then
                clk_z80_div <= 0;
            else
                clk_z80_div <= clk_z80_div + 1;
            end if;
            if clk_vga_div = 3 then
                clk_vga_div <= 0;
            else
                clk_vga_div <= clk_vga_div + 1;
            end if;
            if rst = '1' then
                clk_z80_div <= 0;
                clk_vga_div <= 0;
            end if;
        end if;
    end process;
    clk_z80 <= '1' when clk_z80_div = 0 else '0';
    clk_vga <= '1' when clk_vga_div = 0 else '0';

    -- buses
    rst <= btns(1);
    cbi.wt <= '0';
    cbi.int <= int;
    cbi.reset <= rst;
    -- OR data bus instead of tristate
    data <= data_z80 or data_mem or data_ti;

    -- cpu / asic
    cpu : z80 port map(clk_z80, cbi, cbo, addr, data, data_z80, dbg_z80);
    ti_comp : ti port map(clk, clk_z80, clk_vga, rst,
                          int, cbo, addr, data, data_ti,
                          keys_down, on_key_down,
                          x_vga, y_vga, data_vga,
                          addr_ext);

    -- external controllers
    vga : vga_motor port map(clk, data_vga, rst, x_vga, y_vga,
                             vga_red, vga_green, vga_blue, hsync, vsync);
    mem : mem_ctrl port map(clk, clk_z80, rst, cbo, addr_ext, data, data_mem,
                            maddr, mdata, mclk, madv_c, mcre, mce_c, moe_c,
                            mwe_c, mlb_c, mub_c, mwait);
    -- TODO add kbd enc
    -- kbd : kbd_enc port map(clk, rst, ps2_kbd_clk, ps2_kbd_clk,
    --                        keys_down, on_key_down);

    -- debug
    mon : monitor port map(clk, btns_op, dbg_z80, seg, led, an);
end arch;
