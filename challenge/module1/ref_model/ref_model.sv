`timescale 1ns/1ns

module ref_model (
    input         clk_in,        // 系统时钟
    input         rst_n,         // 低电平复位
    input [15:0]  data_in,       // 输入数据（16位）
    
    output logic [139:0] data_to_fifo,      // FIFO写入数据（140位）
    output logic         fifo_w_enable,    // FIFO写入使能
    output logic         crc_err,          // CRC错误标志

    output logic [15:0]  data_to_crc,
    input  logic         crc16_done,       // CRC计算完成标志
    output logic         crc16_valid,      // CRC数据发送标志
    input  logic [15:0]  data_from_crc     // 从CRC计算模块接收的16位数据
);

// 状态定义
typedef enum {
    IDLE,
    HEAD_CHECK,
    CHANNEL,
    DATA,
    CRC_OUTPUT,
    ENABLE_CRC
} state_t;
state_t state, next_state;

// 寄存器定义
reg [7:0]  data_ch;         // 通道选择字段
reg [3:0]  data_counter;     // 数据计数器
reg [3:0]  data_count;       // 数据长度位，1表示16，以此类推

reg [15:0] data_shift_reg;   // 数据移位寄存器 (简化设计)
reg [159:0] full_data_reg;   // 完整数据寄存器 (160位)
reg [31:0] tail_detec_reg;   // 帧尾检测寄存器 (32位)
reg [15:0] crc_field_reg;    // 存储的CRC字段

reg [127:0] data_128;      // 用于存到FIFO的128位数据寄存器
reg [3:0]  crc_cnt;          // CRC发送计数器

reg start_crc;          // 启动CRC计算标志
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
            if (data_in == 16'h0E0E) next_state = CRC_OUTPUT;
            else if (data_counter >= 10) next_state = IDLE; // 最大数据长度
        end
        
        CRC_OUTPUT: begin
            if (data_in == 16'h0E0E) next_state = ENABLE_CRC; //确保帧尾正确
            else next_state = IDLE;
        end

        ENABLE_CRC: begin
            next_state = IDLE;
        end
    endcase
end

// 数据计数器和数据存储
always_ff @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        data_counter <= 0;
        full_data_reg <= 0;
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
                // 存储完整数据 
                full_data_reg <= {full_data_reg[143:0], data_in}; // 160位数据寄存器
                
                // 数据计数器递增
                if (data_counter < 10) // 限制最大计数器
                    data_counter <= data_counter + 1;         
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

// CRC字段提取
always_ff @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        crc_field_reg <= 0;
        data_128 <= 0;
        data_count <= 0;
    end else begin
        case (state)
            CRC_OUTPUT: begin
                // 从帧尾前提取CRC字段
                crc_field_reg   <= tail_detec_reg[31:16];
                data_128        <= full_data_reg[159:32]; // 提取128位数据
                data_count      <= data_counter - 2; // 数据长度位
            end     
            ENABLE_CRC:begin
                // 启动CRC校验
                start_crc <= 1'b1; // 启动CRC计算       
            end
        endcase
    end
end

// CRC字段数据处理
always_ff @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        data_to_crc <= 0;
        crc_err <= 0;
        crc_cnt <= 0;
        crc16_valid <= 0;
        fifo_w_enable <= 0;
    end else if (start_crc == 1'b1) begin
            start_crc <= 1'b0; // 清除启动标志 
                // 检查CRC发送计数器
            if (crc_cnt < data_count) begin
                    crc16_valid <= 1'b1;
                    
                    // 从低位开始发送数据（小端序）
                    // data_128[15:0] 是第一个（最低位）
                    // data_128[31:16] 是第二个，以此类推
                    data_to_crc <= data_128[crc_cnt * 16 +: 16];
                    
                    // 递增发送计数器
                    crc_cnt <= crc_cnt + 1;
                end else begin
                    // 所有数据已发送，等待结果
                    crc16_valid <= 1'b0;
                    crc_cnt <= 4'h0;
                end
                
                // CRC计算完成
                if (crc16_done) begin
                    // 检查CRC结果
                    if (data_from_crc == crc_field_reg) begin
                        crc_err <= 1'b0; // 清除CRC错误标志
                        fifo_w_enable <= 1'b1; // CRC正确，写使能  
                        data_to_fifo <= {data_128, data_ch, data_count}; // 将数据写入FIFO           
                    end else begin
                        crc_err <= 1'b1; // CRC错误
                        fifo_w_enable <= 1'b0; // 禁止写入FIFO
                    end
                end
    end    
end
endmodule