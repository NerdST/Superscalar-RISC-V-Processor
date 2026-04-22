module datapath(
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] ReadDataM,
    output logic [31:0] PCF,
    output logic [31:0] ALUResultM,
    output logic [31:0] WriteDataM,
    output logic        MemWrite,
    output logic        MemReadM,
    output logic [31:0] iq0,
    output logic [31:0] iq1,
    output logic        dispatch0Dbg,
    output logic        dispatch1Dbg,
    output logic        cdbvDbg,
    output logic [2:0]  cdbtDbg,
    output logic        wbvDbg,
    output logic [2:0]  wbtDbg,
    output logic        wbStoreDbg,
    output logic        storeDoneDbg,
    output logic        trap,
    output logic [31:0] trapPC
);

  // ===== PARAMETERS =====
  // TAGW=4 → 16 ROB entries (= 16 rename tags)
  localparam int NTAG = 16;
  localparam int TAGW = 4;       // $clog2(NTAG)
  localparam logic [1:0] KADD = 2'd0;
  localparam logic [1:0] KMUL = 2'd1;
  localparam logic [1:0] KLS  = 2'd2;

  // ===== ARCHITECTURAL STATE =====
  logic [31:0] areg[31:0];

  // ===== FETCH =====
  logic [31:0] f0, f1;    // fetched instructions
  logic        fv0, fv1;  // valid bits for f0, f1 (fetched but not yet decoded)
  logic [1:0]  iqpop;     // which instruction(s) to pop from ifetch queue (for next fetch)
  logic        fetchDone; // ifetch queue is empty (no valid instructions)
  // PCF is the byte PC of instruction 0, driven directly by ifetch
  logic [31:0] pc1;           // byte PC of instruction 1
  assign pc1 = PCF + 32'd4;

  // ===== DECODE =====
  logic [2:0] op0, op1;
  logic [1:0] k0, k1;
  logic [4:0] rs10, rs20, rd0;
  logic [4:0] rs11, rs21, rd1;
  logic [31:0] imm0, imm1;
  logic valid0, valid1, regw0, regw1, nop0, nop1;
  logic isStore0, isStore1;
  logic isBranch0, isBranch1;

  // ===== RAT =====
  logic q10v, q20v, q11v, q21v;
  logic [TAGW-1:0] q10t, q20t, q11t, q21t;

  // ===== ROB / TAGS =====
  logic [TAGW-1:0] tag0, tag1;
  logic rename0, rename1;
  logic robFull;
  logic robFlush;
  logic [31:0] robFlushPC;

  // ROB enqueue signals
  logic enq0v, enq1v;
  logic [31:0] enq0branchTarget, enq1branchTarget;

  // ROB commit signals
  logic            commitV;
  logic [4:0]      commitRd;
  logic [TAGW-1:0] commitTag;
  logic [31:0]     commitResult;
  logic            commitRegW;
  logic            commitIsStore;
  logic [31:0]     commitStoreAddr;
  logic [31:0]     commitStoreData;

  // ===== HAZARD =====
  logic addFull, mulFull, lsFull;
  logic dispatch0, dispatch1;
  logic can0Haz, can1Haz, slot1SameKindBusyHaz;
  logic can0Eff, can1Eff;

  // ===== OPERAND READINESS (hazard output) =====
  logic s0qjv, s0qkv;
  logic [TAGW-1:0] s0qj, s0qk;
  logic [31:0] s0vj, s0vk;

  logic s1qjv, s1qkv;
  logic [TAGW-1:0] s1qj, s1qk;
  logic [31:0] s1vj, s1vk;

  logic [31:0] rs10Val, rs20Val, rs11Val, rs21Val;

  // ===== DISPATCH PACK OUTPUT (per slot) =====
  logic slotDisp0, slotDispStore0, slotDispImm0;
  logic [1:0] slotDispKind0;
  logic [TAGW-1:0] slotDispDest0;
  logic [31:0] slotDispVj0, slotDispVk0, slotDispImmVal0;
  logic slotDispQjv0, slotDispQkv0;
  logic [TAGW-1:0] slotDispQj0, slotDispQk0;

  logic slotDisp1, slotDispStore1, slotDispImm1;
  logic [1:0] slotDispKind1;
  logic [TAGW-1:0] slotDispDest1;
  logic [31:0] slotDispVj1, slotDispVk1, slotDispImmVal1;
  logic slotDispQjv1, slotDispQkv1;
  logic [TAGW-1:0] slotDispQj1, slotDispQk1;

  // ===== FU SELECT / MUX TO RS =====
  logic addSel0, addSel1, mulSel0, mulSel1, lsSel0, lsSel1;

  logic addDisp, addDispImm, addDispIsBranch;
  logic [TAGW-1:0] addDispDest;
  logic [31:0] addDispVj, addDispVk, addDispImmVal;
  logic addDispQjv, addDispQkv;
  logic [TAGW-1:0] addDispQj, addDispQk;

  logic mulDisp;
  logic [TAGW-1:0] mulDispDest;
  logic [31:0] mulDispVj, mulDispVk;
  logic mulDispQjv, mulDispQkv;
  logic [TAGW-1:0] mulDispQj, mulDispQk;

  logic lsDisp, lsDispStore;
  logic [TAGW-1:0] lsDispDest;
  logic [31:0] lsDispVj, lsDispVk, lsDispImmVal;
  logic lsDispQjv, lsDispQkv;
  logic [TAGW-1:0] lsDispQj, lsDispQk;

  // ===== RS ISSUE OUTPUTS =====
  logic addIssueV, addIssueImm, addIssueIsBranch;
  logic [TAGW-1:0] addIssueDest;
  logic [31:0] addIssueA, addIssueB, addIssueImmVal;

  logic mulIssueV;
  logic [TAGW-1:0] mulIssueDest;
  logic [31:0] mulIssueA, mulIssueB;

  logic lsIssueV, lsIssueStore;
  logic [TAGW-1:0] lsIssueDest;
  logic [31:0] lsIssueA, lsIssueB, lsIssueImmVal;

