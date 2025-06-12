module ref_model (
  input  [139:0] data_from_fifo,  // FIFO输入的140位数据
  output [127:0] data_gray,       // 格雷码转换后的128位数据
  output [7:0]   vld_ch,          // 8位通道选择位
  output [15:0]  data_count       // 16位数据长度位
);

  // 直接输出通道选择信号
  assign vld_ch = data_from_fifo[11:4];

  // 计算数据长度位
  assign data_count = (data_from_fifo[3:0] <= 8) ? 
                    (data_from_fifo[3:0] << 4) : 16'b0;

  // 格雷码转换处理
  reg [127:0] gray_conv;
  always @(*) begin
    case(data_count)
      16'd0:    gray_conv = 128'b0;
      16'd16:   gray_conv = {data_from_fifo[139:124] ^ {1'b0, data_from_fifo[139:125]}, 112'b0};
      16'd32:   gray_conv = {data_from_fifo[139:108] ^ {1'b0, data_from_fifo[139:109]}, 96'b0};
      16'd48:   gray_conv = {data_from_fifo[139:92] ^ {1'b0, data_from_fifo[139:93]}, 80'b0};
      16'd64:   gray_conv = {data_from_fifo[139:76] ^ {1'b0, data_from_fifo[139:77]}, 64'b0};
      16'd80:   gray_conv = {data_from_fifo[139:60] ^ {1'b0, data_from_fifo[139:61]}, 48'b0};
      16'd96:   gray_conv = {data_from_fifo[139:44] ^ {1'b0, data_from_fifo[139:45]}, 32'b0};
      16'd112:  gray_conv = {data_from_fifo[139:28] ^ {1'b0, data_from_fifo[139:29]}, 16'b0};
      16'd128:  gray_conv = data_from_fifo[139:12] ^ {1'b0, data_from_fifo[139:13]};
      default:  gray_conv = 128'b0;
    endcase
  end
  
  assign data_gray = gray_conv;
  
endmodule
