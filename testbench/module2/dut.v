module async_fifo (
    // Global control
    input          rst_n,         // async reset (active low)
    
    // Write domain
    input          clk_in,        // write clock
    input          fifo_w_enable, // write enable
    input  [139:0] data_to_fifo,  // write data
    
    // Read domain
    input          clk_out,       // read clock
    input          fifo_r_enable, // read enable
    output reg [139:0] data_from_fifo, // read data
    
    // Status flags
    output         fifo_empty,    // FIFO empty (1=empty)
    output         fifo_full      // FIFO full (1=full)
);

// Internal signals
// FIFO memory (depth=2)
reg [139:0] mem [0:1];  

// Pointers and synchronization
reg [1:0] w_ptr_bin;     // write pointer (binary)
reg [1:0] r_ptr_bin;     // read pointer (binary)

reg [1:0] w_ptr_gray;    // write pointer (gray)
reg [1:0] r_ptr_gray;    // read pointer (gray)

// Synchronized pointers
reg [1:0] w_ptr_gray_sync_r1, w_ptr_gray_sync_r2;  // write->read sync
reg [1:0] r_ptr_gray_sync_w1, r_ptr_gray_sync_w2;  // read->write sync

// Status flags
assign fifo_empty = (w_ptr_gray_sync_r2 == r_ptr_gray);
assign fifo_full  = (r_ptr_gray_sync_w2 == {~w_ptr_gray[1], w_ptr_gray[0]});

// Binary to Gray conversion
function [1:0] bin2gray;
    input [1:0] bin;
    begin
        bin2gray = {bin[1], bin[1] ^ bin[0]};
    end
endfunction

// Gray to Binary conversion
function [1:0] gray2bin;
    input [1:0] gray;
    begin
        gray2bin = {gray[1], gray[1] ^ gray[0]};
    end
endfunction

// Write pointer logic (write domain)
always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        w_ptr_bin  <= 2'b00;
        w_ptr_gray <= 2'b00;
    end
    else if (fifo_w_enable && !fifo_full) begin
        w_ptr_bin  <= w_ptr_bin + 1'b1;
        w_ptr_gray <= bin2gray(w_ptr_bin + 1'b1);
    end
end

// Write memory operation
always @(posedge clk_in) begin
    if (!rst_n) begin
        mem[0] <= 140'b0;
        mem[1] <= 140'b0;
    end
    else if (fifo_w_enable && !fifo_full) begin
        mem[w_ptr_bin[0]] <= data_to_fifo;
    end
end

// Read pointer logic (read domain)
always @(posedge clk_out or negedge rst_n) begin
    if (!rst_n) begin
        r_ptr_bin  <= 2'b00;
        r_ptr_gray <= 2'b00;
    end
    else if (fifo_r_enable && !fifo_empty) begin
        r_ptr_bin  <= r_ptr_bin + 1'b1;
        r_ptr_gray <= bin2gray(r_ptr_bin + 1'b1);
    end
end

// Read memory operation
always @(posedge clk_out or negedge rst_n) begin
    if (!rst_n)
        data_from_fifo <= 140'b0;
    else if (fifo_r_enable && !fifo_empty)
        data_from_fifo <= mem[r_ptr_bin[0]];
end

// Write pointer synchronization to read domain
always @(posedge clk_out or negedge rst_n) begin
    if (!rst_n) begin
        w_ptr_gray_sync_r1 <= 2'b00;
        w_ptr_gray_sync_r2 <= 2'b00;
    end
    else begin
        w_ptr_gray_sync_r1 <= w_ptr_gray;
        w_ptr_gray_sync_r2 <= w_ptr_gray_sync_r1;
    end
end

// Read pointer synchronization to write domain
always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        r_ptr_gray_sync_w1 <= 2'b00;
        r_ptr_gray_sync_w2 <= 2'b00;
    end
    else begin
        r_ptr_gray_sync_w1 <= r_ptr_gray;
        r_ptr_gray_sync_w2 <= r_ptr_gray_sync_w1;
    end
end

endmodule
