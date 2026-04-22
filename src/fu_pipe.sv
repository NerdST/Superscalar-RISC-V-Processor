// Functional Unit Pipeline
module fu_pipe #(
    parameter int LAT = 4,
    parameter int TAGW = 3
)(
    input  logic            clk,
    input  logic            reset,
    input  logic            flush,   // pipeline flush — drain in-flight result
    input  logic            issuev,
    input  logic [TAGW-1:0] issuetag,
    input  logic [31:0]     issueres,
    output logic            ready,
    output logic            donev,
    output logic [TAGW-1:0] donetag,
    output logic [31:0]     doneres
);

  localparam int CW = $clog2(LAT+1);

  logic busy;
  logic [CW-1:0] cnt;
  logic [TAGW-1:0] tagReg;
  logic [31:0] resReg;

  assign ready = !busy;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      donev <= 1'b0;
      donetag <= '0;
      doneres <= 32'b0;
      busy <= 1'b0;
      cnt <= '0;
      tagReg <= '0;
      resReg <= 32'b0;
    end else begin
      if (flush) begin
        donev <= 1'b0;
        donetag <= '0;
        doneres <= 32'b0;
        busy <= 1'b0;
        cnt <= '0;
        tagReg <= '0;
        resReg <= 32'b0;
      end else begin
        donev <= 1'b0;

        if (!busy) begin
          if (issuev) begin
            busy <= 1'b1;
            cnt <= CW'(LAT);
            tagReg <= issuetag;
            resReg <= issueres;
          end
        end else if (cnt > 1) begin
          cnt <= cnt - 1'b1;
        end else begin
          busy <= 1'b0;
          cnt <= '0;
          donev <= 1'b1;
          donetag <= tagReg;
          doneres <= resReg;
        end
      end
    end
  end

endmodule
