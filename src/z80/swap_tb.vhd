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
    
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
    end loop;
end process;

  stimuli_generator : process
    variable i : integer;
  begin
    -- Aktivera reset ett litet tag.
    rst <= '1';
    wait for 250 ns;

    wait until rising_edge(clk);        -- se till att reset släpps synkront
                                        -- med klockan
    rst <= '0';
    report "Reset released" severity note;
    wait for 500 ns;
    
    
    rd_a <= '1';
    wait for 2 ns;
    wait until rising_edge(clk); 
    rd_a <= '0';
    wait for 200 ns;
    
    wait for 200 ns;
    dbus <= "11110000";
    
    swp_af <= '1';
    wait for 2 ns;
    wait until rising_edge(clk); 
    swp_af <= '0';
    
    
    wait for 200 ns;
    dbus <= "10101010";
    
    wait for 200 ns;
    rd_a <= '1';
    wait for 2 ns;
    wait until rising_edge(clk); 
    rd_a <= '0';
    wait for 200 ns;
    
    swp_af <= '1';
    wait for 2 ns;
    wait until rising_edge(clk); 
    swp_af <= '0';

    wait for 250 ns;
    wait until rising_edge(clk); 
    
    wait for 2 us;

  end process;
end Behavioral;
