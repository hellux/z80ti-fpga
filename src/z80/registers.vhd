library ieee;
use ieee.std_logic_1164.all;

entity reg_8 is port(
    clk, rst : in std_logic;
    rd, wr : in std_logic;
    di : in std_logic_vector(7 downto 0);
    do : out std_logic_vector(7 downto 0));
end reg_8;

architecture Behavioral of reg_8 is
    signal bits, bits_next : std_logic_vector(7 downto 0) := "00000000";
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
    do <= bits when wr = '1' else (others => 'Z');
end Behavioral;

library ieee;
use ieee.std_logic_1164.all;

entity reg_16 is port( 
    clk, rst : in std_logic;
    rd, wr : in std_logic;
    di : in std_logic_vector(15 downto 0);
    do : out std_logic_vector(15 downto 0));    
end reg_16;

architecture Behavioral of reg_16 is
    signal bits, bits_next : std_logic_vector(15 downto 0)
        := "0000000000000000";
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
    do <= bits when wr = '1' else (others => 'Z');
end Behavioral;

-- buffers, like registers but write on same cp
library ieee;
use ieee.std_logic_1164.all;

entity buf8 is port(
    clk, rst : in std_logic;
    rd, wr : in std_logic;
    di : in std_logic_vector(7 downto 0);
    do : out std_logic_vector(7 downto 0));
end buf8;

architecture arch of buf8 is
    signal bits, bits_next : std_logic_vector(7 downto 0);
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
    do <= bits_next when wr = '1' else (others => 'Z');
end arch;

library ieee;
use ieee.std_logic_1164.all;

entity buf16 is port(
    clk, rst : in std_logic;
    rd, wr : in std_logic;
    di : in std_logic_vector(15 downto 0);
    do : out std_logic_vector(15 downto 0));
end buf16;

architecture arch of buf16 is
    signal bits, bits_next : std_logic_vector(15 downto 0);
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
    do <= bits_next when wr = '1' else (others => 'Z');
end arch;
