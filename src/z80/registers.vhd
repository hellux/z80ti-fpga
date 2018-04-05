--Register by Jakob & Yousef
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg_8 is port(
    clk, rst : in std_logic;
    rd, wr : in std_logic;
    di : in std_logic_vector(7 downto 0);
    do : out std_logic_vector(7 downto 0));
end reg_8;

architecture Behavioral of reg_8 is
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
    do <= bits when wr = '1' else (others => 'Z');
    assert rd = '0' or di /= "ZZZZZZZZ" report "reading Zzzz";
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg_16 is port( 
    clk, rst : in std_logic;
    rd, wr : in std_logic;
    di : in std_logic_vector(15 downto 0);
    do : out std_logic_vector(15 downto 0));    
end reg_16;

architecture Behavioral of reg_16 is
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
    do <= bits when wr = '1' else (others => 'Z');
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg_pair is port(
    clk, rst : in std_logic;
    rd, wr, swp : in std_logic;
    di : in std_logic_vector(7 downto 0);
    do : out std_logic_vector(7 downto 0));
end reg_pair;

architecture Behavioral of reg_pair is
    component reg_8 port (
        clk, rst : in std_logic;
        rd, wr : in std_logic;
        di : in std_logic_vector(7 downto 0);
        do : out std_logic_vector(7 downto 0));
    end component;
    
    signal di_x_prim : std_logic_vector(7 downto 0);
    signal do_x_prim : std_logic_vector(7 downto 0);
    signal di_x      : std_logic_vector(7 downto 0);
    signal do_x      : std_logic_vector(7 downto 0);
    signal rd_x      : std_logic;
    signal wr_x      : std_logic;
begin  
    X : reg_8 port map(clk, rst, rd_x, wr_x, di_x, do_x);
    X_prim : reg_8 port map(clk, rst, rd=>swp, wr=>swp,
                            di=>di_x_prim, do=>do_x_prim);

    rd_x <= rd or swp;
    wr_x <= wr or swp;
    di_x <= do_x_prim   when swp = '1' else 
            di          when swp = '0';
    do <= do_x when wr = '1' else "ZZZZZZZZ";
    di_x_prim <= do_x;
end Behavioral;

-- buffers, like registers but write on same cp
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

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
    do <= bits_next when rd = '1' else (others => 'Z');
end arch;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

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
    do <= bits_next when rd = '1' else (others => 'Z');
end arch;
