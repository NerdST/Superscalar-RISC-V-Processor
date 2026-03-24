module cdb #(parameter int TAGW = 3)
           (input  logic            addv,
            input  logic [TAGW-1:0] addt,
            input  logic [31:0]     addr,
            input  logic            mulv,
            input  logic [TAGW-1:0] mult,
            input  logic [31:0]     mulr,
            input  logic            ldv,
            input  logic [TAGW-1:0] ldt,
            input  logic [31:0]     ldr,
            output logic            cdbv,
            output logic [TAGW-1:0] cdbt,
            output logic [31:0]     cdbr);

  always_comb begin
    cdbv = 1'b0;
    cdbt = '0;
    cdbr = 32'b0;

    if (addv) begin
      cdbv = 1'b1;
      cdbt = addt;
      cdbr = addr;
    end else if (mulv) begin
      cdbv = 1'b1;
      cdbt = mult;
      cdbr = mulr;
    end else if (ldv) begin
      cdbv = 1'b1;
      cdbt = ldt;
      cdbr = ldr;
    end
  end

endmodule
