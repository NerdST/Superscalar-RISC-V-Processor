// Reservation Station
module rs #(
    parameter int DEPTH = 4,
    parameter int TAGW = 3,
    parameter bit INORDER = 1'b0
)(
    input  logic            clk,
    input  logic            reset,
    input  logic            flush,   // pipeline flush — clear all entries
    input  logic            disp,
    input  logic            dispStore,
    input  logic            dispImm,
    input  logic [TAGW-1:0] dispDest,
    input  logic [31:0]     dispVj,
    input  logic [31:0]     dispVk,
    input  logic [31:0]     dispImmVal,
    input  logic            dispQjv,
    input  logic [TAGW-1:0] dispQj,
    input  logic            dispQkv,
    input  logic [TAGW-1:0] dispQk,
    output logic            full,
    input  logic            cdbv,
    input  logic [TAGW-1:0] cdbt,
    input  logic [31:0]     cdbr,
    input  logic            issueReady,
    output logic            issuev,
    output logic            issueStore,
    output logic            issueImm,
    output logic [TAGW-1:0] issueDest,
    output logic [31:0]     issueA,
    output logic [31:0]     issueB,
    output logic [31:0]     issueImmVal
);

  logic busy[DEPTH-1:0];
  logic st[DEPTH-1:0];
  logic imm[DEPTH-1:0];
  logic [TAGW-1:0] dest[DEPTH-1:0];
  logic [31:0] vj[DEPTH-1:0], vk[DEPTH-1:0], imv[DEPTH-1:0];
  logic qjv[DEPTH-1:0], qkv[DEPTH-1:0];
  logic [TAGW-1:0] qj[DEPTH-1:0], qk[DEPTH-1:0];

  int ic;
  int freei;
  int issuei;

  always_comb begin
    full = 1'b1;
    freei = -1;
    issuev = 1'b0;
    issuei = -1;
    issueStore = 1'b0;
    issueImm = 1'b0;
    issueDest = '0;
    issueA = 32'b0;
    issueB = 32'b0;
    issueImmVal = 32'b0;

    for (ic = 0; ic < DEPTH; ic = ic + 1)
      if (!busy[ic] && (freei < 0))
        freei = ic;

    if (INORDER) begin
      // In-order stations issue from the oldest busy entry only.
      for (ic = 0; ic < DEPTH; ic = ic + 1) begin
        if (busy[ic] && (issuei < 0)) begin
          issuei = ic;
          if (!qjv[ic] && !qkv[ic] && issueReady) begin
            issuev = 1'b1;
            issueStore = st[ic];
            issueImm = imm[ic];
            issueDest = dest[ic];
            issueA = vj[ic];
            issueB = vk[ic];
            issueImmVal = imv[ic];
          end
        end
      end
    end else begin
      for (ic = 0; ic < DEPTH; ic = ic + 1)
        if (busy[ic] && !qjv[ic] && !qkv[ic] && issueReady && !issuev) begin
          issuev = 1'b1;
          issuei = ic;
        end
    end

    full = (freei < 0);

    if (issuev) begin
      issueStore = st[issuei];
      issueImm = imm[issuei];
      issueDest = dest[issuei];
      issueA = vj[issuei];
      issueB = vk[issuei];
      issueImmVal = imv[issuei];
    end
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      for (int j = 0; j < DEPTH; j = j + 1) begin
        busy[j] <= 1'b0;
        st[j] <= 1'b0;
        imm[j] <= 1'b0;
        dest[j] <= '0;
        vj[j] <= 32'b0;
        vk[j] <= 32'b0;
        imv[j] <= 32'b0;
        qjv[j] <= 1'b0;
        qkv[j] <= 1'b0;
        qj[j] <= '0;
        qk[j] <= '0;
      end
    end else begin
      if (flush) begin
        for (int j = 0; j < DEPTH; j = j + 1) begin
          busy[j] <= 1'b0;
          st[j] <= 1'b0;
          imm[j] <= 1'b0;
          dest[j] <= '0;
          vj[j] <= 32'b0;
          vk[j] <= 32'b0;
          imv[j] <= 32'b0;
          qjv[j] <= 1'b0;
          qkv[j] <= 1'b0;
          qj[j] <= '0;
          qk[j] <= '0;
        end
      end else begin
        if (cdbv) begin
          for (int j = 0; j < DEPTH; j = j + 1) begin
            if (busy[j] && qjv[j] && (qj[j] == cdbt)) begin
              qjv[j] <= 1'b0;
              vj[j] <= cdbr;
            end
            if (busy[j] && qkv[j] && (qk[j] == cdbt)) begin
              qkv[j] <= 1'b0;
              vk[j] <= cdbr;
            end
          end
        end

        if (issuev)
          busy[issuei] <= 1'b0;

        if (disp && !full) begin
          busy[freei] <= 1'b1;
          st[freei] <= dispStore;
          imm[freei] <= dispImm;
          dest[freei] <= dispDest;
          vj[freei] <= dispVj;
          vk[freei] <= dispVk;
          imv[freei] <= dispImmVal;
          qjv[freei] <= dispQjv;
          qkv[freei] <= dispQkv;
          qj[freei] <= dispQj;
          qk[freei] <= dispQk;
        end
      end
    end
  end

endmodule
