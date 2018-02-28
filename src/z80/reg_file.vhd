--Register by Jakob & Yousef

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Hardware ports
entity reg_file is
    port(
    clk : in std_logic;
    rst : in std_logic
    
    rd, wr : in std_logic;
    rd_adr, wr_adr : in std_logic_vector(2 downto 0);
    di : in std_logic_vector(7 downto 0);
    do : out std_logic_vector(7 downto 0);
    );
    
end reg_file;

-- Behavior of reg file
architecture Behavioral of reg_8 is
    component reg_8
        port ( clk : in std_logic;
               rst : in std_logic
                
               read, write : in std_logic;
               di : in std_logic_vector(7 downto 0);
               do : out std_logic_vector(7 downto 0));
    end component;
    
    component reg_16
        port ( clk : in std_logic;
               rst : in std_logic
                
               read, write : in std_logic;
               di : in std_logic_vector(15 downto 0);
               do : out std_logic_vector(15 downto 0));
    end component;

    signal databus : unsigned(7 downto 0);

begin
    
    
end Behavioral;
