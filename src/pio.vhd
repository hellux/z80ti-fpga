library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

-- PIO
entity pio is
  port ( 
    clk			    : in std_logic;
    rst			    : in std_logic;
    
	--vgaRed		    : out std_logic_vector(2 downto 0);
	--vgaGreen	    : out std_logic_vector(2 downto 0);
	--vgaBlue		    : out std_logic_vector(2 downto 1);
	--Hsync		    : out std_logic;
	--Vsync		    : out std_logic;
	);
end pio;

architecture Behavioral of pio is
    component io_port 
        port ( clk : in std_logic;
               rst : in std_logic;
               -- Insert properties of port
               );
    end component;
    

begin

   

end Behavioral;
