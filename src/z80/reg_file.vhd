--Register by Jakob & Yousef

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Hardware ports
entity reg_file is
    port(
    clk : in std_logic;
    rst : in std_logic;
    
    rd, wr          : in std_logic;
    rd_adr, wr_adr  : in std_logic_vector(2 downto 0);
    
    --Read & write for non writeable
    rd_f, wr_f      : in std_logic;
  
    --Swp 0 => ingen swap
    --Swp 1 => alla
    --Swp 2 => af / a'f'
    --Swp 3 => de / hl
    swp             : in std_logic_vector(1 downto 0);
    di              : in std_logic_vector(7 downto 0);
    do              : out std_logic_vector(7 downto 0));
    
end reg_file;


-- Behavior of reg file
architecture Behavioral of reg_file is
    component reg_8
        port ( clk : in std_logic;
               rst : in std_logic;
                
               rd, wr : in std_logic;
               di : in std_logic_vector(7 downto 0);
               do : out std_logic_vector(7 downto 0));
    end component;
    
    component reg_16
        port ( clk : in std_logic;
               rst : in std_logic;
                
               rd, wr : in std_logic;
               di : in std_logic_vector(15 downto 0);
               do : out std_logic_vector(15 downto 0));
    end component;
    
    component reg_pair
        port ( clk : in std_logic;
               rst : in std_logic;
                
               rd, wr, swp : in std_logic;
               di : in std_logic_vector(7 downto 0);
               do : out std_logic_vector(7 downto 0));
    end component;

    signal rd_int : integer range 0 to 7;
    signal wr_int : integer range 0 to 7;
    signal rd_map : std_logic_vector(7 downto 0);
    signal wr_map : std_logic_vector(7 downto 0);
    
    signal di_a : std_logic_vector(7 downto 0);
    signal do_a : std_logic_vector(7 downto 0);
    
    signal di_b : std_logic_vector(7 downto 0);
    signal do_b : std_logic_vector(7 downto 0);
    
    signal di_c : std_logic_vector(7 downto 0);
    signal do_c : std_logic_vector(7 downto 0);
    
    signal di_d : std_logic_vector(7 downto 0);
    signal do_d : std_logic_vector(7 downto 0);
    
    signal di_e : std_logic_vector(7 downto 0);
    signal do_e : std_logic_vector(7 downto 0);
    
    signal di_h : std_logic_vector(7 downto 0);
    signal do_h : std_logic_vector(7 downto 0);
    
    signal di_l : std_logic_vector(7 downto 0);
    signal do_l : std_logic_vector(7 downto 0);
    
    signal di_f : std_logic_vector(7 downto 0);
    signal do_f : std_logic_vector(7 downto 0);
    
    signal swp_all  : std_logic;
    signal swp_af   : std_logic;
    signal swp_dehl : std_logic;
    
    signal rd_d     : std_logic;
    signal rd_e     : std_logic;
    signal rd_h     : std_logic;
    signal rd_l     : std_logic;
    
    signal wr_d     : std_logic;
    signal wr_e     : std_logic;
    signal wr_h     : std_logic;
    signal wr_l     : std_logic;

begin

    rd_int <= to_integer(unsigned(rd_adr));
    wr_int <= to_integer(unsigned(wr_adr));

    rd_map <= (rd_int => rd, others => '0');
    
    wr_map <= (wr_int => wr, others => '0');
             
    swp_all <= '1' when swp = "01" else '0';         
    swp_af <= '1' when swp = "10" else '0';
    swp_dehl <= '1' when swp = "11" else '0';
    
    --IN
    di_b <= di when rd_map(0) = '1' else "ZZZZZZZZ";
    di_c <= di when rd_map(1) = '1' else "ZZZZZZZZ";
    di_d <= di when rd_map(2) = '1' else 
            do_h when swp_dehl = '1' else "ZZZZZZZZ";
    di_e <= di when rd_map(3) = '1' else 
            do_l when swp_dehl = '1' else "ZZZZZZZZ";
    di_h <= di when rd_map(4) = '1' else 
            do_d when swp_dehl = '1' else "ZZZZZZZZ";
    di_l <= di when rd_map(5) = '1' else 
            do_e when swp_dehl = '1' else "ZZZZZZZZ";
    di_a <= di when rd_map(7) = '1' else "ZZZZZZZZ";
    
    di_f <= di when rd_f = '1' else "ZZZZZZZZ";
    
    --OUT
    do <=   do_b when wr_map(0) = '1' else
            do_c when wr_map(1) = '1' else
            do_d when wr_map(2) = '1' else
            do_e when wr_map(3) = '1' else 
            do_h when wr_map(4) = '1' else 
            do_l when wr_map(5) = '1' else 
            do_a when wr_map(7) = '1' else 
            do_f when wr_f = '1' else "ZZZZZZZZ";
            
    rd_d <= rd_map(2) or swp_dehl;
    rd_e <= rd_map(3) or swp_dehl;
    rd_h <= rd_map(4) or swp_dehl;
    rd_l <= rd_map(5) or swp_dehl;
    
    wr_d <= wr_map(2) or swp_dehl;
    wr_e <= wr_map(3) or swp_dehl;
    wr_h <= wr_map(4) or swp_dehl;
    wr_l <= wr_map(5) or swp_dehl;
    
    --B 000,
    --C 001
    --D 010
    --E 011
    --H 100
    --L 101
    --  ---
    --A 111
    --F 
    
    --B 000  
    B : reg_pair port map(
        clk => clk,
        rst => rst,
        rd => rd_map(0),
        wr => wr_map(0),
        swp => swp_all,
        di => di_b,
        do => do_b);
        
    --C 001        
    C : reg_pair port map(
        clk => clk,
        rst => rst,
        rd => rd_map(1),
        wr => wr_map(1),
        swp => swp_all,
        di => di_c,
        do => do_c);
         
    --D 010        
    D : reg_pair port map(
        clk => clk,
        rst => rst,
        rd => rd_d,
        wr => wr_d,
        swp => swp_all,
        di => di_d,
        do => do_d);
        
    --E 011        
    E : reg_pair port map(
        clk => clk,
        rst => rst,
        rd => rd_e,
        wr => wr_e,
        swp => swp_all,
        di => di_e,
        do => do_e);
        
    --H 100        
    H : reg_pair port map(
        clk => clk,
        rst => rst,
        rd => rd_h,
        wr => wr_h,
        swp => swp_all,
        di => di_h,
        do => do_h);
        
    --L 101        
    L : reg_pair port map(
        clk => clk,
        rst => rst,
        rd => rd_l,
        wr => wr_l,
        swp => swp_all,
        di => di_l,
        do => do_l);
        
    --A 111
    A : reg_pair port map(
        clk => clk,
        rst => rst,
        rd => rd_map(7),
        wr => wr_map(7),
        swp => swp_af,
        di => di_a,
        do => do_a);
        
     --Can't write 
    F : reg_pair port map(
        clk => clk,
        rst => rst,
        rd => rd_f,
        wr => wr_f,
        swp => swp_af,
        di => di_f,
        do => do_f);
        
        
end Behavioral;
