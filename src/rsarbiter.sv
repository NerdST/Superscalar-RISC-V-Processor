module rsarbiter #(
    parameter int TAGW = 3
)(
    input  logic            sel0,
    input  logic            sel1,
    input  logic            store0,
    input  logic            imm0,
    input  logic [TAGW-1:0] dest0,
    input  logic [31:0]     vj0,
    input  logic [31:0]     vk0,
    input  logic [31:0]     imv0,
    input  logic            qjv0,
    input  logic [TAGW-1:0] qj0,
    input  logic            qkv0,
    input  logic [TAGW-1:0] qk0,
    input  logic            store1,
    input  logic            imm1,
    input  logic [TAGW-1:0] dest1,
    input  logic [31:0]     vj1,
    input  logic [31:0]     vk1,
    input  logic [31:0]     imv1,
    input  logic            qjv1,
    input  logic [TAGW-1:0] qj1,
    input  logic            qkv1,
    input  logic [TAGW-1:0] qk1,
    output logic            disp,
    output logic            store,
    output logic            imm,
    output logic [TAGW-1:0] dest,
    output logic [31:0]     vj,
    output logic [31:0]     vk,
    output logic [31:0]     imv,
    output logic            qjv,
    output logic [TAGW-1:0] qj,
    output logic            qkv,
    output logic [TAGW-1:0] qk
);

  always_comb begin
    disp = sel0 | sel1;

    store = 1'b0;
    imm = 1'b0;
    dest = '0;
    vj = 32'b0;
    vk = 32'b0;
    imv = 32'b0;
    qjv = 1'b0;
    qj = '0;
    qkv = 1'b0;
    qk = '0;

    if (sel0) begin
      store = store0;
      imm = imm0;
      dest = dest0;
      vj = vj0;
      vk = vk0;
      imv = imv0;
      qjv = qjv0;
      qj = qj0;
      qkv = qkv0;
      qk = qk0;
    end else if (sel1) begin
      store = store1;
      imm = imm1;
      dest = dest1;
      vj = vj1;
      vk = vk1;
      imv = imv1;
      qjv = qjv1;
      qj = qj1;
      qkv = qkv1;
      qk = qk1;
    end
  end

endmodule
