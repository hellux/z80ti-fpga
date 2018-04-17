library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity pict_mem is
  port ( clk		: in std_logic;
         di     	: in std_logic;
         do     	: out std_logic;
         addr_in		: in std_logic_vector(12 downto 0);
         addr_vga		: in std_logic_vector(12 downto 0));
         
end pict_mem;

architecture Behavioral of pict_mem is

  -- picture memory type 96x64
  type mem_t is array(0 to 6143) of std_logic;
   
  signal pic_mem : mem_t := (others => '0');
  
begin

  process(clk)
  begin
    if rising_edge(clk) then
      
      pic_mem(to_integer(unsigned(addr_in))) <= di;
      do <= pic_mem(to_integer(unsigned(addr_vga)));
    end if;
  end process;

end Behavioral;

