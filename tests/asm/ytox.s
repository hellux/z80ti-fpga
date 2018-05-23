_OP1Set2:   equ 41A7h
_OP2Set4:   equ 4195h
_YToX:      equ 47A1h
_BinOPExec: equ 4663h

org 0x9d95

; load operands
    rst 0x28
    dw _OP1Set2
    rst 0x28
    dw _OP2Set4

; execute op1^op2
    ld a, _YToX
    rst 0x28
    dw _BinOPExec
