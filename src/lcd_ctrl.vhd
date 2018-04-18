library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cmp_comm.all;

entity lcd_ctrl is port(
    clk, rst : in std_logic;
    gmem_data_in : in std_logic_vector(7 downto 0);
    gmem_data_out : out std_logic_vector(7 downto 0);
    gmem_addr : out std_logic_vector(12 downto 0);
    gmem_rst, gmem_rd, gmem_wl : out std_logic;
    status_rd, data_rd : in std_logic;
    status_wr, data_wr : in std_logic;
    status_in, data_in : in std_logic_vector(7 downto 0);
    status_out, data_out : out std_logic_vector(7 downto 0));
end lcd_ctrl;

architecture arch of lcd_ctrl is
    signal up : std_logic; -- increment on read/write when set
    signal xy : std_logic; -- 0=inc x, 1=inc y
    signal x : integer range 0 to 63;
    signal y : integer range 0 to 95;
    signal word_length : std_logic;
begin
    data_out <= gmem_data_in;
    gmem_data_out <= data_in;
    gmem_addr <= std_logic_vector(to_unsigned(x*64+y, gmem_addr'length));
    gmem_rd <= '1' when data_wr = '1' else '0';
    gmem_rst <= rst;

    modify_wl : process(clk) begin
        if rising_edge(clk) then
            if data_wr = '1' then
                if status_in = x"00" then
                    word_length <= '0';
                end if;
                if status_in = x"01" then
                    word_length <= '1';
                end if;
            end if;
        end if;
    end process;

    modify_ptr : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                x <= 0;
                y <= 0;
            elsif data_rd = '1' or data_wr = '1' then
                if xy = '1' then
                    if up = '1' then
                        if y /= 95 then y <= y + 1;
                        else            y <= 0;
                        end if;
                    else
                        if y /= 0  then y <= y - 1;
                        else            y <= 95;
                        end if;
                    end if;
                else
                    if up = '1' then
                        if x /= 63 then x <= x + 1;
                        else            x <= 0;
                        end if;
                    else
                        if x /= 0  then x <= x - 1;
                        else            x <= 63;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end arch;
