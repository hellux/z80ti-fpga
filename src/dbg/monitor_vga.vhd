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

    type page_in_t is record
        title : string(1 to 4);
        data : std_logic_vector(15 downto 0);
    end record;
    type page_in_arr_t is array(0 to PAGE_COUNT-1) of page_in_t;

    type page_t is array(0 to 7) of integer;
    type page_arr_t is array(0 to PAGE_COUNT-1) of page_t;

    signal page_in_arr : page_in_arr_t;
    signal pages : page_arr_t := (others => (others => 0));

    -- page write
    signal wr_page : integer range 0 to PAGE_COUNT-1;
    signal wr_page_char : unsigned(1 downto 0);

    -- data output
    signal col : unsigned(5 downto 0);
    signal row : unsigned(2 downto 0);

    signal page_index : integer range 0 to PAGE_COUNT-1;
    signal current_page : page_t := (others => 0);

    signal page_col : integer range 0 to 7;
    signal current_char : integer range 0 to CHAR_COUNT-1;

    signal col_index, row_index : integer range 0 to 7;
begin
    page_in_arr <= (
        (" AF ", dbg.z80.regs.af),
        (" BC ", dbg.z80.regs.bc),
        (" DE ", dbg.z80.regs.de),
        (" HL ", dbg.z80.regs.hl),
        (" SP ", dbg.z80.regs.sp),
        (" IX ", dbg.z80.regs.ix),
        others => ("    ", x"0000"));

    process(clk)
        variable dig : std_logic_vector(3 downto 0);
        variable char_index : integer range 4 to 7;
    begin
        if rising_edge(clk) then
            wr_page_char <= wr_page_char + 1;

            case wr_page_char is
            when "00" => dig := page_in_arr(wr_page).data(15 downto 12);
            when "01" => dig := page_in_arr(wr_page).data(11 downto 8);
            when "10" => dig := page_in_arr(wr_page).data(7 downto 4);
            when "11" => dig := page_in_arr(wr_page).data(3 downto 0);
            when others => dig := "0000";
            end case;
            char_index := to_integer(wr_page_char) + 4;

            -- constant titles
            for i in pages'range loop
                for j in page_in_arr(i).title'range loop
                    pages(i)(j-1) <= chi(page_in_arr(i).title(j));
                end loop;
            end loop;
            -- variable data
            pages(wr_page)(char_index) <= to_integer(unsigned(dig));

            if (wr_page_char = 3) then
                if wr_page = PAGE_SIZE - 1 then
                    wr_page <= 0;
                else
                    wr_page <= wr_page + 1;
                end if;
            end if;

            current_page <= pages(page_index);
            data_vga <= char_arr(current_char)(row_index)(col_index);
        end if;
    end process;

    col <= unsigned(x_vga(8 downto 3));
    row <= unsigned(y_vga(5 downto 3));

    page_index <= to_integer(col(5 downto 3))*ROWS + to_integer(row);

    page_col <= to_integer(unsigned(col(3 downto 1)));
    current_char <= current_page(page_col);

    col_index <= to_integer(unsigned(x_vga(2 downto 0)));
    row_index <= to_integer(unsigned(y_vga(2 downto 0)));
end arch;
