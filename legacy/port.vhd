library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

-- Port
entity io_port is port(
    clk : in std_logic;
    rst : in std_logic;
    
    int_data : inout std_logic_vector(7 downto 0);
    per_data : inout std_logic_vector(7 downto 0);
    hs_i : in std_logic;
    hs_o : out std_logic);
end io_port;

architecture Behavioral of io_port is
    component reg_8
        port ( clk : in std_logic;
               rst : in std_logic;
                
               rd, wr : in std_logic;
               di : in std_logic_vector(7 downto 0);
               do : out std_logic_vector(7 downto 0));
    end component;
    
    component reg_2
        port ( clk : in std_logic;
               rst : in std_logic;
                
               rd, wr : in std_logic;
               di : in std_logic_vector(1 downto 0);
               do : out std_logic_vector(1 downto 0));
    end component;
    
    
    type op_mode is (byte_out, byte_in, bidir, bitctrl);
    signal cur_mode: op_mode := ;
    
    signal di_rd, do_rd, mode_ct_rd, mask_rd, io_s_rd, mask_ct_rd : std_logic;
    signal di_wr, do_wr, mode_ct_wr, mask_wr, io_s_wr, mask_ct_wr : std_logic;
    signal di_i, do_i, mode_ct_di, mask_di, io_s_di, mask_ct_di : std_logic;
    signal di_o, do_o, mode_ct_do, mask_do, io_s_do, mask_ct_do : std_logic;

begin

    
    

    di_reg: reg_8 port map(clk, rst, di_rd, di_wr, di_i, di_o);
    
    do_reg: reg_8 port map(clk, rst, do_rd, do_wr, do_i, do_o);
    
    mode_ct: reg_2 port map(
    clk, rst, mode_ct_rd, mode_ct_wr, mode_ct_di, mode_ct_do);
    
    mask_reg: reg_8 port map(clk, rst, mask_rd, mask_wr, mask_di, mask_do);
    
    io_s_reg: reg_8 port map(clk, rst, io_s_rd, io_s_wr, io_s_di, io_s_do);
    
    mask_ct_reg: reg_2 port map(
    clk, rst, mask_ct_rd, mask_ct_wr, mask_ct_di, mask_ct_do);
    
    
        


end Behavioral;