/* verilator lint_off UNUSEDSIGNAL */
  logic mulIssueImmDrop;
  logic [31:0] mulIssueImmValDrop;
  logic lsIssueImmDrop;
  logic mulIssueStoreDrop;
/* verilator lint_on UNUSEDSIGNAL */

  // ===== FU COMPLETION =====
  logic [31:0] addRes, mulRes;

  logic addDoneV, mulDoneV;
  logic [TAGW-1:0] addDoneTag, mulDoneTag;
  logic [31:0] addDoneRes, mulDoneRes;
  logic addFuReady, mulFuReady;

  logic loadDoneV, storeDoneV;
  logic [TAGW-1:0] loadDoneTag, storeDoneTag;
  logic [31:0] loadAddr, storeDoneAddr, storeDoneData;

  // Precise exception signals from fu_ls (misaligned address)
  logic lsExcV;
  logic [TAGW-1:0] lsExcTag;

  // ===== CDB =====
  logic cdbv;
  logic [TAGW-1:0] cdbt;
  logic [31:0] cdbr;

  // ===== STORE BUFFER (1-entry) =====
  // Captures a store's address+data when it executes (storeDoneV). The actual
  // RAM write is deferred to commit time to avoid speculative writes. A load
  // that hits the buffer gets the forwarded value instead of stale RAM data.
  logic        stbufValid;
  logic [31:0] stbufAddr, stbufData;
  logic [31:0] loadResult;

  // ===== FETCH =====
  ifetch fq(
      .clk(clk),
      .reset(reset),
      .flush(robFlush),
      .flushPC(robFlushPC),
      .pop(iqpop),
      .instr0(f0),
      .instr1(f1),
      .valid0(fv0),
      .valid1(fv1),
      .pc0(PCF),
      .done(fetchDone)
  );

  // ===== DECODE =====
  tdecode d0(.instr(f0), .op(op0), .kind(k0), .rs1(rs10), .rs2(rs20), .rd(rd0),
             .imm(imm0), .valid(valid0), .regw(regw0), .nop(nop0),
             .isStore(isStore0), .isBranch(isBranch0));
  tdecode d1(.instr(f1), .op(op1), .kind(k1), .rs1(rs11), .rs2(rs21), .rd(rd1),
             .imm(imm1), .valid(valid1), .regw(regw1), .nop(nop1),
             .isStore(isStore1), .isBranch(isBranch1));

  // ===== ROB =====
  // Only non-NOP instructions get ROB entries.
  assign enq0v = dispatch0 && !nop0;
  assign enq1v = dispatch1 && !nop1;
  assign enq0branchTarget = PCF + imm0;
  assign enq1branchTarget = pc1 + imm1;

  rob #(.DEPTH(16), .TAGW(TAGW)) rob0(
      .clk(clk), .reset(reset),
      // Slot 0
      .enq0v(enq0v),
      .enq0rd(rd0),
      .enq0regw(regw0),
      .enq0isStore(isStore0),
      .enq0isBranch(isBranch0),
      .enq0branchTarget(enq0branchTarget),
      .enq0pc(PCF),
      .enq0tag(tag0),
      // Slot 1
      .enq1v(enq1v),
      .enq1rd(rd1),
      .enq1regw(regw1),
      .enq1isStore(isStore1),
      .enq1isBranch(isBranch1),
      .enq1branchTarget(enq1branchTarget),
      .enq1pc(pc1),
      .enq1tag(tag1),
      .robFull(robFull),
      // CDB writeback
      .cdbv(cdbv), .cdbt(cdbt), .cdbr(cdbr),
      // Store writeback
      .storeDoneV(storeDoneV), .storeDoneTag(storeDoneTag),
      .storeDoneAddr(storeDoneAddr), .storeDoneData(storeDoneData),
      // Exception writeback (misaligned LW/SW)
      .excV(lsExcV), .excTag(lsExcTag),
      // Commit
      .commitV(commitV), .commitRd(commitRd), .commitTag(commitTag),
      .commitResult(commitResult), .commitRegW(commitRegW),
      .commitIsStore(commitIsStore),
      .commitStoreAddr(commitStoreAddr), .commitStoreData(commitStoreData),
      // Flush (branch mispredict) + trap (precise exception)
      .flush(robFlush), .flushPC(robFlushPC),
      .trap(trap), .trapPC(trapPC)
  );

  // ===== RAT =====
  // Rename only real dispatched instructions that write a register.
  assign rename0 = dispatch0 && regw0 && !nop0;
  assign rename1 = dispatch1 && regw1 && !nop1;

  rat #(.TAGW(TAGW)) rat0(
      .clk(clk), .reset(reset),
      .flush(robFlush),
      .rs10(rs10), .rs20(rs20), .rs11(rs11), .rs21(rs21),
      .q10v(q10v), .q10t(q10t), .q20v(q20v), .q20t(q20t),
      .q11v(q11v), .q11t(q11t), .q21v(q21v), .q21t(q21t),
      .rename0(rename0), .rd0(rd0), .tag0(tag0),
      .rename1(rename1), .rd1(rd1), .tag1(tag1),
      // Clear on commit (not on CDB broadcast — this is the key ROB change)
      .clearv(commitV && commitRegW),
      .clearrd(commitRd),
      .cleartag(commitTag)
  );

  // ===== DISPATCH UNIT =====
  // Gate dispatch when ROB is full (fewer than 2 free entries).
  assign can0Eff = can0Haz && !robFull;
  assign can1Eff = can1Haz && !robFull;

  dispatchunit du0(
      .flush(robFlush),
      .iqv0(!fetchDone), .iqv1(!fetchDone),
      .valid0(fv0 && valid0), .valid1(fv1 && valid1),
      .nop0(nop0), .nop1(nop1),
      .can0(can0Eff), .can1(can1Eff),
      .slot1SameKindBusy(slot1SameKindBusyHaz),
      .dispatch0(dispatch0), .dispatch1(dispatch1), .iqpop(iqpop)
  );

  // ===== REGISTER FILE READS =====
  assign rs10Val = areg[rs10];
  assign rs20Val = areg[rs20];
  assign rs11Val = areg[rs11];
  assign rs21Val = areg[rs21];

  // ===== HAZARD =====
  hazard #(.TAGW(TAGW)) hz0(
      .kind0(k0), .kind1(k1),
      .addFull(addFull), .mulFull(mulFull), .lsFull(lsFull),
      .op0(op0), .op1(op1),
      .rs10(rs10), .rs20(rs20), .rs11(rs11), .rs21(rs21),
      .rd0(rd0), .nop0(nop0), .nop1(nop1), .regw0(regw0),
      .dispatch0(dispatch0),
      .q10v(q10v), .q10t(q10t), .q20v(q20v), .q20t(q20t),
      .q11v(q11v), .q11t(q11t), .q21v(q21v), .q21t(q21t),
      .slot0Tag(tag0),
      .rs10Val(rs10Val), .rs20Val(rs20Val),
      .rs11Val(rs11Val), .rs21Val(rs21Val),
      .s0qjv(s0qjv), .s0qj(s0qj), .s0vj(s0vj),
      .s0qkv(s0qkv), .s0qk(s0qk), .s0vk(s0vk),
      .s1qjv(s1qjv), .s1qj(s1qj), .s1vj(s1vj),
      .s1qkv(s1qkv), .s1qk(s1qk), .s1vk(s1vk),
      .can0(can0Haz), .can1(can1Haz),
      .slot1SameKindBusy(slot1SameKindBusyHaz)
  );

  // ===== DISPATCH PACK =====
  // NOPs are gated out (en = dispatch && !nop) so they don't fill RS slots.
  dispatchpack #(.TAGW(TAGW)) pack0(
      .op(op0), .kind(k0), .isStore(isStore0), .isBranch(isBranch0),
      .en(dispatch0 && !nop0),
      .destTag(tag0),
      .vj(s0vj), .vk(s0vk), .imm(imm0),
      .qjv(s0qjv), .qj(s0qj), .qkv(s0qkv), .qk(s0qk),
      .disp(slotDisp0), .dispKind(slotDispKind0), .dispStore(slotDispStore0),
      .dispImm(slotDispImm0), .dispDest(slotDispDest0),
      .dispVj(slotDispVj0), .dispVk(slotDispVk0), .dispImmVal(slotDispImmVal0),
      .dispQjv(slotDispQjv0), .dispQj(slotDispQj0),
      .dispQkv(slotDispQkv0), .dispQk(slotDispQk0)
  );

  dispatchpack #(.TAGW(TAGW)) pack1(
      .op(op1), .kind(k1), .isStore(isStore1), .isBranch(isBranch1),
      .en(dispatch1 && !nop1),
      .destTag(tag1),
      .vj(s1vj), .vk(s1vk), .imm(imm1),
      .qjv(s1qjv), .qj(s1qj), .qkv(s1qkv), .qk(s1qk),
      .disp(slotDisp1), .dispKind(slotDispKind1), .dispStore(slotDispStore1),
      .dispImm(slotDispImm1), .dispDest(slotDispDest1),
      .dispVj(slotDispVj1), .dispVk(slotDispVk1), .dispImmVal(slotDispImmVal1),
      .dispQjv(slotDispQjv1), .dispQj(slotDispQj1),
      .dispQkv(slotDispQkv1), .dispQk(slotDispQk1)
  );

  // ===== RS MUX (slot→FU) =====
  assign addSel0 = slotDisp0 && (slotDispKind0 == KADD);
  assign addSel1 = slotDisp1 && (slotDispKind1 == KADD);
  assign mulSel0 = slotDisp0 && (slotDispKind0 == KMUL);
  assign mulSel1 = slotDisp1 && (slotDispKind1 == KMUL);
  assign lsSel0  = slotDisp0 && (slotDispKind0 == KLS);
  assign lsSel1  = slotDisp1 && (slotDispKind1 == KLS);

  // ADD RS inputs
  // slotDispStore is repurposed as isBranch for the ADD RS
  assign addDisp       = addSel0 || addSel1;
  assign addDispIsBranch = addSel0 ? slotDispStore0 : (addSel1 ? slotDispStore1 : 1'b0);
  assign addDispImm    = addSel0 ? slotDispImm0    : (addSel1 ? slotDispImm1    : 1'b0);
  assign addDispDest   = addSel0 ? slotDispDest0   : (addSel1 ? slotDispDest1   : '0);
  assign addDispVj     = addSel0 ? slotDispVj0     : (addSel1 ? slotDispVj1     : 32'b0);
  assign addDispVk     = addSel0 ? slotDispVk0     : (addSel1 ? slotDispVk1     : 32'b0);
  assign addDispImmVal = addSel0 ? slotDispImmVal0 : (addSel1 ? slotDispImmVal1 : 32'b0);
  assign addDispQjv    = addSel0 ? slotDispQjv0    : (addSel1 ? slotDispQjv1    : 1'b0);
  assign addDispQj     = addSel0 ? slotDispQj0     : (addSel1 ? slotDispQj1     : '0);
  assign addDispQkv    = addSel0 ? slotDispQkv0    : (addSel1 ? slotDispQkv1    : 1'b0);
  assign addDispQk     = addSel0 ? slotDispQk0     : (addSel1 ? slotDispQk1     : '0);

  // MUL RS inputs
  assign mulDisp    = mulSel0 || mulSel1;
  assign mulDispDest = mulSel0 ? slotDispDest0 : (mulSel1 ? slotDispDest1 : '0);
  assign mulDispVj  = mulSel0 ? slotDispVj0   : (mulSel1 ? slotDispVj1   : 32'b0);
  assign mulDispVk  = mulSel0 ? slotDispVk0   : (mulSel1 ? slotDispVk1   : 32'b0);
  assign mulDispQjv = mulSel0 ? slotDispQjv0  : (mulSel1 ? slotDispQjv1  : 1'b0);
  assign mulDispQj  = mulSel0 ? slotDispQj0   : (mulSel1 ? slotDispQj1   : '0);
  assign mulDispQkv = mulSel0 ? slotDispQkv0  : (mulSel1 ? slotDispQkv1  : 1'b0);
  assign mulDispQk  = mulSel0 ? slotDispQk0   : (mulSel1 ? slotDispQk1   : '0);

  // LS RS inputs
  assign lsDisp      = lsSel0 || lsSel1;
  assign lsDispStore = lsSel0 ? slotDispStore0 : (lsSel1 ? slotDispStore1 : 1'b0);
  assign lsDispDest  = lsSel0 ? slotDispDest0  : (lsSel1 ? slotDispDest1  : '0);
  assign lsDispVj    = lsSel0 ? slotDispVj0    : (lsSel1 ? slotDispVj1    : 32'b0);
  assign lsDispVk    = lsSel0 ? slotDispVk0    : (lsSel1 ? slotDispVk1    : 32'b0);
  assign lsDispImmVal= lsSel0 ? slotDispImmVal0: (lsSel1 ? slotDispImmVal1: 32'b0);
  assign lsDispQjv   = lsSel0 ? slotDispQjv0   : (lsSel1 ? slotDispQjv1   : 1'b0);
  assign lsDispQj    = lsSel0 ? slotDispQj0    : (lsSel1 ? slotDispQj1    : '0);
  assign lsDispQkv   = lsSel0 ? slotDispQkv0   : (lsSel1 ? slotDispQkv1   : 1'b0);
  assign lsDispQk    = lsSel0 ? slotDispQk0    : (lsSel1 ? slotDispQk1    : '0);

  // ===== RESERVATION STATIONS =====
  rs #(.DEPTH(4), .TAGW(TAGW), .INORDER(1'b0)) rsadd(
      .clk(clk), .reset(reset), .flush(robFlush),
      .disp(addDisp), .dispStore(addDispIsBranch), .dispImm(addDispImm),
      .dispDest(addDispDest), .dispVj(addDispVj), .dispVk(addDispVk),
      .dispImmVal(addDispImmVal),
      .dispQjv(addDispQjv), .dispQj(addDispQj),
      .dispQkv(addDispQkv), .dispQk(addDispQk),
      .full(addFull),
      .cdbv(cdbv), .cdbt(cdbt), .cdbr(cdbr),
      .issueReady(addFuReady),
      .issuev(addIssueV), .issueStore(addIssueIsBranch), .issueImm(addIssueImm),
      .issueDest(addIssueDest), .issueA(addIssueA), .issueB(addIssueB),
      .issueImmVal(addIssueImmVal)
  );

  rs #(.DEPTH(3), .TAGW(TAGW), .INORDER(1'b0)) rsmul(
      .clk(clk), .reset(reset), .flush(robFlush),
      .disp(mulDisp), .dispStore(1'b0), .dispImm(1'b0),
      .dispDest(mulDispDest), .dispVj(mulDispVj), .dispVk(mulDispVk),
      .dispImmVal(32'b0),
      .dispQjv(mulDispQjv), .dispQj(mulDispQj),
      .dispQkv(mulDispQkv), .dispQk(mulDispQk),
      .full(mulFull),
      .cdbv(cdbv), .cdbt(cdbt), .cdbr(cdbr),
      .issueReady(mulFuReady),
      .issuev(mulIssueV), .issueStore(mulIssueStoreDrop),
      .issueImm(mulIssueImmDrop), .issueDest(mulIssueDest),
      .issueA(mulIssueA), .issueB(mulIssueB), .issueImmVal(mulIssueImmValDrop)
  );

  rs #(.DEPTH(4), .TAGW(TAGW), .INORDER(1'b1)) rsls(
      .clk(clk), .reset(reset), .flush(robFlush),
      .disp(lsDisp), .dispStore(lsDispStore), .dispImm(1'b1),
      .dispDest(lsDispDest), .dispVj(lsDispVj), .dispVk(lsDispVk),
      .dispImmVal(lsDispImmVal),
      .dispQjv(lsDispQjv), .dispQj(lsDispQj),
      .dispQkv(lsDispQkv), .dispQk(lsDispQk),
      .full(lsFull),
      .cdbv(cdbv), .cdbt(cdbt), .cdbr(cdbr),
      .issueReady(1'b1),
      .issuev(lsIssueV), .issueStore(lsIssueStore), .issueImm(lsIssueImmDrop),
      .issueDest(lsIssueDest), .issueA(lsIssueA), .issueB(lsIssueB),
      .issueImmVal(lsIssueImmVal)
  );

  // ===== FUNCTIONAL UNITS =====
  // ADD FU: normal add/addi OR branch equality check
  assign addRes = addIssueIsBranch  ? {31'b0, (addIssueA == addIssueB)} :
                  addIssueImm       ? (addIssueA + addIssueImmVal) :
                                      (addIssueA + addIssueB);
  assign mulRes = mulIssueA * mulIssueB;

  fu_pipe #(.LAT(4), .TAGW(TAGW)) addfu(
      .clk(clk), .reset(reset), .flush(robFlush),
      .issuev(addIssueV), .issuetag(addIssueDest), .issueres(addRes),
      .ready(addFuReady),
      .donev(addDoneV), .donetag(addDoneTag), .doneres(addDoneRes)
  );

  fu_pipe #(.LAT(6), .TAGW(TAGW)) mulfu(
      .clk(clk), .reset(reset), .flush(robFlush),
      .issuev(mulIssueV), .issuetag(mulIssueDest), .issueres(mulRes),
      .ready(mulFuReady),
      .donev(mulDoneV), .donetag(mulDoneTag), .doneres(mulDoneRes)
  );

  fu_ls #(.TAGW(TAGW)) lsfu(
      .clk(clk), .reset(reset), .flush(robFlush),
      .issuev(lsIssueV), .issueStore(lsIssueStore), .issuetag(lsIssueDest),
      .base(lsIssueA), .imm(lsIssueImmVal), .storeData(lsIssueB),
      .loadDoneV(loadDoneV), .loadDoneTag(loadDoneTag), .loadAddr(loadAddr),
      .storeDoneV(storeDoneV), .storeDoneTag(storeDoneTag),
      .storeAddr(storeDoneAddr), .storeDoneData(storeDoneData),
      .excV(lsExcV), .excTag(lsExcTag)
  );

  // ===== STORE BUFFER UPDATE =====
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      stbufValid <= 1'b0;
      stbufAddr  <= 32'b0;
      stbufData  <= 32'b0;
    end else begin
      if (robFlush) begin
        stbufValid <= 1'b0;
        stbufAddr  <= 32'b0;
        stbufData  <= 32'b0;
      end else begin
        if (storeDoneV) begin
          stbufValid <= 1'b1;
          stbufAddr  <= storeDoneAddr;
          stbufData  <= storeDoneData;
        end
        if (commitV && commitIsStore)
          stbufValid <= 1'b0;
      end
    end
  end

  // Forward store buffer data to a load that hits the same address.
  assign loadResult = (stbufValid && loadDoneV && (stbufAddr == loadAddr))
                    ? stbufData : ReadDataM;

  // ===== CDB =====
  cdb #(.TAGW(TAGW)) cdb0(
      .clk(clk), .reset(reset),
      .addv(addDoneV), .addt(addDoneTag), .addr(addDoneRes),
      .mulv(mulDoneV), .mult(mulDoneTag), .mulr(mulDoneRes),
      .ldv(loadDoneV),  .ldt(loadDoneTag),  .ldr(loadResult),
      .cdbv(cdbv), .cdbt(cdbt), .cdbr(cdbr)
  );

  // ===== MEMORY INTERFACE =====
  // Stores: write to memory at ROB commit (in-order, no speculative writes).
  // Loads:  issue address as soon as computed; ReadDataM is combinational.
  //         Store-to-load forwarding via stbuf covers the case where a store
  //         has executed but not yet committed when a younger load reads the
  //         same address.
  always_comb begin
    MemWrite    = commitV && commitIsStore;
    MemReadM    = loadDoneV && !MemWrite;
    ALUResultM  = MemWrite ? commitStoreAddr : loadAddr;
    WriteDataM  = MemWrite ? commitStoreData : 32'b0;
  end

  // ===== REGISTER FILE WRITEBACK =====
  // Write architectural state only at commit — never speculatively.
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      for (int j = 0; j < 32; j = j + 1)
        areg[j] <= 32'b0;
    end else begin
      areg[0] <= 32'b0;  // x0 always zero
      if (commitV && commitRegW && (commitRd != 5'b0))
        areg[commitRd] <= commitResult;
    end
  end

  // ===== DEBUG OUTPUTS =====
  assign iq0         = f0;
  assign iq1         = f1;
  assign dispatch0Dbg = dispatch0;
  assign dispatch1Dbg = dispatch1;
  assign cdbvDbg     = cdbv;
  assign cdbtDbg     = cdbt[2:0];  // only 3 debug bits exported
  assign wbvDbg      = commitV && commitRegW;
  assign wbtDbg      = commitTag[2:0];
  assign wbStoreDbg  = commitV && commitIsStore;
  assign storeDoneDbg = storeDoneV;

endmodule
