module riscvprocessor(
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] PCF,
    output logic        MemWrite,
    output logic [31:0] ALUResultM,
    output logic [31:0] WriteData,
    input  logic [31:0] ReadData,
    output logic        MemReadM,
    output logic [31:0] iq0,
    output logic [31:0] iq1,
    output logic        dispatch0,
    output logic        dispatch1,
    output logic        cdbv,
    output logic [2:0]  cdbt,
    output logic        commitv,
    output logic [2:0]  commitTag,
    output logic        commitStore,
    output logic        storeDoneV
);

  datapath dp(
      .clk(clk),
      .reset(reset),
      .ReadDataM(ReadData),
      .PCF(PCF),
      .ALUResultM(ALUResultM),
      .WriteDataM(WriteData),
      .MemWrite(MemWrite),
      .MemReadM(MemReadM),
      .iq0(iq0),
      .iq1(iq1),
      .dispatch0Dbg(dispatch0),
      .dispatch1Dbg(dispatch1),
      .cdbvDbg(cdbv),
      .cdbtDbg(cdbt),
      .commitvDbg(commitv),
      .commitTagDbg(commitTag),
      .commitStoreDbg(commitStore),
      .storeDoneDbg(storeDoneV)
  );

endmodule
