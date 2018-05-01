library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity m45 is port(
    clk : in std_logic;
    maddr : in std_logic_vector(25 downto 0);
    mdata : inout std_logic_vector(15 downto 0);
    mclk, madv_c, mcre, mce_c, moe_c, mwe_c : in std_logic;
    mlb_c, mub_c : in std_logic;
    mwait : out std_logic);
end m45;

architecture arch of m45 is
    constant STACK_TOP : integer := 16#83fff#;
    constant STACK_SIZE : integer := 128;
    type mem_stack_t is array(STACK_TOP-STACK_SIZE to STACK_TOP)
        of std_logic_vector(7 downto 0);
    signal mem_stack : mem_stack_t := (others => x"00");

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
                end if;
            end if;
            if mem_stack'left <= a and a <= mem_stack'right then
                word_out <= mem_stack(a);
            else
                word_out <= x"cc";
            end if;
        end if;
    end process;

    mdata <= x"00" & word_out when moe_c = '0' else (others => 'Z');
    mwait <= 'Z';
end arch;
