library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;
use work.cmp_comm.all;

entity comp is port(
    clk : in std_logic;
    btns : in std_logic_vector(4 downto 0);
    seg, led : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0);
    vga_red : out std_logic_vector(2 downto 0);
    vga_green : out std_logic_vector(2 downto 0);
    vga_blue : out std_logic_vector(2 downto 1);
    hsync, vsync : out std_logic);
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

    component memory port(
        clk, rst : in std_logic;
        cbi : out ctrlbus_in;
        cbo : in ctrlbus_out;
        addr : in std_logic_vector(15 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0));
    end component;

    component io port(
        clk, clk_z80, clk_vga, rst : in std_logic;
        cbi : out ctrlbus_in;
        cbo : in ctrlbus_out;
        addr : in std_logic_vector(7 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        vga_red : out std_logic_vector(2 downto 0);
        vga_green : out std_logic_vector(2 downto 0);
        vga_blue : out std_logic_vector(2 downto 1);
        hsync, vsync : out std_logic);
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
    signal cbi, cbi_mem, cbi_ext, cbi_io : ctrlbus_in;
    signal data, data_z80, data_mem, data_io : std_logic_vector(7 downto 0);

    signal rst : std_logic;
    signal clk_z80, clk_vga : std_logic;
    signal clk_z80_div : integer range 0 to 24;
    signal clk_vga_div : integer range 0 to 3;

    signal btns_sync, btns_q, btns_op : std_logic_vector(4 downto 0);

    signal dbg_z80 : dbg_z80_t;
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
    cbi_ext <= (reset => rst, others => '0');

    -- OR common buses instead of tristate
    -- TODO not connect whole cbus to everyone
    data <= data_z80 or data_mem or data_io;
    cbi.wt    <= cbi_mem.wt    or cbi_ext.wt    or cbi_io.wt;
    cbi.int   <= cbi_mem.int   or cbi_ext.int   or cbi_io.int;
    cbi.reset <= cbi_mem.reset or cbi_ext.reset or cbi_io.reset;

    cpu : z80 port map(clk_z80, cbi, cbo, addr, data, data_z80, dbg_z80);
    mem : memory port map(clk, rst, cbi_mem, cbo, addr, data, data_mem);
    io_comp : io port map(clk, clk_z80, clk_vga, rst,
                          cbi_io, cbo, addr(7 downto 0), data, data_io);

    -- DEBUG
    mon : monitor port map(clk, btns_op, dbg_z80, seg, led, an);
end arch;
