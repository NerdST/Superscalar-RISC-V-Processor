; ROB01: WAW (Write-After-Write) register ordering
;
; MUL writes x1=42 using the slow 6-cycle MUL FU.
; ADDI writes x1=99 using the fast 4-cycle ADD FU.
; ADDI finishes execution first but commits SECOND (in-order after MUL).
; The sw reads x1 via ADDI's ROB tag (CDB snoop), so it always gets 99.
; If renaming were broken, the sw could get 42.
;
; Expected signature: 99

main:
        addi x2, x0, 6
        addi x3, x0, 7
        mul  x1, x2, x3     # x1 = 42  (slow 6-cycle MUL FU, tag=2)
        addi x1, x0, 99     # x1 = 99  (fast 4-cycle ADD FU, tag=3) WAW!
        nop
        nop
        nop
        nop
        sw   x1, 100(x0)    # x1 must be 99 (ADDI tag wins rename)
        nop
