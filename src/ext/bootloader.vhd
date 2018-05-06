library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cmp_comm.all;

entity bootloader is port(
    clk, rst : in std_logic;
-- board -> bootloader
    ld, done : in std_logic;
-- bootloader -> memory interface
    mem_wr : out std_logic;
    mem_data : out std_logic_vector(7 downto 0);
    mem_addr : out std_logic_vector(19 downto 0);
-- bootloader <-> uart
    rx : in std_logic);
end bootloader;

architecture arch of bootloader is
    component reg generic(init : std_logic_vector;
                          size : integer); port(
        clk, rst, ce : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;

    constant ROM_SIZE : integer := 2**19;
    constant UART_RATE : integer := 115200;
    constant UART_DIV : integer := FREQ/UART_RATE;

    type bl_uart_state_t is (idle, read, succ);
    type bl_load_state_t is (idle, init, load);

    signal rx1, rx2 : std_logic;

    signal uart_state : bl_uart_state_t := idle;
    signal load_state : bl_load_state_t := idle;

    signal bit_count : unsigned(9 downto 0) := (others => '0');
    signal bit_index : unsigned(3 downto 0) := (others => '0');
    signal next_bit : std_logic;
    signal byte_done : std_logic;

    signal sreg : std_logic_vector(9 downto 0) := (others => '0');

    signal data_init, data_load : std_logic_vector(7 downto 0);
    signal addr : unsigned(19 downto 0);
begin
    sync_rx : process(clk) begin
        if rising_edge(clk) then
            rx1 <= rx;
            rx2 <= rx1;
        end if;
    end process;

    load_ctrl : process(clk) begin
        if rising_edge(clk) then
            case load_state is
            when idle =>
                if ld = '1' then
                    load_state <= init;
                    addr <= x"7bfff";
                end if;
            when init =>
                if next_bit = '1' then -- use for time delay
                    addr <= addr + 1;
                end if;
                if addr >= x"7c003" and ld = '0' then
                    load_state <= load;
                    addr <= (others => '1');
                end if;
            when load =>
                if addr = ROM_SIZE or done = '1' then
                    load_state <= idle;
                end if;
                if byte_done = '1' then
                    addr <= addr + 1;
                end if;
            end case;
        end if;
    end process;

    mem_wr <= '0' when load_state = idle else '1';
    with addr select
        data_init <= x"c3" when x"7c000",
                     x"00" when x"7c001",
                     x"00" when x"7c002",
                     x"00" when others;

    bit_cntr : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' or bit_count = UART_DIV then
                bit_count <= (others => '0');
            else
                bit_count <= bit_count + 1;
            end if;
        end if;
    end process;

    next_bit <= '1' when bit_count = 0 else '0';

    uart_ctrl : process(clk) begin
        if rising_edge(clk) then
            byte_done <= '0';
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
                        if rx1 = '1' then
                            uart_state <= succ;
                            byte_done <= '1';
                        else 
                            uart_state <= idle;
                        end if;
                    else
                        bit_index <= bit_index + 1;
                    end if;
                when succ => 
                    if rx1 = '1' then
                        uart_state <= idle;
                    else 
                        uart_state <= read;
                        bit_index <= (others => '0');
                    end if;
                end case;
            end if;
        end if;
    end process;

    sreg_proc : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                sreg <= (others => '0');
            elsif next_bit = '1' then
                sreg(9) <= rx2;
                sreg(8 downto 0) <= sreg(9 downto 1);
            end if;
        end if;
    end process;

    dreg : reg generic map(x"00", 8)
               port map(clk, rst, '1', byte_done, sreg(8 downto 1), data_load);

    mem_data <= data_load when load_state = load else data_init;
    mem_addr <= std_logic_vector(addr);
end arch;
