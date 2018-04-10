library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.util.all;

-- INTERNAL RAM LAYOUT
--   addr       high    low      addr
--            _______________  
-- 00 00000  |___B___|___C___|  00001 01
-- 02 00010  |___B___|___C___|  00011 03
-- 04 00100  |___D___|___E___|  00101 05
-- 06 00110  |___D___|___E___|  00111 07
-- 08 01000  |___H___|___L___|  01001 09
-- 10 01010  |___H___|___L___|  01011 11
-- 12 01100  |___A___|___F___|  01101 13
-- 14 01110  |___A___|___F___|  01111 15
-- 16 10000  |___W___|___Z___|  10001 17
-- 18 10010  |______SP_______|  10011 19
-- 20 10100  |______IX_______|  10011 21
-- 22 10110  |______IY_______|  10111 23

entity regfile is port(
    -- ctrl
    clk, rst : in std_logic;
    reg_addr : in integer range 0 to 15;
    rdd, rda, rdf : in std_logic;
    wrd, wra : in std_logic;
    swp : in rf_swap_t;
    -- buses
    data : inout std_logic_vector(7 downto 0);
    addr : in std_logic_vector(15 downto 0);
    f_in : in std_logic_vector(7 downto 0);
    addr_out, addr_out_dis : out std_logic_vector(15 downto 0);
    a_out, f_out : out std_logic_vector(7 downto 0);
    -- debug
    dbg_regs : out dbg_regs_t);
end regfile;

architecture arch of regfile is
    type rf_ram_t is array(0 to 23) of std_logic_vector(7 downto 0);
    type rf_swap_state_t is record reg, af, dehl : std_logic; end record;

    function baddr(reg_addr : integer;
                   s : rf_swap_state_t)
    return integer
    is
        variable r, w_vec : std_logic_vector(3 downto 0);
        variable hl : std_logic;
    begin
        r := std_logic_vector(to_unsigned(reg_addr, 4));
        if r(3) = '0' and r(2 downto 1) /= "11" and s.dehl = '1' then
            w_vec := '0' & r(1) & r(2) & s.reg;
        elsif r(3) = '0' and r(2 downto 1) /= "11" then
            w_vec := r(3 downto 1) & s.reg;
        elsif r(3) = '0' then
            w_vec := "011" & s.af;
        elsif r(3) = '1' then
            w_vec := "10" & r(2 downto 1);
        else
            w_vec := "----";
        end if;
        if r(3 downto 1) = "011" then -- flip FA to AF
            hl := not r(0);
        else
            hl := r(0);
        end if;
        return to_integer(unsigned(w_vec & hl));
    end baddr;

    function get_word(reg : integer range 0 to 15;
                      signal ram : rf_ram_t;
                      signal s : rf_swap_state_t)
    return std_logic_vector is
        variable b, w : integer;
    begin
        b := baddr(reg, s);
        w := b - (b mod 2);
        return ram(w) & ram(w + 1);
    end get_word;

    function next_ram(signal ram : rf_ram_t;
                      signal s : rf_swap_state_t;
                      signal reg_addr : integer range 0 to 15;
                      signal rdd, rda, rdf : std_logic;
                      signal data, f : std_logic_vector(7 downto 0);
                      signal addr : std_logic_vector(15 downto 0))
    return rf_ram_t is
        variable new_ram : rf_ram_t;
    begin
        new_ram := ram;
        if rdd = '1' then
            new_ram(baddr(reg_addr, s)) := data;
        elsif rda = '1' then
            new_ram(baddr(reg_addr, s)) := addr(15 downto 8);
            new_ram(baddr(reg_addr, s)) := addr(7 downto 0);
        end if;
        if rdf = '1' then
            new_ram(baddr(regF, s)) := f;
        end if;
        return new_ram;
    end next_ram;

    signal ram, ram_next : rf_ram_t := (others => (others => '0'));
    signal s : rf_swap_state_t := (others => '0');
begin
    swap_proc : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                s <= (others => '0');
            else
                case swp is
                when none => null;
                when reg  => s.reg  <= not s.reg;
                when af   => s.af   <= not s.af;
                when dehl => s.dehl <= not s.dehl;
                when others => null;
                end case;
            end if;
        end if;
    end process;

    ram_proc : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                ram <= (others => (others => '0'));
            else
                ram <= ram_next;
            end if;
        end if;
    end process;

    ram_next <= next_ram(ram, s, reg_addr, rdd, rda, rdf, data, f_in, addr);

    a_out    <= ram(baddr(regA, s));
    f_out    <= ram(baddr(regF, s));
    addr_out_dis <= get_word(reg_addr, ram, s);
    addr_out <= get_word(reg_addr, ram, s)
        when wra  = '1' else (others => 'Z');
    data <= ram(baddr(reg_addr, s)) when wrd  = '1' else (others => 'Z');

    -- output registers for debug
    dbg_regs.BC <= get_word(regBC, ram, s);
    dbg_regs.DE <= get_word(regDE, ram, s);
    dbg_regs.HL <= get_word(regHL, ram, s);
    dbg_regs.AF <= get_word(regAF, ram, s);
    dbg_regs.WZ <= get_word(regWZ, ram, s);
    dbg_regs.SP <= get_word(regSP, ram, s);
    dbg_regs.IX <= get_word(regIX, ram, s);
    dbg_regs.IY <= get_word(regIY, ram, s);
end arch;
