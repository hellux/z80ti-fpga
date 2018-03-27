-- TestBench register swap

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY swap_tb IS
END swap_tb;

architecture Behavioral of swap_tb is
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


    --Store index for which register to write/read from
    signal clk      : std_logic;
    signal rst      : std_logic := '0';
    signal rd_a     : std_logic := '0';
    signal wr_a     : std_logic := '0';
    signal rd_f     : std_logic := '0';
    signal wr_f     : std_logic := '0'; 
    signal swp_af   : std_logic := '0';
    
    signal dbus     : std_logic_vector(7 downto 0) := "00000001";
    
begin
    
    A : reg_pair port map(
        clk => clk,
        rst => rst,
        rd => rd_a,
        wr => wr_a,
        swp => swp_af,
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
    dbus <= "ZZZZZZZZ";
    wait for 20 ns;
    
    --Read A
    dbus <= "11110000";
    rd_a <= '1';
    wait for 10 ns;
    dbus <= "ZZZZZZZZ";
    rd_a <= '0';
    wait for 20 ns;
    
    --swp AF
    swp_af <= '1';
    wait for 10 ns;
    swp_af <= '0';
    wait for 20 ns;
    
    --swp AF
    swp_af <= '1';
    wait for 10 ns;
    swp_af <= '0';
    wait for 20 ns;

  end process;
end Behavioral;
