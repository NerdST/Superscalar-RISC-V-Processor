; TOM05: Two independent instructions together
; Scope: addi, sw, add, nop
; Expected signature: 11 at address 100

main:
        addi x1, x0, 4         # independent 1
        addi x2, x0, 7         # independent 2
        add  x10, x1, x2       # x10 = 11
        sw   x10, 100(x0)
        nop
