library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

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
-- 18 10010  |__SPh__|__SPh__|  10011 19
-- 20 10100  |__IXh__|__IXl__|  10011 21
-- 22 10110  |__IYh__|__IYl__|  10111 23
-- TODO below
-- 24 11000  |___I___|___R___|  11001 25
-- 26 11010  |__PCh__|__PCl__|  11011 27

entity regfile is port(
    -- ctrl
    clk, rst, ce : in std_logic;
    reg_addr : in std_logic_vector(4 downto 0);
    rp_addr : in std_logic_vector(3 downto 0);
    rdd, rda, rdf : in std_logic;
    swp : in rf_swap_t;
    -- buses
    data_in: in std_logic_vector(7 downto 0);
    addr_in : in std_logic_vector(15 downto 0);
    f_in : in std_logic_vector(7 downto 0);
    data_out: out std_logic_vector(7 downto 0);
    addr_out, addr_out_dis : out std_logic_vector(15 downto 0);
    a_out, f_out : out std_logic_vector(7 downto 0);
    -- debug
    dbg_regs : out dbg_regs_t);
end regfile;

architecture arch of regfile is
    -- addr of internal registers
    constant B0  : integer := 0;
    constant C0  : integer := 1;
    constant B1  : integer := 2;
    constant C1  : integer := 3;
    constant D0  : integer := 4;
    constant E0  : integer := 5;
    constant D1  : integer := 6;
    constant E1  : integer := 7;
    constant H0  : integer := 8;
    constant L0  : integer := 9;
    constant H1  : integer := 10;
    constant L1  : integer := 11;
    constant A0  : integer := 12;
    constant F0  : integer := 13;
    constant A1  : integer := 14;
    constant F1  : integer := 15;
    constant W   : integer := 16;
    constant Z   : integer := 17;
    constant SPh : integer := 18;
    constant SPl : integer := 19;
    constant IXh : integer := 20;
    constant IXl : integer := 21;
    constant IYh : integer := 22;
    constant IYl : integer := 23;
    constant I   : integer := 24;
    constant R   : integer := 25;
    constant PCh : integer := 26;
    constant PCl : integer := 27;

    type rf_ram_t is array(0 to 23) of std_logic_vector(7 downto 0);
    type rf_swap_state_t is record
        reg, af : std_logic;
        dehl : std_logic_vector(1 downto 0);
        fz : std_logic;
    end record;

    function baddr(r : std_logic_vector(4 downto 0);
                   s : rf_swap_state_t)
    return integer is
        variable reg_i : integer range 0 to 1;
        variable rp : std_logic_vector(3 downto 0);
    begin
        if s.reg = '1' then reg_i := 1; else reg_i := 0; end if;

        -- select word
        if s.fz = '1' and r = regF then -- f -> z
            rp := "1000";
        elsif s.fz = '1' and r = regZ then -- z -> f
            rp := "011" & s.reg;
        elsif r(3) = '0' and r(2 downto 1) /= "11" and s.dehl(reg_i) = '1' then
            rp := '0' & r(1) & r(2) & s.reg;
        elsif r(3) = '0' and r(2 downto 1) /= "11" then
            rp := r(3 downto 1) & s.reg;
        elsif r(3) = '0' then
            rp := "011" & s.af;
        elsif r(3) = '1' then
            rp := "10" & r(2 downto 1);
        else
            rp := "----";
        end if;
        return to_integer(unsigned(rp & r(0)));
    end baddr;

    function get_word(reg : std_logic_vector(3 downto 0);
                      signal ram : rf_ram_t;
                      signal s : rf_swap_state_t)
    return std_logic_vector is
        variable bh, bl : std_logic_vector(4 downto 0);
    begin
        bh := reg & '0';
        bl := reg & '1';
        return ram(baddr(bh, s)) & ram(baddr(bl, s));
    end get_word;

    function next_ram(signal ram : in rf_ram_t;
                      signal s : in rf_swap_state_t;
                      signal reg_addr : std_logic_vector(4 downto 0);
                      signal rp_addr : std_logic_vector(3 downto 0);
                      signal rdd, rda, rdf : in std_logic;
                      signal data, f : in std_logic_vector(7 downto 0);
                      signal addr : in std_logic_vector(15 downto 0))
    return rf_ram_t is
        variable new_ram : rf_ram_t;
    begin
        new_ram := ram;
        if rdd = '1' then
            new_ram(baddr(reg_addr, s)) := data;
        elsif rda = '1' then
            new_ram(baddr(rp_addr & '0', s)) := addr(15 downto 8);
            new_ram(baddr(rp_addr & '1', s)) := addr(7 downto 0);
        end if;
        if rdf = '1' then
            new_ram(baddr(regF, s)) := f;
        end if;
        return new_ram;
    end next_ram;

    constant RF_SWAP_INIT : rf_swap_state_t := ('0', '0', "00", '0');
    signal ram, ram_next : rf_ram_t := (others => x"ff");
    signal s : rf_swap_state_t := RF_SWAP_INIT;
begin
    swap_proc : process(clk)
        variable reg_i : integer range 0 to 1;
    begin
        if rising_edge(clk) then
            if s.reg = '1' then reg_i := 1; else reg_i := 0; end if;
            if rst = '1' then
                s <= RF_SWAP_INIT;
            elsif ce = '1' then
                case swp is
                when none => null;
                when reg  => s.reg         <= not s.reg;
                when af   => s.af          <= not s.af;
                when dehl => s.dehl(reg_i) <= not s.dehl(reg_i);
                when fz   => s.fz          <= not s.fz;
                when others => null;
                end case;
            end if;
        end if;
    end process;

    ram_proc : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                ram <= (others => x"ff");
            elsif ce = '1' then
                ram <= ram_next;
            end if;
        end if;
    end process;

    ram_next <= next_ram(ram, s,
                         reg_addr, rp_addr, rdd, rda, rdf,
                         data_in, f_in, addr_in);

    a_out    <= ram(baddr(regA, s));
    f_out    <= ram(baddr(regF, s));
    addr_out_dis <= get_word(rp_addr, ram, s);
    addr_out <= get_word(rp_addr, ram, s);
    data_out <= ram(baddr(reg_addr, s));

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
