library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity m45 is port(
    clk : in std_logic;
    maddr : in std_logic_vector(26 downto 0);
    mdata : inout std_logic_vector(15 downto 0);
    mclk, madv_c, mcre, mce_c, moe_c, mwe_c : in std_logic;
    mlb_c, mub_c : in std_logic;
    mwait : out std_logic);
end m45;

architecture arch of m45 is
    type mem_t is array(128 to 255) of std_logic_vector(7 downto 0);
    signal mem : mem_t;
    signal word_out : std_logic_vector(7 downto 0);
    signal a : integer;
begin
    a <= to_integer(unsigned(maddr));

    process(clk) begin
        if rising_edge(clk) then
            if mce_c = '0' then
                if mwe_c = '0' then
                    if 128 <= a and a <= 255 then
                        mem(a) <= mdata(7 downto 0);
                    end if;
                end if;
            end if;
            if 128 <= a and a <= 255 then
                word_out <= mem(a);
            else
                word_out <= x"cc";
            end if;
        end if;
    end process;

    mdata <= x"00" & word_out when moe_c = '0' else (others => 'Z');
    mwait <= 'Z';
end arch;
