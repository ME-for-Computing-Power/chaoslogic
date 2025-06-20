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
localparam IDLE = 1'b0;
localparam SEND = 1'b1;
wire [7:0] data_out;
wire [7:0] data_vld;
assign crc_valid = |data_vld;
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
    reg state;
    reg [127:0] shift_reg;
    reg [15:0] counter;
    reg [15:0] data_count_reg;
    reg out_bit;
    reg out_valid;
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
                    out_valid <= 1'b0;
                    if (vld_ch[i]) begin
                        shift_reg <= data_gray;
                        data_count_reg <= data_count;
                        counter <= 16'd1;
                        out_bit <= data_gray[127];
                        out_valid <= 1'b1;
                        state <= SEND;
                    end
                    else begin
                        out_bit <= 1'b0;
                    end
                end
                SEND: begin
                    shift_reg <= {shift_reg[126:0], 1'b0};
                    out_bit <= shift_reg[127];
                    counter <= counter + 1'b1;
                    if (counter >= data_count_reg) begin
                        state <= IDLE;
                        out_valid <= 1'b0;
                        out_bit <= 1'b0;
                    end
                    else begin
                        out_valid <= 1'b1;
                    end
                end
            endcase
        end
    end
end
endgenerate
endmodule