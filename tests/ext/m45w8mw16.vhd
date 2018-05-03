library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity m45 is port(
    clk : in std_logic;
    maddr : in std_logic_vector(25 downto 0);
    mdata : inout std_logic_vector(15 downto 0);
    mclk, madv_c, mcre, mce_c, moe_c, mwe_c : in std_logic;
    mlb_c, mub_c : in std_logic);
end m45;

architecture arch of m45 is
    constant ROM_START : integer := 16#00000#;
    constant ROM_SIZE : integer := 256;
    constant STACK_TOP : integer := 16#83fff#;
    constant STACK_SIZE : integer := 128;

    type mem_rom_t is array(ROM_START to ROM_START+ROM_SIZE)
        of std_logic_vector(7 downto 0);
    type mem_stack_t is array(STACK_TOP-STACK_SIZE to STACK_TOP)
        of std_logic_vector(7 downto 0);

    impure function file_to_mem(filename : string) return mem_rom_t is
        use std.textio.all;
        type charfile is file of character;
        file file_p : charfile;
        variable word : character;
        variable mem : mem_rom_t;
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

    signal mem_stack : mem_stack_t := (others => x"00");
    signal mem_rom : mem_rom_t := file_to_mem("a.bin");

    signal word_out : std_logic_vector(7 downto 0);
    signal a : integer;
begin
    a <= to_integer(unsigned(maddr));

    process(clk) begin
        if rising_edge(clk) then
            if mce_c = '0' then
                if mwe_c = '0' then
                    if mem_stack'left <= a and a <= mem_stack'right then
                        mem_stack(a) <= mdata(7 downto 0);
                    end if;
                    if mem_rom'left <= a and a <= mem_rom'right then
                        mem_stack(a) <= mdata(7 downto 0);
                    end if;
                end if;
            end if;
            if mem_stack'left <= a and a <= mem_stack'right then
                word_out <= mem_stack(a);
            elsif mem_rom'left <= a and a <= mem_rom'right then
                word_out <= mem_rom(a);
            else
                word_out <= x"cc";
            end if;
        end if;
    end process;

    mdata <= x"00" & word_out when moe_c = '0' else (others => 'Z');
end arch;
