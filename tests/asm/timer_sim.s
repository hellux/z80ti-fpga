;Setup up a timer that waits 2 seconds
   di
   ld a,0
   out ($35),a ; disable/reset timer 2
   out ($38),a ; disable/reset timer 2
   ld a,$88      ; freq
   out ($30),a
   ld a,0        ; no loop, no interrupt
   out ($31),a
   ld a,2       ; set timer to 16
   out ($32),a
wait:
   in a,(4)
   bit 5,a       ;bit 5 tells if timer 1 is done
   jr z,wait
   xor a
   out ($30),a   ;Turn off the timer.
   out ($31),a
   di
   ld a,0
   out ($35),a ; disable/reset timer 2
   out ($38),a ; disable/reset timer 2
   ld a,$88      ; freq
   out ($30),a
   ld a,2        ; loop, interrupt
   out ($31),a
   ld a,2       ; set timer to 16
   out ($32),a
wait2:
   in a,(4)
   bit 5,a       ;bit 5 tells if timer 1 is done
   jr z,wait2
   ld a,$84
   out ($30),a   ; change freq
   halt
