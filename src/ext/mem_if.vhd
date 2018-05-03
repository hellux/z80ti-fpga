library ieee;
use ieee.std_logic_1164.all;
use work.z80_comm.all;

entity mem_if is port(
-- ti/z80 <-> interface
    clk, rst : in std_logic;
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
    component dcntr is generic(bitwidth : integer); port(
        clk, rst : in std_logic;
        ld : in std_logic;
        ce1, ce2 : in std_logic;
        di : in std_logic_vector(bitwidth-1 downto 0);
        do : out std_logic_vector(bitwidth-1 downto 0));
    end component;

    component reg generic(init : std_logic_vector;
                          size : integer); port(
        clk, rst : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;

    type mif_state_t is (idle, pulse, init, rw, stall);

    signal state : mif_state_t := idle;
    signal init_time : integer range 0 to 7;
    signal rw_time : integer range 0 to 4;
    signal buf_rd : std_logic;
    signal data_buf : std_logic_vector(7 downto 0);
begin
    buf : reg generic map(x"00", 8)
              port map(clk, rst, buf_rd, mdata(7 downto 0), data_buf);
    data_out <= data_buf when rd = '1' else x"00";

    process(clk) begin
        if rising_edge(clk) then
            case state is
            when idle =>
                buf_rd <= '0';
                mce_c <= '0';
                mlb_c <= '1';
                mub_c <= '1';
                moe_c <= '1';
                mwe_c <= '1';
                maddr <= (others => '0');
                mdata <= (others => 'Z');
                if rd = '1' or wr = '1' then
                    mce_c <= '1';
                    maddr <= "000000" & addr_phy;
                    state <= pulse;
                end if;
            when pulse =>
                mce_c <= '0';
                mub_c <= '0';
                mlb_c <= '0';
                state <= init;
                if rd = '1' then
                    init_time <= 6;
                elsif wr = '1' then
                    mwe_c <= '1';
                    init_time <= 1;
                end if;
            when init =>
                if init_time = 0 then
                    state <= rw;
                    if rd = '1' then
                        mwe_c <= '1';
                        moe_c <= '0';
                        rw_time <= 3;
                    elsif wr ='1' then
                        mwe_c <= '0';
                        mdata <= x"00" & data_in;
                        rw_time <= 4;
                    end if;
                else
                    init_time <= init_time - 1;
                end if;
            when rw =>
                if rd = '1' then
                    buf_rd <= '1';
                end if;
                if rw_time = 0 then
                    buf_rd <= '0';
                    mlb_c <= '1';
                    mub_c <= '1';
                    moe_c <= '1';
                    mwe_c <= '1';
                    maddr <= (others => '0');
                    state <= stall;
                else
                    rw_time <= rw_time - 1;
                end if;
            when stall =>
                if rd = '0' and wr = '0' then
                    mdata <= (others => 'Z');
                    state <= idle;
                end if;
            end case;
            if rst = '1' then
                state <= idle;
            end if;
        end if;
    end process;

    mclk <= '0';
    madv_c <= '0';
    mcre <= '0';
end arch;
