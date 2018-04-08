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
    addr_out, addr_dis : out std_logic_vector(15 downto 0);
    a_out, f_out : out std_logic_vector(7 downto 0));
end regfile;

architecture arch of regfile is
    type rf_ram_t is array(0 to 11) of std_logic_vector(15 downto 0);

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

    function next_ram(signal ram : rf_ram_t;
                      signal w, wAF : integer;
                      signal hl : std_logic;
                      signal rdd, rda, rdf : std_logic;
                      signal data, f : std_logic_vector(7 downto 0);
                      signal addr : std_logic_vector(15 downto 0))
    return rf_ram_t is
        variable new_ram : rf_ram_t;
        variable new_word : std_logic_vector(15 downto 0);
    begin
        new_ram := ram;

        new_word := ram(w);
        if rdd = '1' and hl = '0' then
            new_word(15 downto 8) := data;
        elsif rdd = '1' and hl = '1' then
            new_word(7  downto 0) := data;
        elsif rda = '1' then
            new_word := addr;
        end if;
        new_ram(w) := new_word;

        if rdf = '1' then
            new_ram(wAF)(7 downto 0) := f;
        end if;

        return new_ram;
    end next_ram;

    signal ram : rf_ram_t := (others=> (others => '0'));
    signal swp_reg, swp_af, swp_dehl : std_logic := '0';
    signal ram_next : rf_ram_t;
    signal r, w_vec : std_logic_vector(3 downto 0) := "0000";
    signal w, wAF : integer := 0; -- address to word in ram
    signal hl : std_logic;
begin
    swap_proc : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                swp_reg <= '0';
                swp_af <= '0';
                swp_dehl <= '0';
            else
                case swp is
                when none => null;
                when reg  => swp_reg  <= not swp_reg;
                when af   => swp_af   <= not swp_af;
                when dehl => swp_dehl <= not swp_dehl;
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

    r <= std_logic_vector(to_unsigned(reg_addr, 4))
         when reg_addr >= 0 else "0000"; -- int initializes to -229847923947
    w_vec <= 
        '0' & r(1) & r(2) & swp_reg when
            r(3) = '0' and r(2 downto 1) /= "11" and swp_dehl = '1' else
        r(3 downto 1) & swp_reg when
            r(3) = '0' and r(2 downto 1) /= "11" else
        "011" & swp_af
            when r(3) = '0' else
        "10" & r(2 downto 1)
            when r(3) = '1' else
        "----";
    w <= to_integer(unsigned(w_vec));
    wAF <= 7 when swp_af = '1' else 6;

    hl <= not r(0) when r(3 downto 1) = "011" else r(0); -- flip FA to AF

    ram_next <= next_ram(ram, w, wAF, hl, rdd, rda, rdf, data, f_in, addr);

    a_out    <= get_byte(wAF, '0', ram);
    f_out    <= get_byte(wAF, '1', ram);
    addr_dis <= ram(w);
    addr_out <= ram(w)               when wra  = '1' else (others => 'Z');
    data     <= get_byte(w, hl, ram) when wrd  = '1' else (others => 'Z');

    warnings : process(clk) begin
        assert reg_addr /= 6 report "ACCESSING '110' ADDRESS";
    end process;
end arch;
