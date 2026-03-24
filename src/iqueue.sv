module iqueue(input  logic        clk,
							input  logic        reset,
							input  logic [1:0]  pop,
							output logic [31:0] instr0,
							output logic [31:0] instr1,
							output logic        valid0,
							output logic        valid1,
							output logic [31:0] pc0);

	localparam int QDEPTH = 1024;
	localparam int QIDXW = $clog2(QDEPTH);

	logic [31:0] prog[QDEPTH-1:0];
	logic [QIDXW-1:0] head;
	logic [QIDXW:0] head1;

// synthesis translate_off
	string mem_file;
	initial begin
		if (!$value$plusargs("MEM=%s", mem_file))
			mem_file = "../../tests/tomasulo01_addi_smoke.mem";
		$display("[iqueue] loading program image: %s", mem_file);
		$readmemh(mem_file, prog);
	end
// synthesis translate_on

	always_ff @(posedge clk or posedge reset) begin
		if (reset)
			head <= '0;
		else
			head <= head + QIDXW'(pop);
	end

	always_comb begin
		head1 = {1'b0, head} + 1'b1;

		instr0 = 32'h00000013;
		instr1 = 32'h00000013;
		valid0 = 1'b1;
		valid1 = 1'b0;

		instr0 = prog[head];
		if (head1 < (QIDXW+1)'(QDEPTH)) begin
			instr1 = prog[head1[QIDXW-1:0]];
			valid1 = 1'b1;
		end

		pc0 = {20'b0, head, 2'b00};
	end

endmodule
