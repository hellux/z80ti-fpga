library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity m45 is port(
    clk : in std_logic;
    maddr : in std_logic_vector(26 downto 0);
    mdata : inout std_logic_vector(15 downto 0);
    mclk, madv_c, mcre, mce_c, moe_c, mwe_c : in std_logic;
    mlb_c, mub_c : in std_logic;
    mwait : out std_logic);
end m45;

architecture arch of m45 is
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

    -- signal mem : mem_t := (others => (others => '0'));
    signal mem : mem_t := file_to_mem("a.bin");
    signal word_out : std_logic_vector(7 downto 0);
begin
    process(clk)
        variable a : integer range 16#0# to 16#fffff# := 0;
    begin
        a := to_integer(unsigned(maddr));
        if rising_edge(clk) then
            if mce_c = '0' then
                if mwe_c = '0' then
                    if a < mem'length then
                        mem(a) <= mdata(7 downto 0);
                    end if;
                end if;
                if a < mem'length then
                    word_out <= mem(a);
                else
                    word_out <= x"cc";
                end if;
            end if;
        end if;
    end process;

    mdata <= x"00" & word_out when moe_c = '0' else (others => 'Z');
    mwait <= 'Z';
end arch;
