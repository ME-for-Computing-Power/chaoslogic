//VCS coverage off

`timescale 1ns/100ps

module tb_frame_detector();

// 时钟和复位信号
logic clk_in;         // 输入数据时钟 (50-100MHz)
logic clk_out;        // FIFO读取时钟 (50-100MHz)
logic clk_out_s;      // 串行输出时钟 (16×clk_out)
logic rst_n;          // 异步复位 (低有效)

// 输入信号
logic [15:0] data_in; // 16位输入数据 (Big-Endian)

// 输出信号
logic data_out_ch1, data_out_ch2, data_out_ch3, data_out_ch4;
logic data_out_ch5, data_out_ch6, data_out_ch7, data_out_ch8;
logic data_vld_ch1, data_vld_ch2, data_vld_ch3, data_vld_ch4;
logic data_vld_ch5, data_vld_ch6, data_vld_ch7, data_vld_ch8;
//logic fifo_empty, fifo_full;
logic crc_valid, crc_err;

// 测试参数
localparam HEADER = 32'hE0E0E0E0;
localparam TRAILER = 32'h0E0E0E0E;
localparam CLK_PERIOD_IN = 32;   // 100MHz
localparam CLK_PERIOD_OUT = 32;  // 100MHz
localparam CLK_PERIOD_S = 2; // 1600MHz (16×clk_out)

// 实例化被测模块
top dut (
    .clk_in(clk_in),
    .clk_out(clk_out),
    .clk_out16x(clk_out_s),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out_ch1(data_out_ch1),
    .data_out_ch2(data_out_ch2),
    .data_out_ch3(data_out_ch3),
    .data_out_ch4(data_out_ch4),
    .data_out_ch5(data_out_ch5),
    .data_out_ch6(data_out_ch6),
    .data_out_ch7(data_out_ch7),
    .data_out_ch8(data_out_ch8),
    .data_vld_ch1(data_vld_ch1),
    .data_vld_ch2(data_vld_ch2),
    .data_vld_ch3(data_vld_ch3),
    .data_vld_ch4(data_vld_ch4),
    .data_vld_ch5(data_vld_ch5),
    .data_vld_ch6(data_vld_ch6),
    .data_vld_ch7(data_vld_ch7),
    .data_vld_ch8(data_vld_ch8),
    .fifo_empty(fifo_empty),
    .fifo_full(fifo_full),
    .crc_valid_o(crc_valid),
    .crc_err(crc_err)
);

// 时钟生成
initial begin
    clk_in = 0;
    forever #(CLK_PERIOD_IN/2) clk_in = ~clk_in;
end

initial begin
    #8;
    clk_out = 0;
    forever #(CLK_PERIOD_OUT/2) clk_out = ~clk_out;
end

initial begin
    #8;
    clk_out_s = 0;
    forever #(CLK_PERIOD_S/2) clk_out_s = ~clk_out_s;
end

// 二进制到格雷码转换函数
function automatic logic [127:0] bin2gray(input [127:0] bin);
    return bin ^ (bin >> 1);
endfunction

// 测试任务：发送完整帧
task send_frame;
    input [7:0]  channel;     // 通道选择 (独热码)
    input [127:0] data;        // 数据负载 (最大128位)
    input [15:0]  data_len;    // 数据长度 (16-128位)
    input [15:0]  crc;         // CRC校验值
    
    // 发送帧头
    //data_in = 0;  //fix me
    @(posedge clk_in);
    data_in = HEADER[31:16];
    @(posedge clk_in);
    data_in = HEADER[15:0];
    @(posedge clk_in);
    
    // 发送通道选择
    data_in = {8'b0, channel};
    @(posedge clk_in);
    
    // 发送数据
    for (int i = 0; i < data_len; i += 16) begin
        data_in = data[(data_len-i-1) -: 16]; // Big-Endian顺序
        @(posedge clk_in);
    end
    
    // 发送CRC
    data_in = crc;
    @(posedge clk_in);
    
    // 发送帧尾
    data_in = TRAILER[31:16];
    @(posedge clk_in);
    data_in = TRAILER[15:0];
    @(posedge clk_in);
    //data_in = 0;  //fix me
    //@(posedge clk_in);
endtask

// 测试任务：检查串行输出
task check_serial_output;
    input [3:0] channel;          // 通道号 (1-8)
    input [127:0] exp_data; // 预期数据
    input [15:0] data_len;  // 数据长度

    logic [127:0] exp_gray;
    
    logic data_vld;
    logic data_out;

    automatic logic error_flag = 0;
    // 等待有效信号
    fork
        wait(crc_valid === 1'b1);
        #128;
    join_any
    if (crc_valid === 1'b1)begin
        $display("[%0t ps] CH%d 数据输出开始", $time, channel);
        exp_gray = bin2gray(exp_data[127:0]);
        #1;
        // 收集串行数据 (修复循环变量冲突) 
        for (int bit_idx = data_len - 1; bit_idx >= 0; bit_idx--) begin
            case(channel)
                4'd1: begin data_vld = data_vld_ch1; data_out = data_out_ch1; end
                4'd2: begin data_vld = data_vld_ch2; data_out = data_out_ch2; end
                4'd3: begin data_vld = data_vld_ch3; data_out = data_out_ch3; end
                4'd4: begin data_vld = data_vld_ch4; data_out = data_out_ch4; end
                4'd5: begin data_vld = data_vld_ch5; data_out = data_out_ch5; end
                4'd6: begin data_vld = data_vld_ch6; data_out = data_out_ch6; end
                4'd7: begin data_vld = data_vld_ch7; data_out = data_out_ch7; end
                4'd8: begin data_vld = data_vld_ch8; data_out = data_out_ch8; end
            endcase
            if (exp_gray[bit_idx] != data_out) begin
                $error("[%0t ps] CH%d 数据不匹配! 位 %0d: 预期=%h, 实际=%h", 
                    $time, channel, bit_idx, exp_gray[bit_idx], data_out);
                error_flag = 1;
            end
            #CLK_PERIOD_S;
        end
        if (~error_flag) begin
            $display("[%0t ps] CH%d 数据验证通过, %0d 位数据正确", $time, channel, data_len);
        end else begin
            $error("[%0t ps] CH%d 数据验证失败, %0d 位数据错误", $time, channel, data_len);
        end
    end else begin
        $error("[%0t ps] CH%d CRC错误, 无法验证数据", $time, channel);
    end
endtask

logic [3:0] rand_channel;
logic [7:0] single_channel;
logic [127:0] rand_data;
logic [15:0] rand_len;
logic [127:0] sent_data;
// 主测试流程
initial begin
    // 初始化
    $display("\n===== init =====");
    data_in = 0;
    rst_n = 0;
    #100;
    rst_n = 1;
    #100;
    
    $display("\n===== 测试1: 基本功能测试 (16、32、48位数据) =====");
        test_single_frame(8'b0000_0001, 128'h0000_0000_0000_0000_0000_0000_0000_A55A, 16);
        fork 
            check_output(8'b0000_0001, 128'h0000_0000_0000_0000_0000_0000_0000_A55A, 16);
            test_single_frame(8'b0000_0001, 128'h0000_0000_0000_0000_0000_0000_1111_A55A, 32);
        join

        fork
            check_output(8'b0000_0001, 128'h0000_0000_0000_0000_0000_0000_1111_A55A, 32);
 
            $display("\n===== 测试2: 最大长度测试 (128位数据) =====");
            test_single_frame(8'b0000_0010, 128'h0123456789ABCDEFFEDCBA9876543210, 128);
        join

        fork
            check_output(8'b0000_0010, 128'h0123456789ABCDEFFEDCBA9876543210, 128);

            $display("\n===== 测试3: 边界长度测试 =====");
            test_single_frame(8'b0000_0100, 128'h1234, 16);  // 最小长度
        join

        fork
            check_output(8'b0000_0100, 128'h1234, 16);

            test_single_frame(8'b0001_0000, 128'hA5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5, 128); // 最大长度
        join
        check_output(8'b0001_0000, 128'hA5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5, 128);

    // 大规模随机测试
    $display("\n===== 测试4: 大规模随机测试 =====");
    $display("[%0t ps] 进行第 1 次随机测试", $time);
    test_rand_frame(single_channel, sent_data, rand_len);
    
    for (int i = 1; i < 50000; i++) begin
        fork
            check_output(single_channel, sent_data, rand_len);
            $display("[%0t ps] 进行第 %0d 次随机测试", $time, i+1);
            test_rand_frame(single_channel, sent_data, rand_len);
        join
    end 

    // 添加错误测试
    $display("\n===== 测试5: CRC错误测试 =====");
    send_frame(8'b0000_0001, 128'h0000_0000_0000_0000_0000_0000_0000_1234, 16, 16'hFFFF); // 错误CRC
    wait(crc_err === 1'b1);
    $display("crc_err验证通过");
    if(data_vld_ch1 !== 0) $error("CRC错误时不应有有效输出");

    
    //超长数据测试
    send_oversize_frame(8'b0010_0000,{128{2'b10}}, 16'h1145);
    $display("\n===== 所有测试结束 =====");
    $dumpflush;
    $finish;
end

// 测试任务：发送超长帧
task send_oversize_frame;
    input [7:0]  channel;     // 通道选择 (独热码)
    input [255:0] data;        // 数据负载 (最大128位)
    input [15:0]  crc;         // CRC校验值
    
    automatic logic [31:0] data_len = 32'd256;
    // 发送帧头
    //data_in = 0;  //fix me
    @(posedge clk_in);
    data_in = HEADER[31:16];
    @(posedge clk_in);
    data_in = HEADER[15:0];
    @(posedge clk_in);
    
    // 发送通道选择
    data_in = {8'b0, channel};
    @(posedge clk_in);
    
    // 发送数据
    for (int i = 0; i < data_len; i += 16) begin
        data_in = data[(data_len-i-1) -: 16]; // Big-Endian顺序
        @(posedge clk_in);
    end
    
    // 发送CRC
    data_in = crc;
    @(posedge clk_in);
    
    // 发送帧尾
    data_in = TRAILER[31:16];
    @(posedge clk_in);
    data_in = TRAILER[15:0];
    @(posedge clk_in);
    //data_in = 0;  //fix me
    //@(posedge clk_in);
endtask

task automatic test_rand_frame(ref logic [7:0] single_channel, ref logic [127:0] sent_data, ref logic [15:0] rand_len);
    logic [7:0] rand_channel;
    logic [127:0] rand_data;
    rand_channel = $urandom() >> (32 - 8); // 生成随机通道
    single_channel = 1'b1 << (rand_channel % 8); // 独热码
    rand_data = {$urandom(), $urandom(), $urandom(), $urandom()}; // 生成随机数据
    rand_len = ($urandom()>> (32-3)) * 16; // 随机长度 (16-128位,16的倍数)
    if (rand_len < 16) rand_len = 16; // 确保最小长度为16位
    if (rand_len > 128) rand_len = 128; // 确保最大长度为128位
    sent_data = rand_data >> (128 - rand_len); // 截断数据到指定长度
    test_single_frame(single_channel, sent_data, rand_len);
endtask : test_rand_frame


task automatic crc16_ccitt(
    input  logic [127:0] data,
    output logic [15:0] crc_value
);
    reg [15:0] data_to_crc;
    reg [15:0] lfsr_q,lfsr_c;
    lfsr_q = 0;

    // 逐位处理 128 位输入数据

    for (int i = 127; i > 0; i-=16) begin
        data_to_crc = data[(i-15)+:16];
        lfsr_c[0] = lfsr_q[0] ^ lfsr_q[4] ^ lfsr_q[8] ^ lfsr_q[11] ^ lfsr_q[12] ^ data_to_crc[0] ^ data_to_crc[4] ^ data_to_crc[8] ^ data_to_crc[11] ^ data_to_crc[12];
        lfsr_c[1] = lfsr_q[1] ^ lfsr_q[5] ^ lfsr_q[9] ^ lfsr_q[12] ^ lfsr_q[13] ^ data_to_crc[1] ^ data_to_crc[5] ^ data_to_crc[9] ^ data_to_crc[12] ^ data_to_crc[13];
        lfsr_c[2] = lfsr_q[2] ^ lfsr_q[6] ^ lfsr_q[10] ^ lfsr_q[13] ^ lfsr_q[14] ^ data_to_crc[2] ^ data_to_crc[6] ^ data_to_crc[10] ^ data_to_crc[13] ^ data_to_crc[14];
        lfsr_c[3] = lfsr_q[3] ^ lfsr_q[7] ^ lfsr_q[11] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_to_crc[3] ^ data_to_crc[7] ^ data_to_crc[11] ^ data_to_crc[14] ^ data_to_crc[15];
        lfsr_c[4] = lfsr_q[4] ^ lfsr_q[8] ^ lfsr_q[12] ^ lfsr_q[15] ^ data_to_crc[4] ^ data_to_crc[8] ^ data_to_crc[12] ^ data_to_crc[15];
        lfsr_c[5] = lfsr_q[0] ^ lfsr_q[4] ^ lfsr_q[5] ^ lfsr_q[8] ^ lfsr_q[9] ^ lfsr_q[11] ^ lfsr_q[12] ^ lfsr_q[13] ^ data_to_crc[0] ^ data_to_crc[4] ^ data_to_crc[5] ^ data_to_crc[8] ^ data_to_crc[9] ^ data_to_crc[11] ^ data_to_crc[12] ^ data_to_crc[13];
        lfsr_c[6] = lfsr_q[1] ^ lfsr_q[5] ^ lfsr_q[6] ^ lfsr_q[9] ^ lfsr_q[10] ^ lfsr_q[12] ^ lfsr_q[13] ^ lfsr_q[14] ^ data_to_crc[1] ^ data_to_crc[5] ^ data_to_crc[6] ^ data_to_crc[9] ^ data_to_crc[10] ^ data_to_crc[12] ^ data_to_crc[13] ^ data_to_crc[14];
        lfsr_c[7] = lfsr_q[2] ^ lfsr_q[6] ^ lfsr_q[7] ^ lfsr_q[10] ^ lfsr_q[11] ^ lfsr_q[13] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_to_crc[2] ^ data_to_crc[6] ^ data_to_crc[7] ^ data_to_crc[10] ^ data_to_crc[11] ^ data_to_crc[13] ^ data_to_crc[14] ^ data_to_crc[15];
        lfsr_c[8] = lfsr_q[3] ^ lfsr_q[7] ^ lfsr_q[8] ^ lfsr_q[11] ^ lfsr_q[12] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_to_crc[3] ^ data_to_crc[7] ^ data_to_crc[8] ^ data_to_crc[11] ^ data_to_crc[12] ^ data_to_crc[14] ^ data_to_crc[15];
        lfsr_c[9] = lfsr_q[4] ^ lfsr_q[8] ^ lfsr_q[9] ^ lfsr_q[12] ^ lfsr_q[13] ^ lfsr_q[15] ^ data_to_crc[4] ^ data_to_crc[8] ^ data_to_crc[9] ^ data_to_crc[12] ^ data_to_crc[13] ^ data_to_crc[15];
        lfsr_c[10] = lfsr_q[5] ^ lfsr_q[9] ^ lfsr_q[10] ^ lfsr_q[13] ^ lfsr_q[14] ^ data_to_crc[5] ^ data_to_crc[9] ^ data_to_crc[10] ^ data_to_crc[13] ^ data_to_crc[14];
        lfsr_c[11] = lfsr_q[6] ^ lfsr_q[10] ^ lfsr_q[11] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_to_crc[6] ^ data_to_crc[10] ^ data_to_crc[11] ^ data_to_crc[14] ^ data_to_crc[15];
        lfsr_c[12] = lfsr_q[0] ^ lfsr_q[4] ^ lfsr_q[7] ^ lfsr_q[8] ^ lfsr_q[15] ^ data_to_crc[0] ^ data_to_crc[4] ^ data_to_crc[7] ^ data_to_crc[8] ^ data_to_crc[15];
        lfsr_c[13] = lfsr_q[1] ^ lfsr_q[5] ^ lfsr_q[8] ^ lfsr_q[9] ^ data_to_crc[1] ^ data_to_crc[5] ^ data_to_crc[8] ^ data_to_crc[9];
        lfsr_c[14] = lfsr_q[2] ^ lfsr_q[6] ^ lfsr_q[9] ^ lfsr_q[10] ^ data_to_crc[2] ^ data_to_crc[6] ^ data_to_crc[9] ^ data_to_crc[10];
        lfsr_c[15] = lfsr_q[3] ^ lfsr_q[7] ^ lfsr_q[10] ^ lfsr_q[11] ^ data_to_crc[3] ^ data_to_crc[7] ^ data_to_crc[10] ^ data_to_crc[11];
        lfsr_q = lfsr_c;
    end
    crc_value = lfsr_c;
endtask

// 测试单个帧的任务
task test_single_frame;
    input [7:0]  channel;
    input [127:0] data;
    input [15:0] data_len;
    
    automatic logic [15:0] crc_value = 16'h0000;

    crc16_ccitt(data,crc_value); // 计算CRC值
    $display("[%0t ps] tb计算CRC: %h", $time, crc_value);
    // 发送帧
    $display("[%0t ps] 发送帧: 通道=%b, 长度=%0d", $time, channel, data_len);
    $display("[%0t ps] 发送数据: %h", $time, data);
    $display("[%0t ps] 发送CRC: %h", $time, crc_value);
    // 发送帧
    send_frame(channel, data, data_len, crc_value);
endtask


task check_output ;
    input [7:0]  channel;
    input [127:0] data;
    input [15:0] data_len;
// 检查输出
    for (int ch = 1; ch <= 8; ch++) begin
        if (channel[ch-1]) begin
            $display("[%0t ps] 检查CH%d输出", $time, ch);
            check_serial_output(ch, data, data_len);
        end
    end

endtask

// 监控错误信号
always @(posedge clk_in) begin
    if (crc_err) $warning("[%0t ps] CRC错误检测", $time);
end

initial begin
    #1000000000;
    $dumpflush;
    $error("仿真超时");
    $finish;
end


//fsdb dump 
// initial begin
//     $fsdbDumpfile("wave.fsdb");
//     $fsdbDumpvars(0, tb_frame_detector, "+all");
//     $fsdbDumpMDA();
// end

//vcd dump
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_frame_detector);
end
endmodule

//VCS coverage on