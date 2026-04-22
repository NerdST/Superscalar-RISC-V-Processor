; ROB02: BEQ not-taken — branch condition false, continue sequential
;
; x1=5, x2=3: 5 != 3, so the BEQ does NOT redirect fetch.
; The addi x10,x10,1 after the branch executes normally.
; Verifies that a predict-not-taken BEQ with a false condition
; does not flush the ROB or stall the pipeline.
;
; Expected signature: 43

main:
        addi x1,  x0,  5    # x1 = 5
        addi x2,  x0,  3    # x2 = 3  (x1 != x2)
        addi x10, x0,  42   # x10 = 42
        beq  x1,  x2,  done # NOT taken (5 != 3) — no flush
        addi x10, x10, 1    # x10 = 43  (executes normally)
done:
        sw   x10, 100(x0)   # signature = 43
        nop
