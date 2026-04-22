; ROB04: Precise exception — misaligned load address
;
; Layout:
;   addi x5, x0, 99      ; commits normally
;   addi x6, x0, 77      ; commits normally
;   lw   x7, 97(x0)      ; MISALIGNED (97 % 4 = 1) — raises trap
;   addi x7, x0, 123     ; NEVER commits (younger than trap)
;   sw   x5, 100(x0)     ; NEVER commits — no FINAL_SIGNATURE
;
; Expected: TRAP_SIGNATURE with trapPC = PC of the lw (decimal 8).

main:
        addi x5,  x0, 99
        addi x6,  x0, 77
        lw   x7,  97(x0)
        addi x7,  x0, 123
        sw   x5,  100(x0)
        nop
