library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.cmp_comm.all;
use work.util.all;
use work.chars.all;

entity monitor_vga is port(
    clk : in std_logic;
    dbg : in dbg_cmp_t;
    x_vga : in std_logic_vector(8 downto 0);
    y_vga : in std_logic_vector(5 downto 0);
    data_vga : out std_logic);
end monitor_vga;

architecture arch of monitor_vga is
    constant PAGES_PER_ROW : integer := 8;
    constant PAGE_SIZE : integer := 8;
    constant COLS : integer := PAGE_SIZE*PAGES_PER_ROW;
    constant ROWS : integer := 8;
    constant PAGE_COUNT : integer := PAGES_PER_ROW*ROWS;

    type page_in_arr_t is array(0 to PAGE_COUNT-1) of string(1 to PAGE_SIZE);

    type page_t is array(0 to PAGE_SIZE-1) of integer;
    type page_arr_t is array(0 to PAGE_COUNT-1) of string(1 to 8);

    signal page_in_arr : page_in_arr_t;
    signal pages : page_arr_t := (others => (others => 0));

    -- data output
    signal col : unsigned(5 downto 0);
    signal row : unsigned(2 downto 0);

    signal page_index : integer range 0 to PAGE_COUNT-1;
    signal current_page : string(1 to 8);

    signal page_col : integer range 0 to 7;
    signal current_char : integer range 0 to CHAR_COUNT-1;

    signal col_index, row_index : integer range 0 to 7;
    signal val_prefix : string(1 to 4);
    signal val_mode : string(1 to 3);
    signal val_cycle : string(1 to 4);
    signal val_flags : string(1 to 8);
    signal val_cond : string(1 to 8);
    signal val_cb : string(1 to 8);
    signal val_asic : string(1 to 8);
    signal val_int : string(1 to 8);
begin
    with dbg.z80.state.prefix select
        val_prefix <= "MAIN" when main,
                      "  ED" when ed,
                      "  CB" when cb,
                      "  DD" when dd,
                      "DDCB" when ddcb,
                      "  CD" when fd,
                      "FDCB" when fdcb;

    with dbg.z80.state.mode select
        val_mode <= "EXE" when exec,
                    " WZ" when wz,
                    "HLT" when halt,
                    "INT" when int;
    val_cycle <= 
        "M" & hex_str(std_logic_vector(to_unsigned(dbg.z80.state.m, 3))) &
        "T" & hex_str(std_logic_vector(to_unsigned(dbg.z80.state.t, 3)));

    val_flags(1) <= 'S' when dbg.z80.regs.af(7) = '1' else ' ';
    val_flags(2) <= 'Z' when dbg.z80.regs.af(6) = '1' else ' ';
    val_flags(3) <= 'X' when dbg.z80.regs.af(5) = '1' else ' ';
    val_flags(4) <= 'H' when dbg.z80.regs.af(4) = '1' else ' ';
    val_flags(5) <= 'Y' when dbg.z80.regs.af(3) = '1' else ' ';
    val_flags(6) <= 'P' when dbg.z80.regs.af(2) = '1' else ' ';
    val_flags(7) <= 'N' when dbg.z80.regs.af(1) = '1' else ' ';
    val_flags(8) <= 'C' when dbg.z80.regs.af(0) = '1' else ' ';

    val_cond(1 to 2) <= " Z" when dbg.z80.state.cc(1) else "NZ";
    val_cond(3 to 4) <= " C" when dbg.z80.state.cc(3) else "NC";
    val_cond(5 to 6) <= "PE" when dbg.z80.state.cc(5) else "PO";
    val_cond(7 to 8) <= " M" when dbg.z80.state.cc(7) else " P";

    val_asic(1) <= ' ';
    val_asic(2 to 3) <= "WR" when dbg.ti.asic.rd_wr = '1' else "RD";
    val_asic(4) <= ' ';
    val_asic(5) <= 'E' when dbg.ti.asic.ce = '1' else ' ';
    val_asic(6) <= ' ';
    val_asic(7 to 8) <= hex_str(dbg.ti.asic.paddr);

    val_cb(1) <= '1' when dbg.cbo.m1    = '1' else ' ';
    val_cb(2) <= 'M' when dbg.cbo.mreq  = '1' else ' ';
    val_cb(3) <= 'I' when dbg.cbo.iorq  = '1' else ' ';
    val_cb(4) <= 'R' when dbg.cbo.rd    = '1' else ' ';
    val_cb(5) <= 'W' when dbg.cbo.wr    = '1' else ' ';
    val_cb(6) <= 'H' when dbg.cbo.halt  = '1' else ' ';
    val_cb(7) <= 'X' when dbg.cbi.int   = '1' else ' ';
    val_cb(8) <= '0' when dbg.cbi.reset = '1' else ' ';

    val_int(1 to 3) <= " IM";
    val_int(4) <= '0' when dbg.z80.state.im = 0 else
                  '1' when dbg.z80.state.im = 1 else
                  '2';
    val_int(5) <= ' ';
    val_int(6 to 7) <= "EI" when dbg.z80.state.iff = '1' else "DI";
    val_int(8) <= ' ';

    page_in_arr <= (
    -- state / inter
        "PC: " & hex_str(dbg.z80.pc),
        val_mode & ' ' & val_cycle,
        val_prefix & "  " & hex_str(dbg.z80.ir),
        val_flags,
        val_cond,
        val_int,
        val_cb,
        val_asic,

    -- regfile
        " AF:" & hex_str(dbg.z80.regs.af),
        " BC:" & hex_str(dbg.z80.regs.bc),
        " DE:" & hex_str(dbg.z80.regs.de),
        " HL:" & hex_str(dbg.z80.regs.hl),
        " SP:" & hex_str(dbg.z80.regs.sp),
        " IX:" & hex_str(dbg.z80.regs.ix),
        " IY:" & hex_str(dbg.z80.regs.iy),
        " WZ:" & hex_str(dbg.z80.regs.wz),

    -- EXT
        " AX:" & hex_str(dbg.addr_log),
        " A:"  & hex_str(dbg.addr_phy),
        " AB:" & hex_str(dbg.z80.abus),
        " DT:" & hex_str(dbg.z80.dbus & dbg.data),
        " AT:" & hex_str(dbg.z80.act & dbg.z80.tmp),
        (others => ' '),
        (others => ' '),
        (others => ' '),

    -- ports
        " P01:" & hex_str(dbg.ti.asic.p01_kbd) & ' ',
        " P02:" & hex_str(dbg.ti.asic.p02_status) & ' ',
        " P03:" & hex_str(dbg.ti.asic.p03_intmask) & ' ',
        " P04:" & hex_str(dbg.ti.asic.p04_mmap_int) & ' ',
        " P06:" & hex_str(dbg.ti.asic.p06_mempage_a) & ' ',
        " P07:" & hex_str(dbg.ti.asic.p07_mempage_b) & ' ',
        " P10:" & hex_str(dbg.ti.asic.p10_lcd_status) & ' ',
        " P11:" & hex_str(dbg.ti.asic.p11_lcd_data) & ' ',

        others => (others => ' ')
    );

    col <= unsigned(x_vga(8 downto 3));
    row <= unsigned(y_vga(5 downto 3));

    page_index <= to_integer(col(5 downto 3) & row);
    current_page <= pages(page_index);

    page_col <= to_integer(col(2 downto 0));
    current_char <= current_page(page_col);

    col_index <= to_integer(unsigned(x_vga(2 downto 0)));
    row_index <= to_integer(unsigned(y_vga(2 downto 0)));

    data_vga <= char_arr(current_char)(row_index)(col_index);
end arch;
