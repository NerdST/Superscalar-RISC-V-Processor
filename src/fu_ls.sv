// Functional Unit for Load/Store Instructions
module fu_ls #(
    parameter int TAGW = 3
)(
    input  logic            clk,
    input  logic            reset,
    input  logic            flush,   // pipeline flush — suppress in-flight result
    input  logic            issuev,
    input  logic            issueStore,
    input  logic [TAGW-1:0] issuetag,
    input  logic [31:0]     base,
    input  logic [31:0]     imm,
    input  logic [31:0]     storeData,
    output logic            loadDoneV,
    output logic [TAGW-1:0] loadDoneTag,
    output logic [31:0]     loadAddr,
    output logic            storeDoneV,
    output logic [TAGW-1:0] storeDoneTag,
    output logic [31:0]     storeAddr,
    output logic [31:0]     storeDoneData,
    // Precise exception: misaligned address (non-word-aligned LW/SW)
    output logic            excV,
    output logic [TAGW-1:0] excTag
);

  logic v0, st0;
  logic [TAGW-1:0] t0;
  logic [31:0] a0, d0;
  logic misaligned;

  assign misaligned = (a0[1:0] != 2'b00);

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      v0 <= 1'b0;
      st0 <= 1'b0;
      t0 <= '0;
      a0 <= 32'b0;
      d0 <= 32'b0;
      loadDoneV <= 1'b0;
      loadDoneTag <= '0;
      loadAddr <= 32'b0;
      storeDoneV <= 1'b0;
      storeDoneTag <= '0;
      storeAddr <= 32'b0;
      storeDoneData <= 32'b0;
      excV <= 1'b0;
      excTag <= '0;
    end else begin
      if (flush) begin
        v0 <= 1'b0;
        st0 <= 1'b0;
        t0 <= '0;
        a0 <= 32'b0;
        d0 <= 32'b0;
        loadDoneV <= 1'b0;
        loadDoneTag <= '0;
        loadAddr <= 32'b0;
        storeDoneV <= 1'b0;
        storeDoneTag <= '0;
        storeAddr <= 32'b0;
        storeDoneData <= 32'b0;
        excV <= 1'b0;
        excTag <= '0;
      end else begin
        loadDoneV <= 1'b0;
        storeDoneV <= 1'b0;
        excV <= 1'b0;

        if (v0) begin
          if (misaligned) begin
            // Misaligned load/store -> raise exception; suppress memory access
            excV <= 1'b1;
            excTag <= t0;
          end else if (st0) begin
            storeDoneV <= 1'b1;
            storeDoneTag <= t0;
            storeAddr <= a0;
            storeDoneData <= d0;
          end else begin
            loadDoneV <= 1'b1;
            loadDoneTag <= t0;
            loadAddr <= a0;
          end
        end

        v0 <= issuev;
        st0 <= issueStore;
        t0 <= issuetag;
        a0 <= base + imm;
        d0 <= storeData;
      end
    end
  end

endmodule
