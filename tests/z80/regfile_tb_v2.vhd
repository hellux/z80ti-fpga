library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.util.all;

entity regfile_tb_v2 is
end regfile_tb_v2;

architecture arch of regfile_tb_v2 is
    component regfile port(
        clk, rst : in std_logic;
        reg_addr : in integer range 0 to 15;
        rdd, rda, rdf : in std_logic;
        wrd, wra : in std_logic;
        swp : in rf_swap_t;
        data : inout std_logic_vector(7 downto 0);
        addr : in std_logic_vector(15 downto 0);
        f_in : in std_logic_vector(7 downto 0);
        addr_out, addr_out_dis : out std_logic_vector(15 downto 0);
        a_out, f_out : out std_logic_vector(7 downto 0);
        dbg_regs : out dbg_regs_t);
    end component;

    signal clk, rst, rdd, rda, rdf, wrd, wra, wrf : std_logic;
    signal reg_addr : integer range 0 to 15;
    signal swp : rf_swap_t;
    signal f_in, data, a_out, f_out : std_logic_vector(7 downto 0);
    signal addr, addr_out, addr_dis : std_logic_vector(15 downto 0);
    signal dbg_regs : dbg_regs_t;
    
    type reg_hex_t is array(0 to 15) of std_logic_vector(3 downto 0);
    constant r : reg_hex_t := 
        (x"b",  -- B
         x"c",  -- C
         x"d",  -- D
         x"e",  -- E
         x"4",  -- H
         x"1",  -- L
         x"f",  -- (f)
         x"a",  -- a
         x"8",  -- W
         x"2",  -- Z
         x"5",  -- SP
         x"5",  -- SP
         x"6",  -- IX
         x"6",  -- IX
         x"7",  -- IY
         x"7"); -- IY
begin
    rf : regfile port map(clk, rst, reg_addr, rdd, rda, rdf, wrd, wra, swp,
                          data, addr, f_in, addr_out, addr_dis, a_out, f_out,
                          dbg_regs);

    process begin
        clk <= '1';
        wait for 125 ns;
        clk <= '0';
        wait for 125 ns;
    end process;

    process
        variable i : integer range 0 to 15;
        variable value : std_logic_vector(7 downto 0);
        variable value_addr : std_logic_vector(15 downto 0);
    begin
        rst <= '0';
        rdd <= '0';
        rda <= '0';
        rdf <= '0';
        wrd <= '0';
        wra <= '0';
        wrf <= '0';
        wait for 1 us;

        report "TB STARRT";

        report("write to all reg");
        rdd <= '1';
        for i in 0 to 15 loop
            report "reg " & integer'image(i);
            reg_addr <= i;
            data <= x"9" & r(i);
            wait for 250 ns;
        end loop;
        rdd <= '0';
        data <= (others => 'Z');

        wait for 1 us;

        report("read from all reg");
        wrd <= '1';
        for i in 0 to 15 loop
            reg_addr <= i;
            value := x"9" & r(i);
            wait for 125 ns;
            assert data=value report vec_str(data) & "!=" & vec_str(value);
            wait for 125 ns;
        end loop;
        wrd <= '0';
        
        report("swap main reg");
        swp <= reg;
        wait for 250 ns;
        swp <= none;
        wait for 250 ns;

        report("ensure swapped regs are zero");
        wrd <= '1';
        for i in 0 to 5 loop
            reg_addr <= i;
            value := "00000000";
            wait for 125 ns;
            assert data=value report vec_str(data) & "!=" & vec_str(value);
            wait for 125 ns;
        end loop;
        wrd <= '0';

        report("make sure others not swapped");
        wrd <= '1';
        for i in 6 to 12 loop
            reg_addr <= i;
            value := x"9" & r(i);
            wait for 125 ns;
            assert data=value report vec_str(data) & "!=" & vec_str(value);
            wait for 125 ns;
        end loop;
        wrd <= '0';

        report("write to swapped");
        rdd <= '1';
        for i in 0 to 5 loop
            reg_addr <= i;
            data <= x"3" & r(i);
            wait for 250 ns;
        end loop;
        rdd <= '0';
        data <= (others => 'Z');

        swp <= af;
        wait for 250 ns;
        swp <= none;
        wait for 250 ns;

        report("write to swapped af");
        rdd <= '1';
        for i in 6 to 7 loop
            reg_addr <= i;
            data <= x"3" & r(i);
            wait for 250 ns;
        end loop;
        rdd <= '0';
        data <= (others => 'Z');
        
        swp <= dehl;
        wait for 250 ns;
        swp <= none;
        wait for 250 ns;

        report("read swapped dehl");
        wrd <= '1';
        reg_addr <= regD;
        wait for 125 ns;
        assert data=x"34";
        reg_addr <= regE;
        wait for 125 ns;
        assert data=x"31";
        reg_addr <= regH;
        wait for 125 ns;
        assert data=x"3d";
        reg_addr <= regL;
        wait for 125 ns;
        assert data=x"3e";
        wrd <= '0';

        report("write to a and f simultaneosly (swp reg)");
        rdf <= '1';
        rdd <= '1';
        reg_addr <= regA;
        data <= x"2a";
        f_in <= x"2f";
        wait for 250 ns;
        rdf <= '0';
        rdd <= '0';
        data <= (others => 'Z');

        report("control a, f (swp reg)");
        wrd <= '1';
        reg_addr <= regA;
        wait for 125 ns;
        assert data=x"2a";
        assert a_out=x"2a";
        assert f_out=x"2f";
        wait for 125 ns;
        assert f_out=x"2f";
        wait for 125 ns;
        wrd <= '0';

        swp <= af;
        wait for 250 ns;
        swp <= none;
        wait for 250 ns;

        report("write to f and a simultaneosly (main reg)");
        rdf <= '1';
        rdd <= '1';
        reg_addr <= regA;
        data <= x"3a";
        f_in <= x"3f";
        wait for 250 ns;
        rdf <= '0';
        rdd <= '0';
        data <= (others => 'Z');

        report("control f, a (main reg)");
        wrd <= '1';
        reg_addr <= regA;
        wait for 125 ns;
        assert data=x"3a";
        assert a_out=x"3a";
        assert f_out=x"3f";
        wait for 125 ns;
        assert a_out=x"3a";
        assert f_out=x"3f";
        wait for 125 ns;
        wrd <= '0';

        report("write addresses to wz, sp, ix, iy");
        rda <= '1';
        for i in 0 to 3 loop
            reg_addr <= 8+2*i;
            addr <= x"0" & r(8+2*i) & r(8+2*i+1) & x"0";
            wait for 250 ns;
        end loop;
        rda <= '0';
        addr <= (others => 'Z');

        report("control addressses");
        wra <= '1';
        for i in 0 to 3 loop
            reg_addr <= 8+2*i;
            value_addr := x"0" & r(8+2*i) & r(8+2*i+1) & x"0";
            wait for 125 ns;
            assert addr_out=value_addr
                report vec_str(addr_out) & "!=" & vec_str(value_addr);
            assert addr_dis=value_addr
                report vec_str(addr_dis) & "!=" & vec_str(value_addr);
            wait for 125 ns;
        end loop;
        wra <= '0';
        
        wait for 1 us;
        assert false report "TB ENDDDD" severity failure;
    end process;
end arch;
