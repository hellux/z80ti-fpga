--Register by Jakob & Yousef

-- library declaration for 8
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Register 8 bits
entity reg_8 is
    port( clk : in std_logic;
          rst : in std_logic;
        
          rd, wr : in std_logic;
          di : in std_logic_vector(7 downto 0);
          do : out std_logic_vector(7 downto 0));
    
end reg_8;

-- library declaration for 16
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Register 16 bits
entity reg_16 is
    port( clk : in std_logic;
          rst : in std_logic;
        
          rd, wr : in std_logic;
          di : in std_logic_vector(15 downto 0);
          do : out std_logic_vector(15 downto 0));
    
end reg_16;

-- Behavior of reg 8 bits
architecture Behavioral of reg_8 is
    signal bits : std_logic_vector(7 downto 0);

begin  
    process(clk) begin
        if rising_edge(clk) then
            if (rst = '1') then
                bits <= (others => '0');
            else
                if (rd = '1') then
                    bits <= di;
                end if;
                if (wr = '1') then
                    do <= bits;
                else 
                    do <= (others => 'Z');
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;

-- Behavior of reg 16 bits
architecture Behavioral of reg_16 is
    signal bits : std_logic_vector(15 downto 0);

begin
    process(clk) begin
        if rising_edge(clk) then
            if (rst = '1') then
                bits <= (others => '0');
            else
                if (rd = '1') then
                    bits <= di;
                end if;
                if (wr = '1') then
                    do <= bits;
                else 
                    do <= (others => 'Z');
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;
