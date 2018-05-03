library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ti_comm.all;
entity kbd_enc is port (
    clk, rst : in std_logic;
    PS2KeyboardCLK : in std_logic;
    PS2KeyboardData	: in std_logic;
    keys_down : out keys_down_t;
    on_key_down : out std_logic;
-- debug
    scancode_out : out std_logic_vector(7 downto 0);
    keycode_out : out std_logic_vector(7 downto 0));
end kbd_enc;

architecture behavioral of KBD_ENC is
    signal ps2clk : std_logic;
    signal ps2data : std_logic;
    signal ps2clk_q1, ps2clk_q2 : std_logic;
    signal ps2clk_op : std_logic;
    signal ps2data_sr : std_logic_vector(10 downto 0); 
    signal ps2bitcounter : unsigned(3 downto 0);

    type state_type is (idle, break);
    signal ps2_state : state_type;

    signal scancode : std_logic_vector(7 downto 0);
    signal keycode, keycode_ord, keycode_ext : std_logic_vector(7 downto 0);
    signal extended : std_logic;
    signal keys_down_int : keys_down_t := (others => x"ff");
    signal on_key_down_int : std_logic := '1';
begin
    process(clk) begin
        if rising_edge(clk) then
            ps2clk <= ps2keyboardclk;
            ps2data <= ps2keyboarddata;
        end if;
    end process;

	
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                PS2Clk_Q1 <= '1';
                PS2Clk_Q2 <= '0';
            else
                PS2Clk_Q1 <= PS2Clk;
                PS2Clk_Q2 <= not PS2Clk_Q1;
            end if;
        end if;
    end process;
	
    ps2clk_op <= (not ps2clk_q1) and (not ps2clk_q2);
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                ps2data_sr <= (others => '0');
            elsif ps2clk_op = '1' then 
                ps2data_sr(9 downto 0) <= ps2data_sr(10 downto 1);
                ps2data_sr(10) <= ps2data;
            end if;
        end if;
    end process;
    scancode <= ps2data_sr(8 downto 1);
	
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' or ps2bitcounter = 11 then
                ps2bitcounter <= (others => '0');
            elsif ps2clk_op = '1' then 
                ps2bitcounter <= ps2bitcounter + 1;
            end if;
        end if;
    end process;
	
    process(clk)
        variable grp : integer;
        variable key : integer;
    begin
        if rising_edge(clk) then
            grp := to_integer(unsigned(keycode(7 downto 4)));
            key := to_integer(unsigned(keycode(3 downto 0)));
            if rst = '1' then
                ps2_state <= idle;
                extended <= '0';
            end if;
            case ps2_state is
            when idle =>
                if ps2bitcounter = 11 then
                    case scancode is
                    when x"f0" =>
                        ps2_state <= break;         
                    when x"e0" => 
                        extended <= '1';
                        ps2_state <= idle;
                    when x"14" =>
                        on_key_down_int <= '0';
                        extended <= '0';
                    when others =>
                        keys_down_int(grp)(key) <= '0';
                        extended <= '0';
                    end case;
                end if;
            when break =>
                if ps2bitcounter = 11 then
                    case scancode is
                    when x"14" =>
                        on_key_down_int <= '1';
                    when others =>
                        keys_down_int(grp)(key) <= '1';
                    end case;
                    ps2_state <= idle;
                    extended <= '0';
                end if;
            end case;
        end if;
    end process;
	
    with scancode select keycode_ord <=
        x"10" when x"5A",	-- ENTER     | ENTER
        x"11" when x"79",	-- ADD +     | KP_Add 
        x"12" when x"7B",	-- SUB -     | KP_Sub
        x"13" when x"7C",	-- MULT x    | 
        x"14" when x"4E",	-- DIV \     | (+ ? \)   
        x"15" when x"5B",	-- POWER ^   | ^
        x"16" when x"77",	-- CLEAR     | Num Lock
        x"41" when x"69",	-- 1         | KP1
        x"31" when x"72",	-- 2         | KP2
        x"21" when x"7a",	-- 3         | KP3
        x"42" when x"6b",	-- 4         | KP4
        x"32" when x"73",	-- 5         | KP5
        x"22" when x"74",	-- 6         | KP6
        x"43" when x"6c",	-- 7         | KP7
        x"33" when x"75",	-- 8         | KP8
        x"23" when x"7d",	-- 9         | KP9
        x"40" when x"70",	-- 0         | KP0
        x"30" when x"71",	-- .         | KP , (Del)
        x"20" when x"4A",	-- (-)       | - _ 
        x"24" when x"3E",	-- (         | 8  
        x"25" when x"34",	-- TAN       | G
        x"26" when x"2E",	-- VARS      | 5
        x"34" when x"46",	-- )         | 9
        x"35" when x"2B",	-- COS       | F
        x"36" when x"21",	-- PRGM      | C
        x"37" when x"25",	-- STAT      | 4
        x"44" when x"3B",	-- ,         | J 
        x"45" when x"24",	-- SIN       | E
        x"46" when x"32",	-- APPS      | B
        x"47" when x"26",	-- X,T,O,n   | 3
        x"51" when x"22",	-- STO       | X
        x"52" when x"1B",	-- LN        | S
        x"53" when x"31",	-- LOG       | N
        x"54" when x"43",	-- X^2       | I
        x"55" when x"23",	-- X^(-1)    | D
        x"56" when x"1C",	-- MATH      | A
        x"57" when x"58",	-- ALPHA     | Caps Lock
        x"60" when x"03",	-- GRAPH     | F5
        x"61" when x"0C",	-- TRACE     | F4
        x"62" when x"04",	-- ZOOM      | F3
        x"63" when x"06",	-- WINDOW    | F2
        x"64" when x"05",	-- Y=        | F1
        x"65" when x"0D",	-- 2ND       | TAB
        x"66" when x"16",	-- MODE      | 1
        x"67" when x"1E",	-- DEL       | 2
        -- ALPHA BUTTONS --
        x"41" when x"35",	-- Y         | Y
        x"31" when x"1A",	-- Z         | Z
        x"42" when x"2C",	-- T         | T
        x"32" when x"3C",	-- U         | U
        x"22" when x"2A",	-- V         | V
        x"43" when x"44",	-- O         | O
        x"33" when x"4D",	-- P         | P
        x"24" when x"42",	-- K         | K  
        x"34" when x"4B",	-- L         | L
        x"12" when x"1D",	-- W         | W
        x"13" when x"2D",	-- R         | R  
        x"14" when x"3A",	-- M         | M   
        x"15" when x"33",	-- H         | H
        x"23" when x"15",	-- Q         | Q
        x"20" when x"29",	-- SPACE     | Space  
        x"FF" when others;

    with scancode select keycode_ext <= 
        x"00" when x"69",	-- KEY DOWN  | End
        x"01" when x"71",	-- KEY LEFT  | Delete
        x"02" when x"7A",	-- KEY RIGHT | Page Down
        x"03" when x"6C",	-- KEY UP    | Home
        x"FF" when others;

    keycode <= keycode_ext when extended = '1' else keycode_ord;
    
    -- set as keycode
    keys_down <= keys_down_int;
    on_key_down <= on_key_down_int;

    -- debug
    scancode_out <= scancode;
    keycode_out <= keycode;
end behavioral;
