`timescale 1ns/1ns

module frame_detector (
    // 系统时钟与复位
    input         clk_in,        // 系统时钟 (帧解析和CRC计算)
    input         clk_out,       // FIFO读时钟
    input         clk_out_s,    // 串行输出高速时钟 (16倍频)
    input         rst_n,         // 低电平异步复位
    
    // 数据输入接口
    input  [15:0] data_in,       // 16位输入数据
    
    // FIFO控制接口
    //input         fifo_r_enable, // FIFO读使能
    
    // 状态指示
    output        crc_err,       // CRC错误标志
    output        fifo_full,     // FIFO满标志
    output        fifo_empty,    // FIFO空标志
    
    // 串行输出接口
    output        crc_valid_o,     // CRC有效标志
    output        data_out_ch1,  // 通道1串行数据
    output        data_out_ch2,  // 通道2串行数据
    output        data_out_ch3,  // 通道3串行数据
    output        data_out_ch4,  // 通道4串行数据
    output        data_out_ch5,  // 通道5串行数据
    output        data_out_ch6,  // 通道6串行数据
    output        data_out_ch7,  // 通道7串行数据
    output        data_out_ch8,  // 通道8串行数据
    output        data_vld_ch1,  // 通道1数据有效
    output        data_vld_ch2,  // 通道2数据有效
    output        data_vld_ch3,  // 通道3数据有效
    output        data_vld_ch4,  // 通道4数据有效
    output        data_vld_ch5,  // 通道5数据有效
    output        data_vld_ch6,  // 通道6数据有效
    output        data_vld_ch7,  // 通道7数据有效
    output        data_vld_ch8   // 通道8数据有效
);

wire fifo_r_enable = 1'b1; // FIFO读使能信号，暂时设为高电平

    // ================= 信号声明 =================
    // 帧解析模块输出
    wire [139:0] data_to_fifo;
    wire         fifo_w_enable;
    
    // CRC模块接口
    wire [15:0]  data_to_crc;
    wire [15:0]  data_from_crc;
    
    // FIFO接口
    wire [139:0] data_from_fifo;
    
    // 数据转换模块输出
    wire [127:0] data_gray;
    wire [7:0]   vld_ch;
    wire [15:0]  data_count;
    wire [15:0]  crc;
wire crc_valid;

assign crc_valid_o = crc_valid; // 将CRC有效信号输出
    // ================= 模块实例化 =================
    // 1. 帧解析与CRC校验模块
    frame_parser u_frame_parser (
        .clk_in       (clk_in),
        .rst_n        (rst_n),
        .data_in      (data_in),
        .data_to_fifo (data_to_fifo),
        .fifo_w_enable(fifo_w_enable),
        .crc_err      (crc_err),
        .data_to_crc  (data_to_crc),
        .crc          (crc),
        .data_from_crc(data_from_crc)
    );
    
    // 2. CRC计算模块
    crc_module u_crc_module (
        .data_to_crc  (data_to_crc),
        .crc          (crc),
        .data_from_crc(data_from_crc)
    );

    // 3. 异步FIFO模块
    fifo_wrapper u_fifo_wrapper (
        .clk_in       (clk_in),
        .clk_out      (clk_out),
        .rst_n        (rst_n),
        .fifo_w_enable(fifo_w_enable),
        .fifo_r_enable(fifo_r_enable),
        .data_to_fifo (data_to_fifo),
        .data_from_fifo(data_from_fifo),
        .fifo_empty   (fifo_empty),
        .fifo_full    (fifo_full)
    );
    
    // 4. 数据转换模块 (FIFO输出处理)
    gray_conv u_gray_conv (
        .data_from_fifo(data_from_fifo),
        .data_gray    (data_gray),
        .vld_ch       (vld_ch),
        .data_count   (data_count)
    );
    
    // 5. 串行输出模块
    serial_output u_serial_output (
        .rst_n        (rst_n),
        .clk_out16x   (clk_out_s),
        .data_gray    (data_gray),
        .vld_ch       (vld_ch),
        .data_count   (data_count),
        .crc_valid    (crc_valid),
        .data_out_ch1 (data_out_ch1),
        .data_out_ch2 (data_out_ch2),
        .data_out_ch3 (data_out_ch3),
        .data_out_ch4 (data_out_ch4),
        .data_out_ch5 (data_out_ch5),
        .data_out_ch6 (data_out_ch6),
        .data_out_ch7 (data_out_ch7),
        .data_out_ch8 (data_out_ch8),
        .data_vld_ch1 (data_vld_ch1),
        .data_vld_ch2 (data_vld_ch2),
        .data_vld_ch3 (data_vld_ch3),
        .data_vld_ch4 (data_vld_ch4),
        .data_vld_ch5 (data_vld_ch5),
        .data_vld_ch6 (data_vld_ch6),
        .data_vld_ch7 (data_vld_ch7),
        .data_vld_ch8 (data_vld_ch8)
    );

endmodule