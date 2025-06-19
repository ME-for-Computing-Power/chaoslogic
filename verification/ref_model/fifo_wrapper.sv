module fifo_wrapper (
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
    async_fifo1 u_async_fifo (
    //Write clock domain
        .wrclk(clk_in)   ,//写时钟
        .wrrst_n(rst_n) ,//写侧复位，异步复位，低有效
        .wren(fifo_w_enable)    ,//写使能
        .wrdata(data_to_fifo)  ,//写数据输入
        .wrfull(fifo_full)  ,//写侧满标志
        .rdclk(clk_out)   ,//读时钟
        .rdrst_n(rst_n) ,//读侧复位，异步复位，低有效
        .rden(fifo_r_enable)    ,//读使能
        .rddata(data_from_fifo)  ,//读数据输出
        .rdempty(fifo_empty) //读侧空标志
);	
endmodule