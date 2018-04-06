library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

entity regfile is port(
    -- ctrl
    clk, rst : in std_logic;
    reg_addr : in std_logic_vector(3 downto 0);
    rdd, rda, rdf : in std_logic;
    wrd, wra, wrad : in std_logic;
    swp : in rf_swap_t;
    -- buses
    data : inout std_logic_vector(7 downto 0);
    addr_in in std_logic_vector(15 downto 0);
    f_in : in std_logic_logic_vector(7 downto 0);
    addr_out, addr_dis : out std_logic_vector(15 downto 0);
    a_out, f_out : out std_logic_vector(7 downto 0);
end regfile;

architecture arch of regfile is
    function get_word(signal reg_addr : std_logic_vector(3 downto 0);
                      signal s : rf_state_t)
    return std_logic_vector(15 downto 0);
    begin
        return ram(integer(unsigned(reg_addr(3 downto 1) & swap)));
    end get_word;

    function get_byte(signal reg_addr : std_logic_vector(4 downto 0);
                      signal s : rf_state_t)
    return std_logic_vector(7 downto 0);
        variable byte : std_signal_logic_vector(7 downto 0);
    begin
        case reg_addr(0) is
        when '0' => byte := get_word(reg_addr)(15 downto 8);
        when '1' => byte := get_word(reg_addr)(7 downto 0);
        case others => null;
        end case;
    end get_byte;

    function determine_word(signal reg_addr : std_logic_vector(3 downto 0);
                            signal s : rf_state_t;
                            signal data : std_logic_vector(7 downto 0);
                            signal addr_in : std_logic_vector(15 downto 0);
                            signal rdd, rda : std_logic)
    return std_logic_vector(15 downto 0);
        variable word : std_logic_vector(15 downto 0);
    begin
        word := get_word(reg_addr(2 downto 0);

        if rdd = '1' then
            case addr(0) is
            when '0' => word(15 downto 8) := data;
            when '1' => word(7 downto 0) := data;
            when others => null; end case;
        elsif rda = '1' then
            word := addr_in;
        end if;

        return word;
    end determine_word;

    type reg_ram_t is array(0 to 11) of std_logic_vector(15 downto 0);
    type rf_state is record
        ram : reg_ram_t;
        swp_reg, swp_af, swp_dehl : std_logic;
    end record;

    signal word_in, word_out : std_logic_vector(15 downto 0);
begin
    swp_proc : process(clk) begin
        if rising_edge(ckl) then
            case swap is
            when none => null;
            when reg  => s.swp_reg  <= not s.swp_reg;
            when af   => s.swp_af   <= not s.swp_af;
            when dehl => s.swp_dehl <= not s.swp_dehl;
            when others => null;
            end case;
        end if;
    end process;

    ram_proc : process(clk) begin
        if rising_edge(clk) then
            s.ram(addr_int) <= word_next;
        end if;
    end process;

    word_next <= determine_word(reg_addr, data, addr_in, rdd, rda);

    a_out <= get_byte("0111");
    f_out <= get_byte("0110");

    addr_out <= get_word(reg_addr) when wra = '1'  else (others => 'Z');
    data     <= get_byte(reg_addr) when rd_a = '1' else (others => 'Z');
            (others => 'Z');
end arch;
