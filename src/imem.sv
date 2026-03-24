/*** THIS MODULE IS NOW OBSELETE ***/

module imem(input  logic [31:0] a,
            output logic [31:0] rd);

  logic [31:0] RAM[63:0];
  string imem_file;

  // synthesis translate_off
  initial begin
    if (!$value$plusargs("IMEM=%s", imem_file))
      imem_file = "/mnt/shared/sangeeth/Documents/RPI/Semester8/ECSE-4780/projects/project2/tests/riscvtest01_addi_smoke.mem";
    $display("[imem] loading program: %s", imem_file);
    $readmemh(imem_file, RAM);
  end
  // synthesis translate_on

  assign rd = RAM[a[31:2]]; // word aligned
endmodule