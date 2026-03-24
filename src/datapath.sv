module datapath(input  logic        clk,
                input  logic        reset,
                input  logic [31:0] InstrF,
                output logic [31:0] PCF,
                output logic [31:0] ALUResultM,
                output logic [31:0] WriteDataM,
                input  logic [31:0] ReadDataM,
                output logic        MemWrite,
                output logic        MemReadM);

  localparam int NROB = 8;
  localparam int TAGW = $clog2(NROB);

  localparam logic [1:0] K_ADD = 2'd0;
  localparam logic [1:0] K_MUL = 2'd1;
  localparam logic [1:0] K_LS  = 2'd2;

  localparam logic [2:0] OP_ADDI = 3'd2;
  localparam logic [2:0] OP_LW   = 3'd4;
  localparam logic [2:0] OP_SW   = 3'd5;

  logic _unusedInstrF;

  logic [31:0] areg[31:0];
  int i;

  logic [31:0] iq0, iq1, iqpc0;
  logic        iqv0, iqv1;
  logic [1:0]  iqpop;

  logic [2:0] op0, op1;
  logic [1:0] k0, k1;
  logic [4:0] rs10, rs20, rd0;
  logic [4:0] rs11, rs21, rd1;
  logic [31:0] imm0, imm1;
  logic valid0, valid1, regw0, regw1;
  logic nop0, nop1;

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

  logic addIssueV, addIssueStore, addIssueImm;
  logic [TAGW-1:0] addIssueDest;
  logic [31:0] addIssueA, addIssueB, addIssueImmVal;

  logic mulIssueV, mulIssueStore, mulIssueImm;
  logic [TAGW-1:0] mulIssueDest;
  logic [31:0] mulIssueA, mulIssueB, mulIssueImmVal;

  logic lsIssueV, lsIssueStore, lsIssueImm;
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

  logic s0qjv, s0qkv;
  logic [TAGW-1:0] s0qj, s0qk;
  logic [31:0] s0vj, s0vk;

  logic s1qjv, s1qkv;
  logic [TAGW-1:0] s1qj, s1qk;
  logic [31:0] s1vj, s1vk;

  iqueue iq(clk, reset, iqpop, iq0, iq1, iqv0, iqv1, iqpc0);

  tdecode d0(iq0, op0, k0, rs10, rs20, rd0, imm0, valid0, regw0, nop0);
  tdecode d1(iq1, op1, k1, rs11, rs21, rd1, imm1, valid1, regw1, nop1);

  rat #(.TAGW(TAGW)) r0(
    clk, reset,
    rs10, rs20, rs11, rs21,
    q10v, q10t, q20v, q20t, q11v, q11t, q21v, q21t,
    rename0, rd0, robTag0,
    rename1, rd1, robTag1Eff,
    commitv && !commitStore, commitRd, commitTag
  );

  rob #(.NROB(NROB), .TAGW(TAGW)) rb0(
    clk, reset,
    robAlloc0, robAlloc0Store, rd0,
    robAlloc1, robAlloc1Store, rd1,
    robTag0, robTag1, robCanAlloc0, robCanAlloc1,
    cdbv, cdbt, cdbr,
    storeDoneV, storeDoneTag, storeDoneAddr, storeDoneData,
    commitv, commitStore, commitRd, commitVal, commitTag, commitAddr, commitData
  );

  rs #(.DEPTH(4), .TAGW(TAGW)) rsAdd(
    clk, reset,
    addDisp, 1'b0, addDispImm, addDispDest,
    addDispVj, addDispVk, addDispImmVal,
    addDispQjv, addDispQj, addDispQkv, addDispQk,
    addFull,
    cdbv, cdbt, cdbr,
    addIssueV, addIssueStore, addIssueImm, addIssueDest,
    addIssueA, addIssueB, addIssueImmVal
  );

  rs #(.DEPTH(3), .TAGW(TAGW)) rsMul(
    clk, reset,
    mulDisp, 1'b0, 1'b0, mulDispDest,
    mulDispVj, mulDispVk, 32'b0,
    mulDispQjv, mulDispQj, mulDispQkv, mulDispQk,
    mulFull,
    cdbv, cdbt, cdbr,
    mulIssueV, mulIssueStore, mulIssueImm, mulIssueDest,
    mulIssueA, mulIssueB, mulIssueImmVal
  );

  rs #(.DEPTH(3), .TAGW(TAGW), .IN_ORDER(1'b1)) rsLs(
    clk, reset,
    lsDisp, lsDispStore, 1'b1, lsDispDest,
    lsDispVj, lsDispVk, lsDispImmVal,
    lsDispQjv, lsDispQj, lsDispQkv, lsDispQk,
    lsFull,
    cdbv, cdbt, cdbr,
    lsIssueV, lsIssueStore, lsIssueImm, lsIssueDest,
    lsIssueA, lsIssueB, lsIssueImmVal
  );

  assign addRes = addIssueImm ? (addIssueA + addIssueImmVal) : (addIssueA + addIssueB);
  assign mulRes = mulIssueA * mulIssueB;

  fu_pipe #(.LAT(4), .TAGW(TAGW)) fadd(clk, reset, addIssueV, addIssueDest, addRes, addDoneV, addDoneTag, addDoneRes);
  fu_pipe #(.LAT(6), .TAGW(TAGW)) fmul(clk, reset, mulIssueV, mulIssueDest, mulRes, mulDoneV, mulDoneTag, mulDoneRes);

  fu_ls #(.TAGW(TAGW)) fls(
    clk, reset,
    lsIssueV, lsIssueStore, lsIssueDest,
    lsIssueA, lsIssueImmVal, lsIssueB,
    loadDoneV, loadDoneTag, loadAddr,
    storeDoneV, storeDoneTag, storeDoneAddr, storeDoneData
  );

  cdb #(.TAGW(TAGW)) cb0(
    addDoneV, addDoneTag, addDoneRes,
    mulDoneV, mulDoneTag, mulDoneRes,
    loadDoneV, loadDoneTag, ReadDataM,
    cdbv, cdbt, cdbr
  );

  assign _unusedInstrF = InstrF[0];

  always_comb begin
    PCF = iqpc0;

    if ((rs10 != 5'b0) && q10v) begin
      s0qjv = 1'b1;
      s0qj = q10t;
      s0vj = 32'b0;
    end else begin
      s0qjv = 1'b0;
      s0qj = '0;
      s0vj = areg[rs10];
    end

    if ((rs20 != 5'b0) && q20v && (op0 != OP_ADDI) && (op0 != OP_LW) && !nop0) begin
      s0qkv = 1'b1;
      s0qk = q20t;
      s0vk = 32'b0;
    end else begin
      s0qkv = 1'b0;
      s0qk = '0;
      s0vk = areg[rs20];
    end

    if ((rs11 != 5'b0) && q11v) begin
      s1qjv = 1'b1;
      s1qj = q11t;
      s1vj = 32'b0;
    end else begin
      s1qjv = 1'b0;
      s1qj = '0;
      s1vj = areg[rs11];
    end

    if ((rs21 != 5'b0) && q21v && (op1 != OP_ADDI) && (op1 != OP_LW) && !nop1) begin
      s1qkv = 1'b1;
      s1qk = q21t;
      s1vk = 32'b0;
    end else begin
      s1qkv = 1'b0;
      s1qk = '0;
      s1vk = areg[rs21];
    end

    if (regw0 && (rd0 != 5'b0) && !nop0 && iqv0) begin
      if (rd0 == rs11) begin
        s1qjv = 1'b1;
        s1qj = robTag0;
        s1vj = 32'b0;
      end
      if ((op1 != OP_ADDI) && (op1 != OP_LW) && !nop1 && (rd0 == rs21)) begin
        s1qkv = 1'b1;
        s1qk = robTag0;
        s1vk = 32'b0;
      end
    end

    dispatch0 = 1'b0;
    if (iqv0 && valid0) begin
      if (nop0)
        dispatch0 = 1'b1;
      else if (robCanAlloc0) begin
        case (k0)
          K_ADD: dispatch0 = !addFull;
          K_MUL: dispatch0 = !mulFull;
          K_LS:  dispatch0 = !lsFull;
          default: dispatch0 = 1'b0;
        endcase
      end
    end

    dispatch1 = 1'b0;
    // Current RS write path accepts one non-nop dispatch per cycle.
    // Allow slot1 only when slot0 is nop so instruction stream ordering is preserved.
    if (iqv1 && valid1 && dispatch0 && nop0) begin
      if (nop1)
        dispatch1 = 1'b1;
      else if (robCanAlloc1) begin
        case (k1)
          K_ADD: dispatch1 = !addFull;
          K_MUL: dispatch1 = !mulFull;
          K_LS:  dispatch1 = !lsFull;
          default: dispatch1 = 1'b0;
        endcase
      end
    end

    iqpop = 2'b00;
    if (dispatch0)
      iqpop = dispatch1 ? 2'b10 : 2'b01;

    robAlloc0 = dispatch0 && !nop0;
    robAlloc1 = dispatch1 && !nop1;
    robAlloc0Store = (op0 == OP_SW);
    robAlloc1Store = (op1 == OP_SW);

    // Slot1 can allocate by itself when slot0 is a nop.
    // In that case the allocated ROB entry is current tail (robTag0).
    robTag1Eff = robAlloc0 ? robTag1 : robTag0;

    rename0 = robAlloc0 && regw0;
    rename1 = robAlloc1 && regw1;

    addDisp = 1'b0;
    addDispImm = 1'b0;
    addDispDest = '0;
    addDispVj = 32'b0;
    addDispVk = 32'b0;
    addDispImmVal = 32'b0;
    addDispQjv = 1'b0;
    addDispQj = '0;
    addDispQkv = 1'b0;
    addDispQk = '0;

    mulDisp = 1'b0;
    mulDispDest = '0;
    mulDispVj = 32'b0;
    mulDispVk = 32'b0;
    mulDispQjv = 1'b0;
    mulDispQj = '0;
    mulDispQkv = 1'b0;
    mulDispQk = '0;

    lsDisp = 1'b0;
    lsDispStore = 1'b0;
    lsDispDest = '0;
    lsDispVj = 32'b0;
    lsDispVk = 32'b0;
    lsDispImmVal = 32'b0;
    lsDispQjv = 1'b0;
    lsDispQj = '0;
    lsDispQkv = 1'b0;
    lsDispQk = '0;

    if (robAlloc0) begin
      case (k0)
        K_ADD: begin
          addDisp = 1'b1;
          addDispImm = (op0 == OP_ADDI);
          addDispDest = robTag0;
          addDispVj = s0vj;
          addDispVk = s0vk;
          addDispImmVal = imm0;
          addDispQjv = s0qjv;
          addDispQj = s0qj;
          addDispQkv = (op0 == OP_ADDI) ? 1'b0 : s0qkv;
          addDispQk = s0qk;
        end
        K_MUL: begin
          mulDisp = 1'b1;
          mulDispDest = robTag0;
          mulDispVj = s0vj;
          mulDispVk = s0vk;
          mulDispQjv = s0qjv;
          mulDispQj = s0qj;
          mulDispQkv = s0qkv;
          mulDispQk = s0qk;
        end
        K_LS: begin
          lsDisp = 1'b1;
          lsDispStore = (op0 == OP_SW);
          lsDispDest = robTag0;
          lsDispVj = s0vj;
          lsDispVk = s0vk;
          lsDispImmVal = imm0;
          lsDispQjv = s0qjv;
          lsDispQj = s0qj;
          lsDispQkv = (op0 == OP_SW) ? s0qkv : 1'b0;
          lsDispQk = s0qk;
        end
        default: begin end
      endcase
    end else if (robAlloc1) begin
      case (k1)
        K_ADD: begin
          addDisp = 1'b1;
          addDispImm = (op1 == OP_ADDI);
          addDispDest = robTag1Eff;
          addDispVj = s1vj;
          addDispVk = s1vk;
          addDispImmVal = imm1;
          addDispQjv = s1qjv;
          addDispQj = s1qj;
          addDispQkv = (op1 == OP_ADDI) ? 1'b0 : s1qkv;
          addDispQk = s1qk;
        end
        K_MUL: begin
          mulDisp = 1'b1;
          mulDispDest = robTag1Eff;
          mulDispVj = s1vj;
          mulDispVk = s1vk;
          mulDispQjv = s1qjv;
          mulDispQj = s1qj;
          mulDispQkv = s1qkv;
          mulDispQk = s1qk;
        end
        K_LS: begin
          lsDisp = 1'b1;
          lsDispStore = (op1 == OP_SW);
          lsDispDest = robTag1Eff;
          lsDispVj = s1vj;
          lsDispVk = s1vk;
          lsDispImmVal = imm1;
          lsDispQjv = s1qjv;
          lsDispQj = s1qj;
          lsDispQkv = (op1 == OP_SW) ? s1qkv : 1'b0;
          lsDispQk = s1qk;
        end
        default: begin end
      endcase
    end

    MemReadM = loadDoneV;

    // In this simplified core, perform memory writes when LSU store completes.
    // This avoids load/read vs. commit-store write conflicts on single-port RAM.
    MemWrite = storeDoneV;
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

endmodule