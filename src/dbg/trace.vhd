library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cmp_comm.all;

-- write jump addresses to memory for debugging
--
-- example:
--  0x803c: jp 0xf000
--  0xf0d0: call 0x9d95
--   yields:
--                  ____
-- LIST_BOTTOM --> |_3c_|
--                 |_80_|
--                 |_00_|
--                 |_f0_|
--                 |_d0_|
--                 |_f0_|
--                 |_95_|
--                 |_9d_|
--    list ptr --> |____|
--                   :   
--                   :   
--                 |____|
--                 |____|
-- running
--      hexdump -e '"%06.6_ax: " 1/2 "%04x" " -> " 1/2 "%04x" "\n"' trace.bin
-- outputs
--      000000: 8003 -> f000
--      000004: f0d0 -> 9d95

entity trace is port(
    clk, rst, ce : in std_logic;
    enable, disable : in std_logic;
    jump_beg, jump_end : in std_logic;
    pc : in std_logic_vector(15 downto 0);
    cpu_block : out std_logic;
    wr : out std_logic;
    addr : out std_logic_vector(23 downto 0);
    data : out std_logic_vector(15 downto 0);
-- debug
    dbg : out dbg_trace_t);
end trace;

architecture arch of trace is
    component reg is generic(init : std_logic_vector;
                             size : integer); port(
        clk, rst, ce : in std_logic;
        rd : in std_logic;
        di : in std_logic_vector(size-1 downto 0);
        do : out std_logic_vector(size-1 downto 0));
    end component;

    constant LIST_BOTTOM : unsigned(23 downto 0) := x"088000";
    constant WR_CYCLE1 : natural := 2;
    constant WR_CYCLE2 : natural := 6;
    constant CYCLES : natural := 8;

    type trace_state_t is (disabled, idle, store);

    signal from_addr, to_addr, pc_from_corr : std_logic_vector(15 downto 0);
    signal list_ptr : unsigned(23 downto 0) := LIST_BOTTOM;
    signal to_rd : std_logic;
    signal state : trace_state_t := disabled;
    signal store_cycle : integer range 1 to 8;
begin
    pc_from_corr <= std_logic_vector(unsigned(pc) - 1);
    save_from : reg generic map(x"0000", 16)
                    port map(clk, rst, ce, jump_beg, pc_from_corr, from_addr);
    save_to : reg generic map(x"0000", 16)
                  port map(clk, rst, ce, to_rd, pc, to_addr);

    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' or disable = '1' then
                list_ptr <= LIST_BOTTOM;
                state <= disabled;
            elsif ce = '1' then
                to_rd <= '0';
                case state is
                when disabled =>
                    if enable = '1' then
                        state <= idle;
                    end if;
                when idle =>
                    if jump_end = '1' then
                        state <= store;
                        store_cycle <= 1;
                        to_rd <= '1';
                    end if;
                when store =>
                    if store_cycle /= CYCLES then
                        store_cycle <= store_cycle + 1;
                    end if;
                    case store_cycle is
                    when WR_CYCLE1|WR_CYCLE2 =>
                        list_ptr <= list_ptr + 2;
                    when CYCLES =>
                        state <= idle;
                    when others => null; end case;
                end case;
            end if;
        end if;
    end process;

    data <= (others => '0') when state = idle else
            from_addr       when store_cycle = WR_CYCLE1 else 
            to_addr         when store_cycle = WR_CYCLE2 else
            (others => '0');
    addr <= std_logic_vector(list_ptr);
    wr <= '1' when state = store and
        (store_cycle = WR_CYCLE1 or store_cycle = WR_CYCLE2) else
          '0';
    cpu_block <= '1' when state = store else '0';

    dbg.enabled <= '0' when state = disabled else '1';
    dbg.from_jump <= from_addr;
    dbg.to_jump <= to_addr;
end arch;
