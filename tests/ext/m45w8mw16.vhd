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
    constant PC_START : integer := 16#7c000#;

    constant RAM_SIZE : integer := 256;
    constant ROM_SIZE : integer := 256;
    constant STACK_SIZE : integer := 128;

    constant RAM_L : integer := 16#00000#;
    constant RAM_R : integer := RAM_L + RAM_SIZE-1;
    constant JP_L : integer := PC_START;
    constant JP_R : integer := PC_START+2;
    constant ROM_L : integer := 16#7dd49#;
    constant ROM_R : integer := ROM_L+ROM_SIZE-1;
    constant STACK_R : integer := 16#7ffff#;
    constant STACK_L : integer := STACK_R-STACK_SIZE-1;

    type mem_t is array(integer range <>) of std_logic_vector(7 downto 0);

    impure function file_to_mem(filename : string; size : natural) return mem_t is
        use std.textio.all;
        type charfile is file of character;
        file file_p : charfile;
        variable word : character;
        variable mem : mem_t(0 to size-1);
        use ieee.numeric_std.all;
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

    procedure write(signal mem : inout mem_t;
                    signal data : in std_logic_vector(7 downto 0);
                    signal addr : in integer) is begin
        if mem'left <= addr and addr <= mem'right then
            mem(addr) <= data;
        end if;
    end procedure;

    signal mem_ram : mem_t(RAM_L to RAM_R) := (others => x"00");
    signal mem_rom : mem_t(ROM_L to ROM_R) := file_to_mem("a.bin", ROM_SIZE);
    signal mem_jp : mem_t(JP_L to JP_R) := (x"c3", x"95", x"9d");
    signal mem_stack : mem_t(STACK_L to STACK_R) := (others => x"00");

    signal word_out : std_logic_vector(15 downto 0);
    signal a_ub, a_lb : integer;
begin
    a_ub <= to_integer(unsigned(maddr))*2+1;
    a_lb <= to_integer(unsigned(maddr))*2;

    process(clk) begin
        if rising_edge(clk) then
            if mce_c = '0' then
                if mwe_c = '0' then
                    -- write upper byte
                    if mub_c = '0' then 
                        write(mem_rom, mdata(15 downto 8), a_ub);
                        write(mem_ram, mdata(15 downto 8), a_ub);
                        write(mem_stack, mdata(15 downto 8), a_ub);
                    end if;
                    -- write lower byte
                    if mlb_c = '0' then 
                        write(mem_rom, mdata(7 downto 0), a_lb);
                        write(mem_ram, mdata(7 downto 0), a_lb);
                        write(mem_stack, mdata(7 downto 0), a_lb);
                    end if;
                end if;

                -- read upper byte
                if mem_ram'left <= a_ub and a_ub <= mem_ram'right then
                    word_out(15 downto 8) <= mem_ram(a_ub);
                elsif mem_rom'left <= a_ub and a_ub <= mem_rom'right then
                    word_out(15 downto 8) <= mem_rom(a_ub);
                elsif mem_stack'left <= a_ub and a_ub <= mem_stack'right then
                    word_out(15 downto 8) <= mem_stack(a_ub);
                elsif mem_jp'left <= a_ub and a_ub <= mem_jp'right then
                    word_out(15 downto 8) <= mem_jp(a_ub);
                else
                    word_out(15 downto 8) <= x"76";
                end if;

                -- read lower byte
                if mem_ram'left <= a_lb and a_lb <= mem_ram'right then
                    word_out(7 downto 0) <= mem_ram(a_lb);
                elsif mem_rom'left <= a_lb and a_lb <= mem_rom'right then
                    word_out(7 downto 0) <= mem_rom(a_lb);
                elsif mem_stack'left <= a_lb and a_lb <= mem_stack'right then
                    word_out(7 downto 0) <= mem_stack(a_lb);
                elsif mem_jp'left <= a_lb and a_lb <= mem_jp'right then
                    word_out(7 downto 0) <= mem_jp(a_lb);
                else
                    word_out(7 downto 0) <= x"76";
                end if;
            end if;
        end if;
    end process;

    mdata <= word_out when moe_c = '0' else (others => 'Z');
end arch;
