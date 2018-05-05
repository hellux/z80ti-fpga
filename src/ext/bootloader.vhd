library ieee;
use ieee.std_logic_1164.all;

entity bootloader is port(
    clk, rst : std_logic;
-- bootloader <-> memory interface
    mem_wr : std_logic;
    mem_data_in : in std_logic_vector(7 downto 0);
    mem_data_out : out std_logic_vector(7 downto 0);
-- bootloader <-> uart
    rx1, rx2 : std_logic);
end bootloader;

architecture arch of bootloader is
    component reg generic(init : std_logic_vector;
                          size : integer); port(
        clk, rst, ce : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;

    type bl_uart_state_t is (idle, read, succ);
    type bl_load_state_t is (idle, init, load);

    signal uart_state : bl_uart_state_t := idle;
    signal bit_index : unsigned(3 downto 0);

    signal sreg : std_logic_vector(9 downto 0);
    signal sreg_ce : std_logic;
begin
    bit_cntr :process(clk) begin
        if rising_edge(clk) then
            if rst = '1' or bitcount = 868 then
                bitcount <= (others => '0');
            else
                bitcount <= bitcount + 1;
            end if;
        end if;
    end process;
    next_bit <= '1' when bitcount = 868 else '0';

    uart_ctrl : process(clk) begin
        if rising_edge(clk) then
            data_rd <= '0';
            if rst = '1' then
                uart_state <= idle;
            elsif next_bit = '1' then
                case uart_state is
                when idle =>
                    if rx1 = '0' then
                        uart_state <= read;
                        bit_index <= (others => '0');
                    end if;
                when read =>
                    if bit_index = 8 then
                        case rx1 is
                        when '0' =>
                            uart_state <= idle;
                        when '1' =>
                            uart_state <= succ;
                            data_rd <= '1';
                        when others => null;
                        end case;
                    else
                        bit_index <= bit_index + 1;
                    end if;
                when succ => 
                    case rx1 is
                    when '0' => 
                        uart_state <= read;
                        bit_index <= (others => '0');
                    when '1' => 
                        uart_state <= idle;
                    when others => null;
                    end case;
                end case;
            end if;
        end if;
    end process;

    sreg_proc : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                sreg <= (others => '0');
            elsif sreg_ce = '1' then
                sreg(9) <= rx2;
                sreg(8 downto 0) <= sreg(9 downto 1);
            end if;
        end if;
    end process;

    dreg : reg generic port(x"00", 8) port map(clk, rst, '1',
                data_rd, sreg(8 downto 1), mem_data_out);
end arch;
