module riscvprocessor(input  logic        clk, reset,
             output logic [31:0] PCF,
             input  logic [31:0] InstrF,
             output logic        MemWrite,
             output logic [31:0] ALUResultM,
             output logic [31:0] WriteData,
             input  logic [31:0] ReadData,
             output logic        MemReadM);

  datapath dp(clk, reset,
              InstrF,
              PCF, ALUResultM, WriteData, ReadData,
              MemWrite, MemReadM);
endmodule