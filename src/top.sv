module top(
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] WriteDataM,
    output logic [31:0] DataAdrM,
    output logic        MemWriteM,
    output logic        trap,
    output logic [31:0] trapPC
);

  logic [31:0] PCF;
  logic [31:0] ReadDataM;
  logic        MemReadM;
  logic [31:0] instrTap;

  riscvprocessor riscvprocessor(
      .clk(clk),
      .reset(reset),
      .PCF(PCF),
      .MemWrite(MemWriteM),
      .ALUResultM(DataAdrM),
      .WriteData(WriteDataM),
      .ReadData(ReadDataM),
        .MemReadM(MemReadM),
      .trap(trap),
      .trapPC(trapPC)
  );

  mem mem(
      .clk(clk),
      .pcAddrF(PCF),
      .instrF(instrTap),
      .memReadM(MemReadM),
      .memWriteM(MemWriteM),
      .dataAddrM(DataAdrM),
      .writeDataM(WriteDataM),
      .readDataM(ReadDataM)
  );

endmodule
