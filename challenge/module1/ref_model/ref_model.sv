`timescale 1ns/1ps

module ref_model (
    input  logic        clk_in,
    input  logic        rst_n,
    input  logic [15:0] data_in,
    output logic        crc_err,
    output logic [139:0] data_to_fifo,
    output logic        fifo_w_enable,
    output logic [127:0] data_to_crc,
    input  logic [15:0] data_from_crc,
    input  logic        crc16_ready,
    output logic        crc16_valid
);

    // 状态定义
    typedef enum logic [3:0] {
        IDLE,        // 空闲状态
        HEADER1,     // 第一个帧头字
        HEADER2,     // 第二个帧头字
        CHANNEL,     // 通道选择
        DATA,        // 数据接收
        TAIL_START,  // 帧尾开始检测
        TAIL_END,    // 帧尾结束检测
        CRC_EXTRACT, // CRC提取
        CRC_CHECK    // CRC校验
    } state_t;
    
    state_t current_state, next_state;
    
    // 内部寄存器
    logic [7:0]   vld_ch_reg;      // 通道选择寄存器
    logic [3:0]   counter;         // 4位数据计数器
    logic [159:0] shift_reg;       // 160位数据移位寄存器
    logic [15:0]  data_crc_reg;    // CRC校验值寄存器
    logic [3:0]   data_count_reg;  // 4位数据长度寄存器
    logic         crc_match;       // CRC匹配结果
    logic         prev_crc_ready;  // 前一周期crc16_ready
    
    // 状态转移逻辑
    always_ff @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // 状态机控制
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (data_in == 16'hE0E0) begin
                    next_state = HEADER1;
                end
            end
            
            HEADER1: begin
                if (data_in == 16'hE0E0) begin
                    next_state = HEADER2;
                end else begin
                    next_state = IDLE;
                end
            end
            
            HEADER2: begin
                next_state = CHANNEL;
            end
            
            CHANNEL: begin
                next_state = DATA;
            end
            
            DATA: begin
                // 检测帧尾开始
                if (data_in == 16'h0E0E) begin
                    next_state = TAIL_START;
                end
            end
            
            TAIL_START: begin
                // 检测完整帧尾
                if (data_in == 16'h0E0E) begin
                    next_state = TAIL_END;
                end else begin
                    next_state = DATA;
                end
            end
            
            TAIL_END: begin
                next_state = CRC_EXTRACT;
            end
            
            CRC_EXTRACT: begin
                next_state = CRC_CHECK;
            end
            
            CRC_CHECK: begin
                if (crc_match && fifo_w_enable) begin
                    next_state = IDLE;
                end
            end
        endcase
    end
    
    // 数据路径
    always_ff @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            vld_ch_reg     <= 8'h00;
            counter        <= 4'h0;
            shift_reg      <= 160'h0;
            data_crc_reg   <= 16'h0000;
            data_count_reg <= 4'h0;
            crc_err        <= 1'b0;
            fifo_w_enable  <= 1'b0;
            crc16_valid    <= 1'b0;
            crc_match      <= 1'b0;
            prev_crc_ready <= 1'b0;
        end else begin
            prev_crc_ready <= crc16_ready;
            
            case (current_state)
                IDLE: begin
                    counter        <= 4'h0;
                    shift_reg      <= 160'h0;
                    fifo_w_enable  <= 1'b0;
                    crc_err        <= 1'b0;
                    crc16_valid    <= 1'b0;
                    data_count_reg <= 4'h0;
                end
                
                HEADER1: begin
                    // 第一个帧头字
                    shift_reg <= {shift_reg[143:0], data_in};
                end
                
                HEADER2: begin
                    // 第二个帧头字
                    shift_reg <= {shift_reg[143:0], data_in};
                end
                
                CHANNEL: begin
                    // 存储通道选择信号（取低8位）
                    vld_ch_reg <= data_in[7:0];
                    shift_reg <= {shift_reg[143:0], data_in};
                end
                
                DATA: begin
                    // 存储数据并计数
                    shift_reg <= {shift_reg[143:0], data_in};
                    counter   <= counter + 1;
                end
                
                TAIL_START: begin
                    // 存储第一个帧尾字
                    shift_reg <= {shift_reg[143:0], data_in};
                    counter   <= counter + 1;
                end
                
                TAIL_END: begin
                    // 存储第二个帧尾字
                    shift_reg <= {shift_reg[143:0], data_in};
                    counter   <= counter + 1;
                end
                
                CRC_EXTRACT: begin
                    // 提取CRC字段（帧尾前的16位）
                    data_crc_reg <= shift_reg[31:16];
                    
                    // 计算数据长度 (counter - 2)
                    data_count_reg <= (counter < 2) ? 4'h0 : (counter - 2);
                    
                    // 激活CRC校验
                    crc16_valid <= 1'b1;
                end
                
                CRC_CHECK: begin
                    // 当CRC校验完成时
                    if (crc16_ready && !prev_crc_ready) begin
                        // 比较CRC值
                        crc_match <= (data_from_crc == data_crc_reg);
                        
                        // 如果CRC校验通过，则生成fifo写使能
                        fifo_w_enable <= (data_from_crc == data_crc_reg);
                        crc_err <= (data_from_crc != data_crc_reg);
                    end
                    
                    // 复位信号
                    if (fifo_w_enable) begin
                        fifo_w_enable <= 1'b0;
                        crc16_valid <= 1'b0;
                    end
                end
            endcase
        end
    end
    
    // 输出数据到CRC模块 (截取高128位)
    assign data_to_crc = shift_reg[159:32];
    
    // 输出到FIFO的数据
    assign data_to_fifo = {
        data_count_reg,   // [139:136] 4位数据长度表示位
        data_to_crc,      // [135:8]   128位数据位
        vld_ch_reg        // [7:0]     8位通道选择
    };

endmodule