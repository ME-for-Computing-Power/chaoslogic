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
    logic [127:0] shift_reg;
    logic [15:0]  bit_cnt;
    logic         active;
    logic  [7:0]  vld_latched;
    always_ff @(posedge clk_out16x or negedge rst_n) begin
        if (!rst_n) begin
            active       <= 1'b0;
            bit_cnt      <= 16'd0;
            shift_reg    <= 128'd0;
            vld_latched  <= 8'd0;
        end else begin
            if (!active) begin
                if (|vld_ch) begin
                    active      <= 1'b1;
                    bit_cnt     <= 16'd0;
                    shift_reg   <= data_gray;
                    vld_latched <= vld_ch;
                end
            end else begin
                shift_reg <= {shift_reg[126:0], 1'b0};
                bit_cnt   <= bit_cnt + 16'd1;
                if (bit_cnt + 16'd1 == data_count) begin
                    active <= 1'b0;
                end
            end
        end
    end
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
    assign crc_valid = |{data_vld_ch1, data_vld_ch2, data_vld_ch3, data_vld_ch4,
                         data_vld_ch5, data_vld_ch6, data_vld_ch7, data_vld_ch8};
endmodule