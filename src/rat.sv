// Register Alias Table
// Tracks whether an architectural register is waiting for a tagged result.
module rat #(
    parameter int TAGW = 3
)(
    input  logic            clk,
    input  logic            reset,
    input  logic [4:0]      rs10,
    input  logic [4:0]      rs20,
    input  logic [4:0]      rs11,
    input  logic [4:0]      rs21,
    output logic            q10v,
    output logic [TAGW-1:0] q10t,
    output logic            q20v,
    output logic [TAGW-1:0] q20t,
    output logic            q11v,
    output logic [TAGW-1:0] q11t,
    output logic            q21v,
    output logic [TAGW-1:0] q21t,
    input  logic            rename0,
    input  logic [4:0]      rd0,
    input  logic [TAGW-1:0] tag0,
    input  logic            rename1,
    input  logic [4:0]      rd1,
    input  logic [TAGW-1:0] tag1,
    input  logic            clearv,
    input  logic [4:0]      clearrd,
    input  logic [TAGW-1:0] cleartag,
    input  logic            flush    // pipeline flush — clear all rename state
);

  logic            renamed[31:0];
  logic [TAGW-1:0] regTag[31:0];

  always_comb begin
    q10v = (rs10 != 5'b0) && renamed[rs10];
    q20v = (rs20 != 5'b0) && renamed[rs20];
    q11v = (rs11 != 5'b0) && renamed[rs11];
    q21v = (rs21 != 5'b0) && renamed[rs21];

    q10t = regTag[rs10];
    q20t = regTag[rs20];
    q11t = regTag[rs11];
    q21t = regTag[rs21];
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      for (int j = 0; j < 32; j = j + 1) begin
        renamed[j] <= 1'b0;
        regTag[j] <= '0;
      end
    end else begin
      if (flush) begin
        for (int j = 0; j < 32; j = j + 1) begin
          renamed[j] <= 1'b0;
          regTag[j] <= '0;
        end
      end else begin
        if (clearv && (clearrd != 5'b0) && renamed[clearrd] && (regTag[clearrd] == cleartag))
          renamed[clearrd] <= 1'b0;

        if (rename0 && (rd0 != 5'b0)) begin
          renamed[rd0] <= 1'b1;
          regTag[rd0] <= tag0;
        end

        if (rename1 && (rd1 != 5'b0)) begin
          renamed[rd1] <= 1'b1;
          regTag[rd1] <= tag1;
        end
      end
    end
  end

endmodule
