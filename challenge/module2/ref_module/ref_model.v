//spec io
// |信号|位宽|I/O|
// |-----|-----|-----|
// |clk_in|1|I|
// |clk_out|1|I|
// |rst_n|1|I|
// |fifo_w_enable|1|I|
// |fifo_r_enable|1|I|
// |data_to_fifo|140|I|
// |data_from_fifo|140|O|
// |fifo_empty|1|O|
// |fifo_full|1|O|

module ref_model(
    input clk_in,
    input clk_out,
    input rst_n,
    input fifo_w_enable,
    input fifo_r_enable,
    input [139:0] data_to_fifo,
    output reg [139:0] data_from_fifo,
    output reg fifo_empty,
    output reg fifo_full
);

    // param
    parameter DSIZE = 140; // Data size
    parameter ASIZE = 2;   // Address size

    fifo #(DSIZE, ASIZE) fifo_inst (
        .rdata(data_from_fifo),
        .wfull(fifo_full),
        .rempty(fifo_empty),
        .wdata(data_to_fifo),
        .winc(fifo_w_enable),
        .wclk(clk_in),
        .wrst_n(rst_n),
        .rinc(fifo_r_enable),
        .rclk(clk_out),
        .rrst_n(rst_n)
    );
endmodule