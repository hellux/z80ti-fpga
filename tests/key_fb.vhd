library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
use work.ti_comm.all;

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
         keys_down          : out keys_down_t;
         on_key_down        : out std_logic);
    end component;

    component segment is port(
        clk : in std_logic;
        value : in std_logic_vector(15 downto 0);
        dp_num : in unsigned(3 downto 0);
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

        
    signal keys_down : keys_down_t;
    signal seg_value : std_logic_vector(15 downto 0);
    signal on_key_down : std_logic;
    signal pulse : std_logic;
begin

    k_enc : kbd_enc port map(clk, btns(1), PS2KeyboardCLK, PS2KeyboardData, keys_down, on_key_down);

    led(7) <= on_key_down;
    led(6 downto 0) <= keys_down(1)(6 downto 0);
    --led(5 downto 0) <= keys_down(0)(5 downto 0);

    process(clk) begin
        if rising_edge(clk) then
            if btns(1) = '1' then
                pulse <= '0';
            elsif PS2KeyboardData = '1' then
                pulse <= '1';
            end if;
        end if;
    end process;
     
    smt : segment port map(clk, seg_value, x"0", seg, an);
               
  
     

end arch;


