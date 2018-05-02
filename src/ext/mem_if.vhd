library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

entity mem_if is port(
-- ti/z80 <-> interface
    rd, wr : in std_logic;
    addr_phy : in std_logic_vector(19 downto 0);
    data_in : in std_logic_vector(7 downto 0);
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
-- clk_z80  ______|       |_______|       |_______|       ¦_______|      
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
    signal ce : std_logic;
begin
    ce <= rd or wr;

    -- DQ -> z80
    data_out <= mdata(7 downto 0) when rd = '1' else x"00";
    -- z80 -> DQ
    mdata <= x"00" & data_in when wr = '1' else (others => 'Z');
    -- z80/mmap -> A
    maddr <= "000000" & addr_phy;

    madv_c <= '0';
    mce_c <= not ce;
    mub_c <= not ce;
    mlb_c <= not ce;
    moe_c <= not rd;
    mwe_c <= not wr;

    mclk <= '0'; -- use asynchronous ops
    mcre <= '0'; -- do not configure
end arch;
