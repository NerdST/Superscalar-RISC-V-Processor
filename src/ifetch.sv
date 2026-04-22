module ifetch(
        input  logic        clk,
        input  logic        reset,
        input  logic        flush,    // redirect to flushPC on misprediction
        input  logic [31:0] flushPC,
        input  logic [1:0]  pop,
        output logic [31:0] instr0,
        output logic [31:0] instr1,
        output logic        valid0,
        output logic        valid1,
        output logic [31:0] pc0,
        output logic        done
);

    localparam int QDEPTH = 1024;
    localparam int QW = $clog2(QDEPTH);

    logic [31:0] prog[QDEPTH-1:0];
    logic [QW-1:0] head;
    logic [QW:0] head1;
    logic [QW:0] proglen;
    int unsigned proglenArg;

// synthesis translate_off
    string mem_file;
    initial begin
        if (!$value$plusargs("MEM=%s", mem_file))
            mem_file = "../../tests/tomasulo01_addi_smoke.mem";
        if (!$value$plusargs("PROGLEN=%d", proglenArg))
            proglenArg = 64;
        if (proglenArg > QDEPTH)
            proglen = (QW+1)'(QDEPTH);
        else
            proglen = (QW+1)'(proglenArg);
        $display("[ifetch] loading program image: %s", mem_file);
        $readmemh(mem_file, prog);
    end
// synthesis translate_on

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            head <= '0;
        else if (flush)
            head <= flushPC[QW+1:2];  // byte addr → word index
        else
            head <= head + QW'(pop);
    end

    always_comb begin
        head1 = {1'b0, head} + 1'b1;

        instr0 = 32'h00000013;
        instr1 = 32'h00000013;
        valid0 = ({1'b0, head} < proglen);
        valid1 = (head1 < proglen);
        done = !valid0;

        if (valid0)
            instr0 = prog[head];
        if (valid1)
            instr1 = prog[head1[QW-1:0]];

        pc0 = {20'b0, head, 2'b00};
    end

endmodule
