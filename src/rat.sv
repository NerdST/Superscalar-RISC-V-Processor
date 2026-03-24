module rat #(parameter int TAGW = 3)
           (input  logic            clk,
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
            input  logic [TAGW-1:0] cleartag);

  logic            v[31:0];
  logic [TAGW-1:0] t[31:0];
  int i;

  always_comb begin
    q10v = (rs10 != 5'b0) && v[rs10];
    q20v = (rs20 != 5'b0) && v[rs20];
    q11v = (rs11 != 5'b0) && v[rs11];
    q21v = (rs21 != 5'b0) && v[rs21];

    q10t = t[rs10];
    q20t = t[rs20];
    q11t = t[rs11];
    q21t = t[rs21];
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      for (i = 0; i < 32; i = i + 1) begin
        v[i] <= 1'b0;
        t[i] <= '0;
      end
    end else begin
      if (clearv && (clearrd != 5'b0) && v[clearrd] && (t[clearrd] == cleartag))
        v[clearrd] <= 1'b0;

      if (rename0 && (rd0 != 5'b0)) begin
        v[rd0] <= 1'b1;
        t[rd0] <= tag0;
      end
      if (rename1 && (rd1 != 5'b0)) begin
        v[rd1] <= 1'b1;
        t[rd1] <= tag1;
      end
    end
  end

endmodule
