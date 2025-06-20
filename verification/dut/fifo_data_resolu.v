module fifo_data_resolu (
  input  [139:0] data_from_fifo,
  output [127:0] data_gray,
  output [7:0]   vld_ch,
  output [15:0]  data_count
);

  // 1. 直接提取通道选择信号
  assign vld_ch = data_from_fifo[11:4];
  
  // 2. 计算数据长度
  assign data_count =  {8'b0, data_from_fifo[3:0], 4'b0};
  
  // 3. 数据转换处理
  wire [127:0] data_high = data_from_fifo[139:12];  // 提取128位原始数据
  wire [127:0] gray_full = data_high ^ (data_high >> 1);  // 完整格雷码转换
  
  // 根据长度指示位选择有效数据段
  reg [127:0] gray_out;
  always @(*) begin
    case (data_from_fifo[3:0])
      4'd0: gray_out = 128'd0;          // 0000 -> 全0
      4'd1: gray_out = {gray_full[127:112], 112'd0};  // 高16位有效
      4'd2: gray_out = {gray_full[127:96], 96'd0};    // 高32位有效
      4'd3: gray_out = {gray_full[127:80], 80'd0};    // 高48位有效
      4'd4: gray_out = {gray_full[127:64], 64'd0};    // 高64位有效
      4'd5: gray_out = {gray_full[127:48], 48'd0};    // 高80位有效
      4'd6: gray_out = {gray_full[127:32], 32'd0};    // 高96位有效
      4'd7: gray_out = {gray_full[127:16], 16'd0};    // 高112位有效
      4'd8: gray_out = gray_full;        // 全部128位有效
    endcase
  end
  
  assign data_gray = gray_out;

endmodule
