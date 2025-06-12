// fifo_data_resolu 参考模型（不可综合）
module ref_model(
    input  logic [139:0] data_from_fifo,
    output logic [127:0] data_gray,
    output logic  [7:0]  vld_ch,
    output logic [15:0]  data_count
);
    // 字段拆分
    logic [127:0] data_bin;
    logic  [7:0]  ch_sel;
    logic  [3:0]  len_code;
    logic [127:0] data_bin_cut;
    logic [127:0] data_gray_tmp;
    logic [15:0]  count;

    assign data_bin = data_from_fifo[139:12];
    assign ch_sel   = data_from_fifo[11:4];
    assign len_code = data_from_fifo[3:0];

    // 长度映射
    always_comb begin
        unique case (len_code)
            4'd0:  count = 16'd0;
            4'd1:  count = 16'd16;
            4'd2:  count = 16'd32;
            4'd3:  count = 16'd48;
            4'd4:  count = 16'd64;
            4'd5:  count = 16'd80;
            4'd6:  count = 16'd96;
            4'd7:  count = 16'd112;
            4'd8:  count = 16'd128;
            default: count = 16'd0;
        endcase
    end
    assign data_count = count;

    // 先提取高位数据，再转Gray码，最后低位补0
    always_comb begin
        data_bin_cut = '0;
        if (count > 0 && count <= 128) begin
            data_bin_cut[127:128-count] = data_bin[127:128-count];
        end
        // Gray码转换
        data_gray[127:128-count] = data_bin_cut ^ (data_bin_cut >> 1);
        if(count < 128)
            data_gray[128-count-1:0] = '0; // 低位补0
    end

    // 通道选择直接输出
    assign vld_ch = ch_sel;

endmodule
