library ieee;
use ieee.std_logic_1164.all;

entity swaptest is
end swaptest;

architecture arch of swaptest is
    signal clk : std_logic;

    signal main : std_logic_vector(1 downto 0) := "01";
    signal di_main, do_main : std_logic_vector(1 downto 0) := "00";
    signal rd_main : std_logic := '0';

    signal prim : std_logic_vector(1 downto 0) := "10";
    signal di_prim, do_prim : std_logic_vector(1 downto 0) := "00";
    signal rd_prim : std_logic := '0';

    signal di, do, do_buf, data_bus : std_logic_vector(1 downto 0);
    signal rd, wr, swap : std_logic := '0';

    signal data : std_logic_vector(1 downto 0);
begin

    -- reg internals
    process(clk) begin
        if rising_edge(clk) then
            if rd_main = '1' then
                main <= di_main;
            end if;
            if rd_prim = '1' then
                prim <= di_prim;
            end if;
        end if;
    end process;

    do_main <= main;
    do_prim <= prim;

    -- pair
    di_main <= do_prim when rd = '0' else di;
    di_prim <= do_main;
    do_buf <= do_main;

    -- reg file
    di <= data_bus;
    data_bus <= do;
    do <= do_buf when wr = '1' else (others => 'Z');

    rd_main <= rd or swap;
    rd_prim <= swap;


    -- TESTBENCH --

    data_bus <= data;

    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    process begin
        data <= (others => 'Z');
        wait for 10 ns;
        
        report "swap";
        swap <= '1';
        wait for 10 ns;
        swap <= '0';
        wait for 30 ns;

        report "read";
        data <= "11";
        rd <= '1';
        wait for 10 ns;
        data <= (others => 'Z');
        rd <= '0';
        wait for 30 ns;

        report "write";
        wr <= '1';
        wait for 10 ns;
        wr <= '0';
        wait for 30 ns;

        assert false severity failure;
    end process;

end arch;
