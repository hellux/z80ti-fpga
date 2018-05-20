library ieee;
use ieee.std_logic_1164.all;

entity mem_if is port(
-- comp <-> interface
    rd, wr : in std_logic;
    mode : in std_logic; -- 0: 16-bit, 1: 8-bit
    addr : in std_logic_vector(23 downto 0);
    data_in : in std_logic_vector(15 downto 0);
    data_out : out std_logic_vector(7 downto 0);
-- external memory <-> interface
    maddr : out std_logic_vector(25 downto 0);
    mdata : inout std_logic_vector(15 downto 0);
    mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
    mlb_c, mub_c : out std_logic);
end mem_if;

-- READ
--                                |<---~170 ns--->|
--                |      t1       |      t2       |      t3       |
--                 _______         _______         _______         ______
-- clk_z80  ______|       |_______|       |_______|       |_______|      
--
-- addr_z80 ======|<===invalid===>|<====VALID===========VALID============
--                                 _______________ 
-- mreq     ______________________|               |______________________
--                                 _______________ 
-- rd       ______________________|               |______________________
--
-- data_z80 ======|<===invalid========invalid====>|<====VALID====>|======

-- WRITE
--                |      t1       |      t2       |      t3       |
--                 _______         _______         _______         ______
-- clk_z80  ______|       |_______|       |_______|       |_______|      
--
-- addr_z80 ======|<===invalid===>|<====VALID===========VALID============
--                                 _______________________________
-- mreq     ______________________|                               |______
--                                                 _______________ 
-- rd       ______________________________________|               |______
--
-- data_z80 ======|<===invalid========invalid====>|<====VALID====>|======

-- memory: Micron M45W8MW16

architecture arch of mem_if is
    signal byte_sel : std_logic; -- byte of word for 8-bit mode
begin
    byte_sel <= addr(0);

    -- internal output
    data_out <= x"00" when rd = '0' else
                mdata(7 downto 0) when byte_sel = '0' else
                mdata(15 downto 8);

    -- external output

    mdata <= (others => 'Z') when wr = '0' else
             data_in when mode = '0' else
             data_in(7 downto 0) & data_in(7 downto 0);
    maddr <= "000" & addr(23 downto 1);

    mce_c <= not (rd or wr);
    moe_c <= not rd; 
    mwe_c <= not wr; 

    mub_c <= mode and not byte_sel;
    mlb_c <= mode and byte_sel;

    mclk <= '0';
    madv_c <= '0';
    mcre <= '0';
end arch;
