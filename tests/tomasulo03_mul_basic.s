; TOM03: MUL Basic
; Scope: mul, addi, sw, nop
; Expected signature: 42 at address 100

main:
        addi x1, x0, 6         # x1 = 6
        addi x2, x0, 7         # x2 = 7
        mul  x10, x1, x2       # x10 = 42
        sw   x10, 100(x0)      # mem[100] = 42
        nop
        nop
