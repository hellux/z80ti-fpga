library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;
use work.cmp_comm.all;

entity comp is port(
    clk : in std_logic;
    btns : in std_logic_vector(4 downto 0);
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
    -- debug
        dbg : out dbg_z80_t);
    end component;

    component mem_rom port(
        clk, rst : in std_logic;
        rd, wr, ce : in std_logic;
        cbi : out ctrlbus_in;
        addr : in std_logic_vector(13 downto 0);
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
        clk : in std_logic;
        gmem_data_in : in std_logic_vector(7 downto 0);
        gmem_data_out : out std_logic_vector(7 downto 0);
        gmem_addr : out std_logic_vector(9 downto 0);
        gmem_rd, gmem_rst : out std_logic;
        status_rd, data_rd : in std_logic;
        status_wr, data_wr : in std_logic;
        status_in, data_in : in std_logic_vector(7 downto 0);
        status_out, data_out : out std_logic_vector(7 downto 0));
    end component;

    component pict_mem port(
        clk, rst : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(7 downto 0);
        do : out std_logic_vector(7 downto 0);
        addr_rd	: in std_logic_vector(9 downto 0);
        addr_wr : in std_logic_vector(9 downto 0));
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
    signal cbi, cbi_rom, cbi_ext, cbi_asic : ctrlbus_in;
    signal data, data_z80, data_rom, data_asic : std_logic_vector(7 downto 0);
    signal io_ports : io_ports_t;
    signal io_data : io_data_t;
    signal lcd_gmem_data, gmem_do : std_logic_vector(7 downto 0);
    signal lcd_gmem_addr, vga_gmem_addr : std_logic_vector(9 downto 0);
    signal gmem_rd, gmem_rst : std_logic;

    signal rom_ce : std_logic;

    signal rst : std_logic;
    signal clk_z80 : std_logic;
    signal clk_div : integer range 0 to 25;

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
            if btns(1) = '1' then
                clk_div <= 0;
            elsif clk_div = 25 then
                clk_div <= 0;
            else
                clk_div <= clk_div + 1;
            end if;
        end if;
    end process;
    clk_z80 <= '1' when clk_div = 0 else '0';

    -- buses
    rst <= btns(1);
    cbi_ext <= (reset => rst, others => '0');

    -- OR common buses instead of tristate
    data <= data_z80 or data_rom or data_asic;
    cbi.wt    <= cbi_rom.wt    or cbi_ext.wt    or cbi_asic.wt;
    cbi.int   <= cbi_rom.int   or cbi_ext.int   or cbi_asic.int;
    cbi.nmi   <= cbi_rom.nmi   or cbi_ext.nmi   or cbi_asic.nmi;
    cbi.reset <= cbi_rom.reset or cbi_ext.reset or cbi_asic.reset;
    cbi.busrq <= cbi_rom.busrq or cbi_ext.busrq or cbi_asic.busrq;

    -- CPU / MEM
    cpu : z80 port map(clk_z80, cbi, cbo, addr, data, data_z80, dbg_z80);
    rom_ce <= cbo.mreq and not addr(15) and not addr(14); -- 0-3fff
    rom : mem_rom port map(clk_z80, rst, cbo.wr, cbo.rd, rom_ce, cbi_rom,
                           addr(13 downto 0), data, data_rom);

    -- IO
    asic_c : asic port map(clk_z80, cbi_asic, cbo,
                           addr(7 downto 0), data, data_asic,
                           io_data, io_ports);
    lcd : lcd_ctrl port map(clk_z80,
                            gmem_do, lcd_gmem_data, lcd_gmem_addr,
                            gmem_rd, gmem_rst,
                            io_ports.lcd_status.rd, io_ports.lcd_data.rd,
                            io_ports.lcd_status.wr, io_ports.lcd_data.wr,
                            io_ports.lcd_status.data, io_ports.lcd_data.data,
                            io_data.lcd_status, io_data.lcd_data);
    gmem : pict_mem port map(clk_z80, gmem_rst, gmem_rd,
                             lcd_gmem_data, gmem_do,
                             lcd_gmem_addr, vga_gmem_addr);

    -- DEBUG
    mon : monitor port map(clk, btns_op, dbg_z80, seg, led, an);
end arch;
