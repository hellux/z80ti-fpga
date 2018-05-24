library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ti_comm is
    constant SYS_FREQ : integer := 100*10**6;
    constant DIV_TI : integer := 3;
    constant LCD_COLS : integer := 120;
    constant LCD_ROWS : integer := 64;

    type port_in_t is record
        data : std_logic_vector(7 downto 0);
    end record;

    type port_out_t is record
        data : std_logic_vector(7 downto 0);
        rd, wr : std_logic;
    end record;

    type ports_in_t is record
        p01_kbd : port_in_t;
        p02_status : port_in_t;
        p04_mmap_int : port_in_t;
        p10_lcd_status, p11_lcd_data : port_in_t;
    end record;

    type ports_out_t is record
        p01_kbd : port_out_t;
        p03_intmask : port_out_t;
        p04_mmap_int : port_out_t;
        p05_protect : port_out_t;
        p06_mempage_a, p07_mempage_b : port_out_t;
        p10_lcd_status, p11_lcd_data : port_out_t;
    end record;

    type int_dev_t is (none, on_key, hwt1, hwt2);

    impure function fdiv(freq : natural) return std_logic_vector;
    type hwt_divs_t is array(0 to 3) of std_logic_vector(19 downto 0);
    constant HWT1_DIVS : hwt_divs_t :=
        (fdiv(560), fdiv(248), fdiv(170), fdiv(118));
    constant HWT2_DIVS : hwt_divs_t :=
        (fdiv(1120), fdiv(497), fdiv(344), fdiv(236));

    constant PI02_BATTERY_GOOD      : natural := 0;
    constant PI02_NOT_73            : natural := 1;
    constant PI02_FLASH_UNLOCKED    : natural := 2;
    constant PI02_PROTECT_0         : natural := 3;
    constant PI02_PROTECT_1         : natural := 4;
    constant PI02_PROTECT_2         : natural := 5;
    constant PI02_LINK_ASSIST       : natural := 6;
    constant PI02_73_83             : natural := 7;

    constant PO03_ON_KEY_INT        : natural := 0;
    constant PO03_HWT1_INT          : natural := 1;
    constant PO03_HWT2_INT          : natural := 2;

    constant PI04_ON_KEY_INT        : natural := 0;
    constant PI04_HWT1_INT          : natural := 1;
    constant PI04_HWT2_INT          : natural := 2;
    constant PI04_ON_KEY_DOWN       : natural := 3;
    constant PI04_LINK_INT          : natural := 4;

    constant PI10_AUTO_INC_DEC      : natural := 0;
    constant PI10_AUTO_Y_X          : natural := 1;
    constant PI10_RESET_STATE       : natural := 4;
    constant PI10_LCD_ENABLED       : natural := 5;
    constant PI10_WL_8_6            : natural := 6;
    constant PI10_LCD_BUSY          : natural := 7;

    type dbg_int_t is record 
        on_key : std_logic;
        hwt1, hwt2 : std_logic;
    end record;

    type dbg_kbd_t is record 
        grp : std_logic_vector(7 downto 0);
    end record;

    type dbg_hwt_t is record 
        hwt1 : std_logic_vector(19 downto 0);
        hwt2 : std_logic_vector(19 downto 0);
        freq : std_logic_vector(1 downto 0);
    end record;

    type dbg_lcd_t is record 
        x : std_logic_vector(5 downto 0);
        y : std_logic_vector(4 downto 0);
        z : std_logic_vector(5 downto 0);
        up, counter, active, wl : std_logic;
    end record;

    type dbg_memctrl_t is record 
        mode : std_logic;
        sec_ram_rom : std_logic;
        sec_page : std_logic_vector(4 downto 0);
        thi_ram_rom : std_logic;
        thi_page : std_logic_vector(4 downto 0);
        fou_ram_rom : std_logic;
        fou_page : std_logic_vector(4 downto 0);
    end record;

    type dbg_asic_t is record 
        paddr : std_logic_vector(4 downto 0);
        rd_wr : std_logic; -- 0 rd, 1 wr
        ce : std_logic;
        p01_kbd : std_logic_vector(7 downto 0);
        p02_status : std_logic_vector(7 downto 0);
        p03_intmask : std_logic_vector(7 downto 0);
        p04_mmap_int : std_logic_vector(7 downto 0);
        p06_mempage_a : std_logic_vector(7 downto 0);
        p07_mempage_b : std_logic_vector(7 downto 0);
        p10_lcd_status : std_logic_vector(7 downto 0);
        p11_lcd_data : std_logic_vector(7 downto 0);
    end record;

    type dbg_ti_t is record
        asic : dbg_asic_t;
        memctrl : dbg_memctrl_t;
        kbd : dbg_kbd_t;
        hwt : dbg_hwt_t;
        lcd : dbg_lcd_t;
        int : dbg_int_t;
    end record;
end ti_comm;

package body ti_comm is
    -- CLK FREQ / TI_DIV / freq = divider for to get frequency freq
    impure function fdiv(freq : natural) return std_logic_vector is begin
        return std_logic_vector(to_unsigned(SYS_FREQ/DIV_TI/freq, 20));
    end fdiv;
end ti_comm;
