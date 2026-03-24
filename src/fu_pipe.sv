module fu_pipe #(
    parameter int LAT = 4,
    parameter int TAGW = 3
)(
    input  logic            clk,
    input  logic            reset,
    input  logic            issuev,
    input  logic [TAGW-1:0] issuetag,
    input  logic [31:0]     issueres,
    output logic            donev,
    output logic [TAGW-1:0] donetag,
    output logic [31:0]     doneres
);

  logic            pv[LAT-1:0];
  logic [TAGW-1:0] pt[LAT-1:0];
  logic [31:0]     pr[LAT-1:0];
  int i;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      donev <= 1'b0;
      donetag <= '0;
      doneres <= 32'b0;
      for (i = 0; i < LAT; i = i + 1) begin
        pv[i] <= 1'b0;
        pt[i] <= '0;
        pr[i] <= 32'b0;
      end
    end else begin
      donev <= 1'b0;

      for (i = LAT-1; i > 0; i = i - 1) begin
        pv[i] <= pv[i-1];
        pt[i] <= pt[i-1];
        pr[i] <= pr[i-1];
      end

      pv[0] <= issuev;
      pt[0] <= issuetag;
      pr[0] <= issueres;

      if (pv[LAT-1]) begin
        donev <= 1'b1;
        donetag <= pt[LAT-1];
        doneres <= pr[LAT-1];
      end
    end
  end

endmodule
