module tdecode(input  logic [31:0] instr,
               output logic [2:0]  op,
               output logic [1:0]  kind,
               output logic [4:0]  rs1,
               output logic [4:0]  rs2,
               output logic [4:0]  rd,
               output logic [31:0] imm,
               output logic        valid,
               output logic        regw,
               output logic        nop);

  localparam logic [2:0] OP_NOP  = 3'd0;
  localparam logic [2:0] OP_ADD  = 3'd1;
  localparam logic [2:0] OP_ADDI = 3'd2;
  localparam logic [2:0] OP_MUL  = 3'd3;
  localparam logic [2:0] OP_LW   = 3'd4;
  localparam logic [2:0] OP_SW   = 3'd5;

  localparam logic [1:0] K_ADD = 2'd0;
  localparam logic [1:0] K_MUL = 2'd1;
  localparam logic [1:0] K_LS  = 2'd2;

  function automatic logic [31:0] sextI(input logic [31:0] i);
    sextI = {{20{i[31]}}, i[31:20]};
  endfunction

  function automatic logic [31:0] sextS(input logic [31:0] i);
    sextS = {{20{i[31]}}, i[31:25], i[11:7]};
  endfunction

  logic [6:0] opc;
  logic [2:0] f3;
  logic [6:0] f7;

  always_comb begin
    opc = instr[6:0];
    f3 = instr[14:12];
    f7 = instr[31:25];

    rs1 = instr[19:15];
    rs2 = instr[24:20];
    rd = instr[11:7];

    op = OP_NOP;
    kind = K_ADD;
    imm = 32'b0;
    valid = 1'b1;
    regw = 1'b0;
    nop = 1'b0;

    if (instr == 32'h00000013) begin
      nop = 1'b1;
    end else if ((opc == 7'b0110011) && (f3 == 3'b000) && (f7 == 7'b0000000)) begin
      op = OP_ADD;
      kind = K_ADD;
      regw = 1'b1;
    end else if ((opc == 7'b0110011) && (f3 == 3'b000) && (f7 == 7'b0000001)) begin
      op = OP_MUL;
      kind = K_MUL;
      regw = 1'b1;
    end else if ((opc == 7'b0010011) && (f3 == 3'b000)) begin
      op = OP_ADDI;
      kind = K_ADD;
      regw = 1'b1;
      imm = sextI(instr);
    end else if ((opc == 7'b0000011) && (f3 == 3'b010)) begin
      op = OP_LW;
      kind = K_LS;
      regw = 1'b1;
      imm = sextI(instr);
    end else if ((opc == 7'b0100011) && (f3 == 3'b010)) begin
      op = OP_SW;
      kind = K_LS;
      regw = 1'b0;
      imm = sextS(instr);
    end else begin
      nop = 1'b1;
    end
  end

endmodule
