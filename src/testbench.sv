module testbench();

  logic        clk;
  logic        reset;

  logic [31:0] WriteData, DataAdr;
  logic        MemWrite;
  logic [31:0] RAM [4095:0];
  logic [31:0] PCF, InstrF;
  int unsigned cycle_count;
  int unsigned max_cycles;
  string test_name;
  int debug_en;
  
  // instantiate device to be tested
  top dut(clk, reset, WriteData, DataAdr, MemWrite);

  // Expose unified memory contents as a single global for waveform debug.
  always_comb RAM = dut.mem.RAM;
  always_comb PCF = dut.PCF;
  always_comb InstrF = dut.InstrF;
  
  // initialize test
  initial
    begin
      if (!$value$plusargs("MAXCYC=%d", max_cycles))
        max_cycles = 2000;
      if (!$value$plusargs("TEST=%s", test_name))
        test_name = "unnamed";
      if (!$value$plusargs("DBG=%d", debug_en))
        debug_en = 0;

      $display("[tb] test=%s max_cycles=%0d", test_name, max_cycles);
      reset = 1; #22; reset = 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk = 1; #5; clk = 0; #5;
    end

  always @(posedge clk)
    if (!reset)
      cycle_count <= cycle_count + 1;

  initial cycle_count = 0;

  // check results
  always @(negedge clk)
    begin
      if (debug_en != 0 && !reset && cycle_count < 120) begin
        $display("DBG c=%0d PC=%08x i0=%08x i1=%08x d0=%0d d1=%0d aI=%0d aD=%0d lsI=%0d cdb=%0d t=%0d cv=%0d ct=%0d cs=%0d sd=%0d mw=%0d adr=%0d wd=%0d",
                 cycle_count,
                 dut.PCF,
                 dut.riscvprocessor.dp.iq0,
                 dut.riscvprocessor.dp.iq1,
                 dut.riscvprocessor.dp.dispatch0,
                 dut.riscvprocessor.dp.dispatch1,
                 dut.riscvprocessor.dp.addIssueV,
                 dut.riscvprocessor.dp.addDoneV,
                 dut.riscvprocessor.dp.lsIssueV,
                 dut.riscvprocessor.dp.cdbv,
                 dut.riscvprocessor.dp.cdbt,
                 dut.riscvprocessor.dp.commitv,
                 dut.riscvprocessor.dp.commitTag,
                 dut.riscvprocessor.dp.commitStore,
                 dut.riscvprocessor.dp.storeDoneV,
                 MemWrite,
                 DataAdr,
                 WriteData);
      end

      if (!reset && cycle_count > max_cycles) begin
        $display("TIMEOUT: test=%s cycles=%0d", test_name, cycle_count);
        $fatal(1);
      end

      if (MemWrite) begin
        if (DataAdr === 32'd100) begin
          $display("FINAL_SIGNATURE: DataAdr=%0d WriteData=%0d", DataAdr, WriteData);
          $stop;
        end
      end
    end
endmodule