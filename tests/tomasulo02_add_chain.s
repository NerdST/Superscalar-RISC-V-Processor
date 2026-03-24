; TOM02: ADD/ADDI Chain
; Scope: add, addi, sw, nop
; Expected signature: 21 at address 100

main:
        addi x1, x0, 8         # x1 = 8
        addi x2, x0, 13        # x2 = 13
        add  x10, x1, x2       # x10 = 21
        sw   x10, 100(x0)      # mem[100] = 21
        nop
        nop
