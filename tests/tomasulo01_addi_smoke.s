; TOM01: ADDI Smoke Test (project-specific)
; Scope: addi, sw, nop
; Expected signature: 5 at address 100

main:
        addi x10, x0, 5        # x10 = 5
        sw   x10, 100(x0)      # mem[100] = 5
        nop
        nop
