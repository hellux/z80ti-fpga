library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
use work.cmp_comm.all;

entity key_fb is port (
    clk                 : in std_logic;
    btns                : in std_logic_vector(4 downto 0);
    PS2KeyboardCLK	    : in std_logic; 		-- USB keyboard PS2 clock
    PS2KeyboardData     : in std_logic;			-- USB keyboard PS2 data
    seg, led            : out std_logic_vector(7 downto 0);
    an                  : out std_logic_vector(3 downto 0));
end key_fb;

architecture arch of key_fb is
    
    component KBD_ENC is
      port (clk	            : in std_logic;			-- system clock (100 MHz)
	     rst		        : in std_logic;			-- reset signal
         PS2KeyboardCLK	    : in std_logic; 		-- USB keyboard PS2 clock
         PS2KeyboardData	: in std_logic;			-- USB keyboard PS2 data
         data			    : out std_logic_vector(7 downto 0);		-- tile data
         we			        : out std_logic;		-- write enable
         keys_down          : out keys_down_t);
    end component;

    component segment is port(
        clk : in std_logic;
        value : in std_logic_vector(15 downto 0);
        dp_num : in unsigned(3 downto 0);
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

        
    signal data   : std_logic_vector(7 downto 0);
    signal we     : std_logic;
    signal keys_down : keys_down_t;
    signal seg_value : std_logic_vector(15 downto 0);
begin

    k_enc : kbd_enc port map(clk, btns(1), PS2KeyboardCLK, PS2KeyboardData, data, we, keys_down);
    we <= '1';
    led <= keys_down(1);
     
    smt : segment port map(clk, seg_value, x"0", seg, an);
               
    seg_value <= x"00" & data;         
  
     

end arch;


