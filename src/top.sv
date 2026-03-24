module top(
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] WriteDataM,
    output logic [31:0] DataAdrM,
    output logic        MemWriteM
);

  logic [31:0] PCF;
  logic [31:0] ReadDataM;
    logic [31:0] InstrUnused;
  logic        MemReadM;

  logic [31:0] iq0;
  logic [31:0] iq1;
  logic        dispatch0;
  logic        dispatch1;
  logic        cdbv;
  logic [2:0]  cdbt;
  logic        commitv;
  logic [2:0]  commitTag;
  logic        commitStore;
  logic        storeDoneV;

  riscvprocessor riscvprocessor(
      .clk(clk),
      .reset(reset),
      .PCF(PCF),
      .MemWrite(MemWriteM),
      .ALUResultM(DataAdrM),
      .WriteData(WriteDataM),
      .ReadData(ReadDataM),
      .MemReadM(MemReadM),
      .iq0(iq0),
      .iq1(iq1),
      .dispatch0(dispatch0),
      .dispatch1(dispatch1),
      .cdbv(cdbv),
      .cdbt(cdbt),
      .commitv(commitv),
      .commitTag(commitTag),
      .commitStore(commitStore),
      .storeDoneV(storeDoneV)
  );

  mem mem(
      .clk(clk),
      .pcAddrF(PCF),
      .instrF(InstrUnused),
      .memReadM(MemReadM),
      .memWriteM(MemWriteM),
      .dataAddrM(DataAdrM),
      .writeDataM(WriteDataM),
      .readDataM(ReadDataM)
  );

endmodule
