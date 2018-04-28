library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

entity mem_ctrl is port(
    clk, clk_z80, rst : in std_logic;
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

architecture arch of mem_ctrl is
begin
    maddr <= "0000000" & addr_ext;
    mdata <= x"00" & data_in;
    madv_c <= not cbo.mreq;
    mcre <= '0';
    mce_c <= not cbo.mreq;
    moe_c <= not (cbo.mreq and cbo.rd);
    mwe_c <= not (cbo.mreq and cbo.wr);
    mclk <= '0'; -- use asynchronous ops
    mub_c <= '1'; -- never use upper byte;
    mlb_c <= '0'; -- always use lower byte;
end arch;
