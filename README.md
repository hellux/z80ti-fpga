# z80ti
<img src="https://github.com/hellux/z80ti-fpga/raw/master/.demo.jpg" width="480">

Replica of a TI83p calculator written in VHDL.

## Status
All documented instructions and almost all undocumented instructions of the Z80
processor are implemented. Only interrupt mode 1 and 2 have been implemented
since TI calculators never use IM0 or nonmaskable interrupts. Currently runs
the TI83p operating system fine, as well as all games that have been tested.
Uses a PS2 keyboard for input and a VGA monitor at 640x480 resolution for
displaying the LCD, as well as live register values for debugging.

## Possible extensions
  * Execution mask and flash rom protection is not implemented.
  * Grayscale LCD (add second LCD memory for pixel intensities)
  * TI84p
    * crystal timers
    * MD5 module
    * alternate memory mapping
    * other ports

## Resources
  * Z80 instructions and functionality
    * _Z80 Family CPU User Manual_ by Zilog
  * Internal design of the Z80
    * _Programming the Z80_ by Rodney Zaks
  * Structure of TI83p memory and programs
    * _TI-83 Plus Developer Guide_ by Texas Instruments
  * Information repositories about Z80 and TI calculators
    * [z80.info](http://z80.info)
    * [WikiTI](http://wikiti.brandonw.net/index.php)
  * TI Emulators
    * [z80e](https://github.com/KnightOS/z80e)
    * [Tilem2](http://lpg.ticalc.org/prj_tilem)
  * Archive of TI83p programs
    * [ticalc.org](https://www.ticalc.org/pub/83plus/)
  * Functionality of the LCD controller
    * _T604A datasheet_ by TOSHIBA
