library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.cmp_comm.all;
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

    type page_in_arr_t is array(0 to PAGE_COUNT-1) of string(1 to 7);

    type page_t is array(0 to 7) of integer;
    type page_arr_t is array(0 to PAGE_COUNT-1) of page_t;

    signal page_in_arr : page_in_arr_t;
    signal pages : page_arr_t := (others => (others => 0));

    -- data output
    signal col : unsigned(5 downto 0);
    signal row : unsigned(2 downto 0);

    signal page_index : integer range 0 to PAGE_COUNT-1;
    signal current_page : page_t := (others => 0);

    signal page_col : integer range 0 to 7;
    signal current_char : integer range 0 to CHAR_COUNT-1;

    signal col_index, row_index : integer range 0 to 7;
    signal val_prefix : std_logic_vector(15 downto 0);
begin
    with dbg.z80.state.prefix select
        val_prefix <= x"0000" when main,
                      x"00ed" when ed,
                      x"00cb" when cb,
                      x"00dd" when dd,
                      x"ddcb" when ddcb,
                      x"00fd" when fd,
                      x"fdcb" when fdcbL

    page_in_arr <= (
        (" AF:" & hex_str(dbg.z80.regs.af)),
        (" BC:" & hex_str(dbg.z80.regs.bc)),
        (" DE:", dbg.z80.regs.de),
        (" HL:", dbg.z80.regs.hl),
        (" SP:", dbg.z80.regs.sp),
        (" IX:", dbg.z80.regs.ix),
        (" IY:", dbg.z80.regs.iy),
        (" WZ:", dbg.z80.regs.wz),
        (" PC:", dbg.z80.pc),
        (" PX:", val_prefix),
        (" ID:", dbg.z80.ir),
        (" AB:", dbg.z80.act & dbg.z80.tmp),
        (" DX:", dbg.z80.act & dbg.z80.tmp),
        (" AX:", dbg.z80.act & dbg.z80.tmp),
        (" AP:", dbg.z80.act & dbg.z80.tmp),
        ("  ", dbg.z80.act & dbg.z80.tmp),
        (" 0D ", dbg.z80.act & dbg.z80.tmp),
        (" 0E ", dbg.z80.act & dbg.z80.tmp),
        (" 0F ", dbg.z80.act & dbg.z80.tmp),
        (" 10 ", dbg.z80.act & dbg.z80.tmp),
        (" 11 ", dbg.z80.act & dbg.z80.tmp),
        (" 12 ", dbg.z80.act & dbg.z80.tmp),
        (" 13 ", dbg.z80.act & dbg.z80.tmp),
        (" 14 ", dbg.z80.act & dbg.z80.tmp),
        others => ("    ", x"0000"));

    process(page_in_arr)
        variable dig : std_logic_vector(3 downto 0);
    begin
        for p in pages'range loop
            for c in page_in_arr(p)'range loop
                pages(p)(c) <= chi(page_in_arr(p)(c));
            end loop;
        end loop;
    end process;

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
