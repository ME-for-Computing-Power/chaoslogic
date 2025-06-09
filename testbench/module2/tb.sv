module tb;
    // 参数定义
    localparam int DW = 140;
    localparam int DEPTH = 2;

    // 信号定义
    reg clk_in, clk_out, rst_n;
    reg fifo_w_enable, fifo_r_enable;
    reg  [DW-1:0] data_to_fifo;
    wire [DW-1:0] data_from_fifo;
    wire fifo_empty, fifo_full;

    // reference model
    logic [DW-1:0] ref_queue[$];
    // 随机写入读出测试用变量
    int i, wcnt, rcnt;

    // 实例化被测模块
    async_fifo u_dut (
        .clk_in(clk_in),
        .clk_out(clk_out),
        .rst_n(rst_n),
        .fifo_w_enable(fifo_w_enable),
        .fifo_r_enable(fifo_r_enable),
        .data_to_fifo(data_to_fifo),
        .data_from_fifo(data_from_fifo),
        .fifo_empty(fifo_empty),
        .fifo_full(fifo_full)
    );

    // 时钟生成，180度相位差
    initial clk_in = 0;
    always #5 clk_in = ~clk_in;
    initial clk_out = 1;
    always #5 clk_out = ~clk_out;

    // 任务：复位
    task automatic do_reset();
        rst_n = 0;
        fifo_w_enable = 0;
        fifo_r_enable = 0;
        data_to_fifo = 0;
        repeat (4) @(posedge clk_in);
        rst_n = 1;
        repeat (2) @(posedge clk_in);
    endtask

    // 写入数据
    task automatic write_fifo(input logic [DW-1:0] d);
        fifo_w_enable = 1;
        data_to_fifo  = d;
        @(posedge clk_in);
        fifo_w_enable = 0;
        data_to_fifo  = 0;
        // reference model push
        if (!fifo_full) ref_queue.push_back(d);
    endtask

    // 读出数据
    task automatic read_fifo();
        fifo_r_enable = 1;
        @(posedge clk_out);
        fifo_r_enable = 0;
        // reference model pop & compare
        if (!fifo_empty && ref_queue.size() > 0) begin
            logic [DW-1:0] ref_data = ref_queue.pop_front();
            if (data_from_fifo !== ref_data)
                $display("[ASSERT FAIL] 参考模型比对失败: 期望 %h, 实际 %h", ref_data, data_from_fifo);
        end
    endtask

    // 检查信号
    task automatic check_full_empty(input logic expect_full, input logic expect_empty);
        repeat (2) @(posedge clk_in);
        if (!(fifo_full === expect_full))
            $display("[ASSERT FAIL] fifo_full error: expect %0d, got %0d", expect_full, fifo_full);
        if (!(fifo_empty === expect_empty))
            $display("[ASSERT FAIL] fifo_empty error: expect %0d, got %0d", expect_empty, fifo_empty);
    endtask

    // 主测试流程
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);
        $display("=== TB Start ===");
        do_reset();

        // 空满信号测试
        // 先填满fifo
        write_fifo($urandom);
        write_fifo($urandom);
        check_full_empty(1, 0);  // 满
        // 读空fifo
        read_fifo();
        read_fifo();
        check_full_empty(0, 1);  // 空
        $display("[TB] 空满信号测试完成");

        // 复位测试
        write_fifo($urandom);
        write_fifo($urandom);
        check_full_empty(1, 0);
        do_reset();
        check_full_empty(0, 1);
        $display("[TB] 复位测试完成");

        // 写使能信号测试
        do_reset();
        fifo_w_enable = 0;
        data_to_fifo  = $urandom;
        @(posedge clk_in);
        // 不使能写，fifo应为空
        check_full_empty(0, 1);
        // 使能写
        write_fifo(32'hA5A5A5A5);
        read_fifo();
        repeat (2) @(posedge clk_out);
        // 参考模型比对已在read_fifo中自动完成
        $display("[TB] 写使能信号测试完成");

        // 随机写入读出测试
        do_reset();
        wcnt = 0;
        rcnt = 0;
        for (i = 0; i < 20; i++) begin
            if (!$urandom_range(0, 1) && !fifo_full) begin
                logic [DW-1:0] rand_data = $urandom;
                write_fifo(rand_data);
            end
            if (!$urandom_range(0, 1) && !fifo_empty) begin
                read_fifo();
            end
        end
        $display("[TB] 随机写入读出测试完成，随机写入次数: %0d, 随机读出次数: %0d", wcnt, rcnt);

        $display("=== TB Finish ===");
        $finish;
    end
endmodule
