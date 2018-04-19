library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity KBD_ENC is
  port ( clk	              : in std_logic;			        -- system clock (100 MHz)
	 rst		              : in std_logic;			        -- reset signal
         PS2KeyboardCLK	      : in std_logic; 		            -- USB keyboard PS2 clock
         PS2KeyboardData	  : in std_logic;			        -- USB keyboard PS2 data
         data			      : out std_logic_vector(7 downto 0); -- tile data
         addr			      : out unsigned(10 downto 0);	    -- tile address
         we			          : out std_logic);		            -- write enable
end KBD_ENC;

-- architecture
architecture behavioral of KBD_ENC is
  signal ps2clk			      : std_logic;			            -- synchronized ps2 clock
  signal ps2data		      : std_logic;			            -- synchronized ps2 data
  signal ps2clk_q1, ps2clk_q2 : std_logic;			            -- ps2 clock one pulse flip flop
  signal ps2clk_op 		      : std_logic;			            -- ps2 clock one pulse 
	
  signal ps2data_sr 	      : std_logic_vector(10 downto 0);-- ps2 data shift register
	
  signal ps2bitcounter	      : unsigned(3 downto 0);		    -- ps2 bit counter
  signal make_q			      : std_logic;			            -- make one pulselse flip flop
  signal make_op		      : std_logic;			            -- make one pulse

  type state_type is (idle, make, break);			            -- declare state types for ps2
  signal ps2state : state_type;					                -- ps2 state

  signal scancode		      : std_logic_vector(7 downto 0);	-- scan code
  signal keycode              : std_logic_vector(7 downto 0);   -- key code


	
  type wr_type is (STANDBY, WRCHAR, WRCUR);			            -- declare state types for write cycle
  signal WRstate : wr_type;					                    -- write cycle state

begin

  -- Synchronize PS2-KBD signals
  process(clk)
  begin
    if rising_edge(clk) then
      PS2Clk <= PS2KeyboardCLK;
      PS2Data <= PS2KeyboardData;
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
	
  PS2Clk_op <= (not PS2Clk_Q1) and (not PS2Clk_Q2);
	

  
  -- PS2 data shift register

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  PS2_data_shift_reg             *
  -- *                                 *
  -- ***********************************




  ScanCode <= PS2Data_sr(8 downto 1);
	
  -- PS2 bit counter
  -- The purpose of the PS2 bit counter is to tell the PS2 state machine when to change state

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  PS2_bit_Counter                *
  -- *                                 *
  -- ***********************************

	
	

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
    process(clk) begin
        if rising_edge(clk) then
            if  PS2BitCounter = 11 then
                case PS2_state is 
                when(idle) =>
                    if ScanCode = X"F0" then
                        PS2_state <= make;
                    end if;
                when(make) => PS2_state <= idle;
                when(break) => PS2_state <= idle;
                end case;
            end if;
        end if;
    end process;

  -- Scan Code -> Key Code mapping
  with scancode select
    keycode <=   x"01" when x"72",	-- KEY DOWN  | KP_Down
                 x"02" when x"6B",	-- KEY LEFT  | KP_Left
                 x"03" when x"74",	-- KEY RIGHT | KP_Right
                 x"04" when x"75",	-- KEY UP    | KP_Up
                 x"09" when x"5A",	-- ENTER     | ENTER
                 x"0A" when x"79",	-- ADD +     | KP_Add 
                 x"0B" when x"7B",	-- SUB -     | KP_Sub
                 x"0C" when x"7C",	-- MULT x    | 
                 x"0D" when x"4E",	-- DIV \     | (+ ? \)   
                 x"0E" when x"5B",	-- POWER ^   | (Key next to Å)
                 x"0F" when x"77",	-- CLEAR     | Num Lock
                 x"22" when x"16",	-- 1         | 1
                 x"1A" when x"1E",	-- 2         | 2
                 x"12" when x"26",	-- 3         | 3
                 x"23" when x"25",	-- 4         | 4
                 x"1B" when x"2E",	-- 5         | 5
                 x"13" when x"36",	-- 6         | 6
                 x"24" when x"3D",	-- 7         | 7
                 x"1C" when x"3E",	-- 8         | 8
                 x"14" when x"46",	-- 9         | 9
                 x"21" when x"45",	-- 0         | 0
		         x"36" when x"0D",	-- 2ND       | TAB
		         x"29" when x"0E",	-- ON        | Button next to 1

  -- write state
  -- every write cycle begins with writing the character tile index at the current
  -- cursor position, then moving to the next cursor position and there write the
  -- cursor tile index
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        WRstate <= STANDBY;
      else
        case WRstate is
          when STANDBY =>
            if (PS2state = MAKE) then
              WRstate <= WRCHAR;
            else
              WRstate <= STANDBY;
            end if;
          when WRCHAR =>
            WRstate <= WRCUR;
          when WRCUR =>
            WRstate <= STANDBY;
          when others =>
            WRstate <= STANDBY;
        end case;
      end if;
    end if;
  end process;
	

  -- we will be enabled ('1') for two consecutive clock 
  -- cycles during WRCHAR and WRCUR states
  -- and disabled ('0') otherwise at STANDBY state
  we <= '0' when (WRstate = STANDBY) else '1';


  -- memory address is a composite of curposY and curposX
  -- the "to_unsigned(20, 6)" is needed to generate a correct 
  -- size of the resulting unsigned vector
  addr <= to_unsigned(20, 6)*curposY + curposX;

  
  -- data output is set to be x"1F" (cursor tile index) 
  -- during WRCUR state, otherwise set as scan code tile index
  data <= x"1F" when (WRstate =  WRCUR) else TileIndex;

  
end behavioral;
