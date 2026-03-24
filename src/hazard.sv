module hazard #(
    parameter int TAGW = 3
)(
  input  logic [1:0]      kind0,
  input  logic [1:0]      kind1,
  input  logic            addFull,
  input  logic            mulFull,
  input  logic            lsFull,
    input  logic [2:0]      op0,
    input  logic [2:0]      op1,
    input  logic [4:0]      rs10,
    input  logic [4:0]      rs20,
    input  logic [4:0]      rs11,
    input  logic [4:0]      rs21,
    input  logic [4:0]      rd0,
    input  logic            nop0,
    input  logic            nop1,
    input  logic            regw0,
    input  logic            dispatch0,
    input  logic            q10v,
    input  logic [TAGW-1:0] q10t,
    input  logic            q20v,
    input  logic [TAGW-1:0] q20t,
    input  logic            q11v,
    input  logic [TAGW-1:0] q11t,
    input  logic            q21v,
    input  logic [TAGW-1:0] q21t,
    input  logic [TAGW-1:0] robTag0,
    input  logic [31:0]     rs10Val,
    input  logic [31:0]     rs20Val,
    input  logic [31:0]     rs11Val,
    input  logic [31:0]     rs21Val,
    output logic            s0qjv,
    output logic [TAGW-1:0] s0qj,
    output logic [31:0]     s0vj,
    output logic            s0qkv,
    output logic [TAGW-1:0] s0qk,
    output logic [31:0]     s0vk,
    output logic            s1qjv,
    output logic [TAGW-1:0] s1qj,
    output logic [31:0]     s1vj,
    output logic            s1qkv,
    output logic [TAGW-1:0] s1qk,
    output logic [31:0]     s1vk,
    output logic            can0,
    output logic            can1,
    output logic            slot1SameKindBusy
);

  localparam logic [1:0] KADD  = 2'd0;
  localparam logic [1:0] KMUL  = 2'd1;
  localparam logic [1:0] KLS   = 2'd2;
  localparam logic [2:0] OPADDI = 3'd2;
  localparam logic [2:0] OPLW   = 3'd4;

  always_comb begin
    case (kind0)
      KADD: can0 = !addFull;
      KMUL: can0 = !mulFull;
      KLS:  can0 = !lsFull;
      default: can0 = 1'b0;
    endcase

    case (kind1)
      KADD: can1 = !addFull;
      KMUL: can1 = !mulFull;
      KLS:  can1 = !lsFull;
      default: can1 = 1'b0;
    endcase

    slot1SameKindBusy = (kind0 == kind1);

    if ((rs10 != 5'b0) && q10v) begin
      s0qjv = 1'b1;
      s0qj = q10t;
      s0vj = 32'b0;
    end else begin
      s0qjv = 1'b0;
      s0qj = '0;
      s0vj = rs10Val;
    end

    if ((rs20 != 5'b0) && q20v && (op0 != OPADDI) && (op0 != OPLW) && !nop0) begin
      s0qkv = 1'b1;
      s0qk = q20t;
      s0vk = 32'b0;
    end else begin
      s0qkv = 1'b0;
      s0qk = '0;
      s0vk = rs20Val;
    end

    if ((rs11 != 5'b0) && q11v) begin
      s1qjv = 1'b1;
      s1qj = q11t;
      s1vj = 32'b0;
    end else begin
      s1qjv = 1'b0;
      s1qj = '0;
      s1vj = rs11Val;
    end

    if ((rs21 != 5'b0) && q21v && (op1 != OPADDI) && (op1 != OPLW) && !nop1) begin
      s1qkv = 1'b1;
      s1qk = q21t;
      s1vk = 32'b0;
    end else begin
      s1qkv = 1'b0;
      s1qk = '0;
      s1vk = rs21Val;
    end

    if (regw0 && (rd0 != 5'b0) && !nop0 && dispatch0) begin
      if (rd0 == rs11) begin
        s1qjv = 1'b1;
        s1qj = robTag0;
        s1vj = 32'b0;
      end
      if ((op1 != OPADDI) && (op1 != OPLW) && !nop1 && (rd0 == rs21)) begin
        s1qkv = 1'b1;
        s1qk = robTag0;
        s1vk = 32'b0;
      end
    end
  end

endmodule
