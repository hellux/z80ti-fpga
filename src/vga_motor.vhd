library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_motor is port ( 
     clk			: in std_logic;
	 data			: in std_logic;
	 rst			: in std_logic;
     x : out std_logic_vector(6 downto 0);
     y : out std_logic_vector(5 downto 0);
	 vgaRed		    : out std_logic_vector(2 downto 0);
	 vgaGreen	    : out std_logic_vector(2 downto 0);
	 vgaBlue		: out std_logic_vector(2 downto 1);
	 Hsync		    : out std_logic;
	 Vsync		    : out std_logic);
end vga_motor;

architecture Behavioral of vga_motor is
    signal Xpixel : integer range 0 to 800; -- Horizontal pixel counter
    signal Ypixel : integer range 0 to 521; -- Vertical pixel counter
    signal clk_count : unsigned(1 downto 0); -- Clock div, for 25MHz clk
    signal vga_clk : std_logic; -- One pulse width 25 MHz signal
    signal colour : std_logic_vector(7 downto 0);	
    signal blank : std_logic;                        -- blanking signal
begin
    clk_div : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                clk_count <= (others => '0');
            else
	            clk_count <= clk_count + 1;
            end if;
        end if;
    end process;
    vga_clk <= '1' when (clk_count = 3) else '0';

    x_cntr : process(clk) begin
        if rising_edge(clk) then
            if rst ='1' then
                Xpixel <= 0;     
            elsif vga_clk = '1'  then    
                if Xpixel = 799 then
                    Xpixel <= 0;
                else
                    Xpixel <= Xpixel + 1;
                end if;
            end if;
        end if;
    end process;
    y_cntr : process(clk) begin
        if rising_edge(clk) then   
            if rst = '1' then
                Ypixel <= 0;  
            elsif vga_clk = '1' then  
                if Ypixel = 520 then
                    Ypixel <= 0;
                elsif Xpixel = 799 then 
                    Ypixel <= Ypixel + 1;
                end if;
            end if;
        end if;
    end process;

    Hsync <= '0' when Xpixel > 656 and Xpixel <= 752 else
             '1';
    Vsync <= '0' when Ypixel > 490 and Ypixel <= 492 else
             '1';
    blank <= '1' when Xpixel > 640 or Ypixel > 480 else '0';
    colour <= x"00" when blank = '1' else
              x"00" when Xpixel > 383 or Ypixel > 255 else
              --001 010 01
              x"00" when data = '1' else
              --01001000
              x"48" when data = '0' else
              (others => '-');
  
    x <= std_logic_vector(to_unsigned(Xpixel/4, x'length))
             when Xpixel < 480 else (others => '0');
    y <= std_logic_vector(to_unsigned(Ypixel/4, y'length))
            when Ypixel < 256 else (others => '0');
    vgaRed 	    <= colour(7 downto 5);
    vgaGreen    <= colour(4 downto 2);
    vgaBlue 	<= colour(1 downto 0);
end Behavioral;

