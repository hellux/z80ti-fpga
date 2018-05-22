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
-- 7 segment, led
    seg : out std_logic_vector(7 downto 0);
    an : out std_logic_vector(3 downto 0));
end comp;

architecture arch of comp is
    component clkgen generic(div : natural); port(
        clk : in std_logic;
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
        rd, wr : in std_logic;
        mode : in std_logic;
        addr : in std_logic_vector(23 downto 0);
        data_in : in std_logic_vector(15 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        maddr : out std_logic_vector(25 downto 0);
        mdata : inout std_logic_vector(15 downto 0);
        mclk, madv_c, mcre, mce_c, moe_c, mwe_c : out std_logic;
        mlb_c, mub_c : out std_logic);
    end component;

    component vga_motor port(
         clk, ce : in std_logic;
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
        on_key_down : out std_logic);
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
        num_disp : in std_logic_vector(15 downto 0);
        rst, step, trc_en, trc_di : out std_logic;
        num_sel : out std_logic_vector(15 downto 0);
        num_new : out std_logic;
        seg : out std_logic_vector(7 downto 0);
        an : out std_logic_vector(3 downto 0));
    end component;

    component dcntr generic(init : std_logic_vector;
                            bitwidth : integer); port(
        clk, rst, ce : in std_logic;
        cnten : in std_logic;
        ld : in std_logic;
        di : in std_logic_vector(bitwidth-1 downto 0);
        do : out std_logic_vector(bitwidth-1 downto 0));
    end component;

    component trace port(
        clk, rst, ce : in std_logic;
        enable, disable : in std_logic;
        jump_beg, jump_end : in std_logic;
        pc : in std_logic_vector(15 downto 0);
        cpu_block : out std_logic;
        wr : out std_logic;
        addr : out std_logic_vector(23 downto 0);
        data : out std_logic_vector(15 downto 0);
        dbg : out dbg_trace_t);
    end component;

    -- cpu bus
    signal addr : std_logic_vector(15 downto 0);
    signal addr_phy, addr_bl, addr_ti : std_logic_vector(19 downto 0);
    signal data : std_logic_vector(7 downto 0);
    signal data_z80, data_mem : std_logic_vector(7 downto 0);
    signal data_ti, data_bl : std_logic_vector(7 downto 0);
    signal cpu_rd, cpu_wr : std_logic;
    signal cbo : ctrlbus_out;
    signal cbi : ctrlbus_in;
    signal int : std_logic;

    -- switches / btns
    type run_mode_t is (normal, step_i, step_m, step_t);
    type break_sel_t is (br_wr, br_ic, br_ex, br_no);
    signal stop : std_logic;
    signal cpu_freq : std_logic_vector(1 downto 0);
    signal run_mode : run_mode_t;
    signal disable_int : std_logic;
    signal break_sel : break_sel_t;
    signal step, rst, trc_en, trc_di : std_logic;

    -- break / instruction count number
    signal num_sel, num_curr : std_logic_vector(15 downto 0);
    signal num_new, num_ce, num_ld : std_logic;

    -- clocks / enables
    signal clk_6mhz, clk_25mhz, clk_50mhz : std_logic;
    signal clk_10khz, clk_1mhz, clk_14mhz : std_logic;
    signal clk_z80, clk_ti, clk_vga : std_logic;
    signal clk_z80_ce, clk_ti_ce : std_logic;
    signal clk_z80_cpu_ce : std_logic;
    signal cpu_stop, cpu_block : std_logic;
    signal sp_s, sp_q, sp_op : std_logic;

    -- mem input ctrl
    signal mem_rd, mem_wr, mem_mode : std_logic;
    signal mem_addr : std_logic_vector(23 downto 0);
    signal mem_data : std_logic_vector(15 downto 0);

    -- kbd -> ti
    signal keys_down : keys_down_t;
    signal on_key_down : std_logic := '0';

    -- ti <-> vga
    signal gmem_vga_data : std_logic;
    signal vga_gmem_x : std_logic_vector(6 downto 0);
    signal vga_gmem_y : std_logic_vector(5 downto 0);

    -- trc -> mem if
    signal trc_wr : std_logic;
    signal trc_addr : std_logic_vector(23 downto 0);
    signal trc_data : std_logic_vector(15 downto 0);

    -- components -> mon
    signal dbg : dbg_cmp_t;

    -- mon <-> vga
    signal mon_vga_data : std_logic;
    signal vga_mon_x : std_logic_vector(8 downto 0);
    signal vga_mon_y : std_logic_vector(5 downto 0);

    -- mon <-> char rom
    signal mon_crom_row, mon_crom_col : std_logic_vector(2 downto 0);
    signal mon_crom_char : std_logic_vector(5 downto 0);
    signal crom_mon_pixel : std_logic;
