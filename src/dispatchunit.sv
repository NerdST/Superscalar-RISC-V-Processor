module dispatchunit(
    input  logic       flush,   // suppress all dispatch during redirect cycle
    input  logic       iqv0,
    input  logic       iqv1,
    input  logic       valid0,
    input  logic       valid1,
    input  logic       nop0,
    input  logic       nop1,
    input  logic       can0,
    input  logic       can1,
    input  logic       slot1SameKindBusy,
    output logic       dispatch0,
    output logic       dispatch1,
    output logic [1:0] iqpop
);

  logic alloc0NonNop;

  always_comb begin
    dispatch0    = 1'b0;
    dispatch1    = 1'b0;
    iqpop        = 2'b00;
    alloc0NonNop = 1'b0;

    if (!flush) begin
      if (iqv0 && valid0) begin
        if (nop0)
          dispatch0 = 1'b1;
        else
          dispatch0 = can0;
      end

      alloc0NonNop = dispatch0 && !nop0;

      if (dispatch0 && iqv1 && valid1) begin
        if (nop1)
          dispatch1 = 1'b1;
        else if (!(alloc0NonNop && slot1SameKindBusy))
          dispatch1 = can1;
      end

      if (dispatch0)
        iqpop = dispatch1 ? 2'b10 : 2'b01;
    end
  end

endmodule