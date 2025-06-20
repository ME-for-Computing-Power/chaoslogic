module async_fifo (
  input        clk_in,         // 写时钟域时钟
  input        clk_out,        // 读时钟域时钟
  input        rst_n,          // 异步复位
  input        fifo_w_enable,  // 写使能
  input        fifo_r_enable,  // 读使能
  input  [139:0] data_to_fifo, // 140位输入数据
  output [139:0] data_from_fifo, // 140位输出数据
  output       fifo_empty,     // FIFO空标志
  output       fifo_full       // FIFO满标志
);

  // 存储阵列 (8x140)
  reg [139:0] mem [0:7];
  
  // 写域指针（二进制和格雷码）
  reg [3:0] wr_ptr_bin;
  wire [3:0] wr_ptr_gray;
  
  // 读域指针（二进制和格雷码）
  reg [3:0] rd_ptr_bin;
  wire [3:0] rd_ptr_gray;
  
  // 同步寄存器链（写域同步读指针）
  reg [3:0] rd_ptr_gray_sync0;
  reg [3:0] rd_ptr_gray_sync1;
  
  // 同步寄存器链（读域同步写指针）
  reg [3:0] wr_ptr_gray_sync0;
  reg [3:0] wr_ptr_gray_sync1;
  
  // 二进制转格雷码函数
  function [3:0] bin2gray;
    input [3:0] bin;
    begin
      bin2gray = bin ^ (bin >> 1);
    end
  endfunction

  // ======== 写时钟域逻辑 ========
  always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
      // 写指针复位
      wr_ptr_bin <= 4'b0;
      
      // 同步链复位
      rd_ptr_gray_sync0 <= 4'b0;
      rd_ptr_gray_sync1 <= 4'b0;
    end
    else begin
      // 同步读指针（格雷码跨时钟域）
      rd_ptr_gray_sync0 <= rd_ptr_gray;
      rd_ptr_gray_sync1 <= rd_ptr_gray_sync0;
      
      // 写操作（非满且使能）
      if (fifo_w_enable && !fifo_full) begin
        mem[wr_ptr_bin[2:0]] <= data_to_fifo;  // 写入RAM
        wr_ptr_bin <= wr_ptr_bin + 1;           // 指针递增
      end
    end
  end
  
  // 写指针格雷码转换
  assign wr_ptr_gray = bin2gray(wr_ptr_bin);

  // ======== 读时钟域逻辑 ========
  always @(posedge clk_out or negedge rst_n) begin
    if (!rst_n) begin
      // 读指针复位
      rd_ptr_bin <= 4'b0;
      
      // 同步链复位
      wr_ptr_gray_sync0 <= 4'b0;
      wr_ptr_gray_sync1 <= 4'b0;
    end
    else begin
      // 同步写指针（格雷码跨时钟域）
      wr_ptr_gray_sync0 <= wr_ptr_gray;
      wr_ptr_gray_sync1 <= wr_ptr_gray_sync0;
      
      // 读操作（非空且使能）
      if (fifo_r_enable && !fifo_empty) begin
        rd_ptr_bin <= rd_ptr_bin + 1;  // 指针递增
      end
    end
  end
  
  // 读指针格雷码转换
  assign rd_ptr_gray = bin2gray(rd_ptr_bin);

  // ======== 空满标志生成 ========
  // 满标志（写域判断）：指针最高两位不同但低两位相同
  assign fifo_full = (wr_ptr_gray == {~rd_ptr_gray_sync1[3:2], rd_ptr_gray_sync1[1:0]});
  
  // 空标志（读域判断）：格雷码指针完全相等
  assign fifo_empty = (rd_ptr_gray == wr_ptr_gray_sync1);

  // ======== 数据输出逻辑 ========
  assign data_from_fifo = fifo_empty ? 140'b0 : mem[rd_ptr_bin[2:0]];

endmodule
