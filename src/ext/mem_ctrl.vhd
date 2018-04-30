library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

entity mem_ctrl is port(
    clk, rst : in std_logic;
    cbo : in ctrlbus_out;
    addr_ext : in std_logic_vector(19 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0);
-- external
    maddr : out std_logic_vector(26 downto 0);
    mdata : inout std_logic_vector(15 downto 0);
    mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
    mlb_c, mub_c : out std_logic;
    mwait : in std_logic);
end mem_ctrl;

-- READ
--                                ¦<---~170 ns--->¦
--                |      t1       |      t2       |      t3        |
--                 _______         _______         _______          ______
-- clk_z80  ______|       |_______|       |_______¦       ¦________¦      
--
-- addr_z80 ======|<===invalid===>|<====VALID===========VALID=============
--                                 _______________ 
-- mreq     ______________________|               |_______________________
--                                 _______________ 
-- rd       ______________________¦               ¦_______________________
--
-- data_z80 ======|<===invalid========invalid====>|<====VALID=====>|======

-- WRITE
--                |      t1       |      t2       |      t3        |
--                 _______         _______         _______          ______
-- clk_z80  ______|       |_______|       |_______¦       ¦________¦      
--
-- addr_z80 ======|<===invalid===>|<====VALID===========VALID=============
--                                 ________________________________
-- mreq     ______________________|                                |______
--                                                 ________________ 
-- rd       ______________________________________|                |______
--
-- data_z80 ======|<===invalid========invalid====>|<====VALID=====>|======

-- memory: Micron M45W8MW16

architecture arch of mem_ctrl is
    component memory_interface generic(addr_width: natural := 26;
				                       data_width: natural := 16);
                               port(
		addr_o : out std_logic_vector(addr_width-1 downto 0);
		clk_o : out  std_logic;
		addr_valid_o :out std_logic;
		cntl_reg_enable_o : out std_logic;
		chip_enable_o : out std_logic;
		output_enable_o : out std_logic;
		write_en_o : out std_logic;
		lower_byte_en_o : out std_logic;
		upper_byte_en_o : out std_logic;
		data_io : inout std_logic_vector( data_width-1 downto 0);
		wait_i : in std_logic;
		addr_i : in std_logic_vector (addr_width-1 downto 0);
		we_i : in std_logic ;
		data_i : in std_logic_vector (data_width-1 downto 0);
		data_o : out std_logic_vector (data_width-1 downto 0);
		clk_i : in std_logic; 
		go_i : in std_logic);
    end component;

    signal addr_i : std_logic_vector(25 downto 0);
    signal data_i, data_o : std_logic_vector(15 downto 0);
    signal rd, wr, ce : std_logic;
begin
    ce <= cbo.mreq;
    rd <= cbo.mreq and cbo.rd;
    wr <= cbo.mreq and cbo.wr;

    addr_i <= "000000" & addr_ext;
    data_i <= x"00" & data_in;
    data_out <= data_o(7 downto 0) when rd = '1' else x"00";

    mint : memory_interface port map(
    -- interface -> mem
        addr_o => maddr(25 downto 0),
        clk_o => mclk,
        addr_valid_o => madv_c,
        chip_enable_o => mce_c,
        output_enable_o => moe_c,
        write_en_o => mwe_c,
        lower_byte_en_o => mlb_c,
        upper_byte_en_o => mub_c,
    -- interface <-> mem
        data_io => mdata,
    -- mem -> interface
        wait_i => mwait,
    -- cpu -> interface
        addr_i => addr_i,
        we_i => wr,
        data_i => data_i,
        clk_i => clk,
        go_i => ce,
    -- interface -> cpu
        data_o => data_o);

    mcre <= '0';
end arch;
