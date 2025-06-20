module ref_model (
    input  logic         rst_n,
    input  logic         clk_out16x,
    input  logic [127:0] data_gray,
    input  logic  [7:0]  vld_ch,
    input  logic [15:0]  data_count,
    output logic         crc_valid,
    output logic         data_out_ch1,
    output logic         data_out_ch2,
    output logic         data_out_ch3,
    output logic         data_out_ch4,
    output logic         data_out_ch5,
    output logic         data_out_ch6,
    output logic         data_out_ch7,
    output logic         data_out_ch8,
    output logic         data_vld_ch1,
    output logic         data_vld_ch2,
    output logic         data_vld_ch3,
    output logic         data_vld_ch4,
    output logic         data_vld_ch5,
    output logic         data_vld_ch6,
    output logic         data_vld_ch7,
    output logic         data_vld_ch8
);

    // 内部信号
    logic [127:0] shift_reg;     // 串行移位寄存器
    logic [15:0]  bit_cnt;       // 已发送位计数
    logic         active;        // 输出进行中标志
    logic  [7:0]  vld_latched;   // 触发时刻锁存的通道独热码

    // 1. 异步复位及状态机
    always_ff @(posedge clk_out16x or negedge rst_n) begin
        if (!rst_n) begin
            active       <= 1'b0;
            bit_cnt      <= 16'd0;
            shift_reg    <= 128'd0;
            vld_latched  <= 8'd0;
        end else begin
            if (!active) begin
                // 空闲状态：检测到 vld_ch 上的独热码后加载数据
                if (|vld_ch) begin
                    active      <= 1'b1;
                    bit_cnt     <= 16'd0;
                    shift_reg   <= data_gray;
                    vld_latched <= vld_ch;
                end
            end else begin
                // 发送中：移位并计数
                shift_reg <= {shift_reg[126:0], 1'b0};
                bit_cnt   <= bit_cnt + 16'd1;
                // 发送完成后回到空闲
                if (bit_cnt + 16'd1 == data_count) begin
                    active <= 1'b0;
                end
            end
        end
    end

    // 2. 串行数据输出 + 数据有效信号
    //    高位优先输出，每个通道独立
    assign data_out_ch1 = (active & vld_latched[0]) ? shift_reg[127] : 1'b0;
    assign data_out_ch2 = (active & vld_latched[1]) ? shift_reg[127] : 1'b0;
    assign data_out_ch3 = (active & vld_latched[2]) ? shift_reg[127] : 1'b0;
    assign data_out_ch4 = (active & vld_latched[3]) ? shift_reg[127] : 1'b0;
    assign data_out_ch5 = (active & vld_latched[4]) ? shift_reg[127] : 1'b0;
    assign data_out_ch6 = (active & vld_latched[5]) ? shift_reg[127] : 1'b0;
    assign data_out_ch7 = (active & vld_latched[6]) ? shift_reg[127] : 1'b0;
    assign data_out_ch8 = (active & vld_latched[7]) ? shift_reg[127] : 1'b0;

    assign data_vld_ch1 = (active & vld_latched[0]);
    assign data_vld_ch2 = (active & vld_latched[1]);
    assign data_vld_ch3 = (active & vld_latched[2]);
    assign data_vld_ch4 = (active & vld_latched[3]);
    assign data_vld_ch5 = (active & vld_latched[4]);
    assign data_vld_ch6 = (active & vld_latched[5]);
    assign data_vld_ch7 = (active & vld_latched[6]);
    assign data_vld_ch8 = (active & vld_latched[7]);

    // 3. CRC 有效信号：任一通道有效则高
    assign crc_valid = |{data_vld_ch1, data_vld_ch2, data_vld_ch3, data_vld_ch4,
                         data_vld_ch5, data_vld_ch6, data_vld_ch7, data_vld_ch8};

endmodule
