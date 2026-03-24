module dispatchpack #(
    parameter int TAGW = 3
)(
    input  logic            en,
    input  logic [2:0]      op,
    input  logic [1:0]      kind,
    input  logic            isStore,
    input  logic [TAGW-1:0] destTag,
    input  logic [31:0]     vj,
    input  logic [31:0]     vk,
    input  logic [31:0]     imm,
    input  logic            qjv,
    input  logic [TAGW-1:0] qj,
    input  logic            qkv,
    input  logic [TAGW-1:0] qk,
    output logic            addDisp,
    output logic            addDispImm,
    output logic [TAGW-1:0] addDispDest,
    output logic [31:0]     addDispVj,
    output logic [31:0]     addDispVk,
    output logic [31:0]     addDispImmVal,
    output logic            addDispQjv,
    output logic [TAGW-1:0] addDispQj,
    output logic            addDispQkv,
    output logic [TAGW-1:0] addDispQk,
    output logic            mulDisp,
    output logic [TAGW-1:0] mulDispDest,
    output logic [31:0]     mulDispVj,
    output logic [31:0]     mulDispVk,
    output logic            mulDispQjv,
    output logic [TAGW-1:0] mulDispQj,
    output logic            mulDispQkv,
    output logic [TAGW-1:0] mulDispQk,
    output logic            lsDisp,
    output logic            lsDispStore,
    output logic [TAGW-1:0] lsDispDest,
    output logic [31:0]     lsDispVj,
    output logic [31:0]     lsDispVk,
    output logic [31:0]     lsDispImmVal,
    output logic            lsDispQjv,
    output logic [TAGW-1:0] lsDispQj,
    output logic            lsDispQkv,
    output logic [TAGW-1:0] lsDispQk
);

  localparam logic [1:0] KADD = 2'd0;
  localparam logic [1:0] KMUL = 2'd1;
  localparam logic [1:0] KLS  = 2'd2;

  localparam logic [2:0] OPADDI = 3'd2;

  always_comb begin
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

    if (en) begin
      case (kind)
        KADD: begin
          addDisp = 1'b1;
          addDispImm = (op == OPADDI);
          addDispDest = destTag;
          addDispVj = vj;
          addDispVk = vk;
          addDispImmVal = imm;
          addDispQjv = qjv;
          addDispQj = qj;
          addDispQkv = (op == OPADDI) ? 1'b0 : qkv;
          addDispQk = qk;
        end
        KMUL: begin
          mulDisp = 1'b1;
          mulDispDest = destTag;
          mulDispVj = vj;
          mulDispVk = vk;
          mulDispQjv = qjv;
          mulDispQj = qj;
          mulDispQkv = qkv;
          mulDispQk = qk;
        end
        KLS: begin
          lsDisp = 1'b1;
          lsDispStore = isStore;
          lsDispDest = destTag;
          lsDispVj = vj;
          lsDispVk = vk;
          lsDispImmVal = imm;
          lsDispQjv = qjv;
          lsDispQj = qj;
          lsDispQkv = isStore ? qkv : 1'b0;
          lsDispQk = qk;
        end
        default: begin end
      endcase
    end
  end

endmodule
