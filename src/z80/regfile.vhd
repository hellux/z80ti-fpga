library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;

-- INTERNAL RAM LAYOUT
-- addr_int    high    low
--           _______________  
-- 0000     |___B___|___C___| 
-- 0001     |___B___|___C___|
-- 0010     |___D___|___E___|
-- 0011     |___D___|___E___|
-- 0100     |___H___|___L___|
-- 0101     |___H___|___L___|
-- 0110     |___A___|___F___|
-- 0111     |___A___|___F___|
-- 1000     |___W___|___Z___|
-- 1001     |______SP_______|
-- 1010     |______IX_______|
-- 1011     |______IY_______|

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
    type rf_ram_t is array(0 to 11) of std_logic_vector(15 downto 0);
    type rf_context_t is record
        ram : rf_ram_t;
        swp_reg, swp_dehl, swp_af : std_logic;
    end record;
        
    -- get address to word from external reg addr (depends on swap state)
    function waddr(reg_addr : integer; c : rf_context_t)
    return integer
    is
        variable r, w_vec : std_logic_vector(3 downto 0);
    begin
        r := std_logic_vector(to_unsigned(reg_addr, 4));
        if r(3) = '0' and r(2 downto 1) /= "11" and c.swp_dehl = '1' then
            w_vec := '0' & r(1) & r(2) & c.swp_reg;
        elsif r(3) = '0' and r(2 downto 1) /= "11" then
            w_vec := r(3 downto 1) & c.swp_reg;
        elsif r(3) = '0' then
            w_vec := "011" & c.swp_af;
        elsif r(3) = '1' then
            w_vec := "10" & r(2 downto 1);
        else
            w_vec := "----";
        end if;
        return to_integer(unsigned(w_vec));
    end waddr;

    -- get byte at word w
    function get_byte(w : integer;      -- address to 16bit word where byte is
                      hl : std_logic;   -- hl = 0 => get higher byte
                      ram : rf_ram_t)   -- ram array
    return std_logic_vector is
        variable word : std_logic_vector(15 downto 0);
    begin
        word := ram(w);
        if hl = '0' then return word(15 downto 8);
        else             return word(7 downto 0);
        end if;
    end get_byte;

    function next_ram(signal c : rf_context_t;
                      signal reg_addr : integer;
                      signal hl : std_logic;
                      signal rdd, rda, rdf : std_logic;
                      signal data, f : std_logic_vector(7 downto 0);
                      signal addr : std_logic_vector(15 downto 0))
    return rf_ram_t is
        variable new_ram : rf_ram_t;
        variable new_word : std_logic_vector(15 downto 0);
    begin
        new_ram := c.ram;

        new_word := new_ram(waddr(reg_addr, c));
        if rdd = '1' and hl = '0' then
            new_word(15 downto 8) := data;
        elsif rdd = '1' and hl = '1' then
            new_word(7  downto 0) := data;
        elsif rda = '1' then
            new_word := addr;
        end if;
        new_ram(waddr(reg_addr, c)) := new_word;

        if rdf = '1' then
            new_ram(waddr(regAF, c))(7 downto 0) := f;
        end if;

        return new_ram;
    end next_ram;

    signal c : rf_context_t :=
        (ram => (others => (others => '0')), others => '0');
    signal ram_next : rf_ram_t;
    signal r : std_logic_vector(3 downto 0) := "0000";
    signal hl : std_logic;
begin
    swap_proc : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                c.swp_reg <= '0';
                c.swp_af <= '0';
                c.swp_dehl <= '0';
            else
                case swp is
                when none => null;
                when reg  => c.swp_reg  <= not c.swp_reg;
                when af   => c.swp_af   <= not c.swp_af;
                when dehl => c.swp_dehl <= not c.swp_dehl;
                when others => null;
                end case;
            end if;
        end if;
    end process;

    ram_proc : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                c.ram <= (others => (others => '0'));
            else 
                c.ram <= ram_next;
            end if;
        end if;
    end process;

    hl <= not r(0) when r(3 downto 1) = "011" else r(0); -- flip FA to AF
    ram_next <= next_ram(c, reg_addr, hl, rdd, rda, rdf, data, f_in, addr);

    a_out    <= get_byte(waddr(regAF, c), '0', c.ram);
    f_out    <= get_byte(waddr(regAF, c), '1', c.ram);
    addr_out_dis <= c.ram(waddr(reg_addr, c));
    addr_out <= c.ram(waddr(reg_addr, c)) when wra = '1' else (others => 'Z');
    data <= get_byte(waddr(reg_addr, c), hl, c.ram)
            when wrd  = '1' else (others => 'Z');

    -- store current registers in debug record
--    dbg_regs.AF <= c.ram(waddr(regAF, c));
 --   dbg_regs.BC <= c.ram(waddr(regBC, c));
  --  dbg_regs.DE <= c.ram(waddr(regDE, c));
   -- dbg_regs.HL <= c.ram(waddr(regHL, c));
    --dbg_regs.WZ <= c.ram(waddr(regWZ, c));
    --dbg_regs.SP <= c.ram(waddr(regSP, c));
    --dbg_regs.IX <= c.ram(waddr(regIX, c));
    --dbg_regs.IY <= c.ram(waddr(regIY, c));
end arch;
