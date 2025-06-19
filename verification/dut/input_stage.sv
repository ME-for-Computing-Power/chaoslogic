`timescale 1ns/1ns

module input_stage (
        input         clk_in,        // 系统时钟
        input         rst_n,         // 低电平复位
        input [15:0]  data_in,       // 输入数据（16位）

        output logic [139:0] data_to_fifo,      // FIFO写入数据（140位）
        output logic         fifo_w_enable,    // FIFO写入使能
        output logic         crc_err,          // CRC错误标志
        output logic         crc_done,

        output logic [15:0]  data_to_crc,
        output logic [15:0]  crc,
        input  logic [15:0]  data_from_crc     // 从CRC计算模块接收的16位数据
    );

// 状态定义
    typedef enum {
        IDLE,
        CHANNEL,
        DATA
    } state_t;
    state_t state;
    logic [15:0] ch_sel;
    logic [47:0] data_buffer;
    logic [127:0] data;
    logic [15:0]  data_count;
    reg [1:0] wait_count;  // 2位计数器，用于替代WAIT状态
    always_ff @( posedge clk_in or negedge rst_n) begin
        if(!rst_n)
        begin
            state <= IDLE;
            fifo_w_enable <= 0;
            crc_err <= 0;
            data <= 128'b0;
            data_to_fifo <= 140'b0;
            wait_count <= 0;
        end
        else 
        begin
            data_buffer <= {data_buffer[31:0],data_in};
            case(state)
                IDLE:
                begin
                    //if(data_buffer[31:0] == 32'he0e0e0e0)    state <= WAIT_1;   
                    if (data_buffer[31:0] == 32'he0e0e0e0 && wait_count == 0)
                    begin
                        wait_count <= 1;  // 标记第一个等待周期
                    end
                    else if (wait_count == 1)
                    begin
                        wait_count <= 2;  // 标记第二个等待周期
                    end
                    else if (wait_count == 2)
                    begin
                        state <= CHANNEL; // 满足两个周期等待后进入 CHANNEL
                        wait_count <= 0;
                    end
                    else state <= state;
                    crc <= 16'h0000;
                    data_count <= 16'h0000;
                    crc_err <= 0;
                    fifo_w_enable <= 0;
                    data_to_crc <= 16'h0000;
                end
                CHANNEL:
                begin
                    ch_sel <= data_buffer[47:32];
                    state <= DATA;
                end
                DATA:
                begin
                    if(data_buffer[31:0] == 32'h0e0e0e0e)
                    begin
                        state <= IDLE;
                        if(data_count > 0 && data_from_crc == data_buffer[47:32])
                        begin
                            crc_err <= 0;
                            case(data_count)
                                16'd16:
                                    data_to_fifo <= {data[15:0],112'd0,ch_sel[7:0],data_count[7:4]};
                                16'd32:
                                    data_to_fifo <= {data[31:0],96'd0,ch_sel[7:0],data_count[7:4]};
                                16'd48:
                                    data_to_fifo <= {data[47:0],80'd0,ch_sel[7:0],data_count[7:4]};
                                16'd64:
                                    data_to_fifo <= {data[63:0],64'd0,ch_sel[7:0],data_count[7:4]};
                                16'd80:
                                    data_to_fifo <= {data[79:0],48'd0,ch_sel[7:0],data_count[7:4]};
                                16'd96:
                                    data_to_fifo <= {data[95:0],32'd0,ch_sel[7:0],data_count[7:4]};
                                16'd112:
                                    data_to_fifo <= {data[111:0],16'd0,ch_sel[7:0],data_count[7:4]};
                                16'd128:
                                    data_to_fifo <= {data[127:0],ch_sel[7:0],data_count[7:4]};
                                default:
                                    data_to_fifo <= 0;
                            endcase
                            fifo_w_enable <= 1;
                        end
                        else
                        begin
                            crc_err <= 1;
                            fifo_w_enable <= 0;
                        end
                    end
                    else 
                    begin
                        data_count <= data_count + 16'd16;
                        if(data_count > 16'd122)
                            state <= IDLE;
                        else 
                            state <= DATA;
                        data_to_crc <= data_buffer[47:32];
                        crc <= data_from_crc;
                        data <= {data[111:0],data_buffer[47:32]};
                    end
                end
                default:
                begin
                    state <= IDLE; // 默认状态回到IDLE
                    fifo_w_enable <= 0;
                    crc_err <= 0;
                    data_to_fifo <= 140'b0;
                    data_to_crc <= 16'h0000;
                    crc <= 16'h0000;
                end
            endcase
        end
    end

endmodule