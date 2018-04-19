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
    -- debug
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

    component asic port(
        clk : in std_logic;
        cbi : out ctrlbus_in;
        cbo : in ctrlbus_out;
        addr : in std_logic_vector(7 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        ports_in : in io_data_t;
        ports_out : out io_ports_t);
    end component;

    component lcd_ctrl port(
        clk, rst : in std_logic;
        gmem_data_in : in std_logic_vector(7 downto 0);
        gmem_data_out : out std_logic_vector(7 downto 0);
        gmem_x : out std_logic_vector(5 downto 0);
        gmem_y : out std_logic_vector(4 downto 0);
        gmem_rst, gmem_rd, gmem_wl : out std_logic;
        status_rd, data_rd : in std_logic;
        status_wr, data_wr : in std_logic;
        status_in, data_in : in std_logic_vector(7 downto 0);
        status_out, data_out : out std_logic_vector(7 downto 0));
    end component;

    component pict_mem port(
        clk_z80, clk_vga, rst : in std_logic;
        rd, wl : in std_logic;
        page_in : in std_logic_vector(7 downto 0);
        x_lcd : in std_logic_vector(5 downto 0); -- row
        y_lcd : in std_logic_vector(4 downto 0); -- column page
        x_vga : in std_logic_vector(6 downto 0); -- column
        y_vga : in std_logic_vector(5 downto 0); -- row
        do_vga: out std_logic;
        do_lcd: out std_logic_vector(7 downto 0));
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

    component monitor port(
        clk : in std_logic;
        btns : in std_logic_vector(4 downto 0);
        dbg : in dbg_z80_t;
        seg, led : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    signal cbo : ctrlbus_out;
    signal addr : std_logic_vector(15 downto 0);
    signal cbi, cbi_mem, cbi_ext, cbi_asic : ctrlbus_in;
    signal data, data_z80, data_rom, data_asic : std_logic_vector(7 downto 0);
    signal io_ports : io_ports_t;
    signal io_data : io_data_t;
    signal x_vga : std_logic_vector(6 downto 0);
    signal y_vga : std_logic_vector(5 downto 0);
    signal x_lcd : std_logic_vector(5 downto 0);
    signal y_lcd : std_logic_vector(4 downto 0);
    signal gmem_lcd_data, lcd_gmem_data : std_logic_vector(7 downto 0);
    signal gmem_vga_data : std_logic;
    signal gmem_rst, gmem_rd, gmem_wl : std_logic;

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
    data <= data_z80 or data_rom or data_asic;
    cbi.wt    <= cbi_mem.wt    or cbi_ext.wt    or cbi_asic.wt;
    cbi.int   <= cbi_mem.int   or cbi_ext.int   or cbi_asic.int;
    cbi.nmi   <= cbi_mem.nmi   or cbi_ext.nmi   or cbi_asic.nmi;
    cbi.reset <= cbi_mem.reset or cbi_ext.reset or cbi_asic.reset;
    cbi.busrq <= cbi_mem.busrq or cbi_ext.busrq or cbi_asic.busrq;

    -- CPU / MEM
    cpu : z80 port map(clk_z80, cbi, cbo, addr, data, data_z80, dbg_z80);
    mem : memory port map(clk_z80, rst, cbi_mem, cbo, addr, data, data_rom);

    -- IO
    asic_c : asic port map(clk_z80, cbi_asic, cbo,
                           addr(7 downto 0), data, data_asic,
                           io_data, io_ports);
    lcd : lcd_ctrl port map(clk_z80, rst,
                            gmem_lcd_data, lcd_gmem_data, x_lcd, y_lcd,
                            gmem_rst, gmem_rd, gmem_wl,
                            io_ports.lcd_status.rd, io_ports.lcd_data.rd,
                            io_ports.lcd_status.wr, io_ports.lcd_data.wr,
                            io_ports.lcd_status.data, io_ports.lcd_data.data,
                            io_data.lcd_status, io_data.lcd_data);
    gmem : pict_mem port map(clk_z80, clk_vga, gmem_rst, gmem_rd, gmem_wl,
                             lcd_gmem_data, x_lcd, y_lcd, x_vga, y_vga,
                             gmem_vga_data, gmem_lcd_data);
    vga : vga_motor port map(clk, gmem_vga_data, rst, x_vga, y_vga,
                             vga_red, vga_green, vga_blue, hsync, vsync);

    -- DEBUG
    mon : monitor port map(clk, btns_op, dbg_z80, seg, led, an);
end arch;
