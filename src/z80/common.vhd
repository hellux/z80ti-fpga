library ieee;
use ieee.std_logic_1164.all;

package z80_comm is
    type instr_set_t is (main, ed, cb, dd, ddcb, fd, fdcb);

    type ctrlword is record 
        rf_addr : std_logic_vector(3 downto 0);
        rf_rdd, rf_wrd, rf_rda, rf_wra : std_logic;
        rf_swp : std_logic_vector(1 downto 0);
        f_rd, f_wr, f_swp : std_logic;
        alu_wr : std_logic;
        alu_set : instr_set_t;
        alu_op : std_logic_vector(7 downto 0);
        act_rd, tmp_rd : std_logic;
        ir_rd : std_logic;
        pc_rd, pc_wr : std_logic;
    end record;

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
end z80_comm;
