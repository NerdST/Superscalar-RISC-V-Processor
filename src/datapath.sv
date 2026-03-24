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
    output logic        commitvDbg,
    output logic [2:0]  commitTagDbg,
    output logic        commitStoreDbg,
    output logic        storeDoneDbg
);

  localparam int NROB = 8;
  localparam int TAGW = $clog2(NROB);

  logic [31:0] areg[31:0];
  int i;

  logic [31:0] f0, f1;
  logic        fv0, fv1;
  logic [1:0]  iqpop;
  logic        fetchDone;

  logic [2:0] op0, op1;
  logic [1:0] k0, k1;
  logic [4:0] rs10, rs20, rd0;
  logic [4:0] rs11, rs21, rd1;
  logic [31:0] imm0, imm1;
  logic valid0, valid1, regw0, regw1, nop0, nop1;
  logic isStore0, isStore1;

  logic q10v, q20v, q11v, q21v;
  logic [TAGW-1:0] q10t, q20t, q11t, q21t;

  logic robAlloc0, robAlloc1;
  logic robAlloc0Store, robAlloc1Store;
  logic [TAGW-1:0] robTag0, robTag1;
  logic [TAGW-1:0] robTag1Eff;
  logic robCanAlloc0, robCanAlloc1;

  logic commitv, commitStore;
  logic [4:0] commitRd;
  logic [31:0] commitVal, commitAddr, commitData;
  logic [TAGW-1:0] commitTag;

  logic rename0, rename1;

  logic addFull, mulFull, lsFull;
  logic dispatch0, dispatch1;
    logic can0Haz, can1Haz, slot1SameKindBusyHaz;

  logic s0qjv, s0qkv;
  logic [TAGW-1:0] s0qj, s0qk;
  logic [31:0] s0vj, s0vk;

  logic s1qjv, s1qkv;
  logic [TAGW-1:0] s1qj, s1qk;
  logic [31:0] s1vj, s1vk;

  logic [31:0] rs10Val, rs20Val, rs11Val, rs21Val;

  logic addDisp, addDispImm;
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

  logic addIssueV, addIssueImm;
  logic [TAGW-1:0] addIssueDest;
  logic [31:0] addIssueA, addIssueB, addIssueImmVal;

  logic mulIssueV;
  logic [TAGW-1:0] mulIssueDest;
  logic [31:0] mulIssueA, mulIssueB;

  logic lsIssueV, lsIssueStore;
  logic [TAGW-1:0] lsIssueDest;
  logic [31:0] lsIssueA, lsIssueB, lsIssueImmVal;

  logic [31:0] addRes, mulRes;

  logic addDoneV, mulDoneV;
  logic [TAGW-1:0] addDoneTag, mulDoneTag;
  logic [31:0] addDoneRes, mulDoneRes;

  logic loadDoneV, storeDoneV;
  logic [TAGW-1:0] loadDoneTag, storeDoneTag;
  logic [31:0] loadAddr, storeDoneAddr, storeDoneData;

  logic cdbv;
  logic [TAGW-1:0] cdbt;
  logic [31:0] cdbr;

  logic addStoreUnused;
  logic mulStoreUnused;
  logic mulImmUnused;
  logic [31:0] mulImvUnused;
  logic lsImmUnused;
    logic addIssueStoreUnused;
    logic mulIssueStoreUnused;
    logic mulIssueImmUnused;
    logic [31:0] mulIssueImmValUnused;
    logic lsIssueImmUnused;

  logic addDisp0, addDispImm0;
  logic [TAGW-1:0] addDispDest0;
  logic [31:0] addDispVj0, addDispVk0, addDispImmVal0;
  logic addDispQjv0, addDispQkv0;
  logic [TAGW-1:0] addDispQj0, addDispQk0;

  logic mulDisp0;
  logic [TAGW-1:0] mulDispDest0;
  logic [31:0] mulDispVj0, mulDispVk0;
  logic mulDispQjv0, mulDispQkv0;
  logic [TAGW-1:0] mulDispQj0, mulDispQk0;

  logic lsDisp0, lsDispStore0;
  logic [TAGW-1:0] lsDispDest0;
  logic [31:0] lsDispVj0, lsDispVk0, lsDispImmVal0;
  logic lsDispQjv0, lsDispQkv0;
  logic [TAGW-1:0] lsDispQj0, lsDispQk0;

  logic addDisp1, addDispImm1;
  logic [TAGW-1:0] addDispDest1;
  logic [31:0] addDispVj1, addDispVk1, addDispImmVal1;
  logic addDispQjv1, addDispQkv1;
  logic [TAGW-1:0] addDispQj1, addDispQk1;

  logic mulDisp1;
  logic [TAGW-1:0] mulDispDest1;
  logic [31:0] mulDispVj1, mulDispVk1;
  logic mulDispQjv1, mulDispQkv1;
  logic [TAGW-1:0] mulDispQj1, mulDispQk1;

  logic lsDisp1, lsDispStore1;
  logic [TAGW-1:0] lsDispDest1;
  logic [31:0] lsDispVj1, lsDispVk1, lsDispImmVal1;
  logic lsDispQjv1, lsDispQkv1;
  logic [TAGW-1:0] lsDispQj1, lsDispQk1;

  ifetch fq(
      .clk(clk),
      .reset(reset),
      .pop(iqpop),
      .instr0(f0),
      .instr1(f1),
      .valid0(fv0),
      .valid1(fv1),
      .pc0(PCF),
      .done(fetchDone)
  );

  tdecode d0(.instr(f0), .op(op0), .kind(k0), .rs1(rs10), .rs2(rs20), .rd(rd0),
             .imm(imm0), .valid(valid0), .regw(regw0), .nop(nop0), .isStore(isStore0));
  tdecode d1(.instr(f1), .op(op1), .kind(k1), .rs1(rs11), .rs2(rs21), .rd(rd1),
             .imm(imm1), .valid(valid1), .regw(regw1), .nop(nop1), .isStore(isStore1));

  rat #(.TAGW(TAGW)) rat0(
      .clk(clk), .reset(reset),
      .rs10(rs10), .rs20(rs20), .rs11(rs11), .rs21(rs21),
      .q10v(q10v), .q10t(q10t), .q20v(q20v), .q20t(q20t),
      .q11v(q11v), .q11t(q11t), .q21v(q21v), .q21t(q21t),
      .rename0(rename0), .rd0(rd0), .tag0(robTag0),
      .rename1(rename1), .rd1(rd1), .tag1(robTag1Eff),
      .clearv(commitv && !commitStore), .clearrd(commitRd), .cleartag(commitTag)
  );

  rob #(.NROB(NROB), .TAGW(TAGW)) rob0(
      .clk(clk), .reset(reset),
      .alloc0(robAlloc0), .alloc0Store(robAlloc0Store), .alloc0Rd(rd0),
      .alloc1(robAlloc1), .alloc1Store(robAlloc1Store), .alloc1Rd(rd1),
      .tag0(robTag0), .tag1(robTag1), .canAlloc0(robCanAlloc0), .canAlloc1(robCanAlloc1),
      .wbv(cdbv), .wbt(cdbt), .wbval(cdbr),
      .storeDoneV(storeDoneV), .storeDoneTag(storeDoneTag),
      .storeDoneAddr(storeDoneAddr), .storeDoneData(storeDoneData),
      .commitv(commitv), .commitStore(commitStore), .commitRd(commitRd), .commitVal(commitVal),
      .commitTag(commitTag), .commitAddr(commitAddr), .commitData(commitData)
  );

  dispatchunit du0(
      .iqv0(!fetchDone), .iqv1(!fetchDone),
      .valid0(fv0 && valid0), .valid1(fv1 && valid1),
      .nop0(nop0), .nop1(nop1),
            .can0(can0Haz), .can1(can1Haz), .slot1SameKindBusy(slot1SameKindBusyHaz),
      .isStore0(isStore0), .isStore1(isStore1),
      .robCanAlloc0(robCanAlloc0), .robCanAlloc1(robCanAlloc1),
      .dispatch0(dispatch0), .dispatch1(dispatch1), .iqpop(iqpop),
      .robAlloc0(robAlloc0), .robAlloc1(robAlloc1),
        .robAlloc0Store(robAlloc0Store), .robAlloc1Store(robAlloc1Store)
  );

  assign robTag1Eff = robAlloc0 ? robTag1 : robTag0;
  assign rename0 = robAlloc0 && regw0;
  assign rename1 = robAlloc1 && regw1;

  assign rs10Val = areg[rs10];
  assign rs20Val = areg[rs20];
  assign rs11Val = areg[rs11];
  assign rs21Val = areg[rs21];

  hazard #(.TAGW(TAGW)) hz0(
      .kind0(k0),
      .kind1(k1),
      .addFull(addFull),
      .mulFull(mulFull),
      .lsFull(lsFull),
      .op0(op0),
      .op1(op1),
      .rs10(rs10),
      .rs20(rs20),
      .rs11(rs11),
      .rs21(rs21),
      .rd0(rd0),
      .nop0(nop0),
      .nop1(nop1),
      .regw0(regw0),
      .dispatch0(dispatch0),
      .q10v(q10v),
      .q10t(q10t),
      .q20v(q20v),
      .q20t(q20t),
      .q11v(q11v),
      .q11t(q11t),
      .q21v(q21v),
      .q21t(q21t),
      .robTag0(robTag0),
      .rs10Val(rs10Val),
      .rs20Val(rs20Val),
      .rs11Val(rs11Val),
      .rs21Val(rs21Val),
      .s0qjv(s0qjv),
      .s0qj(s0qj),
      .s0vj(s0vj),
      .s0qkv(s0qkv),
      .s0qk(s0qk),
      .s0vk(s0vk),
      .s1qjv(s1qjv),
      .s1qj(s1qj),
      .s1vj(s1vj),
      .s1qkv(s1qkv),
      .s1qk(s1qk),
      .s1vk(s1vk),
      .can0(can0Haz),
      .can1(can1Haz),
      .slot1SameKindBusy(slot1SameKindBusyHaz)
  );

  dispatchpack #(.TAGW(TAGW)) pack0(
      .en(robAlloc0),
      .op(op0),
      .kind(k0),
      .isStore(isStore0),
      .destTag(robTag0),
      .vj(s0vj),
      .vk(s0vk),
      .imm(imm0),
      .qjv(s0qjv),
      .qj(s0qj),
      .qkv(s0qkv),
      .qk(s0qk),
      .addDisp(addDisp0),
      .addDispImm(addDispImm0),
      .addDispDest(addDispDest0),
      .addDispVj(addDispVj0),
      .addDispVk(addDispVk0),
      .addDispImmVal(addDispImmVal0),
      .addDispQjv(addDispQjv0),
      .addDispQj(addDispQj0),
      .addDispQkv(addDispQkv0),
      .addDispQk(addDispQk0),
      .mulDisp(mulDisp0),
      .mulDispDest(mulDispDest0),
      .mulDispVj(mulDispVj0),
      .mulDispVk(mulDispVk0),
      .mulDispQjv(mulDispQjv0),
      .mulDispQj(mulDispQj0),
      .mulDispQkv(mulDispQkv0),
      .mulDispQk(mulDispQk0),
      .lsDisp(lsDisp0),
      .lsDispStore(lsDispStore0),
      .lsDispDest(lsDispDest0),
      .lsDispVj(lsDispVj0),
      .lsDispVk(lsDispVk0),
      .lsDispImmVal(lsDispImmVal0),
      .lsDispQjv(lsDispQjv0),
      .lsDispQj(lsDispQj0),
      .lsDispQkv(lsDispQkv0),
      .lsDispQk(lsDispQk0)
  );

  dispatchpack #(.TAGW(TAGW)) pack1(
      .en(robAlloc1),
      .op(op1),
      .kind(k1),
      .isStore(isStore1),
      .destTag(robTag1Eff),
      .vj(s1vj),
      .vk(s1vk),
      .imm(imm1),
      .qjv(s1qjv),
      .qj(s1qj),
      .qkv(s1qkv),
      .qk(s1qk),
      .addDisp(addDisp1),
      .addDispImm(addDispImm1),
      .addDispDest(addDispDest1),
      .addDispVj(addDispVj1),
      .addDispVk(addDispVk1),
      .addDispImmVal(addDispImmVal1),
      .addDispQjv(addDispQjv1),
      .addDispQj(addDispQj1),
      .addDispQkv(addDispQkv1),
      .addDispQk(addDispQk1),
      .mulDisp(mulDisp1),
      .mulDispDest(mulDispDest1),
      .mulDispVj(mulDispVj1),
      .mulDispVk(mulDispVk1),
      .mulDispQjv(mulDispQjv1),
      .mulDispQj(mulDispQj1),
      .mulDispQkv(mulDispQkv1),
      .mulDispQk(mulDispQk1),
      .lsDisp(lsDisp1),
      .lsDispStore(lsDispStore1),
      .lsDispDest(lsDispDest1),
      .lsDispVj(lsDispVj1),
      .lsDispVk(lsDispVk1),
      .lsDispImmVal(lsDispImmVal1),
      .lsDispQjv(lsDispQjv1),
      .lsDispQj(lsDispQj1),
      .lsDispQkv(lsDispQkv1),
      .lsDispQk(lsDispQk1)
  );

  rsarbiter #(.TAGW(TAGW)) addArb(
      .sel0(addDisp0),
      .sel1(addDisp1),
      .store0(1'b0),
      .imm0(addDispImm0),
      .dest0(addDispDest0),
      .vj0(addDispVj0),
      .vk0(addDispVk0),
      .imv0(addDispImmVal0),
      .qjv0(addDispQjv0),
      .qj0(addDispQj0),
      .qkv0(addDispQkv0),
      .qk0(addDispQk0),
      .store1(1'b0),
      .imm1(addDispImm1),
      .dest1(addDispDest1),
      .vj1(addDispVj1),
      .vk1(addDispVk1),
      .imv1(addDispImmVal1),
      .qjv1(addDispQjv1),
      .qj1(addDispQj1),
      .qkv1(addDispQkv1),
      .qk1(addDispQk1),
      .disp(addDisp),
      .store(addStoreUnused),
      .imm(addDispImm),
      .dest(addDispDest),
      .vj(addDispVj),
      .vk(addDispVk),
      .imv(addDispImmVal),
      .qjv(addDispQjv),
      .qj(addDispQj),
      .qkv(addDispQkv),
      .qk(addDispQk)
  );

  rsarbiter #(.TAGW(TAGW)) mulArb(
      .sel0(mulDisp0),
      .sel1(mulDisp1),
      .store0(1'b0),
      .imm0(1'b0),
      .dest0(mulDispDest0),
      .vj0(mulDispVj0),
      .vk0(mulDispVk0),
      .imv0(32'b0),
      .qjv0(mulDispQjv0),
      .qj0(mulDispQj0),
      .qkv0(mulDispQkv0),
      .qk0(mulDispQk0),
      .store1(1'b0),
      .imm1(1'b0),
      .dest1(mulDispDest1),
      .vj1(mulDispVj1),
      .vk1(mulDispVk1),
      .imv1(32'b0),
      .qjv1(mulDispQjv1),
      .qj1(mulDispQj1),
      .qkv1(mulDispQkv1),
      .qk1(mulDispQk1),
      .disp(mulDisp),
      .store(mulStoreUnused),
      .imm(mulImmUnused),
      .dest(mulDispDest),
      .vj(mulDispVj),
      .vk(mulDispVk),
      .imv(mulImvUnused),
      .qjv(mulDispQjv),
      .qj(mulDispQj),
      .qkv(mulDispQkv),
      .qk(mulDispQk)
  );

  rsarbiter #(.TAGW(TAGW)) lsArb(
      .sel0(lsDisp0),
      .sel1(lsDisp1),
      .store0(lsDispStore0),
      .imm0(1'b1),
      .dest0(lsDispDest0),
      .vj0(lsDispVj0),
      .vk0(lsDispVk0),
      .imv0(lsDispImmVal0),
      .qjv0(lsDispQjv0),
      .qj0(lsDispQj0),
      .qkv0(lsDispQkv0),
      .qk0(lsDispQk0),
      .store1(lsDispStore1),
      .imm1(1'b1),
      .dest1(lsDispDest1),
      .vj1(lsDispVj1),
      .vk1(lsDispVk1),
      .imv1(lsDispImmVal1),
      .qjv1(lsDispQjv1),
      .qj1(lsDispQj1),
      .qkv1(lsDispQkv1),
      .qk1(lsDispQk1),
      .disp(lsDisp),
      .store(lsDispStore),
      .imm(lsImmUnused),
      .dest(lsDispDest),
      .vj(lsDispVj),
      .vk(lsDispVk),
      .imv(lsDispImmVal),
      .qjv(lsDispQjv),
      .qj(lsDispQj),
      .qkv(lsDispQkv),
      .qk(lsDispQk)
  );

  rs #(.DEPTH(4), .TAGW(TAGW), .INORDER(1'b0)) rsadd(
      .clk(clk), .reset(reset),
      .disp(addDisp), .dispStore(1'b0), .dispImm(addDispImm), .dispDest(addDispDest),
      .dispVj(addDispVj), .dispVk(addDispVk), .dispImmVal(addDispImmVal),
      .dispQjv(addDispQjv), .dispQj(addDispQj),
      .dispQkv(addDispQkv), .dispQk(addDispQk),
      .full(addFull),
      .cdbv(cdbv), .cdbt(cdbt), .cdbr(cdbr),
      .issuev(addIssueV), .issueStore(addIssueStoreUnused), .issueImm(addIssueImm), .issueDest(addIssueDest),
      .issueA(addIssueA), .issueB(addIssueB), .issueImmVal(addIssueImmVal)
  );

  rs #(.DEPTH(3), .TAGW(TAGW), .INORDER(1'b0)) rsmul(
      .clk(clk), .reset(reset),
      .disp(mulDisp), .dispStore(1'b0), .dispImm(1'b0), .dispDest(mulDispDest),
      .dispVj(mulDispVj), .dispVk(mulDispVk),
      .dispImmVal(32'b0),
      .dispQjv(mulDispQjv), .dispQj(mulDispQj),
      .dispQkv(mulDispQkv), .dispQk(mulDispQk),
      .full(mulFull),
      .cdbv(cdbv), .cdbt(cdbt), .cdbr(cdbr),
      .issuev(mulIssueV), .issueStore(mulIssueStoreUnused), .issueImm(mulIssueImmUnused), .issueDest(mulIssueDest),
      .issueA(mulIssueA), .issueB(mulIssueB), .issueImmVal(mulIssueImmValUnused)
  );

  rs #(.DEPTH(4), .TAGW(TAGW), .INORDER(1'b1)) rsls(
      .clk(clk), .reset(reset),
      .disp(lsDisp), .dispStore(lsDispStore), .dispDest(lsDispDest),
      .dispImm(1'b1),
      .dispVj(lsDispVj), .dispVk(lsDispVk), .dispImmVal(lsDispImmVal),
      .dispQjv(lsDispQjv), .dispQj(lsDispQj),
      .dispQkv(lsDispQkv), .dispQk(lsDispQk),
      .full(lsFull),
      .cdbv(cdbv), .cdbt(cdbt), .cdbr(cdbr),
      .issuev(lsIssueV), .issueStore(lsIssueStore), .issueImm(lsIssueImmUnused), .issueDest(lsIssueDest),
      .issueA(lsIssueA), .issueB(lsIssueB), .issueImmVal(lsIssueImmVal)
  );

  assign addRes = addIssueImm ? (addIssueA + addIssueImmVal) : (addIssueA + addIssueB);
  assign mulRes = mulIssueA * mulIssueB;

  fu_pipe #(.LAT(4), .TAGW(TAGW)) addfu(
      .clk(clk), .reset(reset),
      .issuev(addIssueV), .issuetag(addIssueDest), .issueres(addRes),
      .donev(addDoneV), .donetag(addDoneTag), .doneres(addDoneRes)
  );

  fu_pipe #(.LAT(6), .TAGW(TAGW)) mulfu(
      .clk(clk), .reset(reset),
      .issuev(mulIssueV), .issuetag(mulIssueDest), .issueres(mulRes),
      .donev(mulDoneV), .donetag(mulDoneTag), .doneres(mulDoneRes)
  );

  fu_ls #(.TAGW(TAGW)) lsfu(
      .clk(clk), .reset(reset),
      .issuev(lsIssueV), .issueStore(lsIssueStore), .issuetag(lsIssueDest),
      .base(lsIssueA), .imm(lsIssueImmVal), .storeData(lsIssueB),
      .loadDoneV(loadDoneV), .loadDoneTag(loadDoneTag), .loadAddr(loadAddr),
      .storeDoneV(storeDoneV), .storeDoneTag(storeDoneTag),
      .storeAddr(storeDoneAddr), .storeDoneData(storeDoneData)
  );

  cdb #(.TAGW(TAGW)) cdb0(
      .addv(addDoneV), .addt(addDoneTag), .addr(addDoneRes),
      .mulv(mulDoneV), .mult(mulDoneTag), .mulr(mulDoneRes),
      .ldv(loadDoneV), .ldt(loadDoneTag), .ldr(ReadDataM),
      .cdbv(cdbv), .cdbt(cdbt), .cdbr(cdbr)
  );

  always_comb begin
    MemWrite = storeDoneV;
    MemReadM = loadDoneV && !MemWrite;
    ALUResultM = MemWrite ? storeDoneAddr : loadAddr;
    WriteDataM = MemWrite ? storeDoneData : 32'b0;
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      for (i = 0; i < 32; i = i + 1)
        areg[i] <= 32'b0;
    end else begin
      areg[0] <= 32'b0;
      if (commitv && !commitStore && (commitRd != 5'b0))
        areg[commitRd] <= commitVal;
    end
  end

  assign iq0 = f0;
  assign iq1 = f1;
  assign dispatch0Dbg = dispatch0;
  assign dispatch1Dbg = dispatch1;
  assign cdbvDbg = cdbv;
  assign cdbtDbg = cdbt;
  assign commitvDbg = commitv;
  assign commitTagDbg = commitTag;
  assign commitStoreDbg = commitStore;
  assign storeDoneDbg = storeDoneV;

endmodule