module dispatchpack #(
    parameter int TAGW = 3
)(
    input  logic            en,
    input  logic [2:0]      op,
    input  logic [1:0]      kind,
    input  logic            isStore,
    input  logic            isBranch,
    input  logic [TAGW-1:0] destTag,
    input  logic [31:0]     vj,
    input  logic [31:0]     vk,
    input  logic [31:0]     imm,
    input  logic            qjv,
    input  logic [TAGW-1:0] qj,
    input  logic            qkv,
    input  logic [TAGW-1:0] qk,
    output logic            disp,
    output logic [1:0]      dispKind,
    output logic            dispStore,
    output logic            dispImm,
    output logic [TAGW-1:0] dispDest,
    output logic [31:0]     dispVj,
    output logic [31:0]     dispVk,
    output logic [31:0]     dispImmVal,
    output logic            dispQjv,
    output logic [TAGW-1:0] dispQj,
    output logic            dispQkv,
    output logic [TAGW-1:0] dispQk
);

  localparam logic [1:0] KADD = 2'd0;
  localparam logic [1:0] KLS  = 2'd2;

  localparam logic [2:0] OPADDI = 3'd2;

  always_comb begin
    disp = 1'b0;
    dispKind = KADD;
    dispStore = 1'b0;
    dispImm = 1'b0;
    dispDest = '0;
    dispVj = 32'b0;
    dispVk = 32'b0;
    dispImmVal = 32'b0;
    dispQjv = 1'b0;
    dispQj = '0;
    dispQkv = 1'b0;
    dispQk = '0;

    if (en) begin
      disp = 1'b1;
      dispKind = kind;
      // For ADD FU: repurpose dispStore as isBranch flag (ADD RS's st[] bit)
      // For LS FU:  dispStore = isStore as before
      dispStore = (kind == KLS) ? isStore : (kind == KADD) ? isBranch : 1'b0;
      dispImm = ((kind == KADD) && (op == OPADDI)) || (kind == KLS);
      dispDest = destTag;
      dispVj = vj;
      dispVk = vk;
      dispImmVal = imm;
      dispQjv = qjv;
      dispQj = qj;
      if ((kind == KADD) && (op == OPADDI))
        dispQkv = 1'b0;
      else if ((kind == KLS) && !isStore)
        dispQkv = 1'b0;
      else
        dispQkv = qkv;
      dispQk = qk;
    end
  end

endmodule
