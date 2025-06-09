module frame_detector(
    input clk_in,
    input clk_out,
    input clk_out_s,
    input rst_n,
    input [15:0] data_in,
    
    output reg data_out_ch1,  // 声明为reg类型
    output reg data_out_ch2,
    output reg data_out_ch3,
    output reg data_out_ch4,
    output reg data_out_ch5,
    output reg data_out_ch6,
    output reg data_out_ch7,
    output reg data_out_ch8,
    
    output reg data_vld_ch1,  // 声明为reg类型
    output reg data_vld_ch2,
    output reg data_vld_ch3,
    output reg data_vld_ch4,
    output reg data_vld_ch5,
    output reg data_vld_ch6,
    output reg data_vld_ch7,
    output reg data_vld_ch8,
    
    output fifo_empty,
    output fifo_full,
    output reg crc_valid,     // 声明为reg类型
    output reg crc_err        // 声明为reg类型
);

// 参数定义
localparam HEADER = 32'hE0E0E0E0;
localparam TRAILER = 32'h0E0E0E0E;

// 内部寄存器
logic [127:0] frame_data;
logic [15:0] data_counter;
logic [7:0] channel_reg;
logic frame_active;
logic [3:0] state;
logic [15:0] crc_reg;
logic [127:0] fifo_data;
logic fifo_we;
logic fifo_re;
logic [3:0] bit_counter;
logic [15:0] shift_reg;
logic data_vld;

// 状态定义
localparam IDLE = 4'd0;
localparam HEADER1 = 4'd1;
localparam HEADER2 = 4'd2;
localparam CHANNEL = 4'd3;
localparam DATA = 4'd4;
localparam CRC = 4'd5;
localparam TRAILER1 = 4'd6;
localparam TRAILER2 = 4'd7;
localparam VALID = 4'd8;

// 二进制到格雷码转换函数
function automatic logic [15:0] bin2gray(input [15:0] bin);
    return bin ^ (bin >> 1);
endfunction

// 输入时钟域逻辑 (clk_in)
always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        frame_data <= 0;
        data_counter <= 0;
        channel_reg <= 0;
        frame_active <= 0;
        crc_reg <= 0;
        fifo_we <= 0;
        crc_valid <= 0;
        crc_err <= 0;
    end
    else begin
        fifo_we <= 0;
        crc_valid <= 0;
        crc_err <= 0;
        
        case(state)
            IDLE: begin
                if (data_in == HEADER[31:16]) begin
                    state <= HEADER1;
                end
            end
            
            HEADER1: begin
                if (data_in == HEADER[15:0]) begin
                    state <= CHANNEL;
                end
                else begin
                    state <= IDLE;
                end
            end
            
            CHANNEL: begin
                channel_reg <= data_in[7:0];
                state <= DATA;
                data_counter <= 0;
            end
            
            DATA: begin
                // 简单存储数据 (实际应限制16-128位)
                frame_data <= {frame_data[111:0], data_in};
                data_counter <= data_counter + 16;
                
                // 假设固定128位数据
                if (data_counter >= 112) begin
                    state <= CRC;
                end
            end
            
            CRC: begin
                crc_reg <= data_in; // 存储CRC
                state <= TRAILER1;
            end
            
            TRAILER1: begin
                if (data_in == TRAILER[31:16]) begin
                    state <= TRAILER2;
                end
                else begin
                    state <= IDLE;
                end
            end
            
            TRAILER2: begin
                if (data_in == TRAILER[15:0]) begin
                    state <= VALID;
                    fifo_we <= 1;
                    // 简单CRC验证: 如果CRC非0则有效
                    if (crc_reg != 0) begin
                        crc_valid <= 1;
                    end
                    else begin
                        crc_err <= 1;
                    end
                end
                else begin
                    state <= IDLE;
                end
            end
            
            VALID: begin
                state <= IDLE;
                fifo_we <= 0;
            end
            
            default: state <= IDLE;
        endcase
    end
end

// 简单的FIFO模型 (单深度)
always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        fifo_data <= 0;
    end
    else if (fifo_we) begin
        fifo_data <= frame_data;
    end
end

assign fifo_empty = (fifo_data == 0);
assign fifo_full = 0; // 永远不满

// 输出时钟域逻辑 (clk_out_s)
always @(posedge clk_out_s or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= 0;
        bit_counter <= 0;
        data_vld <= 0;
    end
    else begin
        if (fifo_we) begin
            // 当新数据写入时加载移位寄存器
            shift_reg <= bin2gray(fifo_data[127:112]); // 取前16位
            bit_counter <= 15;
            data_vld <= 1;
        end
        else if (data_vld) begin
            if (bit_counter > 0) begin
                shift_reg <= shift_reg << 1;
                bit_counter <= bit_counter - 1;
            end
            else begin
                data_vld <= 0;
            end
        end
    end
end

// 输出分配 (使用组合逻辑)
always @(*) begin
    // 默认值
    data_out_ch1 = 0;
    data_out_ch2 = 0;
    data_out_ch3 = 0;
    data_out_ch4 = 0;
    data_out_ch5 = 0;
    data_out_ch6 = 0;
    data_out_ch7 = 0;
    data_out_ch8 = 0;
    data_vld_ch1 = 0;
    data_vld_ch2 = 0;
    data_vld_ch3 = 0;
    data_vld_ch4 = 0;
    data_vld_ch5 = 0;
    data_vld_ch6 = 0;
    data_vld_ch7 = 0;
    data_vld_ch8 = 0;
    
    // 根据通道选择激活对应输出
    if (channel_reg[0]) begin
        data_out_ch1 = shift_reg[15];
        data_vld_ch1 = data_vld;
    end
    if (channel_reg[1]) begin
        data_out_ch2 = shift_reg[15];
        data_vld_ch2 = data_vld;
    end
    if (channel_reg[2]) begin
        data_out_ch3 = shift_reg[15];
        data_vld_ch3 = data_vld;
    end
    if (channel_reg[3]) begin
        data_out_ch4 = shift_reg[15];
        data_vld_ch4 = data_vld;
    end
    if (channel_reg[4]) begin
        data_out_ch5 = shift_reg[15];
        data_vld_ch5 = data_vld;
    end
    if (channel_reg[5]) begin
        data_out_ch6 = shift_reg[15];
        data_vld_ch6 = data_vld;
    end
    if (channel_reg[6]) begin
        data_out_ch7 = shift_reg[15];
        data_vld_ch7 = data_vld;
    end
    if (channel_reg[7]) begin
        data_out_ch8 = shift_reg[15];
        data_vld_ch8 = data_vld;
    end
end

endmodule