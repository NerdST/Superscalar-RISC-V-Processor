; TOM04: SW then LW roundtrip
; Scope: sw, lw, addi, nop
; Expected signature: 33 at address 100

main:
        addi x5, x0, 33        # x5 = 33
        sw   x5, 96(x0)        # mem[96] = 33
        nop
        lw   x10, 96(x0)       # x10 = 33
        sw   x10, 100(x0)      # mem[100] = 33
        nop
