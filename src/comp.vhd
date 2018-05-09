library ieee;
use ieee.std_logic_1164.all;
use work.cmp_comm.all;
use work.z80_comm.all;
use work.ti_comm.all;
use work.util.all;

entity comp is port(
    clk : in std_logic;
-- dbg input
    btns : in std_logic_vector(4 downto 0);
    sw : in std_logic_vector(7 downto 0);
-- keyboard
    ps2_kbd_clk : in std_logic;
    ps2_kbd_data : in std_logic;
-- vga monitor
    vga_red : out std_logic_vector(2 downto 0);
    vga_green : out std_logic_vector(2 downto 0);
    vga_blue : out std_logic_vector(2 downto 1);
    hsync, vsync : out std_logic;
-- memory
    maddr : out std_logic_vector(25 downto 0);
    mdata : inout std_logic_vector(15 downto 0);
    mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
    mlb_c, mub_c : out std_logic;
-- uart
    rx : in std_logic;
-- 7 segment, led
    seg : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0));
end comp;

architecture arch of comp is
    component clkgen generic(div : natural); port(
        clk : in std_logic;
        clk_out : out std_logic);
    end component;

    component clkgen_meta generic(div : natural); port(
        clk : in std_logic;
        clk_in : in std_logic;
        clk_out : out std_logic);
    end component;

    component z80 port(
        clk, ce : in std_logic;
        cbi : in ctrlbus_in;
        cbo : out ctrlbus_out;
        addr : out std_logic_vector(15 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        dbg : out dbg_z80_t);
    end component;

    component ti port(
        clk, rst, ce : in std_logic;
        int : out std_logic;
        cbo : in ctrlbus_out;
        addr_log : in std_logic_vector(15 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        keys_down : in keys_down_t;
        on_key_down : in std_logic;
        x_vga : in std_logic_vector(6 downto 0);
        y_vga : in std_logic_vector(5 downto 0);
        data_vga : out std_logic;
        rd, wr : out std_logic;
        addr_phy : out std_logic_vector(19 downto 0);
        dbg : out dbg_ti_t);
    end component;

    component mem_if port(
        clk, rst : in std_logic;
        rd, wr : in std_logic;
        addr_phy : in std_logic_vector(19 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        maddr : out std_logic_vector(25 downto 0);
        mdata : inout std_logic_vector(15 downto 0);
        mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
        mlb_c, mub_c : out std_logic);
    end component;

    component vga_motor port(
         clk, rst, ce : in std_logic;
         gmem_data : in std_logic;
         gmem_x : out std_logic_vector(6 downto 0);
         gmem_y : out std_logic_vector(5 downto 0);
         mon_data : in std_logic;
         mon_x : out std_logic_vector(8 downto 0);
         mon_y : out std_logic_vector(5 downto 0);
         vgaRed	: out std_logic_vector(2 downto 0);
         vgaGreen : out std_logic_vector(2 downto 0);
         vgaBlue : out std_logic_vector(2 downto 1);
         Hsync : out std_logic;
         Vsync : out std_logic);
    end component;

    component kbd_enc port (
        clk, rst : in std_logic;
        PS2KeyboardCLK : in std_logic;
        PS2KeyboardData	: in std_logic;
        keys_down : out keys_down_t;
        on_key_down : out std_logic;
        scancode_out : out std_logic_vector(7 downto 0);
        keycode_out : out std_logic_vector(7 downto 0));
    end component;

    component memory port(
        clk, rst : in std_logic;
        cbo : in ctrlbus_out;
        addr : in std_logic_vector(15 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0));
    end component;

    component char_rom port(
        clk : in std_logic;
        char : in std_logic_vector(5 downto 0);
        col, row : in std_logic_vector(2 downto 0);
        pixel : out std_logic);
    end component;

    component monitor_vga port(
        clk : in std_logic;
        dbg : in dbg_cmp_t;
        x_vga : in std_logic_vector(8 downto 0);
        y_vga : in std_logic_vector(5 downto 0);
        char : out std_logic_vector(5 downto 0);
        col_index, row_index : out std_logic_vector(2 downto 0);
        char_pixel : in std_logic;
        data_vga : out std_logic);
    end component;

    component board port(
        clk : in std_logic;
        btns : in std_logic_vector(4 downto 0);
        rst, step, boot_ld, boot_done : out std_logic;
        break_addr : out std_logic_vector(15 downto 0);
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    component bootloader port(
        clk, rst : in std_logic;
        ld, done : in std_logic;
        mem_wr : out std_logic;
        mem_data : out std_logic_vector(7 downto 0);
        mem_addr : out std_logic_vector(19 downto 0);
        rx : in std_logic);
    end component;

    -- clocks
    signal clk_1000hz, clk_100khz : std_logic;
    signal clk_ce : std_logic;
    signal clk_var : std_logic;
    signal clk_z80, clk_ti, clk_vga : std_logic;
    signal clk_z80_ce, clk_ti_ce : std_logic;
    signal clk_z80_main, clk_z80_var: std_logic;
    signal clk_ti_main, clk_ti_var : std_logic;

    -- control bus
    signal cbo : ctrlbus_out;
    signal cbi : ctrlbus_in;
    signal int : std_logic;

    -- data bus / addr bus
    signal addr : std_logic_vector(15 downto 0);
    signal addr_phy, addr_bl, addr_ti : std_logic_vector(19 downto 0);
    signal data : std_logic_vector(7 downto 0);
    signal data_z80, data_mem : std_logic_vector(7 downto 0);
    signal data_ti, data_bl : std_logic_vector(7 downto 0);

    -- debug
    type run_mode_t is (normal, step_i, step_m, step_t);
    signal run_mode : run_mode_t;
    signal break : std_logic;
    signal cpu_stop, cpu_ce : std_logic;
    signal sp_s, sp_q, sp_op : std_logic;
    signal dbg : dbg_cmp_t;

    -- board -> ctrl
    signal step, rst, boot_ld, boot_done : std_logic;
    signal break_addr : std_logic_vector(15 downto 0);

    -- ti <-> kbd
    signal keys_down : keys_down_t;
    signal on_key_down : std_logic := '0';

    -- ti <-> vga
    signal gmem_vga_data : std_logic;
    signal vga_gmem_x : std_logic_vector(6 downto 0);
    signal vga_gmem_y : std_logic_vector(5 downto 0);

    -- mon <-> vga
    signal mon_vga_data : std_logic;
    signal vga_mon_x : std_logic_vector(8 downto 0);
    signal vga_mon_y : std_logic_vector(5 downto 0);

    -- mon <-> char rom
    signal mon_crom_row, mon_crom_col : std_logic_vector(2 downto 0);
    signal mon_crom_char : std_logic_vector(5 downto 0);
    signal crom_mon_pixel : std_logic;

    -- ti/bootloader <-> mem controller
    signal mem_wr_bl, mem_wr_ti : std_logic;
    signal mem_data : std_logic_vector(7 downto 0);
    signal mem_rd, mem_wr : std_logic;
begin
    with sw(7 downto 6) select
        clk_var <= clk_1000hz when "01",
                   clk_100khz when "10",
                   '0'        when others;
    with sw(5 downto 4) select
        run_mode <= step_i when "01",
                    step_m when "10",
                    step_t when "11",
                    normal when others;
    break <= sw(0);

    -- generate clocks
    gen_1000hz : clkgen generic map(DIV_1000HZ)
                        port map(clk, clk_1000hz);
    gen_100khz : clkgen generic map(DIV_100KHZ)
                        port map(clk, clk_100khz);
    -- cpu step / break
    step_op : process(clk) begin
        if rising_edge(clk) then
            if clk_z80 = '1' then
                sp_s <= step;
                sp_q <= sp_s;
            end if;
        end if;
    end process;
    sp_op <= sp_s and not sp_q;
    cpu_stop <= not sp_op and 
        (bool_sl(run_mode = step_t) or
        (bool_sl(run_mode = step_m) and dbg.z80.ct.cycle_end) or
        (bool_sl(run_mode = step_i) and dbg.z80.ct.instr_end) or
        (bool_sl(addr = break_addr) and break and mem_rd and cbo.m1));

    gen_z80_main : clkgen generic map(DIV_Z80)
                               port map(clk, clk_z80_main);
    gen_z80_var  : clkgen_meta generic map(DIV_Z80)
                              port map(clk, clk_var, clk_z80_var);
    gen_ti_main : clkgen generic map(DIV_TI)
                         port map(clk, clk_ti_main);
    gen_ti_var : clkgen_meta generic map(DIV_TI)
                             port map(clk, clk_var, clk_ti_var);
    gen_vga : clkgen generic map(DIV_VGA) port map(clk, clk_vga);

    clk_z80 <= clk_z80_main when sw(7 downto 6) = "00" else clk_z80_var;
    clk_ti <= clk_ti_main when sw(7 downto 6) = "00" else clk_ti_var;

    clk_z80_ce <= clk_z80 and not cpu_stop;
    clk_ti_ce <= clk_ti and not cpu_stop;

    -- buses
    cbi.int <= int;
    cbi.reset <= rst;
    -- OR data bus instead of tristate
    data <= data_z80 or data_mem or data_ti;

    cpu : z80 port map(clk, clk_z80_ce, cbi, cbo, addr, data, data_z80,
                       dbg.z80);
    ti_comp : ti port map(clk, rst, clk_ti_ce,
                          int, cbo, addr, data, data_ti,
                          keys_down, on_key_down,
                          vga_gmem_x, vga_gmem_y, gmem_vga_data,
                          mem_rd, mem_wr_ti, addr_ti,
                          dbg.ti);

    -- mem signals (bootloader priority)
    mem_wr <= mem_wr_bl or mem_wr_ti;
    addr_phy <= addr_bl when mem_wr_bl = '1' else addr_ti;
    mem_data <= data_bl when mem_wr_bl = '1' else data;

    -- external controllers
    vga : vga_motor port map(clk, rst, clk_vga,
                             gmem_vga_data, vga_gmem_x, vga_gmem_y,
                             mon_vga_data, vga_mon_x, vga_mon_y,
                             vga_red, vga_green, vga_blue, hsync, vsync);
    mif : mem_if port map(clk, rst,
                          mem_rd, mem_wr, addr_phy, mem_data, data_mem,
                          maddr, mdata, mclk, madv_c, mcre, mce_c, moe_c,
                          mwe_c, mlb_c, mub_c);
    kbd : kbd_enc port map(clk, rst, ps2_kbd_clk, ps2_kbd_data,
                           keys_down, on_key_down, dbg.scancode, dbg.keycode);
    boot : bootloader port map(clk, rst, boot_ld, boot_done,
                               mem_wr_bl, data_bl, addr_bl, rx);

    -- debug
    dbg.mem_rd <= mem_rd;
    dbg.mem_wr <= mem_wr;
    dbg.mem_wr_bl <= mem_wr_bl;
    dbg.keys_down <= keys_down;
    dbg.on_key_down <= on_key_down;
    dbg.data <= data;
    dbg.data_mem <= data_mem;
    dbg.addr_log <= addr;
    dbg.data_mem <= data_mem;
    dbg.addr_phy <= addr_phy;
    dbg.cbi <= cbi;
    dbg.cbo <= cbo;

    crom : char_rom port map(clk, mon_crom_char, mon_crom_col, mon_crom_row,
                             crom_mon_pixel);
    mon_vga : monitor_vga port map(clk, dbg, vga_mon_x, vga_mon_y,
                                   mon_crom_char, mon_crom_col, mon_crom_row,
                                   crom_mon_pixel,
                                   mon_vga_data);
    brd : board port map(clk, btns, rst, step, boot_ld, boot_done,
                         break_addr,
                         seg, an);
end arch;
