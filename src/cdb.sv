// Common Data Bus
module cdb #(
    parameter int TAGW = 3
)(
    input  logic                    clk,
    input  logic                    reset,
    input  logic                    addv,
    input  logic [TAGW-1:0]         addt,
    input  logic [31:0]             addr,
    input  logic                    mulv,
    input  logic [TAGW-1:0]         mult,
    input  logic [31:0]             mulr,
    input  logic            ldv,
    input  logic [TAGW-1:0] ldt,
    input  logic [31:0]     ldr,
    output logic            cdbv,
    output logic [TAGW-1:0] cdbt,
    output logic [31:0]     cdbr
);

  logic [1:0] rrPtr;
  logic [1:0] sel;
  logic found;

  always_comb begin
    cdbv = 1'b0;
    cdbt = '0;
    cdbr = 32'b0;
    found = 1'b0;
    sel = rrPtr;

    for (int off = 0; off < 3; off = off + 1) begin
      logic [1:0] idx;
      idx = rrPtr + off[1:0];
      if (idx >= 3)
        idx = idx - 3;

      if (!found) begin
        if ((idx == 2'd0) && addv) begin
          found = 1'b1;
          sel = idx;
        end else if ((idx == 2'd1) && mulv) begin
          found = 1'b1;
          sel = idx;
        end else if ((idx == 2'd2) && ldv) begin
          found = 1'b1;
          sel = idx;
        end
      end
    end

    if (found) begin
      cdbv = 1'b1;
      case (sel)
        2'd0: begin cdbt = addt; cdbr = addr; end
        2'd1: begin cdbt = mult; cdbr = mulr; end
        default: begin cdbt = ldt; cdbr = ldr; end
      endcase
    end
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      rrPtr <= 2'd0;
    else if (cdbv) begin
      if (sel == 2'd2)
        rrPtr <= 2'd0;
      else
        rrPtr <= sel + 2'd1;
    end
  end

endmodule