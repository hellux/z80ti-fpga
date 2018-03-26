--OPeration decoder by Jakob & Yousef
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity op_decoder is
    port(
    clk : in std_logic;
    rst : in std_logic;
   
    di  : in std_logic_vector(7 downto 0);
    do  : out std_logic_vector(7 downto 0);
   
end op_decoder;


architecture Behavioral of op_decoder is
    
    --bit coding
    --x   = bit 7-6
    --y   = bit 5-3
    --z   = bit 2-0
    --p   = bit 5-4
    --q   = bit 3
    
    signal x, p     : std_logic_vector(1 downto 0);
    signal y, z     : std_logic_vector(2 downto 0);
    signal q        : std_logic;
    
 begin
 
    --Split operand into 2 hex numbers
    x   <= di(7 downto 6);
    y   <= di(5 downto 3);
    z   <= di(2 downto 0);
    p   <= di(5 downto 4);
    q   <= di(3);
   
    
    process(clk) begin
        if rising_edge(clk) then
        
            --MAIN instructions
            if (x = x"0") then
                if (z = x"0") then
                    if (y = x"0") then -- NOP
                    elsif (y = x"1") then -- SWP AF,AF'
                    elsif (y = x"2") then -- DJNZ d
                    elsif (y = x"3") then -- JR d
                    elsif (y >= x"4" and y <= x"7") then -- JR cc[y-4] d
                    end if;
                elsif (z = x"1") then
                    if (q = '0') then -- LD rp[p], nn
                    elsif (q = '1') then -- ADD HL, rp[p]
                    end if;
                elsif (z = x"2") then
                    if (q = '0') then
                        if (p = x"0") then -- LD (BC), A
                        elsif (p = x"1") then -- LD (DE), A
                        elsif (p = x"2") then -- LD (nn), HL
                        elsif (p = x"3") then -- LD (nn), A
                        end if;
                    elsif (q = '1') then
                        if (p = x"0") then -- LD A, (BC)
                        elsif (p = x"1") then -- LD A, (DE)
                        elsif (p = x"2") then -- LD HL, (nn)
                        elsif (p = x"3") then -- LD A, (nn)
                        end if;
                    end if;
                elsif (z = x"3") then
                    if (q = '0') then -- INC rp[y]
                    elsif (q = '1') then -- DEC rp[y]
                    end if;
                elsif (z = x"4") then -- INC r[y]
                elsif (z = x"5") then -- DEC r[y]
                elsif (z = x"6") then -- LD r[y]
                elsif (z = x"7") then
                    if (y = x"0") then -- RLCA
                    elsif (y = x"1") then -- RRCA
                    elsif (y = x"2") then -- RLA
                    elsif (y = x"3") then -- RRA
                    elsif (y = x"4") then -- DAA
                    elsif (y = x"5") then -- CPL
                    elsif (y = x"6") then -- SCF
                    elsif (y = x"7") then -- CCF
                    end if;
                end if;
    
            elsif (x = "1") then
                if (z /= x"6") then --LD r[y], r[z]
                elsif (z = x"6") then
                    if (y = x"6") then -- HALT
                    end if;
                end if;
            --Add, adc, sub, sbc, and, or, xor, cp, 
            elsif (x = x"2") then -- alu[y] r[z]
            elsif (x = x"3") then
                if (z = x"0" then -- RET cc[y]   
                elsif (z = x"1") then
                    if (q = '0') then -- POP rp2[p]
                    elsif (q = '1') then
                        if (p = x"0") then -- RET
                        elsif (p = x"1") then -- SWP ALL
                        elsif (p = x"2") then -- JP HL
                        elsif (p = x"3") then -- LD SP, HL
                        end if;
                    end if;
                elsif (z = x"2") then -- JP cc[y], nn
                elsif (z = x"3") then
                    if (y = x"0") then -- JP nn
                    elsif (y = x"1") then -- (CB prefix)
                    elsif (y = x"2") then -- OUT (n), A
                    elsif (y = x"3") then -- IN A, (n)
                    elsif (y = x"4") then -- EX (SP), HL
                    elsif (y = x"5") then -- EX DE, HL
                    elsif (y = x"6") then -- DI
                    elsif (y = x"7") then -- EI
                    end if;
                elsif (z = x"4") then -- CALL cc[y], nn
                elsif (z = x"5") then
                    if (q = '0') then -- PUSH rp2[p]
                    elsif (q = '1') then
                        if (p = x"0") then -- CALL nn
                        elsif (p = x"1") then -- (DD prefix)
                        elsif (p = x"2") then -- (ED prefix)
                        elsif (p = x"3") then -- (FD prefix)
                elsif (z = x"6") then -- alu[y] n
                elsif (z = x"7") then -- RST y*8
                end if;
            end if;
                    
            --Extended instructions (ED)   
                
            --Bit instructions (CB)
                if (x = x("0")) then -- rot[y] r[z]
                elsif (x = x("1")) then -- BIT y, r[z]
                elsif (x = x("2")) then -- RES y, r[z]
                elsif (x = x("3")) then -- SET y, r[z]
                end if;
            --IX instructions (DD)
            
            --IX bit instructions (DDCB)
            
            --IY instructions (FD)
            
            --IY bit instructions (FDCB)
            
               
        end if;
    end process;
  
 end Behavioral;
