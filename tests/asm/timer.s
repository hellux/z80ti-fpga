;Setup up a timer that waits 2 seconds
   di
   ld a,$47      ;8 hz
   out ($30),a
   ld a,0        ; no loop, no interrupt
   out ($31),a
   ld a,16       ;16 ticks / 8 hz equals 2 seconds
   out ($32),a
wait:
   in a,(4)
   bit 5,a       ;bit 5 tells if timer 1
   jr z,wait     ;is done
   xor a
   out ($30),a   ;Turn off the timer.
   out ($31),a
   halt
