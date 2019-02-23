library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util.all;

entity m45 is port(
    clk : in std_logic;
    maddr : in std_logic_vector(25 downto 0);
    mdata : inout std_logic_vector(15 downto 0);
    mclk, madv_c, mcre, mce_c, moe_c, mwe_c : in std_logic;
    mlb_c, mub_c : in std_logic);
end m45;

architecture arch of m45 is
    constant ROM_SIZE : integer := 256;
    constant INIT_SIZE : integer := 62;
    constant APP_SIZE : integer := 2048;
    constant STACK_SIZE : integer := 256;
    constant RAM_SIZE : integer := 128;
    constant TRACE_SIZE : integer := 256;

    constant INIT_L : integer := 16#7c000#;
    constant INIT_R : integer := INIT_L+INIT_SIZE-1;

    constant APP_L : integer := 16#81d49#;
    constant APP_R : integer := APP_L+APP_SIZE-1;

    constant ROM_L : integer := 16#00000#;
    constant ROM_R : integer := ROM_L+ROM_SIZE-1;
    constant RAM_L : integer := 16#87000#;
    constant RAM_R : integer := RAM_L+RAM_SIZE-1;
    constant IM2_TBL_L : integer := 16#81900#; -- (9900)
    constant IM2_TBL_R : integer := 16#819ff#;
    constant IM2_JP_L : integer := 16#81a9a#; -- (9a9a)
    constant IM2_JP_R : integer := 16#81a9c#;
    constant OPRAM_L : integer := 16#84478#; -- (0x8478)
    constant OPRAM_R : integer := OPRAM_L+11*6-1;

    constant STACK_R : integer := 16#87fff#; -- (0xffff)
    constant STACK_L : integer := STACK_R-STACK_SIZE+1;

    constant TRACE_L : integer := 16#088000#;
    constant TRACE_R : integer := TRACE_L+TRACE_SIZE-1;

    type mem_t is array(integer range <>) of std_logic_vector(7 downto 0);

    impure function file_to_mem(filename : string; size : natural)
    return mem_t is
        use std.textio.all;
        type charfile is file of character;
        file file_p : charfile;
        variable word : character;
        variable mem : mem_t(0 to size-1);
    begin
        mem := (others => x"00");
        file_open(file_p, filename, READ_MODE);
        for i in mem'range loop
            if endfile(file_p) then exit; end if; 
            read(file_p, word);
            mem(i) := std_logic_vector(to_unsigned(character'pos(word), 8));
        end loop;
        file_close(file_p);
        return mem;
    end function;

    procedure read(signal mem : inout mem_t;
                   signal a : in integer;
                   signal data : out std_logic_vector(15 downto 0)) is begin
        if mem'left <= a+1 and a+1 <= mem'right then
            data(15 downto 8) <= mem(a+1);
        end if;
        if mem'left <= a and a <= mem'right then
            data(7 downto 0) <= mem(a);
        end if;
    end procedure;

    procedure write(signal mem : inout mem_t;
                    signal mub_c, mlb_c : in std_logic;
                    signal a : in integer;
                    signal data : in std_logic_vector(15 downto 0)) is begin
        if mub_c = '0' then 
            if mem'left <= a+1 and a+1 <= mem'right then
                mem(a+1) <= data(15 downto 8);
            end if;
        end if;
        if mlb_c = '0' then 
            if mem'left <= a and a <= mem'right then
                mem(a) <= data(7 downto 0);
            end if;
        end if;
    end procedure;

    signal mem_rom : mem_t(ROM_L to ROM_R) := (others => x"00");
    signal mem_ram : mem_t(RAM_L to RAM_R) := (others => x"00");
    signal mem_im2_tbl : mem_t(IM2_TBL_L to IM2_TBL_R) := (others => x"9a");
    signal mem_im2_jp : mem_t(IM2_JP_L to IM2_JP_R) := (others => x"00");
    signal mem_app : mem_t(APP_L to APP_R) := file_to_mem("a.bin", APP_SIZE);
    signal mem_stack : mem_t(STACK_L to STACK_R) := (others => x"00");
    signal mem_trace : mem_t(TRACE_L to TRACE_R) := (others => x"00");

    -- jump to user ram/app, pc init
    signal mem_init : mem_t(INIT_L to INIT_R)
        := file_to_mem("tests/binary/init.z", INIT_SIZE);

    signal word_out : std_logic_vector(15 downto 0);
    signal a_ub, a_lb : integer;
begin
    a_ub <= to_integer(unsigned(maddr))*2+1;
    a_lb <= to_integer(unsigned(maddr))*2;

    process(clk) begin
        if rising_edge(clk) then
            if mce_c = '0' then
                if mwe_c = '0' then
                    write(mem_rom, mub_c, mlb_c, a_lb, mdata);
                    write(mem_app, mub_c, mlb_c, a_lb, mdata);
                    write(mem_ram, mub_c, mlb_c, a_lb, mdata);
                    write(mem_im2_tbl, mub_c, mlb_c, a_lb, mdata);
                    write(mem_im2_jp, mub_c, mlb_c, a_lb, mdata);
                    write(mem_stack, mub_c, mlb_c, a_lb, mdata);
                    write(mem_trace, mub_c, mlb_c, a_lb, mdata);
                end if;
                word_out <= x"7676";
                read(mem_rom, a_lb, word_out);
                read(mem_app, a_lb, word_out);
                read(mem_ram, a_lb, word_out);
                read(mem_im2_tbl, a_lb, word_out);
                read(mem_im2_jp, a_lb, word_out);
                read(mem_stack, a_lb, word_out);

                read(mem_init, a_lb, word_out);
            end if;
        end if;
    end process;

    mdata <= word_out when moe_c = '0' else (others => 'Z');
end arch;
