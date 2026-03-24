module regfile(
		input  logic        clk,
		input  logic        we,
		input  logic [4:0]  wa,
		input  logic [31:0] wd,
		input  logic [4:0]  ra1,
		input  logic [4:0]  ra2,
		output logic [31:0] rd1,
		output logic [31:0] rd2
);

	logic [31:0] rf[31:0];

	always_ff @(posedge clk) begin
		if (we && (wa != 5'b0))
			rf[wa] <= wd;
		rf[0] <= 32'b0;
	end

	assign rd1 = (ra1 == 5'b0) ? 32'b0 : rf[ra1];
	assign rd2 = (ra2 == 5'b0) ? 32'b0 : rf[ra2];

endmodule