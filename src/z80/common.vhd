library ieee;
use ieee.std_logic_1164.all;

package z80_comm is
    type instr_set_t is (main, ed, cb, dd, ddcb, fd, fdcb);
    type rf_swap_t is (none, af, reg, dehl);

    type ctrlbus_in is record
        -- cpu control
        wt, int, nmi, reset : std_logic;
        -- cpu bus control
        busrq : std_logic;
    end record;

    type ctrlbus_out is record
        -- system control
        m1, mreq, iorq, rd, wr, rfsh : std_logic;
        -- cpu control
        halt : std_logic;
        -- cpu bus control
        busack : std_logic;
    end record;

    type ctrlword is record 
        -- regfile
        rf_addr : std_logic_vector(3 downto 0);
        rf_rdd, rf_rda, rf_wrd, rf_wra : std_logic;
        rf_swp : rf_swap_t;
        f_rd : std_logic;
        -- alu
        alu_wr : std_logic;
        alu_set : instr_set_t;
        alu_op : std_logic_vector(7 downto 0);
        act_rd : std_logic;
        tmp_rd, tmp_wr : std_logic;
        -- control
        ir_rd : std_logic;
        pc_rd, pc_wr : std_logic;
        -- buffers
        data_rdi, data_wri, data_rdo, data_wro : std_logic;
        addr_rd, addr_wr : std_logic;
    end record;

    -- machine states
    constant m1 : integer := 1;
    constant m2 : integer := 2;
    constant m3 : integer := 3;
    constant m4 : integer := 4;
    constant m5 : integer := 5;
    constant m6 : integer := 6;
    constant t1 : integer := 1;
    constant t2 : integer := 2;
    constant t3 : integer := 3;
    constant t4 : integer := 4;
    constant t5 : integer := 5;

    -- register addresses
    constant regB  : std_logic_vector(3 downto 0) := "0000";
    constant regC  : std_logic_vector(3 downto 0) := "0001";
    constant regD  : std_logic_vector(3 downto 0) := "0010";
    constant regE  : std_logic_vector(3 downto 0) := "0011";
    constant regH  : std_logic_vector(3 downto 0) := "0100";
    constant regL  : std_logic_vector(3 downto 0) := "0101";
    constant regF  : std_logic_vector(3 downto 0) := "0110";
    constant regA  : std_logic_vector(3 downto 0) := "0111";
    constant regW  : std_logic_vector(3 downto 0) := "1000";
    constant regZ  : std_logic_vector(3 downto 0) := "1001";
    constant regIX : std_logic_vector(3 downto 0) := "1010";
    constant regIY : std_logic_vector(3 downto 0) := "1011";
    constant regSP : std_logic_vector(3 downto 0) := "1100";
end z80_comm;
