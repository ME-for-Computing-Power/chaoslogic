module ref_model (
    input         clk_in,         // Write clock
    input         clk_out,        // Read clock
    input         rst_n,          // Async reset (active low)
    input         fifo_w_enable,  // Write enable
    input         fifo_r_enable,  // Read enable
    input  [139:0] data_to_fifo,   // Write data
    output [139:0] data_from_fifo, // Read data
    output        fifo_empty,     // Empty flag
    output        fifo_full       // Full flag
);

// Pointers (2-bit for depth 2)
reg [1:0] wptr_bin;      // Write pointer (binary)
reg [1:0] rptr_bin;      // Read pointer (binary)
wire [1:0] wptr_gray;    // Write pointer (gray)
wire [1:0] rptr_gray;    // Read pointer (gray)

// Storage for depth=2
reg [139:0] mem [0:1];  // Dual storage elements

// Synchronization registers
reg [1:0] wptr_gray_sync0, wptr_gray_sync1; // Write->Read sync
reg [1:0] rptr_gray_sync0, rptr_gray_sync1; // Read->Write sync

// Control signals
wire full_cond;  // Full condition in write domain
wire empty_cond; // Empty condition in read domain

// ===================================================================
// Write Domain (clk_in)
// ===================================================================

// Write pointer update
always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        wptr_bin <= 2'b00;
    end else if (fifo_w_enable && !fifo_full) begin
        wptr_bin <= wptr_bin + 1;
    end
end

// Write data to memory
always @(posedge clk_in) begin
    if (!rst_n) begin
        mem[0] <= 140'b0;
        mem[1] <= 140'b0;
    end else if (fifo_w_enable && !fifo_full) begin
        mem[wptr_bin[0]] <= data_to_fifo; // LSB selects mem[0] or [1]
    end
end

// Binary to Gray conversion
assign wptr_gray = (wptr_bin >> 1) ^ wptr_bin;

// Read pointer synchronization (to write clock domain)
always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        rptr_gray_sync0 <= 2'b00;
        rptr_gray_sync1 <= 2'b00;
    end else begin
        rptr_gray_sync0 <= rptr_gray;
        rptr_gray_sync1 <= rptr_gray_sync0;
    end
end

// Full condition generation
assign full_cond = (
    (wptr_gray == 2'b00 && rptr_gray_sync1 == 2'b10) ||
    (wptr_gray == 2'b01 && rptr_gray_sync1 == 2'b11) ||
    (wptr_gray == 2'b11 && rptr_gray_sync1 == 2'b01) ||
    (wptr_gray == 2'b10 && rptr_gray_sync1 == 2'b00)
);

// Full flag output
assign fifo_full = full_cond;

// ===================================================================
// Read Domain (clk_out)
// ===================================================================

// Read pointer update
always @(posedge clk_out or negedge rst_n) begin
    if (!rst_n) begin
        rptr_bin <= 2'b00;
    end else if (fifo_r_enable && !fifo_empty) begin
        rptr_bin <= rptr_bin + 1;
    end
end

// Binary to Gray conversion
assign rptr_gray = (rptr_bin >> 1) ^ rptr_bin;

// Write pointer synchronization (to read clock domain)
always @(posedge clk_out or negedge rst_n) begin
    if (!rst_n) begin
        wptr_gray_sync0 <= 2'b00;
        wptr_gray_sync1 <= 2'b00;
    end else begin
        wptr_gray_sync0 <= wptr_gray;
        wptr_gray_sync1 <= wptr_gray_sync0;
    end
end

// Empty condition
assign empty_cond = (rptr_gray == wptr_gray_sync1);

// Empty flag output
assign fifo_empty = empty_cond;

// Data output logic
assign data_from_fifo = fifo_empty ? 140'b0 : mem[rptr_bin[0]];

endmodule
