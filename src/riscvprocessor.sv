module riscvprocessor(
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] PCF,
    output logic        MemWrite,
    output logic [31:0] ALUResultM,
    output logic [31:0] WriteData,
    input  logic [31:0] ReadData,
    output logic        MemReadM,
    output logic        trap,
    output logic [31:0] trapPC
);

/* verilator lint_off UNUSEDSIGNAL */
  logic [31:0] iq0Tap;
  logic [31:0] iq1Tap;
  logic        dispatch0Tap;
  logic        dispatch1Tap;
  logic        cdbvTap;
  logic [2:0]  cdbtTap;
  logic        wbvTap;
  logic [2:0]  wbtTap;
  logic        wbStoreTap;
  logic        storeDoneTap;
/* verilator lint_on UNUSEDSIGNAL */

  datapath dp(
      .clk(clk),
      .reset(reset),
      .ReadDataM(ReadData),
      .PCF(PCF),
      .ALUResultM(ALUResultM),
      .WriteDataM(WriteData),
      .MemWrite(MemWrite),
      .MemReadM(MemReadM),
        .iq0(iq0Tap),
        .iq1(iq1Tap),
        .dispatch0Dbg(dispatch0Tap),
        .dispatch1Dbg(dispatch1Tap),
        .cdbvDbg(cdbvTap),
        .cdbtDbg(cdbtTap),
        .wbvDbg(wbvTap),
        .wbtDbg(wbtTap),
        .wbStoreDbg(wbStoreTap),
        .storeDoneDbg(storeDoneTap),
        .trap(trap),
        .trapPC(trapPC)
  );

endmodule
