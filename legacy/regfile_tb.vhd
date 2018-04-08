-- TestBench register swap

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY regfile_tb IS
END regfile_tb;

architecture Behavioral of regfile_tb is
    component reg_file 
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
    
end component;

    --Store index for which register to write/read from
    signal clk              : std_logic;
    signal rst              : std_logic := '0'; 
    signal rd_regs          : std_logic := '0';
    signal wr_regs          : std_logic := '0';
    signal rd_adr, wr_adr   : std_logic_vector(2 downto 0);
    signal rd_f, wr_f       : std_logic := '0';
    signal swp_regs         : std_logic_vector(1 downto 0);
    signal dbus             : std_logic_vector(7 downto 0) := "00000000";
       
begin
    
    regs : reg_file port map(
        clk => clk,
        rst => rst,
        rd => rd_regs,
        wr => wr_regs,
        rd_adr =>rd_adr,
        wr_adr =>wr_adr,
        rd_f => rd_f,
        wr_f => wr_f,
        swp => swp_regs,
        di => dbus,
        do => dbus
        );
        
process begin
    while true loop
    
      clk <= '1';
      wait for 5 ns;
      clk <= '0';
      wait for 5 ns;
    end loop;
end process;

  stimuli_generator : process
    variable i : integer;
  begin
    --RESET
    wait for 10 ns;
    rst <= '1';
    wait for 10 ns;
    rst <= '0';
    wr_adr <= "000";
    rd_adr <= "000";
    swp_regs <= "00";
    dbus <= "ZZZZZZZZ";
    wait for 10 ns;
    
    --Read A
    dbus <= "11110000";
    rd_adr <= "111";
    rd_regs <= '1';
    wait for 10 ns;
    dbus <= "ZZZZZZZZ";
    rd_regs <= '0';
    wait for 20 ns;
    
    
   --Read B
    dbus <= "00110011";
    rd_adr <= "000";
    rd_regs <= '1';
    wait for 10 ns;
    dbus <= "ZZZZZZZZ";
    rd_regs <= '0';
    wait for 20 ns;
    
    --Change Databus
    --dbus <= "00001111";
    --wait for
  
   --Write A Read C
    rd_adr <= "001";
    wr_adr <= "111";
    wr_regs <= '1';
    rd_regs <= '1';
    wait for 10 ns;
    rd_regs <= '0';
    wr_regs <= '0';
    wait for 20 ns;
    
    --Write B Read A
    rd_adr <= "111";
    wr_adr <= "000";
    wr_regs <= '1';
    rd_regs <= '1';
    wait for 10 ns;
    rd_regs <= '0';
    wr_regs <= '0';
    wait for 20 ns;
    
    --Swap AF
    swp_regs <= "10";
    wait for 10 ns;
    swp_regs <= "00";
    wait for 20 ns;
    
    --Swap AF
    swp_regs <= "10";
    wait for 10 ns;
    swp_regs <= "00";
    wait for 20 ns;

  end process;
end Behavioral;
