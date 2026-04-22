module testbench();

/* verilator lint_off BLKSEQ */
/* verilator lint_off SYNCASYNCNET */

  logic clk;
  logic reset;

  logic [31:0] WriteData;
  logic [31:0] DataAdr;
  logic        MemWrite;
  logic        trap;
  logic [31:0] trapPC;
  int unsigned cycle_count;
  int unsigned max_cycles;
  string test_name;
  int debug_en;

  top dut(
      .clk(clk),
      .reset(reset),
      .WriteDataM(WriteData),
      .DataAdrM(DataAdr),
      .MemWriteM(MemWrite),
      .trap(trap),
      .trapPC(trapPC)
  );

  initial begin
    if (!$value$plusargs("MAXCYC=%d", max_cycles))
      max_cycles = 3000;
    if (!$value$plusargs("TEST=%s", test_name))
      test_name = "unnamed";
    if (!$value$plusargs("DBG=%d", debug_en))
      debug_en = 0;

    $display("[tb] test=%s max_cycles=%0d", test_name, max_cycles);
    reset = 1'b1;
    #22;
    reset = 1'b0;
  end

  always begin
    clk = 1'b1;
    #5;
    clk = 1'b0;
    #5;
  end

  initial cycle_count = 0;
  always @(posedge clk)
    if (!reset)
      cycle_count <= cycle_count + 1;

  always @(negedge clk) begin
    if (debug_en != 0 && !reset && cycle_count < 180) begin
      $display("DBG c=%0d PC=%08x i0=%08x i1=%08x d0=%0d d1=%0d cdb=%0d t=%0d wbv=%0d wbt=%0d wbs=%0d sd=%0d mw=%0d adr=%0d wd=%0d",
               cycle_count,
               dut.riscvprocessor.PCF,
             dut.riscvprocessor.dp.iq0,
             dut.riscvprocessor.dp.iq1,
             dut.riscvprocessor.dp.dispatch0Dbg,
             dut.riscvprocessor.dp.dispatch1Dbg,
             dut.riscvprocessor.dp.cdbvDbg,
             dut.riscvprocessor.dp.cdbtDbg,
             dut.riscvprocessor.dp.wbvDbg,
             dut.riscvprocessor.dp.wbtDbg,
             dut.riscvprocessor.dp.wbStoreDbg,
             dut.riscvprocessor.dp.storeDoneDbg,
               MemWrite,
               DataAdr,
               WriteData);
    end

    if (!reset && cycle_count > max_cycles) begin
      $display("TIMEOUT: test=%s cycles=%0d", test_name, cycle_count);
      $fatal(1);
    end

    if (MemWrite && (DataAdr === 32'd100)) begin
      $display("FINAL_SIGNATURE: DataAdr=%0d WriteData=%0d", DataAdr, WriteData);
      $stop;
    end

    if (trap) begin
      $display("TRAP_SIGNATURE: trapPC=%0d", trapPC);
      $stop;
    end
  end

endmodule

/* verilator lint_on SYNCASYNCNET */
/* verilator lint_on BLKSEQ */
