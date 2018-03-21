library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_tb is
end alu_tb;

architecture arch of alu_tb is
    component alu port(
        clk, rst : in std_logic;
        op1, op2 : in std_logic_vector(7 downto 0);
        c_in : in std_logic;
        instr : in std_logic_vector(7 downto 0);
        instr_set : in std_logic_vector(2 downto 0);
        res, flags : out std_logic_vector(7 downto 0));
    end component;

    signal clk, rst : std_logic;
    signal carry : std_logic;
    signal op1, op2 : std_logic_vector(7 downto 0);
    signal instr : std_logic_vector(7 downto 0);
    signal instr_set : std_logic_vector(2 downto 0);
    signal res, flags : std_logic_vector(7 downto 0);

    procedure test_value(
        signal op1 : out std_logic_vector(7 downto 0);
        signal op2 : out std_logic_vector(7 downto 0);
        signal instr : out std_logic_vector(7 downto 0);
        signal instr_set : out std_logic_vector(2 downto 0);
        signal c_in : out std_logic;
        signal flags : in std_logic_vector(7 downto 0);
        signal res : in std_logic_vector(7 downto 0);
        -- input
        constant operand1 : std_logic_vector(7 downto 0);
        constant operand2 : std_logic_vector(7 downto 0);
        constant instruction : std_logic_vector(7 downto 0);
        constant set : std_logic_vector(2 downto 0);
        constant carry_in : std_logic;
        -- assertions
        constant carry : std_logic;
        constant overflow : std_logic;
        constant result : std_logic_vector(7 downto 0))
    is begin
        op1 <= operand1;
        op2 <= operand2;
        instr <= instruction;
        instr_set <= set;
        c_in <= carry_in;
        wait for 15 ns;
        assert flags(0)=carry and flags(2)=overflow and res=result report lf &
            "instr: " & integer'image(to_integer(unsigned(instruction))) & lf &
            "ops: " & integer'image(to_integer(unsigned(operand1))) &
            " " & integer'image(to_integer(unsigned(operand2))) & lf &
            "res: " & integer'image(to_integer(unsigned(res))) &
            " " & integer'image(to_integer(unsigned(result))) & lf &
            "carry: " & std_logic'image(flags(0)) &
            " " & std_logic'image(carry_in) & lf &
            "overflow: " & std_logic'image(flags(2)) &
            " " & std_logic'image(overflow);
        wait for 5 ns;
    end procedure;

begin

    alu_comp : alu port map(
        clk => clk,
        rst => rst,
        op1 => op1,
        op2 => op2,
        c_in => carry,
        instr => instr,
        instr_set => instr_set,
        res => res,
        flags => flags);

    process begin
        while true loop
            clk <= '1';
            wait for 5 ns;
            clk <= '0';
            wait for 5 ns;
        end loop;
    end process;

    process begin
        op1 <= x"00";
        op2 <= x"00";
        instr <= x"00";
        instr_set <= "000";

        --add without carry
    --             op1    op2    instr  set    c_in  c_out o   res
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"01", x"01", x"80", "000", '0', '0', '0', x"02");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"01", x"7f", x"80", "000", '0', '0', '1', x"80");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"01", x"80", x"80", "000", '0', '0', '0', x"81");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"01", x"ff", x"80", "000", '0', '1', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"7f", x"01", x"80", "000", '0', '0', '1', x"80");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"80", x"7f", x"80", "000", '0', '0', '0', x"ff");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"80", x"80", x"80", "000", '0', '1', '1', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"80", x"ff", x"80", "000", '0', '1', '1', x"7f");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"ff", x"00", x"80", "000", '0', '0', '0', x"ff");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"ff", x"01", x"80", "000", '0', '1', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"ff", x"7f", x"80", "000", '0', '1', '0', x"7e");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"ff", x"7f", x"80", "000", '0', '1', '0', x"7e");
        
        --add with carry
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"00", x"88", "000", '0', '0', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"00", x"88", "000", '1', '0', '0', x"01");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"01", x"01", x"88", "000", '1', '0', '0', x"03");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"7f", x"88", "000", '1', '0', '1', x"80");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"ff", x"88", "000", '1', '1', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"7f", x"7f", x"88", "000", '1', '0', '1', x"ff");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"80", x"80", x"88", "000", '1', '1', '1', x"01");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"7f", x"81", x"88", "000", '1', '1', '0', x"01");

        --sub
    --             op1    op2    instr  set    c_in  c_o  ov  res
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"00", x"90", "000", '0', '0', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"01", x"90", "000", '0', '1', '0', x"ff");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"7f", x"7f", x"90", "000", '0', '0', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"80", x"01", x"90", "000", '0', '0', '1', x"7f");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"ff", x"ff", x"90", "000", '0', '0', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"7f", x"81", x"90", "000", '0', '1', '1', x"fe");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"ff", x"7f", x"90", "000", '0', '0', '0', x"80");

        --sub with carry
    --             op1    op2    instr  set    c_in  c_o  ov  res
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"00", x"98", "000", '0', '0', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"01", x"90", "000", '0', '1', '0', x"ff");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"7f", x"7f", x"90", "000", '0', '0', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"80", x"01", x"90", "000", '0', '0', '1', x"7f");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"ff", x"ff", x"90", "000", '0', '0', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"7f", x"81", x"90", "000", '0', '1', '1', x"fe");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"ff", x"7f", x"90", "000", '0', '0', '0', x"80");
    end process;

    rst <= '0';

end arch;
