// Reorder Buffer — 16-entry circular queue.
// Provides in-order commit of instructions that execute out-of-order.
// The ROB index IS the rename tag used throughout the pipeline.
module rob #(
    parameter int DEPTH = 16,
    parameter int TAGW  = 4   // must equal $clog2(DEPTH)
)(
    input  logic        clk,
    input  logic        reset,

    // ---- Dispatch: enqueue up to 2 per cycle ----
    input  logic            enq0v,           // slot 0 valid (non-NOP)
    input  logic [4:0]      enq0rd,
    input  logic            enq0regw,
    input  logic            enq0isStore,
    input  logic            enq0isBranch,
    input  logic [31:0]     enq0branchTarget,
    input  logic [31:0]     enq0pc,
    output logic [TAGW-1:0] enq0tag,         // allocated ROB index = rename tag

    input  logic            enq1v,           // slot 1 valid (non-NOP)
    input  logic [4:0]      enq1rd,
    input  logic            enq1regw,
    input  logic            enq1isStore,
    input  logic            enq1isBranch,
    input  logic [31:0]     enq1branchTarget,
    input  logic [31:0]     enq1pc,
    output logic [TAGW-1:0] enq1tag,

    output logic            robFull,         // <2 free entries — stall dispatch

    // ---- CDB writeback: marks arithmetic/load entries done ----
    input  logic            cdbv,
    input  logic [TAGW-1:0] cdbt,
    input  logic [31:0]     cdbr,

    // ---- Store writeback: marks store entries done, captures addr/data ----
    input  logic            storeDoneV,
    input  logic [TAGW-1:0] storeDoneTag,
    input  logic [31:0]     storeDoneAddr,
    input  logic [31:0]     storeDoneData,

    // ---- Exception writeback: marks entry done + exc (e.g. misaligned LW/SW) ----
    input  logic            excV,
    input  logic [TAGW-1:0] excTag,

    // ---- Commit outputs (one instruction retired per cycle) ----
    output logic            commitV,
    output logic [4:0]      commitRd,
    output logic [TAGW-1:0] commitTag,       // = head; used by RAT clear
    output logic [31:0]     commitResult,
    output logic            commitRegW,
    output logic            commitIsStore,
    output logic [31:0]     commitStoreAddr,
    output logic [31:0]     commitStoreData,

    // ---- Flush on branch misprediction ----
    output logic            flush,
    output logic [31:0]     flushPC,

    // ---- Trap on precise exception (fires when head.exc=1) ----
    output logic            trap,
    output logic [31:0]     trapPC
);

    typedef struct packed {
        logic        valid;
        logic        done;
        logic        exc;
        logic        isBranch;
        logic        isStore;
        logic        regw;
        logic [4:0]  rd;
        logic [31:0] result;
        logic [31:0] storeAddr;
        logic [31:0] storeData;
        logic [31:0] branchTarget;
        logic [31:0] pc;
    } rob_entry_t;

    rob_entry_t          entries[DEPTH];
    logic [TAGW-1:0]     head;
    logic [TAGW-1:0]     tail;
    logic [4:0]          count;   // 0..DEPTH

    // ---- Tag allocation: combinational ----
    // slot 1 gets tail+1 only when slot 0 also enqueues this cycle
    assign enq0tag = tail;
    assign enq1tag = enq0v ? (tail + TAGW'(1)) : tail;

    // Full when fewer than 2 entries are free
    assign robFull = (count >= 5'(DEPTH - 1));

    // ---- Commit: combinational head check ----
    always_comb begin
        commitV         = 1'b0;
        commitRd        = 5'b0;
        commitTag       = head;
        commitResult    = 32'b0;
        commitRegW      = 1'b0;
        commitIsStore   = 1'b0;
        commitStoreAddr = 32'b0;
        commitStoreData = 32'b0;
        flush           = 1'b0;
        flushPC         = 32'b0;
        trap            = 1'b0;
        trapPC          = 32'b0;

        if (entries[head].valid && entries[head].done) begin
            if (entries[head].exc) begin
                // Precise exception: older insns already committed, this one
                // and all younger ones are prevented from retiring. Signal trap.
                trap   = 1'b1;
                trapPC = entries[head].pc;
            end else begin
                commitV         = 1'b1;
                commitRd        = entries[head].rd;
                commitResult    = entries[head].result;
                commitRegW      = entries[head].regw;
                commitIsStore   = entries[head].isStore;
                commitStoreAddr = entries[head].storeAddr;
                commitStoreData = entries[head].storeData;

                // Predict not-taken; result[0]=1 means branch was actually taken
                if (entries[head].isBranch && entries[head].result[0]) begin
                    flush   = 1'b1;
                    flushPC = entries[head].branchTarget;
                end
            end
        end
    end

    // ---- Sequential state ----
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            head  <= '0;
            tail  <= '0;
            count <= '0;
            for (int k = 0; k < DEPTH; k++) begin
                entries[k].valid        <= 1'b0;
                entries[k].done         <= 1'b0;
                entries[k].exc          <= 1'b0;
                entries[k].isBranch     <= 1'b0;
                entries[k].isStore      <= 1'b0;
                entries[k].regw         <= 1'b0;
                entries[k].rd           <= 5'b0;
                entries[k].result       <= 32'b0;
                entries[k].storeAddr    <= 32'b0;
                entries[k].storeData    <= 32'b0;
                entries[k].branchTarget <= 32'b0;
                entries[k].pc           <= 32'b0;
            end
        end else begin
            if (flush) begin
                head  <= '0;
                tail  <= '0;
                count <= '0;
                for (int k = 0; k < DEPTH; k++) begin
                    entries[k].valid        <= 1'b0;
                    entries[k].done         <= 1'b0;
                    entries[k].exc          <= 1'b0;
                    entries[k].isBranch     <= 1'b0;
                    entries[k].isStore      <= 1'b0;
                    entries[k].regw         <= 1'b0;
                    entries[k].rd           <= 5'b0;
                    entries[k].result       <= 32'b0;
                    entries[k].storeAddr    <= 32'b0;
                    entries[k].storeData    <= 32'b0;
                    entries[k].branchTarget <= 32'b0;
                    entries[k].pc           <= 32'b0;
                end
            end else begin

            // ---- CDB writeback (arithmetic + load results) ----
            if (cdbv && entries[cdbt].valid && !entries[cdbt].done)
                entries[cdbt].done   <= 1'b1;
            if (cdbv && entries[cdbt].valid)
                entries[cdbt].result <= cdbr;

            // ---- Store writeback (address + data from LSU) ----
            if (storeDoneV && entries[storeDoneTag].valid && !entries[storeDoneTag].done) begin
                entries[storeDoneTag].done      <= 1'b1;
                entries[storeDoneTag].storeAddr <= storeDoneAddr;
                entries[storeDoneTag].storeData <= storeDoneData;
            end

            // ---- Exception writeback (misaligned LW/SW from LSU) ----
            if (excV && entries[excTag].valid && !entries[excTag].done) begin
                entries[excTag].done <= 1'b1;
                entries[excTag].exc  <= 1'b1;
            end

            // ---- Commit: retire head ----
            if (commitV) begin
                entries[head].valid <= 1'b0;
                head <= head + TAGW'(1);
            end

            // ---- Enqueue slot 0 ----
            if (enq0v) begin
                entries[tail].valid          <= 1'b1;
                entries[tail].done           <= (!enq0regw && !enq0isStore && !enq0isBranch);
                entries[tail].exc            <= 1'b0;
                entries[tail].isBranch       <= enq0isBranch;
                entries[tail].isStore        <= enq0isStore;
                entries[tail].regw           <= enq0regw;
                entries[tail].rd             <= enq0rd;
                entries[tail].result         <= 32'b0;
                entries[tail].storeAddr      <= 32'b0;
                entries[tail].storeData      <= 32'b0;
                entries[tail].branchTarget   <= enq0branchTarget;
                entries[tail].pc             <= enq0pc;
            end

            // ---- Enqueue slot 1 ----
            if (enq1v) begin
                entries[enq1tag].valid          <= 1'b1;
                entries[enq1tag].done           <= (!enq1regw && !enq1isStore && !enq1isBranch);
                entries[enq1tag].exc            <= 1'b0;
                entries[enq1tag].isBranch       <= enq1isBranch;
                entries[enq1tag].isStore        <= enq1isStore;
                entries[enq1tag].regw           <= enq1regw;
                entries[enq1tag].rd             <= enq1rd;
                entries[enq1tag].result         <= 32'b0;
                entries[enq1tag].storeAddr      <= 32'b0;
                entries[enq1tag].storeData      <= 32'b0;
                entries[enq1tag].branchTarget   <= enq1branchTarget;
                entries[enq1tag].pc             <= enq1pc;
            end

            // ---- Update tail ----
            if (enq0v && enq1v)
                tail <= tail + TAGW'(2);
            else if (enq0v || enq1v)
                tail <= tail + TAGW'(1);

            // ---- Update count (enq0v=>enq1v guaranteed by dispatchunit) ----
            case ({enq0v, enq1v, commitV})
                3'b001: count <= count - 5'd1;
                3'b010: count <= count + 5'd1;   // shouldn't occur
                3'b011: count <= count;
                3'b100: count <= count + 5'd1;
                3'b101: count <= count;
                3'b110: count <= count + 5'd2;
                3'b111: count <= count + 5'd1;
                default: count <= count;
            endcase
            end

        end
    end

endmodule
