library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.z80_comm.all;
use work.cmp_comm.all;
use work.util.all;

entity monitor_vga is port(
    clk : in std_logic;
    dbg : in dbg_cmp_t;
    x_vga : in std_logic_vector(8 downto 0);
    y_vga : in std_logic_vector(5 downto 0);
    char : out std_logic_vector(5 downto 0);
    col_index, row_index : out std_logic_vector(2 downto 0);
    char_pixel : in std_logic;
    data_vga : out std_logic);
end monitor_vga;

architecture arch of monitor_vga is
    constant PAGES_PER_ROW : integer := 8;
    constant PAGE_SIZE : integer := 8;
    constant COLS : integer := PAGE_SIZE*PAGES_PER_ROW;
    constant ROWS : integer := 8;
    constant PAGE_COUNT : integer := PAGES_PER_ROW*ROWS;

    type pages_t is array(0 to PAGE_COUNT-1) of string(1 to PAGE_SIZE);

    signal col : unsigned(5 downto 0);
    signal row : unsigned(2 downto 0);
    signal page_index : integer range 0 to PAGE_COUNT-1;
    signal page_col : integer range 0 to 7;
begin
    process(clk)
        variable val_prefix : string(1 to 4);
        variable val_mode : string(1 to 3);
        variable val_cycle : string(1 to 4);
        variable val_flags : string(1 to 8);
        variable val_cond : string(1 to 8);
        variable val_cb : string(1 to 8);
        variable val_asic : string(1 to 8);
        variable val_int : string(1 to 8);
        variable val_alu_op : string(1 to 8);
        variable val_kbd_group : string(1 to 8);
        variable val_hwt1, val_hwt2 : string(1 to 8);
        variable val_hwt1f, val_hwt2f : string(1 to 8);
        variable val_lcd_mode : string(1 to 8);
        variable val_lcd_ptr : string(1 to 8);

        variable pages : pages_t;
        variable char_ch : character;
        variable char_int, char_int_o : integer;
    begin
        if rising_edge(clk) then
        case dbg.z80.state.prefix is
        when main => val_prefix := "MAIN";
        when   ed => val_prefix := "  ED";
        when   cb => val_prefix := "  CB";
        when   dd => val_prefix := "  DD";
        when ddcb => val_prefix := "DDCB";
        when   fd => val_prefix := "  FD";
        when fdcb => val_prefix := "FDCB";
        when int  => val_prefix := " INT";
        end case;
        case dbg.z80.state.mode is
        when exec       => val_mode := "EXE";
        when halt       => val_mode := "HLT";
        when  interrupt => val_mode := "INT";
        end case;
        val_cycle := "M" &
            hex_str(std_logic_vector(to_unsigned(dbg.z80.state.m, 3))) &
                     "T" &
            hex_str(std_logic_vector(to_unsigned(dbg.z80.state.t, 3)));

        val_flags := (others => ' ');
        if dbg.z80.regs.af(7) = '1' then val_flags(1) := 'S'; end if;
        if dbg.z80.regs.af(6) = '1' then val_flags(2) := 'Z'; end if;
        if dbg.z80.regs.af(5) = '1' then val_flags(3) := 'Y'; end if;
        if dbg.z80.regs.af(4) = '1' then val_flags(4) := 'H'; end if;
        if dbg.z80.regs.af(3) = '1' then val_flags(5) := 'X'; end if;
        if dbg.z80.regs.af(2) = '1' then val_flags(6) := 'P'; end if;
        if dbg.z80.regs.af(1) = '1' then val_flags(7) := 'N'; end if;
        if dbg.z80.regs.af(0) = '1' then val_flags(8) := 'C'; end if;

        val_cond := " Z CPE M";
        if dbg.z80.state.cc(0) then val_cond(1) := 'N'; end if;
        if dbg.z80.state.cc(2) then val_cond(3) := 'N'; end if;
        if dbg.z80.state.cc(4) then val_cond(6) := 'O'; end if;
        if dbg.z80.state.cc(6) then val_cond(8) := 'P'; end if;

        val_asic := "R       ";
        if dbg.ti.asic.rd_wr = '1' then val_asic(1) := 'W'; end if;
        if dbg.ti.asic.ce = '1' then val_asic(2) := 'E'; end if;
        val_asic(3 to 4) := hex_str(dbg.ti.asic.paddr);
        if dbg.ti.int.on_key = '1' then val_asic(6) := 'O'; end if;
        if dbg.ti.int.hwt1 = '1' then val_asic(7) := '1'; end if;
        if dbg.ti.int.hwt2 = '1' then val_asic(8) := '2'; end if;

        val_cb := (others => ' ');
        if dbg.cbo.m1   = '1' then val_cb(1) := '1'; end if;
        if dbg.cbo.mreq = '1' then val_cb(2) := 'M'; end if;
        if dbg.cbo.iorq = '1' then val_cb(3) := 'I'; end if;
        if dbg.cbo.rd   = '1' then val_cb(4) := 'R'; end if;
        if dbg.cbo.wr   = '1' then val_cb(5) := 'W'; end if;
        if dbg.cbo.halt = '1' then val_cb(6) := 'H'; end if;
        if dbg.cbi.int  = '1' then val_cb(7) := 'X'; end if;
        if dbg.cbi.reset= '1' then val_cb(8) := '0'; end if;

        val_int := " IM  DI ";
        case dbg.z80.state.im is
        when 0 => val_int(4) := '0';
        when 1 => val_int(4) := '1';
        when 2 => val_int(4) := '2';
        end case;
        if dbg.z80.state.iff = '1' then val_int(6 to 7) := "EI"; end if;
        
        case dbg.z80.alu_op is
        when add_i    => val_alu_op := " ADD    ";
        when adc_i    => val_alu_op := " ADC    ";
        when sub_i    => val_alu_op := " SUB    ";
        when sbc_i    => val_alu_op := " SBC    ";
        when cp_i     => val_alu_op := " CP     ";
        when inc_i    => val_alu_op := " INC    ";
        when dec_i    => val_alu_op := " DEC    ";
        when neg_i    => val_alu_op := " NEG    ";
        when add16_i1 => val_alu_op := " ADD16_1";
        when add16_i2 => val_alu_op := " ADD16_2";
        when adc16_i1 => val_alu_op := " ADC16_1";
        when adc16_i2 => val_alu_op := " ADC16_2";
        when sbc16_i1 => val_alu_op := " SBC16_1";
        when sbc16_i2 => val_alu_op := " SBC16_2";
        when and_i    => val_alu_op := " AND    ";
        when or_i     => val_alu_op := " OR     ";
        when xor_i    => val_alu_op := " XOR    ";
        when bit_i    => val_alu_op := " BIT    ";
        when res_i    => val_alu_op := " RES    ";
        when set_i    => val_alu_op := " SET    ";
        when rlc_i    => val_alu_op := " RLC    ";
        when rl_i     => val_alu_op := " RL     ";
        when sla_i    => val_alu_op := " SLA    ";
        when sll_i    => val_alu_op := " SLL    ";
        when rrc_i    => val_alu_op := " RRC    ";
        when rr_i     => val_alu_op := " RR     ";
        when sra_i    => val_alu_op := " SRA    ";
        when srl_i    => val_alu_op := " SRL    ";
        when rlca_i   => val_alu_op := " RLCA   ";
        when rrca_i   => val_alu_op := " RRCA   ";
        when rla_i    => val_alu_op := " RLA    ";
        when rra_i    => val_alu_op := " RRA    ";
        when daa_i    => val_alu_op := " DAA    ";
        when cpl_i    => val_alu_op := " CPL    ";
        when scf_i    => val_alu_op := " SCF    ";
        when ccf_i    => val_alu_op := " CCF    ";
        when in_i     => val_alu_op := " IN     ";
        when ld_i     => val_alu_op := " LD     ";
        when rld_i1   => val_alu_op := " RLD_I1 ";
        when rld_i2   => val_alu_op := " RLD_I2 ";
        when rrd_i1   => val_alu_op := " RRD_I1 ";
        when rrd_i2   => val_alu_op := " RRD_I2 ";
        when ldi_i    => val_alu_op := " LDI    ";
        when cpi_i    => val_alu_op := " CPI    ";
        when ini_i    => val_alu_op := " INI    ";
        when outi_i   => val_alu_op := " OUTI   ";
        when ldd_i    => val_alu_op := " LDD    ";
        when cpd_i    => val_alu_op := " CPD    ";
        when ind_i    => val_alu_op := " IND    ";
        when ldir_i   => val_alu_op := " LDIR   ";
        when cpir_i   => val_alu_op := " CPIR   ";
        when inir_i   => val_alu_op := " INIR   ";
        when otir_i   => val_alu_op := " OTIR   ";
        when outd_i   => val_alu_op := " OUTD   ";
        when lddr_i   => val_alu_op := " LDDR   ";
        when cpdr_i   => val_alu_op := " CPDR   ";
        when indr_i   => val_alu_op := " INDR   ";
        when otdr_i   => val_alu_op := " OTDR   ";
        when unknown  => val_alu_op := " UNKNOWN";
        end case;

        val_kbd_group := (others => ' ');
        if dbg.ti.kbd.grp(0) = '0' then val_kbd_group(8) := '0'; end if;
        if dbg.ti.kbd.grp(1) = '0' then val_kbd_group(7) := '1'; end if;
        if dbg.ti.kbd.grp(2) = '0' then val_kbd_group(6) := '2'; end if;
        if dbg.ti.kbd.grp(3) = '0' then val_kbd_group(5) := '3'; end if;
        if dbg.ti.kbd.grp(4) = '0' then val_kbd_group(4) := '4'; end if;
        if dbg.ti.kbd.grp(5) = '0' then val_kbd_group(3) := '5'; end if;
        if dbg.ti.kbd.grp(6) = '0' then val_kbd_group(2) := '6'; end if;
        if dbg.ti.kbd.grp(7) = '0' then val_kbd_group(1) := '7'; end if;

        val_hwt1(1 to 3) := "H1:";
        val_hwt1(4 to 8) := hex_str(dbg.ti.hwt.hwt1);
        val_hwt2(1 to 3) := "H2:";
        val_hwt2(4 to 8) := hex_str(dbg.ti.hwt.hwt2);
        case dbg.ti.hwt.freq is
        when "00" => val_hwt1f := "  560 HZ"; val_hwt2f := " 1120 HZ";
        when "01" => val_hwt1f := "  248 HZ"; val_hwt2f := "  497 HZ";
        when "10" => val_hwt1f := "  170 HZ"; val_hwt2f := "  344 HZ";
        when "11" => val_hwt1f := "  118 HZ"; val_hwt2f := "  236 HZ";
        when others => null; end case;

        val_lcd_mode := "DECX 6  ";
        if dbg.ti.lcd.up = '1' then val_lcd_mode(1 to 3) := "INC"; end if;
        if dbg.ti.lcd.counter = '1' then val_lcd_mode(4) := 'Y'; end if;
        if dbg.ti.lcd.wl = '1' then val_lcd_mode(6) := '8'; end if;
        if dbg.ti.lcd.active = '1' then val_lcd_mode(8) := 'E'; end if;

        val_lcd_mode := "XX:YY:ZZ";
        val_lcd_mode(1 to 2) := hex_str(dbg.ti.lcd.x);
        val_lcd_mode(4 to 5) := hex_str(dbg.ti.lcd.y);
        val_lcd_mode(7 to 8) := hex_str(dbg.ti.lcd.z);

        pages := (others => (others => ' '));

    -- states / int
        pages(0) := "PC: " & hex_str(dbg.z80.pc);
        pages(1) := val_mode & ' ' & val_cycle;
        pages(2) := val_prefix & "  " & hex_str(dbg.z80.ir);
        pages(3) := val_flags;
        pages(4) := val_cond;
        pages(5) := val_int;
        pages(6) := val_cb;
        pages(7) := val_asic;

    -- regfile
        pages(8)  := " AF:" & hex_str(dbg.z80.regs.af);
        pages(9)  := " BC:" & hex_str(dbg.z80.regs.bc);
        pages(10) := " DE:" & hex_str(dbg.z80.regs.de);
        pages(11) := " HL:" & hex_str(dbg.z80.regs.hl);
        pages(12) := " SP:" & hex_str(dbg.z80.regs.sp);
        pages(13) := " IX:" & hex_str(dbg.z80.regs.ix);
        pages(14) := " IY:" & hex_str(dbg.z80.regs.iy);
        pages(15) := " WZ:" & hex_str(dbg.z80.regs.wz);

    -- data, addr, alu
        pages(16) := " AX:" & hex_str(dbg.addr_log);
        pages(17) := " A:"  & hex_str(dbg.addr_phy);
        pages(18) := " AB:" & hex_str(dbg.z80.abus);
        pages(19) := " DT:" & hex_str(dbg.z80.dbus & dbg.data);
        pages(20) := " DF:" & hex_str(dbg.z80.dbufo) & hex_str(dbg.z80.dbufi);
        pages(22) := " AT:" & hex_str(dbg.z80.act & dbg.z80.tmp);
        pages(23) := val_alu_op;

    -- ports in
        pages(24) := " PI01:" & hex_str(dbg.ti.asic.p01_kbd);
        pages(25) := " PI02:" & hex_str(dbg.ti.asic.p02_status);
        pages(26) := " PI03:" & hex_str(dbg.ti.asic.p03_intmask);
        pages(27) := " PI04:" & hex_str(dbg.ti.asic.p04_mmap_int);
        pages(28) := " PI06:" & hex_str(dbg.ti.asic.p06_mempage_a);
        pages(29) := " PI07:" & hex_str(dbg.ti.asic.p07_mempage_b);
        pages(30) := " PI10:" & hex_str(dbg.ti.asic.p10_lcd_status);
        pages(31) := " PI11:" & hex_str(dbg.ti.asic.p11_lcd_data);

    -- mem map
        pages(32) := "  MODE0 ";
        pages(34) := "  ROM00 ";
        pages(35) := "  ROM?? ";
        pages(36) := "  ROM?? ";
        pages(37) := "  ROM?? ";
        if dbg.ti.memctrl.mode = '1' then pages(32)(7) := '1'; end if;
        if dbg.ti.memctrl.sec_ram_rom = '1' then pages(35)(4) := 'A'; end if;
        pages(35)(6 to 7) := hex_str(dbg.ti.memctrl.sec_page);
        if dbg.ti.memctrl.thi_ram_rom = '1' then pages(36)(4) := 'A'; end if;
        pages(36)(6 to 7) := hex_str(dbg.ti.memctrl.thi_page);
        if dbg.ti.memctrl.fou_ram_rom = '1' then pages(37)(4) := 'A'; end if;
        pages(37)(6 to 7) := hex_str(dbg.ti.memctrl.fou_page);

    -- ports out
        pages(40) := val_kbd_group;
        pages(41) := val_hwt1;
        pages(42) := val_hwt1f;
        pages(43) := val_hwt2;
        pages(44) := val_hwt2f;
        pages(45) := val_lcd_mode;
        pages(46) := val_lcd_ptr;

    -- trace jumps
        pages(48) := ' ' & hex_str(dbg.trc_ptr) & 'D';
        if dbg.trace.enabled = '1' then pages(48)(8) := 'E'; end if;
        pages(49) := " FR:" & hex_str(dbg.trace.from_jump);
        pages(50) := " TO:" & hex_str(dbg.trace.to_jump);

        char_ch := pages(page_index)(page_col+1);
        char_int := character'pos(char_ch);

        if '0' <= char_ch and char_ch <= '9' then
            char_int_o := char_int - character'pos('0');
        elsif 'A' <= char_ch and char_ch <= 'Z' then
            char_int_o := 10 + char_int - character'pos('A');
        elsif char_ch = ':' then
            char_int_o := 36;
        else
            char_int_o := 37;
        end if;

        char <= std_logic_vector(to_unsigned(char_int_o, 6));

        end if;
    end process;

    col <= unsigned(x_vga(8 downto 3));
    row <= unsigned(y_vga(5 downto 3));
    page_index <= to_integer(col(5 downto 3) & row);
    page_col <= to_integer(col(2 downto 0));

    col_index <= x_vga(2 downto 0);
    row_index <= y_vga(2 downto 0);
    data_vga <= char_pixel;
end arch;
