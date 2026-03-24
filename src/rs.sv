module rs #(parameter int DEPTH = 4,
            parameter int TAGW = 3,
            parameter bit IN_ORDER = 1'b0)
          (input  logic            clk,
           input  logic            reset,
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
           output logic            issuev,
           output logic            issueStore,
           output logic            issueImm,
           output logic [TAGW-1:0] issueDest,
           output logic [31:0]     issueA,
           output logic [31:0]     issueB,
           output logic [31:0]     issueImmVal);

  logic busy[DEPTH-1:0];
  logic st[DEPTH-1:0];
  logic imm[DEPTH-1:0];
  logic [TAGW-1:0] dest[DEPTH-1:0];
  logic [31:0] vj[DEPTH-1:0], vk[DEPTH-1:0], imv[DEPTH-1:0];
  logic qjv[DEPTH-1:0], qkv[DEPTH-1:0];
  logic [TAGW-1:0] qj[DEPTH-1:0], qk[DEPTH-1:0];

  int ic;
  int is;
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

    for (ic = 0; ic < DEPTH; ic = ic + 1) begin
      if (!busy[ic] && (freei < 0))
        freei = ic;
    end

    if (IN_ORDER) begin
      for (ic = 0; ic < DEPTH; ic = ic + 1) begin
        if (busy[ic] && (issuei < 0)) begin
          issuei = ic;
          if (!qjv[ic] && !qkv[ic])
            issuev = 1'b1;
        end
      end
    end else begin
      for (ic = 0; ic < DEPTH; ic = ic + 1) begin
        if (busy[ic] && !qjv[ic] && !qkv[ic] && !issuev) begin
          issuev = 1'b1;
          issuei = ic;
        end
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
      for (is = 0; is < DEPTH; is = is + 1) begin
        busy[is] <= 1'b0;
        st[is] <= 1'b0;
        imm[is] <= 1'b0;
        dest[is] <= '0;
        vj[is] <= 32'b0;
        vk[is] <= 32'b0;
        imv[is] <= 32'b0;
        qjv[is] <= 1'b0;
        qkv[is] <= 1'b0;
        qj[is] <= '0;
        qk[is] <= '0;
      end
    end else begin
      if (cdbv) begin
        for (is = 0; is < DEPTH; is = is + 1) begin
          if (busy[is] && qjv[is] && (qj[is] == cdbt)) begin
            qjv[is] <= 1'b0;
            vj[is] <= cdbr;
          end
          if (busy[is] && qkv[is] && (qk[is] == cdbt)) begin
            qkv[is] <= 1'b0;
            vk[is] <= cdbr;
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

endmodule
