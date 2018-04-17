library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.cmp_comm.all;

entity asic is port(
    clk : in std_logic;
    cbi : out ctrlbus_in;
    cbo : in ctrlbus_out;
    addr : in std_logic_vector(7 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0);
    ports_in : in io_data_t;
    ports_out : out io_ports_t);
end asic;

architecture arch of asic is
    type io_ports_array_t is array(0 to 255) of port_t;
    type data_array_t is array(0 to 255) of std_logic_vector(7 downto 0);
    type rw_array_t is array(0 to 255) of std_logic;

    signal a : integer range 0 to 255 := 0;
    signal darr_in, darr_out : data_array_t;
    signal parr_out : io_ports_array_t;
    signal rd_arr, wr_arr : rw_array_t;
    signal port_rd_data : std_logic_vector(7 downto 0);
begin
    a <= to_integer(unsigned(addr));
    data_out <= port_rd_data when cbo.iorq = '1' and cbo.rd = '1' else x"00";
    port_rd_data <= darr_in(a);

    process(a, darr_out, rd_arr, wr_arr) begin
        for i in parr_out'range loop
            parr_out(i) <= (data => darr_out(i),
                            rd => rd_arr(i),
                            wr => wr_arr(i));
        end loop;
    end process;

    process(a, data_in) begin
        darr_out <= (others => (others => '-'));
        darr_out(a) <= data_in;
    end process;

    process(a, cbo.rd) begin
        rd_arr <= (others => '-');
        rd_arr(a) <= cbo.rd;
    end process;

    process(a, cbo.wr) begin
        wr_arr <= (others => '0');
        wr_arr(a) <= cbo.wr;
    end process;

    cbi.reset <= '0';
    cbi.wt <= '0';
    cbi.int <= '0';
    cbi.nmi <= '0';
    cbi.busrq <= '0';

    ports_out.lcd_status <= parr_out(16);
    ports_out.lcd_data <= parr_out(17);

    darr_in <= (2   => x"e1",               -- battery level
                -- TODO add static from legacy file
                16  => ports_in.lcd_status,
                17  => ports_in.lcd_data,
                others => (x"00"));
end arch;
