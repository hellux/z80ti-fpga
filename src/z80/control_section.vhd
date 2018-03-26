--OPeration decoder by Jakob & Yousef
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_section is
    port(
    clk : in std_logic;
    rst : in std_logic;
   
    di  : in std_logic_vector(7 downto 0);
    do  : out std_logic_vector(7 downto 0);
    
    --rd_addr
    rd_adr : out std_logic_vector(2 downto 0);
    --wr_addr
    wr_adr : out std_logic_vector(2 downto 0);
    --instr
    alu_instr : out std_logic_vector(7 downto 0);
    
    rd, wr          : out std_logic;
    rd_f, wr_f      : out std_logic;
    swp             : out std_logic_vector(1 downto 0));
    
end control_section;


architecture Behavioral of control_section is
    component reg_8
        port ( clk : in std_logic;
               rst : in std_logic;
                
               rd, wr : in std_logic;
               di : in std_logic_vector(7 downto 0);
               do : out std_logic_vector(7 downto 0));
    end component;
     
    signal di_ir : std_logic_vector(7 downto 0);
    signal do_ir : std_logic_vector(7 downto 0);
    signal rd_ir, wr_ir : out std_logic;
    
    signal di_i : std_logic_vector(7 downto 0);
    signal do_i : std_logic_vector(7 downto 0);
    
    signal di_r : std_logic_vector(7 downto 0);
    signal do_r : std_logic_vector(7 downto 0);
    
    --bit coding
    --op1 = bit 7-4
    --op2 = bit 3-0
    --x   = bit 7-6
    --y   = bit 5-3
    --z   = bit 2-0
    --p   = bit 5-4
    --q   = bit 3
    
    signal op1, op2 : std_logic_vector(3 downto 0);
    signal x, p     : std_logic_vector(1 downto 0);
    signal y, z     : std_logic_vector(2 downto 0);
    signal q        : std_logic;
    
    
    type state is (t1, t2, t3, t4, t5);
    signal cur: state := t1;
    
 begin
 
    --Split operand into 2 hex numbers
    op1 <= do_ir(7 downto 4);
    op2 <= do_ir(3 downto 0);
    x   <= do_ir(7 downto 6);
    y   <= do_ir(5 downto 3);
    z   <= do_ir(2 downto 0);
    p   <= do_ir(5 downto 4);
    q   <= do_ir(3);
   

    alu_instr <= do_ir; --Op to ALU
   
    --AND
    
    --op1 = A && op2 < 8
    --des = op2 (2-0)
    --ladda des & a
    --spara i a
    
    --XOR
    
    --op1 = A && op2 > 8
    --des = op2 (2-0)
    --ladda des & a
    --spara i a
    
    --OR
    
    --samma som AND
    --ladda des + a
    --spara i a
    
    
    
    
    --Inc
    
    des <= do_ir(5 downto 3) when (do_ir(7 downto 6) <= "00" and 
           (do_ir(3 downto 2) <= "11" or do_ir(2) <= '1' or do_ir(1 downto 0) <= "11"));
 
 
    --op <= do_ir(7 downto 6);
    des <= do_ir(5 downto 3);
    src <= do_ir(2 downto 0);

    --Instruction register
    IR : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_ir,
        wr => wr_ir,
        di => di_ir,
        do => do_ir);
 
    --Interrupt page address register
    I : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_i,
        wr => wr_i,
        di => di_i,
        do => do_i);
        
    --Memory-refresh register       
    R : reg_8 port map(
        clk => clk,
        rst => rst,
        rd => rd_r,
        wr => wr_r,
        di => di_r,
        do => do_r);
 
    
    
                if (cur = t1) then
                    cur <= t2;
                elsif (cur = t2) then
                    wr <= '1';
                    wr_adr <= "111"; -- Get value from A
                    cur <= t3;
                elsif (cur = t3) then
                    wr <= '1';
                    wr_adr <= op2(2 downto 0); -- Send register value to ALU
                    
                    rd_ir <= '1';
                    cur <= t4;
                elsif (cur = t4) then
                    wr <= '0';
                    rd <= '1';
                    rd_adr <= "111" --Read to A
                    
                    wr_ir <= '1';
                    cur <= t1;
                end if;
 
    
 end Behavioral;
