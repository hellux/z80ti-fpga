library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bram is generic(dwidth : integer;
                       size : integer;
                       awidth : integer); port(
    clk, ce : in std_logic;
    wea, web : in std_logic;
    addra, addrb : in std_logic_vector(awidth-1 downto 0);
    data_ina, data_inb : in std_logic_vector(dwidth-1 downto 0);
    data_outa, data_outb : out std_logic_vector(dwidth-1 downto 0));
end bram;

architecture arch of bram is
    type bram_mem_t is array(0 to size-1) of
        std_logic_vector(dwidth-1 downto 0); 
    signal mem : bram_mem_t := (others => (others => '0'));
begin
    process(clk) begin
        if rising_edge(clk) then
            if ce = '1' then
                if wea = '1' then
                    mem(to_integer(unsigned(addra))) <= data_ina;
                end if;
                data_outa <= mem(to_integer(unsigned(addra)));

                if web = '1' then
                    mem(to_integer(unsigned(addrb))) <= data_inb;
                end if;
                data_outb <= mem(to_integer(unsigned(addrb)));
            end if;
        end if;
    end process;
end arch;
