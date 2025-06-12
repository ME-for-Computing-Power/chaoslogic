module ref_model (
    input  logic [139:0] data_from_fifo,
    output logic [127:0] data_gray,
    output logic [  7:0] vld_ch,
    output logic [ 15:0] data_count
);

    // 拆分字段
    logic [127:0] raw_data;
    logic [  7:0] sel_ch;
    logic [  3:0] len_code;

    assign raw_data = data_from_fifo[139:12];
    assign sel_ch = data_from_fifo[11:4];
    assign len_code = data_from_fifo[3:0];

    // 二进制转Gray码
    assign data_gray = raw_data ^ (raw_data >> 1);

    // 通道选择直接输出
    assign vld_ch = sel_ch;

    // 长度映射: 0->0,1->16,...,8->128,其余默认0
    always_comb begin
        unique case (len_code)
            4'd0: data_count = 16'd0;
            4'd1: data_count = 16'd16;
            4'd2: data_count = 16'd32;
            4'd3: data_count = 16'd48;
            4'd4: data_count = 16'd64;
            4'd5: data_count = 16'd80;
            4'd6: data_count = 16'd96;
            4'd7: data_count = 16'd112;
            4'd8: data_count = 16'd128;
            default: data_count = 16'd0;
        endcase
    end

endmodule
