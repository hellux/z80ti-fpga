-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity pict_mem is
  port ( clk		: in std_logic;
         di     	: in std_logic;
         do     	: out std_logic;
         addr		: in unsigned(12 downto 0));
         
end pict_mem;

architecture Behavioral of pict_mem is

  -- picture memory type 96x64
  signal pic_mem    : std_logic_vector(6143 downto 0);

begin

  process(clk)
  begin
    if rising_edge(clk) then
      
      pic_mem(to_integer(addr)) <= di;
      do <= pic_mem(to_integer(addr));
    end if;
  end process;

end Behavioral;

