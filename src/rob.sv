// ReOrder Buffer
module rob #(
    parameter int NROB = 8,
    parameter int TAGW = 3
)(
    input  logic            clk,
    input  logic            reset,
    input  logic            alloc0,
    input  logic            alloc0Store,
    input  logic [4:0]      alloc0Rd,
    input  logic            alloc1,
    input  logic            alloc1Store,
    input  logic [4:0]      alloc1Rd,
    output logic [TAGW-1:0] tag0,
    output logic [TAGW-1:0] tag1,
    output logic            canAlloc0,
    output logic            canAlloc1,
    input  logic            wbv,
    input  logic [TAGW-1:0] wbt,
    input  logic [31:0]     wbval,
    input  logic            storeDoneV,
    input  logic [TAGW-1:0] storeDoneTag,
    input  logic [31:0]     storeDoneAddr,
    input  logic [31:0]     storeDoneData,
    output logic            commitv,
    output logic            commitStore,
    output logic [4:0]      commitRd,
    output logic [31:0]     commitVal,
    output logic [TAGW-1:0] commitTag,
    output logic [31:0]     commitAddr,
    output logic [31:0]     commitData
);

  localparam logic [1:0] RTREG = 2'd0;
  localparam logic [1:0] RTST  = 2'd1;

  logic busy[NROB-1:0];
  logic ready[NROB-1:0];
  logic [1:0] rtype[NROB-1:0];
  logic [4:0] rd[NROB-1:0];
  logic [31:0] val[NROB-1:0];
  logic [31:0] addr[NROB-1:0];
  logic [31:0] data[NROB-1:0];

  logic [TAGW-1:0] head;
  logic [TAGW-1:0] tail;
  logic [TAGW:0] count;
  int i;

  always_comb begin
    tag0 = tail;
    tag1 = tail + TAGW'(1);

    canAlloc0 = (count < (TAGW+1)'(NROB));
    canAlloc1 = (count + (TAGW+1)'(1) < (TAGW+1)'(NROB));

    commitTag = head;
    commitv = (count != 0) && busy[head] && ready[head];
    commitStore = commitv && (rtype[head] == RTST);
    commitRd = rd[head];
    commitVal = val[head];
    commitAddr = addr[head];
    commitData = data[head];
  end

  always_ff @(posedge clk or posedge reset) begin
    logic [TAGW-1:0] nh;
    logic [TAGW-1:0] nt;
    logic [TAGW:0] nc;

    if (reset) begin
      head <= '0;
      tail <= '0;
      count <= '0;
      for (i = 0; i < NROB; i = i + 1) begin
        busy[i] <= 1'b0;
        ready[i] <= 1'b0;
        rtype[i] <= RTREG;
        rd[i] <= 5'b0;
        val[i] <= 32'b0;
        addr[i] <= 32'b0;
        data[i] <= 32'b0;
      end
    end else begin
      nh = head;
      nt = tail;
      nc = count;

      if (wbv) begin
        ready[wbt] <= 1'b1;
        val[wbt] <= wbval;
      end

      if (storeDoneV) begin
        ready[storeDoneTag] <= 1'b1;
        addr[storeDoneTag] <= storeDoneAddr;
        data[storeDoneTag] <= storeDoneData;
      end

      if (alloc0 && canAlloc0) begin
        busy[nt] <= 1'b1;
        ready[nt] <= 1'b0;
        rtype[nt] <= alloc0Store ? RTST : RTREG;
        rd[nt] <= alloc0Rd;
        nt = nt + 1'b1;
        nc = nc + 1'b1;
      end

      if (alloc1 && canAlloc1) begin
        busy[nt] <= 1'b1;
        ready[nt] <= 1'b0;
        rtype[nt] <= alloc1Store ? RTST : RTREG;
        rd[nt] <= alloc1Rd;
        nt = nt + 1'b1;
        nc = nc + 1'b1;
      end

      if (commitv) begin
        busy[nh] <= 1'b0;
        ready[nh] <= 1'b0;
        nh = nh + 1'b1;
        nc = nc - 1'b1;
      end

      head <= nh;
      tail <= nt;
      count <= nc;
    end
  end

endmodule
