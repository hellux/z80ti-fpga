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
-- 24 11000  |___I___|___R___|  11001 25
-- 26 11010  |__PCh__|__PCl__|  11011 27

entity regfile is port(
    -- ctrl
    clk, rst, ce : in std_logic;
    reg_addr : in std_logic_vector(4 downto 0);
    rp_addr : in std_logic_vector(3 downto 0);
    rdd : in std_logic; -- read from data_in to selected reg
    rda : in std_logic; -- read from addr_in to selected rp
    rdf : in std_logic; -- read from f_in bus to F
    ldpc : in std_logic; -- load pc with selected rp
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
    -- addr of internal 16 byte regs
    constant rpBC : std_logic_vector(3 downto 0) := "0000";
    constant rpDE : std_logic_vector(3 downto 0) := "0010";
    constant rpHL : std_logic_vector(3 downto 0) := "0100";
    constant rpAF : std_logic_vector(3 downto 0) := "0110";
    constant rpWZ : std_logic_vector(3 downto 0) := "1000";
    constant rpSP : std_logic_vector(3 downto 0) := "1001";
    constant rpIX : std_logic_vector(3 downto 0) := "1010";
    constant rpIY : std_logic_vector(3 downto 0) := "1011";
    constant rpIR : std_logic_vector(3 downto 0) := "1100";
    constant rpPC : std_logic_vector(3 downto 0) := "1101";

    type rf_ram_t is array(0 to 27) of std_logic_vector(7 downto 0);
    type rf_swap_state_t is record
        reg, af : std_logic;
        dehl : std_logic_vector(1 downto 0);
        afwz : std_logic;
    end record;

    function baddr(reg : std_logic_vector(4 downto 0);
                   s : rf_swap_state_t)
    return integer is
        variable reg_i : integer range 0 to 1;
        variable rp : std_logic_vector(3 downto 0);
    begin
        if s.reg = '1' then reg_i := 1; else reg_i := 0; end if;

        case reg is
        when regB|regC => rp := rpBC(3 downto 2) & s.reg & rpBC(0);
        when regD|regE =>
            if s.dehl(reg_i) = '1'
            then rp := rpHL(3 downto 1) & s.reg;
            else rp := rpDE(3 downto 1) & s.reg;
            end if;
        when regH|regL =>
            if s.dehl(reg_i) = '1'
            then rp := rpDE(3 downto 1) & s.reg;
            else rp := rpHL(3 downto 1) & s.reg;
            end if;
        when regA|regF =>
            if s.afwz = '1'
            then rp := rpWZ;
            else rp := rpAF(3 downto 1) & s.af;
            end if;
        when regW|regZ =>
            if s.afwz = '1'
            then rp := rpAF(3 downto 1) & s.af;
            else rp := rpWZ;
            end if;
        when regSPh|regSPl => rp := rpSP;
        when regIXh|regIXl => rp := rpIX;
        when regIYh|regIYl => rp := rpIY;
        when regI|regR => rp := rpIR;
        when regPCh|regPCl => rp := rpPC;
        when others => rp := (others => '-');
        end case;

        return to_integer(unsigned(rp & reg(0)));
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
                      signal rdd, rda, rdf, ldpc : in std_logic;
                      signal data_in, f_in : in std_logic_vector(7 downto 0);
                      signal addr_in : in std_logic_vector(15 downto 0))
    return rf_ram_t is
        variable new_ram : rf_ram_t;
    begin
        new_ram := ram;
        if rdd = '1' then
            new_ram(baddr(reg_addr, s)) := data_in;
        end if;
        if rda = '1' then
            new_ram(baddr(rp_addr & '0', s)) := addr_in(15 downto 8);
            new_ram(baddr(rp_addr & '1', s)) := addr_in(7 downto 0);
        end if;
        if rdf = '1' then
            new_ram(baddr(regF, s)) := f_in;
        end if;
        if ldpc = '1' then
            new_ram(baddr(regPCh, s)) := ram(baddr(rp_addr & '0', s));
            new_ram(baddr(regPCl, s)) := ram(baddr(rp_addr & '1', s));
        end if;
        return new_ram;
    end next_ram;

    constant RF_RAM_INIT : rf_ram_t := (26 => x"80", 27 => x"00",
                                        others => x"ff");
    constant RF_SWAP_INIT : rf_swap_state_t := ('0', '0', "00", '0');
    signal ram, ram_next : rf_ram_t := RF_RAM_INIT;
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
                when afwz => s.afwz        <= not s.afwz;
                when others => null;
                end case;
            end if;
        end if;
    end process;

    ram_proc : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                ram <= RF_RAM_INIT;
            elsif ce = '1' then
                ram <= ram_next;
            end if;
        end if;
    end process;

    ram_next <= next_ram(ram, s,
                         reg_addr, rp_addr, rdd, rda, rdf, ldpc,
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
    dbg_regs.IR <= get_word(regIR, ram, s);
    dbg_regs.PC <= get_word(regPC, ram, s);
end arch;
