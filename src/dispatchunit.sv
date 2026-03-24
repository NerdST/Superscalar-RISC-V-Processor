module dispatchunit(
    input  logic       iqv0,
    input  logic       iqv1,
    input  logic       valid0,
    input  logic       valid1,
    input  logic       nop0,
    input  logic       nop1,
    input  logic       can0,
    input  logic       can1,
    input  logic       slot1SameKindBusy,
    input  logic       isStore0,
    input  logic       isStore1,
    input  logic       robCanAlloc0,
    input  logic       robCanAlloc1,
    output logic       dispatch0,
    output logic       dispatch1,
    output logic [1:0] iqpop,
    output logic       robAlloc0,
    output logic       robAlloc1,
    output logic       robAlloc0Store,
    output logic       robAlloc1Store
);

  logic alloc0NonNop;

  always_comb begin
    dispatch0 = 1'b0;
    if (iqv0 && valid0) begin
      if (nop0)
        dispatch0 = 1'b1;
      else
        dispatch0 = robCanAlloc0 && can0;
    end

    alloc0NonNop = dispatch0 && !nop0;

    dispatch1 = 1'b0;
    if (dispatch0 && iqv1 && valid1) begin
      if (nop1)
        dispatch1 = 1'b1;
      else if (!(alloc0NonNop && slot1SameKindBusy)) begin
        if (alloc0NonNop)
          dispatch1 = robCanAlloc1 && can1;
        else
          dispatch1 = robCanAlloc0 && can1;
      end
    end

    iqpop = 2'b00;
    if (dispatch0)
      iqpop = dispatch1 ? 2'b10 : 2'b01;

    robAlloc0 = dispatch0 && !nop0;
    robAlloc1 = dispatch1 && !nop1;
    robAlloc0Store = robAlloc0 && isStore0;
    robAlloc1Store = robAlloc1 && isStore1;
  end

endmodule