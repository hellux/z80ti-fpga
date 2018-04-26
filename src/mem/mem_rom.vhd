library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity mem_rom is port(
    clk : in std_logic;
    rd, wr, ce : in std_logic;
    addr : in std_logic_vector(13 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0));
end mem_rom;

architecture arch of mem_rom is
    type mem_t is array(0 to 127) of std_logic_vector(7 downto 0);

    impure function file_to_mem(filename : string) return mem_t is
        use std.textio.all;
        type charfile is file of character;
        file file_p : charfile;
        variable word : character;
        variable mem : mem_t;
        use ieee.numeric_std.all;
    begin
        mem := (others => x"00");
        file_open(file_p, filename, READ_MODE);
        for i in mem_t'range loop
            if endfile(file_p) then exit; end if;
            read(file_p, word);
            mem(i) := std_logic_vector(to_unsigned(character'pos(word), 8));
        end loop;
        file_close(file_p);
        return mem;
    end function;

    --signal mem : mem_t := file_to_mem("a.bin");
    signal mem : mem_t := (others =>(others => '0'));
    signal word_out : std_logic_vector(7 downto 0);
    signal a : integer range 0 to 16383 := 0;
begin
    a <= to_integer(unsigned(addr));

    process(clk) begin
        if rising_edge(clk) then
            if ce = '1' then
                if rd = '1' then
                    mem(a) <= data_in;
                end if;
                word_out <= mem(a);
            end if;
        end if;
    end process;

    data_out <= word_out when ce = '1' and wr = '1' else x"00";
end arch;
