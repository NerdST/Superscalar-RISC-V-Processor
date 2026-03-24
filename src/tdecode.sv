module tdecode(
    input  logic [31:0] instr,
    output logic [2:0]  op,
    output logic [1:0]  kind,
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,
    output logic [31:0] imm,
    output logic        valid,
    output logic        regw,
    output logic        nop,
    output logic        isStore
);

  localparam logic [2:0] OPNOP  = 3'd0;
  localparam logic [2:0] OPADD  = 3'd1;
  localparam logic [2:0] OPADDI = 3'd2;
  localparam logic [2:0] OPMUL  = 3'd3;
  localparam logic [2:0] OPLW   = 3'd4;
  localparam logic [2:0] OPSW   = 3'd5;

  localparam logic [1:0] KADD = 2'd0;
  localparam logic [1:0] KMUL = 2'd1;
  localparam logic [1:0] KLS  = 2'd2;

  function automatic logic [31:0] sextI(input logic [31:0] x);
    sextI = {{20{x[31]}}, x[31:20]};
  endfunction

  function automatic logic [31:0] sextS(input logic [31:0] x);
    sextS = {{20{x[31]}}, x[31:25], x[11:7]};
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

    op = OPNOP;
    kind = KADD;
    imm = 32'b0;
    valid = 1'b1;
    regw = 1'b0;
    nop = 1'b0;
    isStore = 1'b0;

    if (instr == 32'h00000013) begin
      nop = 1'b1;
    end else if ((opc == 7'b0110011) && (f3 == 3'b000) && (f7 == 7'b0000000)) begin
      op = OPADD;
      kind = KADD;
      regw = 1'b1;
    end else if ((opc == 7'b0110011) && (f3 == 3'b000) && (f7 == 7'b0000001)) begin
      op = OPMUL;
      kind = KMUL;
      regw = 1'b1;
    end else if ((opc == 7'b0010011) && (f3 == 3'b000)) begin
      op = OPADDI;
      kind = KADD;
      regw = 1'b1;
      imm = sextI(instr);
    end else if ((opc == 7'b0000011) && (f3 == 3'b010)) begin
      op = OPLW;
      kind = KLS;
      regw = 1'b1;
      imm = sextI(instr);
    end else if ((opc == 7'b0100011) && (f3 == 3'b010)) begin
      op = OPSW;
      kind = KLS;
      regw = 1'b0;
      isStore = 1'b1;
      imm = sextS(instr);
    end else begin
      valid = 1'b0;
      nop = 1'b1;
    end
  end

endmodule
