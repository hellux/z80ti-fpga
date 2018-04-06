library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.util.all;

-- INTERNAL RAM LAYOUT
-- addr_int    high    low
--           _______________
-- 0000     |___B___|___C___|
-- 0001     |___B___|___C___|
-- 0010     |___D___|___E___|
-- 0011     |___D___|___E___|
-- 0100     |___H___|___L___|
-- 0101     |___H___|___L___|
-- 0110     |___F___|___A___|
-- 0111     |___F___|___A___|
-- 1000     |___W___|___Z___|
-- 1001     |______SP_______|
-- 1010     |______IX_______|
-- 1011     |______IY_______|

-- ADDRESSES
-- reg_addr reg
-- 0000     B
-- 0001     C
-- 0010     D
-- 0011     E
-- 0100     H
-- 0101     L
-- 0110     F
-- 0111     A
-- 1000     W
-- 1001     Z
-- 1010     IX
-- 1011     IY
-- 1100     SP

entity regfile is port(
    -- ctrl
    clk, rst : in std_logic;
    reg_addr : in std_logic_vector(3 downto 0);
    rdd, rda, rdf : in std_logic;
    wrd, wra : in std_logic;
    swp : in rf_swap_t;
    -- buses
    data : inout std_logic_vector(7 downto 0);
    addr : in std_logic_vector(15 downto 0);
    f_in : in std_logic_vector(7 downto 0);
    addr_out, addr_dis : out std_logic_vector(15 downto 0);
    a_out, f_out : out std_logic_vector(7 downto 0));
end regfile;

architecture arch of regfile is
    type rf_ram_t is array(0 to 11) of std_logic_vector(15 downto 0);
    type rf_state_t is record
        ram : rf_ram_t;
        swp_reg, swp_af, swp_dehl : std_logic;
    end record;
    type rf_input_t is record
        reg_addr : std_logic_vector(3 downto 0);
        rdd, rda, rdf : std_logic;
        swp : rf_swap_t;
        data, f : std_logic_vector(7 downto 0);
        addr : std_logic_vector(15 downto 0);
    end record;

    function addr_int(reg_addr : std_logic_vector(3 downto 0);
                      signal s : rf_state_t)
    return integer is
        variable addr_internal : std_logic_vector(3 downto 0);
    begin
        if reg_addr(3) = '0' and reg_addr(2 downto 1) /= "11" then
            addr_internal := reg_addr(3 downto 1) & s.swp_reg;
            if s.swp_dehl = '1' and reg_addr(2 downto 1) /= "00" then
                addr_internal(2 downto 1) := not addr_internal(2 downto 1);
            end if;
        elsif reg_addr(3) = '0' then
            addr_internal := "011" & s.swp_af;
            addr_internal := reg_addr;
        elsif reg_addr(3 downto 1) = "100" then
            addr_internal := "1000";
        elsif reg_addr = "1100" then
            addr_internal := "1001";
        else
            addr_internal := reg_addr;
        end if;
        return to_integer(unsigned(addr_internal));
    end addr_int;

    function get_word(reg_addr : std_logic_vector(3 downto 0);
                      signal s : rf_state_t)
    return std_logic_vector is
    begin
        return s.ram(addr_int(reg_addr, s));
    end get_word;

    function get_byte(reg_addr : std_logic_vector(3 downto 0);
                      signal s : rf_state_t)
    return std_logic_vector is
        variable w : std_logic_vector(15 downto 0);
    begin
        w := get_word(reg_addr, s);
        if reg_addr(0) = '0' then
            return w(15 downto 8);
        else 
            return w(7 downto 0);
        end if;
    end get_byte;

    function next_ram(signal s : rf_state_t; signal i : rf_input_t)
    return rf_ram_t is
        variable ram : rf_ram_t;
        variable new_word : std_logic_vector(15 downto 0);
    begin
        ram := s.ram;

        new_word := get_word(i.reg_addr, s);
        if i.rdd = '1' and i.reg_addr(0) = '0' then
            new_word(15 downto 8) := i.data;
        elsif i.rdd = '1' and i.reg_addr(0) = '1' then
            new_word(7  downto 0) := i.data;
        elsif i.rda = '1' then
            new_word := i.addr;
        end if;
        ram(addr_int(i.reg_addr, s)) := new_word;

        if i.rdf = '1' then
            ram(addr_int(regF, s))(15 downto 8) := i.f;
        end if;

        return ram;
    end next_ram;

    signal s : rf_state_t := ((others => (others => '0')), others => '0');
    signal i : rf_input_t;
    signal ram_next : rf_ram_t;
begin
    swp_proc : process(clk) begin
        if rising_edge(clk) then
            case swp is
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
            if rst = '1' then
                s <= ((others => (others => '0')), others => '0');
            else 
                s.ram <= ram_next;
            end if;
        end if;
    end process;

    i <= (reg_addr, rdd, rda, rdf, swp, data, f_in, addr);
    ram_next <= next_ram(s, i); 

    a_out    <= get_byte(regA, s);
    f_out    <= get_byte(regF, s);
    addr_dis <= get_word(reg_addr, s);
    addr_out <= get_word(reg_addr, s) when wra  = '1' else (others => 'Z');
    data     <= get_byte(reg_addr, s) when wrd  = '1' else (others => 'Z');
end arch;
