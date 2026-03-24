; TOM06: Slot1 depends on Slot0 style dependency
; Scope: addi, add, sw, nop
; Expected signature: 9 at address 100

main:
        addi x1, x0, 4         # producer
        add  x10, x1, x1       # dependent consumer => 8
        addi x10, x10, 1       # => 9
        sw   x10, 100(x0)
        nop
