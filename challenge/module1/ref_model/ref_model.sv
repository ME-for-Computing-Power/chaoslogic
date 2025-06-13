`timescale 1ns/1ns

module ref_model (
    input         clk_in,        // 系统时钟
    input         rst_n,         // 低电平复位
    input [15:0]  data_in,       // 输入数据（16位）
    
    output logic [139:0] fifo_w_data,      // FIFO写入数据（140位）
    output logic         fifo_w_enable,    // FIFO写入使能
    output logic         crc_err           // CRC错误标志
);

// 状态定义
typedef enum {
    IDLE,
    HEAD_CHECK,
    CHANNEL,
    DATA,
    CRC_OUTPUT,
    WAIT_CRC
} state_t;
state_t state, next_state;

// 寄存器定义
reg [7:0]  data_ch;         // 通道选择字段
reg [3:0]  data_counter;     // 数据计数器
reg [15:0] data_shift_reg;   // 数据移位寄存器 (简化设计)
reg [159:0] full_data_reg;   // 完整数据寄存器 (160位)
reg [15:0] prev_data;        // 前一周期数据
reg [31:0] tail_detec_reg;   // 帧尾检测寄存器 (32位)
reg [15:0] crc_field_reg;    // 存储的CRC字段
reg [15:0] crc_calculated;   // 计算的CRC值
reg [2:0]  crc_cnt;          // CRC发送计数器
reg        sending_crc;       // CRC发送状态标志
reg        crc_start;         // CRC计算启动标志

// 本地参数
localparam HEADER = 32'hE0E0_E0E0;  // 帧头
localparam TAIL   = 32'h0E0E_0E0E;  // 帧尾

// 状态转移逻辑
always_ff @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// 下一状态逻辑
always_comb begin
    next_state = state;
    case (state)
        IDLE: if (data_in == 16'hE0E0) next_state = HEAD_CHECK;
        
        HEAD_CHECK: begin
            if (data_in == 16'hE0E0) next_state = CHANNEL;
            else next_state = IDLE;
        end
        
        CHANNEL: next_state = DATA;
        
        DATA: begin
            if (tail_detec_reg == TAIL) next_state = CRC_OUTPUT;
            else if (data_counter >= 10) next_state = IDLE; // 最大数据长度
        end
        
        CRC_OUTPUT: next_state = WAIT_CRC;
        
        WAIT_CRC: begin
            if (crc_cnt == (data_counter - 1) && !sending_crc) 
                next_state = IDLE;
        end
    endcase
end

// 数据计数器和数据存储
always_ff @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        data_counter <= 0;
        full_data_reg <= 0;
        prev_data <= 0;
        tail_detec_reg <= 0;
    end else begin
        case (state)
            CHANNEL: begin
                data_counter <= 0;
                full_data_reg <= 0;
                tail_detec_reg <= 0;
            end
            
            DATA: begin
                // 更新帧尾检测寄存器
                tail_detec_reg <= {tail_detec_reg[15:0], data_in};
                
                // 存储当前数据
                prev_data <= data_in;
                
                // 数据计数器递增
                if (data_counter < 10) // 限制最大计数器
                    data_counter <= data_counter + 1;
                
                // 存储完整数据 (简化版本)
                case(data_counter)
                    0: full_data_reg[159:144] <= data_in;
                    1: full_data_reg[143:128] <= data_in;
                    2: full_data_reg[127:112] <= data_in;
                    3: full_data_reg[111:96] <= data_in;
                    4: full_data_reg[95:80] <= data_in;
                    5: full_data_reg[79:64] <= data_in;
                    6: full_data_reg[63:48] <= data_in;
                    7: full_data_reg[47:32] <= data_in;
                    8: full_data_reg[31:16] <= data_in;
                    9: full_data_reg[15:0] <= data_in;
                endcase
            end
            
            default: begin
                // 其他状态清除计数器
                if (state == IDLE) data_counter <= 0;
            end
        endcase
    end
end

// 通道选择字段处理
always_ff @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        data_ch <= 0;
    end else if (state == CHANNEL) begin
        data_ch <= data_in[7:0]; // 取低8位
    end
end

// CRC字段提取和处理
always_ff @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        crc_field_reg <= 0;
        crc_start <= 0;
        crc_cnt <= 0;
        sending_crc <= 0;
    end else begin
        case (state)
            CRC_OUTPUT: begin
                // 从帧尾前提取CRC字段
                crc_field_reg <= prev_data;
                crc_start <= 1; // 启动CRC计算
            end
            
            WAIT_CRC: begin
                if (crc_start) begin
                    crc_cnt <= 0;
                    sending_crc <= 1;
                    crc_start <= 0;
                end
                
                if (sending_crc) begin
                    if (crc_cnt < data_counter - 2) begin
                        crc_cnt <= crc_cnt + 1;
                    end else begin
                        sending_crc <= 0;
                    end
                end
            end
        endcase
    end
end

// CRC计算（简化版）
always_comb begin
    // 在实际实现中使用完整CRC16算法
    // 这里使用简单的位反转作为示例
    crc_calculated = ~crc_field_reg;
end

// 输出逻辑
always_ff @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        fifo_w_data <= 0;
        fifo_w_enable <= 0;
        crc_err <= 0;
    end else begin
        fifo_w_enable <= 0;
        crc_err <= 0;
        
        // CRC校验结果处理
        if (state == WAIT_CRC && !sending_crc && (crc_cnt >= data_counter - 2)) begin
            if (crc_calculated == crc_field_reg) begin
                // CRC校验成功
                fifo_w_enable <= 1;
                // 构造140位输出数据:
                // [139:132] = 数据长度(4位)
                // [131:124] = 通道号(8位)
                // [123:0]   = 有效数据(128位，高位在前)
                fifo_w_data <= {
                    {4'h0, data_counter - 2},  // 数据长度(4位) 
                    data_ch,                    // 通道选择(8位)
                    full_data_reg[159:32]       // 有效数据(128位)
                };
            end else begin
                // CRC校验失败
                crc_err <= 1;
            end
        end
    end
end

endmodule