library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

-- INTERNAL RAM LAYOUT
-- addr        high    low       addr
--           _______________  
-- 00000    |___B___|___C___|    00001
-- 00010    |___B___|___C___|    00011
-- 00100    |___D___|___E___|    00101
-- 00110    |___D___|___E___|    00111
-- 01000    |___H___|___L___|    01001
-- 01010    |___H___|___L___|    01011
-- 01100    |___A___|___F___|    01101
-- 01110    |___A___|___F___|    01111
-- 10000    |___W___|___Z___|    10001
-- 10010    |______SP_______|    10011
-- 10100    |______IX_______|    10011
-- 10110    |______IY_______|    10111

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
    a_out, f_out : out std_logic_vector(7 downto 0));
end regfile;

architecture arch of regfile is
    type rf_ram_t is array(0 to 22) of std_logic_vector(7 downto 0);
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

    signal ram : rf_ram_t := (others => (others => '0'));
    signal s : rf_swap_state_t := (others => '0');
    signal addr_out_tmp : std_logic_vector(15 downto 0);
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
            if rdd = '1' then
                ram(baddr(reg_addr, s)) <= data;
            elsif rda = '1' then
                ram(baddr(reg_addr, s)) <= addr(15 downto 8);
                ram(baddr(reg_addr, s)) <= addr(7 downto 0);
            end if;
            if rdf = '1' then
                ram(baddr(regF, s)) <= f_in;
            end if;
            if rst = '1' then
                ram <= (others => (others => '0'));
            end if;
        end if;
    end process;

    a_out    <= ram(baddr(regA, s));
    f_out    <= ram(baddr(regF, s));
    addr_out_tmp <= ram(baddr(reg_addr, s)) & ram(baddr(reg_addr+1, s));
    addr_out_dis <= addr_out_tmp;
    addr_out <= addr_out_tmp            when wra  = '1' else (others => 'Z');
    data     <= ram(baddr(reg_addr, s)) when wrd  = '1' else (others => 'Z');
end arch;