begin
    -- generate clocks
    gen_10khz : clkgen generic map(DIV_10KHZ) port map(clk, clk_10khz);
    gen_1mhz  : clkgen generic map(DIV_1MHZ)  port map(clk, clk_1mhz);
    gen_6mhz  : clkgen generic map(DIV_6MHZ)  port map(clk, clk_6mhz);
    gen_14mhz : clkgen generic map(DIV_14MHZ) port map(clk, clk_14mhz);
    gen_25mhz : clkgen generic map(DIV_25MHZ) port map(clk, clk_25mhz);

    -- map clocks
    with cpu_freq select
        clk_z80 <= clk_6mhz  when "00",
                   clk_14mhz when "01",
                   clk_1mhz  when "10",
                   clk_10khz when others;
    clk_ti <= clk_14mhz;
    clk_vga <= clk_25mhz;

    -- buses
    cbi.int <= int and not disable_int;
    cbi.reset <= rst;
    data <= data_z80 or data_mem or data_ti;
    
    -- memory input ctrl
    mem_rd <= cpu_rd;
    mem_wr <= cpu_wr or trc_wr;
    mem_addr <= trc_addr when trc_wr = '1' else x"0" & addr_phy;
    mem_data <= trc_data when trc_wr = '1' else data & data;
    mem_mode <= not trc_wr;

    -- components
    cpu : z80 port map(clk, clk_z80_cpu_ce, cbi, cbo, addr, data, data_z80,
                       dbg.z80);
    ti_comp : ti port map(clk, rst, clk_ti_ce,
                          int, cbo, addr, data, data_ti,
                          keys_down, on_key_down,
                          vga_gmem_x, vga_gmem_y, gmem_vga_data,
                          cpu_rd, cpu_wr, addr_phy,
                          dbg.ti);
    -- external controllers
    vga : vga_motor port map(clk, clk_vga,
                             gmem_vga_data, vga_gmem_x, vga_gmem_y,
                             mon_vga_data, vga_mon_x, vga_mon_y,
                             vga_red, vga_green, vga_blue, hsync, vsync);
    mif : mem_if port map(mem_rd, mem_wr, mem_mode,
                          mem_addr, mem_data, data_mem,
                          maddr, mdata, mclk, madv_c, mcre, mce_c, moe_c,
                          mwe_c, mlb_c, mub_c);
    kbd : kbd_enc port map(clk, rst, ps2_kbd_clk, ps2_kbd_data,
                           keys_down, on_key_down);

    --- DEBUG ---
    dbg.data <= data;
    dbg.addr_log <= addr;
    dbg.addr_phy <= addr_phy;
    dbg.trc_ptr <= std_logic_vector(trc_addr);
    dbg.cbi <= cbi;
    dbg.cbo <= cbo;

    -- switch control
    stop <= sw(7);
    cpu_freq <= sw(6 downto 5);
    with sw(4 downto 3) select
        run_mode <= step_m when "01",
                    step_i when "10",
                    step_t when "11",
                    normal when others;
    disable_int <= sw(2);
    with sw(1 downto 0) select
        break_sel <= br_wr when "11",
                     br_ic when "10",
                     br_ex when "01",
                     br_no when others;

    -- step / break
    step_op : process(clk) begin
        if rising_edge(clk) then
            if clk_z80 = '1' then
                sp_s <= step;
                sp_q <= sp_s;
            end if;
        end if;
    end process;
    sp_op <= sp_s and not sp_q;
    cpu_stop <= stop or (not sp_op and 
        (bool_sl(run_mode = step_t) or
        (bool_sl(run_mode = step_m) and dbg.z80.cycle_start) or
        (bool_sl(run_mode = step_i) and dbg.z80.instr_start) or
        (bool_sl(break_sel = br_ic) and bool_sl(num_curr = x"0000")) or
        (bool_sl(addr = num_sel) and
       ((bool_sl(break_sel = br_wr) and cpu_wr) or
        (bool_sl(break_sel = br_ex) and cpu_rd and cbo.m1)))));
    -- chip enables
    clk_z80_ce <= clk_z80 and not cpu_stop;
    clk_z80_cpu_ce <= clk_z80_ce and not cpu_block;
    clk_ti_ce <= clk_ti and not cpu_stop;

    num_ce <= bool_sl(break_sel = br_ic) and
              dbg.z80.instr_start and
              clk_z80_ce;
    num_ld <= num_new or sp_op;
    num_sel_cntr : dcntr generic map(x"9d95", 16)
                         port map(clk, '0', clk_z80, num_ce,
                                  num_ld, num_sel, num_curr);
    crom : char_rom port map(clk, mon_crom_char, mon_crom_col, mon_crom_row,
                             crom_mon_pixel);
    mon_vga : monitor_vga port map(clk, dbg, vga_mon_x, vga_mon_y,
                                   mon_crom_char, mon_crom_col, mon_crom_row,
                                   crom_mon_pixel,
                                   mon_vga_data);
    brd : board port map(clk,
                         btns, num_curr,
                         rst, step, trc_en, trc_di,
                         num_sel, num_new,
                         seg, an);
    trc : trace port map(clk, rst, clk_z80_ce,
                         trc_en, trc_di,
                         dbg.z80.id.jump_beg, dbg.z80.id.jump_end,
                         dbg.z80.pc, 
                         cpu_block, trc_wr, trc_addr, trc_data,
                         dbg.trace);
end arch;
