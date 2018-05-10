library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ti_comm.all;
use work.util.all;

entity int_ctrl is port(
    clk, rst, ce : in std_logic;
    activate : in std_logic;
    enable : in std_logic;
    ack : in std_logic;
    fire : out std_logic); 
end int_ctrl;
    
architecture arch of int_ctrl is
    signal active : std_logic;
begin
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                active <= '0';
            elsif ce = '1' then
                if active = '1' then
                    if enable = '1' and activate = '1' then
                        active <= '1';
                    end if;
                else
                    if ack = '1' or enable = '0' then
                        active <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    fire <= active;
end arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ti_comm.all;
use work.util.all;

entity interrupt is port(
    clk, rst, ce : in std_logic;
-- ports
    p02_status_o : in port_out_t;
    p03_intmask_o : in port_out_t;
    p04_mmap_int_o : in port_out_t;
    p04_mmap_int_i : out port_in_t;
-- interrupt sources
    hwt_fin : in std_logic_vector(1 to 2);
    on_key_down : in std_logic;
-- cpu comm
    int : out std_logic);
end interrupt;

architecture arch of interrupt is
    component int_ctrl port(
        clk, rst, ce : in std_logic;
        activate : in std_logic;
        enable : in std_logic;
        ack : in std_logic;
        fire : out std_logic);
    end component;

    type int_t is record
        on_key : std_logic;
        hwt1 : std_logic;
        hwt2 : std_logic;
    end record;

    signal activate : int_t;
    signal enable : int_t;
    signal ack : int_t;
    signal fire : int_t;
begin
    -- interrupt activate
    activate.on_key <= not on_key_down;
    activate.hwt1 <= hwt_fin(1);
    activate.hwt1 <= hwt_fin(2);

    -- interrupt enable
    enable.on_key <= p03_intmask_o.data(PO03_ON_KEY_INT);
    enable.hwt1   <= p03_intmask_o.data(PO03_HWT1_INT);
    enable.hwt2   <= p03_intmask_o.data(PO03_HWT2_INT);

    -- interrupt acknowledge
    ack.on_key <= p02_status_o.wr and not p02_status_o.data(PO02_ON_KEY_ACK);
    ack.hwt1   <= p02_status_o.wr and not p02_status_o.data(PO02_HWT1_ACK);
    ack.hwt2   <= p02_status_o.wr and not p02_status_o.data(PO02_HWT2_ACK);

    -- controllers
    on_key_c : int_ctrl port map(clk, rst, ce,
                                 activate.on_key,
                                 enable.on_key,
                                 ack.on_key,
                                 fire.on_key);
    hwt1_c : int_ctrl port map(clk, rst, ce,
                                 activate.hwt1,
                                 enable.hwt1,
                                 ack.hwt1,
                                 fire.hwt1);
    hwt2_c : int_ctrl port map(clk, rst, ce,
                               activate.hwt2,
                               enable.hwt2,
                               ack.hwt2,
                               fire.hwt2);
                                 
    -- interrupt fire
    int <= fire.on_key or fire.hwt1 or fire.hwt2;

    -- port output
    p04_mmap_int_i.data <= (
        PI04_ON_KEY_INT  => fire.on_key,
        PI04_HWT1_INT    => fire.hwt1,
        PI04_HWT2_INT    => fire.hwt2,
        PI04_LINK_INT    => '0',
        PI04_ON_KEY_DOWN => on_key_down,
        others => '0');
end arch;
