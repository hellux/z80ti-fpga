library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity regfile_tb_v2 is
end regfile_tb_v2;

architecture arch of regfile_tb_v2 is
    component regfile port(
        clk, rst : in std_logic;
        reg_addr : in std_logic_vector(3 downto 0);
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
    signal data, a_out, f_out : std_logic_vector(7 downto 0);
    signal addr, addr_out, addr_dis : std_logic_vector(15 downto 0);
begin
    rf : regfile port map(clk, rst, reg_addr, rdd, rda, rdf, wrd, wra, swp,
                          data, addr, x"00", addr_out, addr_dis, a_out, f_out);

    process begin
        clk <= '1';
        wait for 125 ns;
        clk <= '0';
        wait for 125 ns;
    end process;

    process
        variable i : integer;
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

        rdd <= '1';
        for i in 0 to 12 loop
            reg_addr <= std_logic_vector(to_unsigned(i, 4));
            data <= x"f" & std_logic_vector(to_unsigned(i, 4));
            wait for 250 ns;
        end loop;
        rdd <= '0';
        data <= (others => 'Z');

        wait for 1 us;
        assert false report "TB ENDDDD" severity failure;
    end process;
end arch;
