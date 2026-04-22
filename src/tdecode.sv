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
    output logic        isStore,
    output logic        isBranch
);

  localparam logic [2:0] OPNOP  = 3'd0;
  localparam logic [2:0] OPADD  = 3'd1;
  localparam logic [2:0] OPADDI = 3'd2;
  localparam logic [2:0] OPMUL  = 3'd3;
  localparam logic [2:0] OPLW   = 3'd4;
  localparam logic [2:0] OPSW   = 3'd5;
  localparam logic [2:0] OPBEQ  = 3'd6;

  localparam logic [1:0] KADD = 2'd0;
  localparam logic [1:0] KMUL = 2'd1;
  localparam logic [1:0] KLS  = 2'd2;

  function automatic logic [31:0] sextI(input logic [11:0] x);
    sextI = {{20{x[11]}}, x};
  endfunction

  function automatic logic [31:0] sextS(input logic [6:0] hi, input logic [4:0] lo);
    sextS = {{20{hi[6]}}, hi, lo};
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
    isBranch = 1'b0;

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
      imm = sextI(instr[31:20]);
    end else if ((opc == 7'b0000011) && (f3 == 3'b010)) begin
      op = OPLW;
      kind = KLS;
      regw = 1'b1;
      imm = sextI(instr[31:20]);
    end else if ((opc == 7'b0100011) && (f3 == 3'b010)) begin
      op = OPSW;
      kind = KLS;
      regw = 1'b0;
      isStore = 1'b1;
      imm = sextS(instr[31:25], instr[11:7]);
    end else if ((opc == 7'b1100011) && (f3 == 3'b000)) begin
      // BEQ — routes to ADD FU which computes (rs1 == rs2) → result[0]
      op = OPBEQ;
      kind = KADD;
      regw = 1'b0;
      isBranch = 1'b1;
      rd = 5'b0;   // branches don't write a register
      // B-type immediate: sign-extended PC offset (always even, LSB=0)
      imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    end else begin
      valid = 1'b0;
      nop = 1'b1;
    end
  end

endmodule
