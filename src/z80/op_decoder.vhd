--OPeration decoder by Jakob & Yousef
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity op_decoder is port(
    clk : in std_logic;
    rst : in std_logic;
    instr : in std_logic_vector(7 downto 0));
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
    
    type reg_list_single is array (7 downto 0) of integer;
    type reg_list_pair is array (3 downto 0) of integer;
    signal r : reg_list_single; 
    signal rp : reg_list_pair; -- 1=BC, 2=DE, 3=HL, 4=SP
    signal rp2 : reg_list_pair; -- 1=BC, 2=DE, 3=HL, 4=AF
    
    type state is (t1, t2, t3, t4, t5);
    signal cur_state: state := t1;
    
    --Controls prefix
    type set is (main, ed, cb, dd, ddcb, fd, fdcb);
    signal cur_set : set := main;
    
    signal swp : std_logic_vector(1 downto 0);
    signal rd_adr, wr_adr : std_logic_vector(2 downto 0);
    signal rd, wr : std_logic;
    
    procedure EX_AF(
        signal swp : out std_logic_vector(1 downto 0)
    ) is begin 
        if (cur_state = t1) then -- Set swp_af
            swp <= "10";
        elsif (cur_state = t2) then -- Reset swp
            swp <= "00";
        elsif (cur_state = t3) then
        elsif (cur_state = t4) then
        end if;
        
    end EX_AF;
    
    procedure ALU(
        signal z : in std_logic_vector(2 downto 0);
        signal rd_adr, wr_adr : out std_logic_vector(2 downto 0);
        signal rd, wr : out std_logic
    ) is begin 
        if (cur_state = t1) then -- Take value A
            wr_adr <= "111";
            wr <= '1';
        elsif (cur_state = t2) then -- Take reg value
            wr_adr <= z;
        elsif (cur_state = t3) then -- quick Mafs
            wr <='0';
            rd <= '1';
        elsif (cur_state = t4) then -- Store value in A
            rd_adr <= "111";
            rd <= '0';
        end if;
    end ALU;
    
 begin
    -- Split op
    x <= instr(7 downto 6);
    y <= instr(5 downto 3);
    z <= instr(2 downto 0);
    p <= instr(5 downto 4);
    q <= instr(3);
    
    process(clk) begin
        if (cur_set = main) then
            if (x = x"0") then
                if (z = x"0") then
                    if (y = x"0") then -- NOP
                    elsif (y = x"1") then -- EX AF,AF'
                        EX_AF(swp);
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
            elsif (x = x"1") then
                if (z /= x"6") then --LD r[y], r[z]
                elsif (z = x"6") then
                    if (y = x"6") then -- HALT
                    end if;
                end if;
            elsif (x = x"2") then -- alu[y] r[z]
                ALU(z, rd_adr, wr_adr, rd, wr);
            elsif (x = x"3") then
                if (z = x"0") then -- RET cc[y]   
                elsif (z = x"1") then
                    if (q = '0') then -- POP rp2[p]
                    elsif (q = '1') then
                        if (p = x"0") then -- RET
                        elsif (p = x"1") then -- EXX
                        elsif (p = x"2") then -- JP HL
                        elsif (p = x"3") then -- LD SP, HL
                        end if;
                    end if;
                elsif (z = x"2") then -- JP cc[y], nn
                elsif (z = x"3") then
                    if (y = x"0") then -- JP nn
                    elsif (y = x"1") then -- (CB prefix)
                        cur_set <= cb;
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
                            cur_set <= dd;
                        elsif (p = x"2") then -- (ED prefix)
                            cur_set <= ed;
                        elsif (p = x"3") then -- (FD prefix)
                            cur_set <= fd;
                        end if;
                    end if;
                elsif (z = x"6") then -- alu[y] n
                elsif (z = x"7") then -- RST y*8
                end if;
            end if;
        elsif (cur_set = ed) then
            if (x = x"1") then -- rot[y] r[z]
                if (z = x"0") then
                    if (y < x"6" or y = x"7") then -- IN r[y], (C)
                    elsif (y = x"6") then -- IN (C)
                    end if;
                elsif (z = x"1") then
                    if (y < x"6" or y = x"7") then -- OUT r[y], (C)
                    elsif (y = x"6") then -- OUT (C), 0
                    end if;
                elsif (z = x"2") then
                    if (q = '0') then -- SBC HL, rp[p]
                    elsif (q = '1') then -- ADC HL, rp[p]
                    end if; 
                elsif (z = x"3") then
                    if (q = '0') then -- LD (nn), rp[p]
                    elsif (q = '1') then -- LD rp[p], (nn)
                    end if; 
                elsif (z = x"4") then -- NEG
                elsif (z = x"5") then
                    if (y = x"0" or y > x"1") then -- RETN
                    elsif (y = x"1") then -- RETI
                    end if;
                elsif (z = x"6") then -- IM im[y]
                elsif (z = x"7") then
                    if (y = x"0") then -- LD I, A
                    elsif (y = x"1") then -- LD R, A
                    elsif (y = x"2") then -- LD A, I
                    elsif (y = x"3") then -- LD A, R
                    elsif (y = x"4") then -- RRD
                    elsif (y = x"5") then -- RLD
                    elsif (y = x"6") then -- NOP
                    elsif (y = x"7") then -- NOP
                    end if;
                end if;
            elsif (x = x"2") then
                if (z <= x"3") then
                    if (y >= x"4") then -- bli[y,z]
                    end if;
                end if;
            end if;
        elsif (cur_set = cb) then
            if (x = x"0") then -- rot[y] r[z]
            elsif (x = x"1") then -- BIT y, r[z]
            elsif (x = x"2") then -- RES y, r[z]
            elsif (x = x"3") then -- SET y, r[z]
            end if;
        elsif (cur_set = dd) then
        elsif (cur_set = ddcb) then
            if (x = x"0") then
                if (z < x"6" or z = x"7") then -- LD r[z], rot[y] (IX+d)
                elsif (z = x"6") then -- rot[y] (IX+d)
                end if;
            elsif (x = x"1") then -- BIT y, (IX+d)
            elsif (x = x"2") then
                if (z < x"6" or z = x"7") then -- LD r[z], RES y, (IX+d)
                elsif (z = x"6") then -- RES y, (IX+d)
                end if;
            elsif (x = x"3") then
                if (z < x"6" or z = x"7") then -- LD r[z], SET y, (IX+d)
                elsif (z = x"6") then -- SET y, (IX+d)
                end if;
            end if;
        elsif (cur_set = fd) then
        elsif (cur_set = fdcb) then
            if (x = x"0") then
                if (z < x"6" or z = x"7") then -- LD r[z], rot[y] (IY+d)
                elsif (z = x"6") then -- rot[y] (IY+d)
                end if;
            elsif (x = x"1") then -- BIT y, (IY+d)
            elsif (x = x"2") then
                if (z < x"6" or z = x"7") then -- LD r[z], RES y, (IY+d)
                elsif (z = x"6") then -- RES y, (IY+d)
                end if;
            elsif (x = x"3") then
                if (z < x"6" or z = x"7") then -- LD r[z], SET y, (IY+d)
                elsif (z = x"6") then -- SET y, (IY+d)
                end if;
            end if;
        end if;
    end process;

 end Behavioral;
