; TOM07: MUL + ADD overlap candidate
; Scope: mul, add, addi, sw, nop
; Expected signature: 17 at address 100

main:
        addi x1, x0, 3
        addi x2, x0, 4
        mul  x5, x1, x2        # 12 (longer latency)
        addi x6, x0, 5         # independent add path
        add  x10, x5, x6       # 17
        sw   x10, 100(x0)
        nop
