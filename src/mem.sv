module mem(input  logic        clk,
            input  logic [31:0] pcAddrF,
            output logic [31:0] instrF,
            input  logic        memReadM,
            input  logic        memWriteM,
            input  logic [31:0] dataAddrM,
            input  logic [31:0] writeDataM,
            output logic [31:0] readDataM);

  logic [31:0] RAM[4095:0];
  logic        memAccessM;
  logic [11:0] pcWord;
  logic [11:0] dataWord;

  assign memAccessM = memReadM | memWriteM;
  assign pcWord = pcAddrF[13:2];
  assign dataWord = dataAddrM[13:2];

// synthesis translate_off
  string mem_file;
initial begin
  if (!$value$plusargs("MEM=%s", mem_file))
    mem_file = "../../tests/tomasulo01_addi_smoke.mem";
  $display("[mem] loading image: %s", mem_file);
$display("Current directory:");
  $system("pwd");
  $readmemh(mem_file, RAM);
end
// synthesis translate_on

  always_comb begin
    // During MEM-stage access, unified single-port RAM is dedicated to data path.
    instrF = 32'h00000013;
    readDataM = 32'b0;

    if (memAccessM) begin
      readDataM = RAM[dataWord];
    end else begin
      instrF = RAM[pcWord];
    end
  end

  always_ff @(posedge clk)
    if (memWriteM) RAM[dataWord] <= writeDataM;
endmodule
