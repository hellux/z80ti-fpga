library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations
use work.cmp_comm.all;
-- entity
entity kbd_enc is
  port ( clk	              : in std_logic;			          -- system clock(100 MHz)
	     rst		              : in std_logic;			      -- reset signal
         PS2KeyboardCLK	      : in std_logic; 		              -- USB keyboard PS2 clock
         PS2KeyboardData	  : in std_logic;			          -- USB keyboard PS2 data
         data			      : out std_logic_vector(7 downto 0); -- scan code data
         keys_down            : out keys_down_t;
         on_key_down          : out std_logic);
end kbd_enc;

-- architecture
architecture behavioral of KBD_ENC is
  signal ps2clk			      : std_logic;			              -- synchronized ps2 clock
  signal ps2data		      : std_logic;			              -- synchronized ps2 data
  signal ps2clk_q1, ps2clk_q2 : std_logic;			              -- ps2 clock one pulse flip flop
  signal ps2clk_op 		      : std_logic;			              -- ps2 clock one pulse 
	
  signal ps2data_sr 	      : std_logic_vector(10 downto 0);    -- ps2 data shift register
	
  signal ps2bitcounter	      : unsigned(3 downto 0);		      -- ps2 bit counter
  signal make_q			      : std_logic;			              -- make one pulselse flip flop
  signal make_op		      : std_logic;			              -- make one pulse

  type state_type is (idle, make, break);			              -- declare state types for ps2
  signal ps2_state : state_type;					              -- ps2 state

  signal scancode		      : std_logic_vector(15 downto 0); 	  -- scan code
  signal keycode              : std_logic_vector(7 downto 0);     -- key code
  signal keys_down_int        : keys_down_t := (others => x"ff"); -- keys_down mtrx set to 1 in evert group
  signal on_key_down          : std_logic;                        -- On key
  
  type wr_type is (standby, wrchar, wrcur);			              -- declare state types for write cycle
  signal wrstate : wr_type;					                      -- write cycle state

begin

  -- Synchronize PS2-KBD signals
  process(clk)
  begin
    if rising_edge(clk) then
      ps2clk <= ps2keyboardclk;
      ps2data <= ps2keyboarddata;
    end if;
  end process;

	
  -- Generate one cycle pulse from PS2 clock, negative edge

  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        PS2Clk_Q1 <= '1';
        PS2Clk_Q2 <= '0';
      else
        PS2Clk_Q1 <= PS2Clk;
        PS2Clk_Q2 <= not PS2Clk_Q1;
      end if;
    end if;
  end process;
	
  ps2clk_op <= (not ps2clk_q1) and (not ps2clk_q2);
  -- PS2 data shift register
    process(clk)
      begin
        if rising_edge(clk) then
          if rst='1' then
            ps2data_sr <= (others => '0');
          elsif ps2clk_op = '1' then 
            ps2data_sr(9 downto 0) <= ps2data_sr(10 downto 1);
            ps2data_sr(10) <= ps2data;
          end if;
        end if;
     end process;
  scancode <= ps2data_sr(8 downto 1);
	
  -- PS2 bit counter
    process(clk)
      begin
        if rising_edge(clk) then
          if rst='1' or ps2bitcounter = 11 then
            ps2bitcounter <= (others => '0');
          elsif ps2clk_op = '1' then 
              ps2bitcounter <= ps2bitcounter + 1;
          end if;
        end if;
     end process;
	
	

  -- PS2 state
  -- Either MAKE or BREAK state is identified from the scancode
  -- Only single character scan codes are identified
  -- The behavior of multiple character scan codes is undefined

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  PS2_State                      *
  -- *                                 *
  -- ***********************************
      process(clk)
        variable grp : integer range 0 to 6;
        variable key : integer range 0 to 7;
      begin
        grp := to_integer(unsigned(keycode(7 downto 4)));
        key := to_integer(unsigned(keycode(3 downto 0)));
        if rising_edge(clk) then
          if rst='1' then
            ps2_state <= idle;
          elsif ps2_state = idle then 
            if ps2bitcounter = 11 and scancode /= X"F0" then
                ps2_state <= make;
                keys_down_int(grp)(key) <= '0'; -- declare key pressed down
            elsif ps2bitcounter = 11 and scancode = X"F0" then 
                ps2_state <= break;
            end if;
          elsif ps2_state = make then 
                ps2_state <= idle;
          elsif ps2_state = break then
            if ps2bitcounter = 11 then 
                keys_down_int(grp)(key) <= '1';  
                ps2_state <= idle;
            end if;
          end if;
        end if;
     end process;
	

  -- Scan Code -> Key Code mapping
  with scancode select
   keycode <=    x"00" when x"E072",	-- KEY DOWN  | KP_Down
                 x"01" when x"E06B",	-- KEY LEFT  | KP_Left
                 x"02" when x"E074",	-- KEY RIGHT | KP_Right
                 x"03" when x"E075",	-- KEY UP    | KP_Up
                 x"10" when x"005A",	-- ENTER     | ENTER
                 x"11" when x"0079",	-- ADD +     | KP_Add 
                 x"12" when x"007B",	-- SUB -     | KP_Sub
                 x"13" when x"007C",	-- MULT x    | 
                 x"14" when x"004E",	-- DIV \     | (+ ? \)   
                 x"15" when x"005B",	-- POWER ^   | (Key next to Å)
                 x"16" when x"0077",	-- CLEAR     | Num Lock
                 x"41" when x"0016",	-- 1         | 1
                 x"31" when x"001E",	-- 2         | 2
                 x"21" when x"0026",	-- 3         | 3
                 x"42" when x"0025",	-- 4         | 4
                 x"32" when x"002E",	-- 5         | 5
                 x"22" when x"0036",	-- 6         | 6
                 x"43" when x"003D",	-- 7         | 7
                 x"33" when x"003E",	-- 8         | 8
                 x"23" when x"0046",	-- 9         | 9
                 x"40" when x"0045",	-- 0         | 0
		         x"65" when x"000D",	-- 2ND       | TAB
                 x"00FF" when others;
  -- we will be enabled ('1') for two consecutive clock 
  -- cycles during WRCHAR and WRCUR states
  -- and disabled ('0') otherwise at STANDBY state
  we <= '0' when (wrstate = standby) else 
        '1';
  
  -- set as keycode
  data <=  keycode;
  keys_down <= keys_down_int;

end behavioral;
