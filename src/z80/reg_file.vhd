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
    
    rd, wr, swp : in std_logic;
    rd_adr, wr_adr, swp_adr : in std_logic_vector(2 downto 0);
    di : in std_logic_vector(7 downto 0);
    do : out std_logic_vector(7 downto 0);
    );
    
end reg_file;

-- Behavior of reg file
architecture Behavioral of reg_file is
    component reg_8
        port ( clk : in std_logic;
               rst : in std_logic
                
               rd, wr : in std_logic;
               di : in std_logic_vector(7 downto 0);
               do : out std_logic_vector(7 downto 0));
    end component;
    
    component reg_16
        port ( clk : in std_logic;
               rst : in std_logic
                
               rd, wr : in std_logic;
               di : in std_logic_vector(15 downto 0);
               do : out std_logic_vector(15 downto 0));
    end component;

    --Store index for which register to write/read from
    signal rd_map : std_logic_vector(7 downto 0);
    signal wr_map : std_logic_vector(7 downto 0);
    signal wr_int : integer range 0 to 7;
    signal rd_int : integer range 0 to 7;

begin

    --rd_int <= to_integer(unsigned(rd_adr));
    --wr_int <= to_integer(unsigned(rd_adr));
    

    rd_map <= (to_unsigned(rd_adr))   => rd,
               others                 => '0');
    
    wr_map <= (to_unsigned(rd_adr))   => wr,
               others                 => '0');                                    
                                        
    --A 111 
    A : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map(7),
        wr => wr_map(7),
        di => di,
        do => do);
        
    --B 000  
    B : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map(0),
        wr => wr_map(0),
        di => di,
        do => do);
        
    --C 001        
    C : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map(1),
        wr => wr_map(1),
        di => di,
        do => do);
        
    --D 010        
    D : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map(2),
        wr => wr_map(2),
        di => di,
        do => do);
        
    --E 011        
    E : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map(3),
        wr => wr_map(3),
        di => di,
        do => do);
        
    --H 100        
    H : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map(4),
        wr => wr_map(4),
        di => di,
        do => do);
        
    --L 101        
    L : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map(5),
        wr => wr_map(5),
        di => di,
        do => do);
        
    
end Behavioral;
