library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_tb_v2 is
end alu_tb_v2;

architecture arch of alu_tb_v2 is
    component alu port(
        clk, rst : in std_logic;
        op1, op2 : in std_logic_vector(7 downto 0);
        flags_in : in std_logic_vector(7 downto 0);
        instr : in std_logic_vector(7 downto 0);
        instr_set : in std_logic_vector(2 downto 0);
        result, flags_out : out std_logic_vector(7 downto 0));
    end component;

    function slv_to_str(x : std_logic_vector(1 to 8)) return string is
        variable res : string(1 to 8);
    begin
        for i in x'range loop
            res(i) := std_logic'image(x(i))(2);
        end loop;
        return res;
    end slv_to_str;

    procedure test(
        signal op1_s : out std_logic_vector(7 downto 0);
        signal op2_s : out std_logic_vector(7 downto 0);
        signal instr_s : out std_logic_vector(7 downto 0);
        signal set_s : out std_logic_vector(2 downto 0);
        signal flags_in_s : out std_logic_vector(7 downto 0);
        signal flags_out_s : in std_logic_vector(7 downto 0);
        signal result_s : in std_logic_vector(7 downto 0);
        -- input
        constant op1 : std_logic_vector(7 downto 0);
        constant op2 : std_logic_vector(7 downto 0);
        constant instr : std_logic_vector(7 downto 0);
        constant set : std_logic_vector(2 downto 0);
        constant flags_in : std_logic_vector(7 downto 0);
        -- assertions
        constant flags_out : std_logic_vector(7 downto 0);
        constant result : std_logic_vector(7 downto 0))
    is begin
        op1_s <= op1;
        op2_s <= op2;
        instr_s <= instr;
        set_s <= set;
        flags_in_s <= flags_in;
        wait for 5 ns;
        assert result_s = result and
               (flags_out(0) = '-' or (flags_out_s(0) = flags_out(0))) and
               (flags_out(1) = '-' or (flags_out_s(1) = flags_out(1))) and
               (flags_out(2) = '-' or (flags_out_s(2) = flags_out(2))) and
               (flags_out(3) = '-' or (flags_out_s(3) = flags_out(3))) and
               (flags_out(4) = '-' or (flags_out_s(4) = flags_out(4))) and
               (flags_out(5) = '-' or (flags_out_s(5) = flags_out(5))) and
               (flags_out(6) = '-' or (flags_out_s(6) = flags_out(6))) and
               (flags_out(7) = '-' or (flags_out_s(7) = flags_out(7)))
            report lf & 
            "index      76543210" & lf &
            "instr      " & slv_to_str(instr) & " " & 
                integer'image(to_integer(unsigned(instr))) & lf & lf &
            "op1        " & slv_to_str(op1) & " " & 
                integer'image(to_integer(unsigned(op1))) & lf &
            "op2        " & slv_to_str(op2) & " " & 
                integer'image(to_integer(unsigned(op2))) & lf & lf &
            "flags      SZ-H-PNC" & lf &
            "flags_in   " & slv_to_str(flags_in) & lf &
            "flags_actu " & slv_to_str(flags_out_s) & lf &
            "flags_want " & slv_to_str(flags_out) & lf & lf &
            "res_actu:  " & slv_to_str(result_s) & " " &
                integer'image(to_integer(unsigned(result_s))) & lf &
            "res_want:  " & slv_to_str(result) & " " &
                integer'image(to_integer(unsigned(result)));
        wait for 5 ns;
    end procedure;

    signal clk, rst : std_logic;
    signal op1, op2 : std_logic_vector(7 downto 0);
    signal flags_in : std_logic_vector(7 downto 0);
    signal instr : std_logic_vector(7 downto 0);
    signal instr_set : std_logic_vector(2 downto 0);
    signal result, flags_out : std_logic_vector(7 downto 0);
begin
    alu_comp : alu port map(
        clk => clk,
        rst => rst,
        op1 => op1,
        op2 => op2,
        flags_in => flags_in,
        instr => instr,
        instr_set => instr_set,
        result => result,
        flags_out => flags_out
    );
    rst <= '0';

    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    process begin
        op1 <= x"00";
        op2 <= x"00";
        instr <= x"00";
        instr_set <= "000";

        report "add";
        test(op1, op2, instr, instr_set, flags_in, flags_out, result,
             x"01", x"01", x"80", "000", "00000001", "00-0-000", x"02");
        test(op1, op2, instr, instr_set, flags_in, flags_out, result,
             x"01", x"01", x"80", "000", "00000000", "00-0-000", x"02");
        test(op1, op2, instr, instr_set, flags_in, flags_out, result,
             x"01", x"7f", x"80", "000", "00000000", "10-1-100", x"80");
        test(op1, op2, instr, instr_set, flags_in, flags_out, result,
             x"01", x"7f", x"80", "000", "00000000", "10-1-100", x"80");
        test(op1, op2, instr, instr_set, flags_in, flags_out, result,
             x"23", x"33", x"80", "000", "00000000", "00-0-000", x"56");

        report "sub";
        test(op1, op2, instr, instr_set, flags_in, flags_out, result,
             x"29", x"11", x"90", "000", "00000001", "00-0-000", x"18");

        report "bit";
        test(op1, op2, instr, instr_set, flags_in, flags_out, result,
             x"f0", x"01", x"40", "100", "00000001", "-0-1--01", x"01");
        test(op1, op2, instr, instr_set, flags_in, flags_out, result,
             x"f0", x"ff", x"50", "110", "00000000", "-0-1--00", x"ff");
        test(op1, op2, instr, instr_set, flags_in, flags_out, result,
             x"f0", x"fd", x"48", "110", "00000000", "-1-1--00", x"fd");
        test(op1, op2, instr, instr_set, flags_in, flags_out, result,
             x"f0", x"fd", x"58", "110", "00000000", "-0-1--00", x"fd");
        test(op1, op2, instr, instr_set, flags_in, flags_out, result,
             x"f0", x"c8", x"62", "100", "11111111", "-1-1--01", x"c8");

        assert false report "TB COMPLETE" severity failure;
     end process;

 end arch;
