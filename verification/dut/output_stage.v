module output_stage(
    input rst_n,
    input clk_out16x,
    input [127:0] data_gray,
    input [7:0] vld_ch,
    input [15:0] data_count,
    
    output crc_valid,
    output data_out_ch1, data_out_ch2, data_out_ch3, data_out_ch4,
    output data_out_ch5, data_out_ch6, data_out_ch7, data_out_ch8,
    output data_vld_ch1, data_vld_ch2, data_vld_ch3, data_vld_ch4,
    output data_vld_ch5, data_vld_ch6, data_vld_ch7, data_vld_ch8
);

// 状态定义
localparam IDLE = 1'b0;
localparam SEND = 1'b1;

// 通道输出信号
wire [7:0] data_out;
wire [7:0] data_vld;

// CRC有效信号
assign crc_valid = |data_vld;

// 通道输出连接
assign data_out_ch1 = data_out[0];
assign data_out_ch2 = data_out[1];
assign data_out_ch3 = data_out[2];
assign data_out_ch4 = data_out[3];
assign data_out_ch5 = data_out[4];
assign data_out_ch6 = data_out[5];
assign data_out_ch7 = data_out[6];
assign data_out_ch8 = data_out[7];

assign data_vld_ch1 = data_vld[0];
assign data_vld_ch2 = data_vld[1];
assign data_vld_ch3 = data_vld[2];
assign data_vld_ch4 = data_vld[3];
assign data_vld_ch5 = data_vld[4];
assign data_vld_ch6 = data_vld[5];
assign data_vld_ch7 = data_vld[6];
assign data_vld_ch8 = data_vld[7];

genvar i;
generate
for (i = 0; i < 8; i = i + 1) begin : channel_gen
    // 状态寄存器
    reg state;
    
    // 数据寄存器
    reg [127:0] shift_reg;
    
    // 长度计数器
    reg [15:0] counter;
    
    // 有效长度寄存器
    reg [15:0] data_count_reg;
    
    // 输出数据
    reg out_bit;
    reg out_valid;
    
    // 输出连接
    assign data_out[i] = out_bit;
    assign data_vld[i] = out_valid;
    
    always @(posedge clk_out16x or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            shift_reg <= 128'd0;
            counter <= 16'd0;
            data_count_reg <= 16'd0;
            out_bit <= 1'b0;
            out_valid <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    out_valid <= 1'b0;  // 确保有效信号置低
                    if (vld_ch[i]) begin
                        // 锁存数据
                        shift_reg <= data_gray;
                        // 锁存数据长度
                        data_count_reg <= data_count;
                        
                        // 初始化计数器
                        counter <= 16'd1;
                        
                        // 输出最高位
                        out_bit <= data_gray[127];
                        out_valid <= 1'b1;
                        
                        // 进入发送状态
                        state <= SEND;
                    end
                    else begin
                        // 保持输出为低
                        out_bit <= 1'b0;
                    end
                end
                
                SEND: begin
                    // 移位寄存器
                    shift_reg <= {shift_reg[126:0], 1'b0};
                    
                    // 输出当前最高位
                    out_bit <= shift_reg[127];
                    
                    // 计数增加
                    counter <= counter + 1'b1;
                    
                    // 检查发送完成
                    if (counter >= data_count_reg) begin
                        // 返回空闲状态
                        state <= IDLE;
                        out_valid <= 1'b0;
                        out_bit <= 1'b0;
                    end
                    else begin
                        // 保持有效
                        out_valid <= 1'b1;
                    end
                end
            endcase
        end
    end
end
endgenerate

endmodule
