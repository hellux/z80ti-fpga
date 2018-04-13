library ieee;
use ieee.std_logic_1164.all;

entity reg is generic(size : integer); port(
    clk, rst : in std_logic;
    rd : in std_logic;
    di : in std_logic_vector(size-1 downto 0);
    do : out std_logic_vector(size-1 downto 0));
end reg;

architecture Behavioral of reg is
    signal bits : std_logic_vector(size-1 downto 0) := (others => '0');
    signal bits_next : std_logic_vector(size-1 downto 0);
begin  
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                bits <= (others => '0');
            else 
                bits <= bits_next;
            end if;
        end if;
    end process;
    bits_next <= di when rd = '1' else bits;
    do <= bits;
end Behavioral;

-- buffers, like registers but write on same cp
library ieee;
use ieee.std_logic_1164.all;

entity buf is generic (size : integer); port(
    clk, rst : in std_logic;
    rd : in std_logic;
    di : in std_logic_vector(size-1 downto 0);
    do : out std_logic_vector(size-1 downto 0));
end buf;

architecture arch of buf is
    signal bits, bits_next : std_logic_vector(size-1 downto 0);
begin
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                bits <= (others => '0');
            else
                bits <= bits_next;
            end if;
        end if;
    end process;
    bits_next <= di when rd = '1' else bits;
    do <= bits_next;
end arch;
