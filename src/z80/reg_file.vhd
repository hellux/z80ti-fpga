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
    f_rd, f_wr      : in std_logic;
    w_rd, w_wr      : in std_logic;
    z_rd, z_wr      : in std_logic;
    
    --Swp 0 => ingen swap
    --Swp 1 => alla
    --Swp 2 => af / a'f'
    --Swp 3 => de / hl
    swp             : in integer range 0 to 3;
    di_a              : in std_logic_vector(7 downto 0);
    do_a              : out std_logic_vector(7 downto 0));
    
    di_b              : in std_logic_vector(7 downto 0);
    do_b              : out std_logic_vector(7 downto 0));
    
    di_c              : in std_logic_vector(7 downto 0);
    do_c              : out std_logic_vector(7 downto 0));
    
    di_d              : in std_logic_vector(7 downto 0);
    do_d              : out std_logic_vector(7 downto 0));
    
    di_e              : in std_logic_vector(7 downto 0);
    do_e              : out std_logic_vector(7 downto 0));
    
    di_h              : in std_logic_vector(7 downto 0);
    do_h              : out std_logic_vector(7 downto 0));
    
    di_l              : in std_logic_vector(7 downto 0);
    do_l              : out std_logic_vector(7 downto 0));
    
    di_f              : in std_logic_vector(7 downto 0);
    do_f              : out std_logic_vector(7 downto 0));
    
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

    --Store index for which register to write/read from
    signal rd_map : std_logic_vector(7 downto 0);
    signal wr_map : std_logic_vector(7 downto 0);
    signal wr_int : integer range 0 to 7;
    signal rd_int : integer range 0 to 7;
    signal rd_adr_prim : std_logic_vector(2 downto 0);
    signal wr_adr_prim : std_logic_vector(2 downto 0);
    
    signal swp_all : std_logic;
    signal swp_af : std_logic;
    signal swp_dehl : std_logic;

begin

    rd_int <= to_integer(unsigned(rd_adr));
    wr_int <= to_integer(unsigned(rd_adr));
    

    rd_map <= (rd_int   => rd,
               others   => '0');
    
    wr_map <= (wr_int   => wr,
               others   => '0');
               
    --Swap all
    --B
    di_b <= di_b when swp_all = '0' else
            do_b_prim when swp_all = '1';
            
    di_b_prim <= di_b_prim when swp_all = '0' else
            do_b when swp_all = '1';
            
    --C     
    di_c <= di_c when swp_all = '0' else
            do_c_prim when swp_all = '1';
            
    di_c_prim <= di_c_prim when swp_all = '0' else
            do_c when swp_all = '1';
            
    --D
    di_d <= di_d when swp_all = '0' else
            do_d_prim when swp_all = '1';
            
    di_d_prim <= di_d_prim when swp_all = '0' else
            do_d when swp_all = '1';
            
    --E        
    di_e <= di_e when swp_all = '0' else
            do_e_prim when swp_all = '1';
            
    di_e_prim <= di_e_prim when swp_all = '0' else
            do_e when swp_all = '1';
            
    --H        
    di_h <= di_h when swp_all = '0' else
            do_h_prim when swp_all = '1';
            
    di_h_prim <= di_h_prim when swp_all = '0' else
            do_h when swp_all = '1';
            
    --L        
    di_l <= di_l when swp_all = '0' else
            do_l_prim when swp_all = '1';
            
    di_l_prim <= di_l_prim when swp_all = '0' else
            do_l when swp_all = '1';
            
            
            
    --Swap AF
    --A
    di_a <= di_a when swp_af = '0' else
            do_a_prim when swp_af = '1';
            
    di_a_prim <= di_a_prim when swp_af = '0' else
            do_a when swp_af = '1';
            
    --F
    di_f <= di_f when swp_af = '0' else
            do_f_prim when swp_af = '1';
            
    di_f_prim <= di_f_prim when swp_af = '0' else
            do_f when swp_af = '1';
            
            
            
    --Swap de/hl
    
    di_d <= di_d when swp_dehl = '0' else
            do_h when swp_dehl = '1';
            
    di_e <= di_e when swp_dehl = '0' else
            do_l when swp_dehl = '1';
            
    di_h <= di_h when swp_dehl = '0' else
            do_d when swp_dehl = '1';
            
    di_l <= di_l when swp_dehl = '0' else
            do_e when swp_dehl = '1';
            
                   
    --Can't write 
    F : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => f_rd,
        wr => f_wr,
        di => di,
        do => do);
        
    --Can't write 
    W : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => w_rd,
        wr => w_wr,
        di => di,
        do => do);
    
    --Can't write 
    Z : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => z_rd,
        wr => z_wr,
        di => di,
        do => do);    
                                     
                                        
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
        
    --Prim regs
    
    F_prim : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => '0',
        wr => '0',
        di => di,
        do => do);
        
    W_prim : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => '0',
        wr => '0',
        di => di,
        do => do);
       
    Z_prim : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => '0',
        wr => '0',
        di => di,
        do => do);
        
    A_prim : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map_prim(7),
        wr => wr_map_prim(7),
        di => di,
        do => do);
        
    B_prim : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map_prim(0),
        wr => wr_map_prim(0),
        di => di,
        do => do);
        
    C_prim : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map_prim(1),
        wr => wr_map_prim(1),
        di => di,
        do => do);
       
    D_prim : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map_prim(2),
        wr => wr_map_prim(2),
        di => di,
        do => do);
        
    E_prim : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map_prim(3),
        wr => wr_map_prim(3),
        di => di,
        do => do);    
        
    H_prim : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map_prim(4),
        wr => wr_map_prim(4),
        di => di,
        do => do);
       
    L_prim : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_map_prim(5),
        wr => wr_map_prim(5),
        di => di,
        do => do);    
        
end Behavioral;
