; ROB03: BEQ taken — misprediction flush + redirect
;
; x1=7, x2=7: 7 == 7, so BEQ is taken.
; We predict not-taken so the instruction after the branch
; (addi x10,x0,0) is speculatively dispatched into the ROB.
; When the BEQ commits, the ROB detects the misprediction,
; flushes everything after the branch, and redirects ifetch to `done`.
;
; Critical: addi x10,x0,77 commits BEFORE the BEQ (in-order), so
; areg[x10]=77 is architectural state when the flush fires.
; After the flush, the RAT is cleared, and the new sw reads x10=77
; directly from the register file.
;
; Expected signature: 77

main:
        addi x1,  x0, 7     # x1 = 7
        addi x2,  x0, 7     # x2 = 7  (x1 == x2)
        addi x10, x0, 77    # x10 = 77  (commits before BEQ)
        beq  x1,  x2, done  # TAKEN — flush all speculative state
        addi x10, x0, 0     # NEVER commits (squashed by flush)
done:
        sw   x10, 100(x0)   # x10 = 77 from areg (RAT cleared by flush)
        nop
