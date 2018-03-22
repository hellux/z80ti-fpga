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
            " " & std_logic'image(carry) & lf &
            "p/v: " & std_logic'image(flags(2)) &
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

        report "add";
        --add without carry
    --             op1    op2    instr  set    c_in  c_out o   res
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"01", x"01", x"80", "000", '1', '0', '0', x"02");
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
        
        report "adc";
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

        report "sub";
        --sub
    --             op1    op2    instr  set    c_in  c_o  ov  res
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"00", x"90", "000", '1', '0', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"00", x"95", "000", '0', '0', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"7f", x"9a", "000", '0', '1', '0', x"81");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"01", x"90", "000", '0', '1', '0', x"ff");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"7f", x"7f", x"9e", "000", '0', '0', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"80", x"01", x"91", "000", '0', '0', '1', x"7f");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"ff", x"ff", x"96", "000", '0', '0', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"7f", x"81", x"97", "000", '0', '1', '1', x"fe");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"ff", x"7f", x"95", "000", '0', '0', '0', x"80");

        report "sbc";
        --sub with carry
    --             op1    op2    instr  set    c_in  c_o  ov  res
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"00", x"98", "000", '0', '0', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"01", x"9c", "000", '1', '1', '0', x"fe");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"ff", x"9e", "000", '1', '1', '0', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"7f", x"9f", "000", '1', '1', '0', x"80");

        report "and";
        -- and
    --             op1    op2    instr  set    c_in  c_o  p  res
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"00", x"a0", "000", '0', '0', '1', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"00", x"a2", "000", '1', '0', '1', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"ff", x"00", x"a5", "000", '1', '0', '1', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"ff", x"ff", x"a7", "000", '0', '0', '1', x"ff");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"0f", x"ff", x"a3", "000", '0', '0', '1', x"0f");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"0f", x"01", x"a3", "000", '0', '0', '0', x"01");

        report "xor";
        -- xor
    --             op1    op2    instr  set    c_in  c_o  ov  res
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"00", x"ac", "000", '0', '0', '1', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"f0", x"f0", x"a9", "000", '1', '0', '1', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"f0", x"0f", x"a8", "000", '0', '0', '1', x"ff");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"02", x"ff", x"aa", "000", '0', '0', '0', x"fd");

        report "or";
        -- or
    --             op1    op2    instr  set    c_in  c_o  p  res
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"ff", x"b0", "000", '0', '0', '1', x"ff");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"01", x"ff", x"b1", "000", '1', '0', '1', x"ff");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"01", x"00", x"b7", "000", '1', '0', '0', x"01");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"01", x"ff", x"b3", "000", '0', '0', '1', x"ff");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"51", x"2e", x"b2", "000", '0', '0', '0', x"7f");

        report "rlc";
        -- rlc
    --             op1    op2    instr  set    c_in  c_o  p  res
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"01", x"02", "100", '0', '0', '0', x"02");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"80", x"80", x"07", "100", '0', '1', '0', x"01");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"00", x"01", "100", '0', '0', '1', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"ff", x"03", "100", '0', '1', '1', x"ff");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"0f", x"00", "100", '0', '0', '1', x"1e");

        report "rrc";
        -- rrc
    --             op1    op2    instr  set    c_in  c_o  p  res
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"01", x"08", "100", '0', '1', '0', x"80");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"80", x"80", x"0f", "100", '0', '0', '0', x"40");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"00", x"09", "100", '0', '0', '1', x"00");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"ff", x"0a", "100", '0', '1', '1', x"ff");
        test_value(op1, op2, instr, instr_set, carry, flags, res,
                   x"00", x"0f", x"0c", "100", '0', '1', '1', x"87");



        report "ALL TESTS COMPLETED";
        assert false severity failure;
    end process;

    rst <= '0';

end arch;
