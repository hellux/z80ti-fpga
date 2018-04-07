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
        r : in std_logic_vector(3 downto 0);
        rdd, rda, rdf : in std_logic;
        wrd, wra : in std_logic;
        swp : in rf_swap_t;
        data : inout std_logic_vector(7 downto 0);
        addr : in std_logic_vector(15 downto 0);
        f_in : in std_logic_vector(7 downto 0);
        addr_out, addr_dis : out std_logic_vector(15 downto 0);
        a_out, f_out : out std_logic_vector(7 downto 0));
    end component;

    signal clk, rst, rdd, rda, rdf, wrd, wra, wrf : std_logic;
    signal reg_addr : std_logic_vector(3 downto 0);
    signal swp : rf_swap_t;
    signal f_in, data, a_out, f_out : std_logic_vector(7 downto 0);
    signal addr, addr_out, addr_dis : std_logic_vector(15 downto 0);
    
    type reg_hex_t is array(0 to 15) of std_logic_vector(3 downto 0);
    constant r : reg_hex_t := 
        (x"b", x"c",  -- BC
         x"d", x"e",  -- DE
         x"4", x"1",  -- HL
         x"f", x"a",  -- FA
         x"8", x"2",  -- WZ
         x"5", x"5",  -- SP
         x"6", x"6",  -- IX
         x"7", x"7"); -- IY
begin
    rf : regfile port map(clk, rst, reg_addr, rdd, rda, rdf, wrd, wra, swp,
                          data, addr, f_in, addr_out, addr_dis, a_out, f_out);

    process begin
        clk <= '1';
        wait for 125 ns;
        clk <= '0';
        wait for 125 ns;
    end process;

    process
        variable i : integer;
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

        -- write to all reg
        rdd <= '1';
        for i in 0 to 15 loop
            reg_addr <= std_logic_vector(to_unsigned(i, 4));
            data <= x"9" & r(i);
            wait for 250 ns;
        end loop;
        rdd <= '0';
        data <= (others => 'Z');

        wait for 1 us;

        -- read from all reg
        wrd <= '1';
        for i in 0 to 15 loop
            reg_addr <= std_logic_vector(to_unsigned(i, 4));
            value := x"9" & r(i);
            wait for 125 ns;
            assert data=value report vec_str(data) & "!=" & vec_str(value);
            wait for 125 ns;
        end loop;
        wrd <= '0';
        
        -- swap main reg
        swp <= reg;
        wait for 250 ns;
        swp <= none;
        wait for 250 ns;

        -- ensure swapped regs are zero
        wrd <= '1';
        for i in 0 to 5 loop
            reg_addr <= std_logic_vector(to_unsigned(i, 4));
            value := "00000000";
            wait for 125 ns;
            assert data=value report vec_str(data) & "!=" & vec_str(value);
            wait for 125 ns;
        end loop;
        wrd <= '0';

        -- make sure others not swapped
        wrd <= '1';
        for i in 6 to 12 loop
            reg_addr <= std_logic_vector(to_unsigned(i, 4));
            value := x"9" & r(i);
            wait for 125 ns;
            assert data=value report vec_str(data) & "!=" & vec_str(value);
            wait for 125 ns;
        end loop;
        wrd <= '0';

        -- write to swapped
        rdd <= '1';
        for i in 0 to 5 loop
            reg_addr <= std_logic_vector(to_unsigned(i, 4));
            data <= x"3" & r(i);
            wait for 250 ns;
        end loop;
        rdd <= '0';
        data <= (others => 'Z');

        swp <= af;
        wait for 250 ns;
        swp <= none;
        wait for 250 ns;

        -- write to swapped af
        rdd <= '1';
        for i in 6 to 7 loop
            reg_addr <= std_logic_vector(to_unsigned(i, 4));
            data <= x"3" & r(i);
            wait for 250 ns;
        end loop;
        rdd <= '0';
        data <= (others => 'Z');
        
        swp <= dehl;
        wait for 250 ns;
        swp <= none;
        wait for 250 ns;

        -- read swapped dehl
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

        -- write to f and a simultaneosly (swp reg)
        rdf <= '1';
        rdd <= '1';
        reg_addr <= regA;
        data <= x"2a";
        f_in <= x"2f";
        wait for 250 ns;
        rdf <= '0';
        rdd <= '0';
        data <= (others => 'Z');

        -- control f, a (swp reg)
        wrd <= '1';
        reg_addr <= regA;
        wait for 125 ns;
        assert data=x"2a";
        assert a_out=x"2a";
        assert f_out=x"2f";
        reg_addr <= regF;
        wait for 125 ns;
        assert data=x"2f";
        wait for 125 ns;
        wrd <= '0';

        swp <= af;
        wait for 250 ns;
        swp <= none;
        wait for 250 ns;

        -- write to f and a simultaneosly (main reg)
        rdf <= '1';
        rdd <= '1';
        reg_addr <= regA;
        data <= x"3a";
        f_in <= x"3f";
        wait for 250 ns;
        rdf <= '0';
        rdd <= '0';
        data <= (others => 'Z');

        -- control f, a (main reg)
        wrd <= '1';
        reg_addr <= regA;
        wait for 125 ns;
        assert data=x"3a";
        assert a_out=x"3a";
        assert f_out=x"3f";
        reg_addr <= regF;
        wait for 125 ns;
        assert data=x"3f";
        assert a_out=x"3a";
        assert f_out=x"3f";
        wait for 125 ns;
        wrd <= '0';

        -- write addresses to wz, sp, ix, iy
        rda <= '1';
        for i in 0 to 3 loop
            reg_addr <= std_logic_vector(to_unsigned(8+2*i, 4));
            addr <= x"0" & r(8+2*i) & r(8+2*i+1) & x"0";
            wait for 250 ns;
        end loop;
        rda <= '0';
        addr <= (others => 'Z');

        -- control addressses
        wra <= '1';
        for i in 0 to 3 loop
            reg_addr <= std_logic_vector(to_unsigned(8+2*i, 4));
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
