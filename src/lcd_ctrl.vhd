library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cmp_comm.all;

entity lcd_ctrl is port(
    clk : in std_logic;
    gmem_data_in : in std_logic_vector(7 downto 0);
    gmem_data_out : out std_logic_vector(7 downto 0);
    gmem_addr : out std_logic_vector(9 downto 0);
    gmem_rd, gmem_rst : out std_logic;
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
begin
    data_out <= gmem_data_in;
    gmem_data_out <= data_in;
    gmem_addr <= std_logic_vector(to_unsigned((x*64+y)/8, gmem_addr'length));

    modify_ptr : process(clk) begin
        if rising_edge(clk) then
            if data_rd = '1' or data_wr = '1' then
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
