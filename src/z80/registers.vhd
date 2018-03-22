--Register by Jakob & Yousef

-- library declaration for 8
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

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

-- Register 16 bits
entity reg_16 is
    port( clk : in std_logic;
          rst : in std_logic;
        
          rd, wr : in std_logic;
          di : in std_logic_vector(15 downto 0);
          do : out std_logic_vector(15 downto 0));
    
end reg_16;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Register primpair
entity reg_pair is
    port( clk : in std_logic;
          rst : in std_logic;
          
          rd, wr, swp : in std_logic;
          di : in std_logic_vector(7 downto 0);
          do : out std_logic_vector(7 downto 0));
          
end reg_pair;

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
            end if;
        end if;
    end process;
    
    do <= bits when wr = '1' else (others => 'Z');
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
            end if;
        end if;
    end process;
    
    do <= bits when wr = '1' else (others => 'Z');
    
end Behavioral;

-- Behavior of reg pair 
architecture Behavioral of reg_pair is
    component reg_8
        port ( clk : in std_logic;
               rst : in std_logic;
                
               rd, wr : in std_logic;
               di : in std_logic_vector(7 downto 0);
               do : out std_logic_vector(7 downto 0));
    end component;
    
    signal di_x_prim : std_logic_vector(7 downto 0);
    signal do_x_prim : std_logic_vector(7 downto 0);
    signal di_x      : std_logic_vector(7 downto 0);
    signal do_x      : std_logic_vector(7 downto 0);
    signal rd_x      : std_logic;
begin  

    rd_x <= (rd or swp);
            
    di_x <= do_x_prim when swp = '1' else di;
    
    X : reg_8 port map(
        clk => clk,
        rst => rst,
        rd  => rd_x,
        wr  => '1',
        di  => di_x,
        do  => do_x);
    
    do <= do_x when wr = '1' else "ZZZZZZZZ";
    di_x_prim <= do_x;
    
    X_prim : reg_8 port map(
        clk => clk,
        rst => rst,
        rd  => swp,
        wr  => '1',
        di  => di_x_prim,
        do  => do_x_prim);
        
end Behavioral;

