
module tb();
  // 时钟和复位信号
  reg clk_in = 0;
  reg clk_out = 0;
  reg rst_n;
  
  // FIFO控制信号
  reg fifo_w_enable;
  reg fifo_r_enable;
  reg [139:0] data_to_fifo;
  
  // DUT输出
  wire [139:0] dut_data;
  wire dut_empty;
  wire dut_full;
  
  // 参考模型输出
  wire [139:0] ref_data;
  wire ref_empty;
  wire ref_full;
  
  // 时钟生成
  always #5 clk_in = ~clk_in;         // 100MHz (周期10ns)
  always #5 clk_out = ~clk_out;       // 同频但180度相位差
  
  // DUT实例化
  async_fifo dut (
    .clk_in(clk_in),
    .clk_out(clk_out),
    .rst_n(rst_n),
    .fifo_w_enable(fifo_w_enable),
    .fifo_r_enable(fifo_r_enable),
    .data_to_fifo(data_to_fifo),
    .data_from_fifo(dut_data),
    .fifo_empty(dut_empty),
    .fifo_full(dut_full)
  );
  
  // 参考模型实例化
  ref_model ref_inst (
    .clk_in(clk_in),
    .clk_out(clk_out),
    .rst_n(rst_n),
    .fifo_w_enable(fifo_w_enable),
    .fifo_r_enable(fifo_r_enable),
    .data_to_fifo(data_to_fifo),
    .data_from_fifo(ref_data),
    .fifo_empty(ref_empty),
    .fifo_full(ref_full)
  );
  
  // 波形记录
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);
  end
  
  // 检查输出差异
  always @(negedge clk_out) begin
    if (dut_empty !== ref_empty) begin
      $display("[ERROR] EMPTY mismatch at time %0t", $time);
      $display("  DUT: %b, REF: %b", dut_empty, ref_empty);
    end
    
    if (dut_full !== ref_full) begin
      $display("[ERROR] FULL mismatch at time %0t", $time);
      $display("  DUT: %b, REF: %b", dut_full, ref_full);
    end
    
    if (dut_data !== ref_data && !ref_empty) begin
      $display("[ERROR] DATA mismatch at time %0t", $time);
      $display("  DUT: %h, REF: %h", dut_data, ref_data);
    end
  end
  
  // 测试主程序
  initial begin
    // 初始化
    rst_n = 0;
    fifo_w_enable = 0;
    fifo_r_enable = 0;
    data_to_fifo = 0;
    
    // 复位至少5个周期
    repeat(10) @(negedge clk_in);
    rst_n = 1;
    
    // 执行所有测试
    test_empty_full();  // 空满信号测试
    test_reset();       // 复位测试
    test_w_enable();    // 写使能测试
    test_r_enable();    // 读使能测试
    test_random();      // 随机读写测试
    test_continuous();  // 连续读写测试
    
    // 完成
    $display("All tests completed");
    $finish;
  end
  
  // ========== 测试任务 ==========
  
  // 空满信号测试
  task test_empty_full;
    begin
      $display("Starting empty/full test");
      
      // 写满FIFO
      while(!dut_full) begin
        @(negedge clk_in);
        fifo_w_enable = 1;
        data_to_fifo = $urandom();
      end
      
      // 验证满标志
      if(!dut_full) begin
        $display("[ERROR] FIFO should be full");
      end
      
      // 等待并释放
      @(negedge clk_in);
      fifo_w_enable = 0;
      repeat(2) @(negedge clk_out);
      
      // 读空FIFO
      while(!dut_empty) begin
        @(negedge clk_out);
        fifo_r_enable = 1;
      end
      
      // 验证空标志
      if(!dut_empty) begin
        $display("[ERROR] FIFO should be empty");
      end
      
      // 等待并释放
      @(negedge clk_out);
      fifo_r_enable = 0;
      repeat(2) @(negedge clk_out);
      
      $display("Empty/full test completed\n");
    end
  endtask
  
  // 复位测试
  task test_reset;
    begin
      $display("Starting reset test");
      
      // 写满FIFO
      while(!dut_full) begin
        @(negedge clk_in);
        fifo_w_enable = 1;
        data_to_fifo = $urandom();
      end
      
      // 复位
      @(negedge clk_in);
      rst_n = 0;
      repeat(5) @(negedge clk_in);
      rst_n = 1;
      
      // 验证复位后状态
      if(!dut_empty || dut_full) begin
        $display("[ERROR] Reset failed - empty:%b full:%b", dut_empty, dut_full);
      end
      
      // 尝试读取应该为空
      @(negedge clk_out);
      fifo_r_enable = 1;
      if(dut_data !== 140'b0) begin
        $display("[ERROR] Data should be zero after reset");
      end
      
      // 重新写入读取
      @(negedge clk_in);
      fifo_w_enable = 1;
      data_to_fifo = $urandom();
      @(negedge clk_in);
      fifo_w_enable = 0;
      
      repeat(2) @(negedge clk_out);
      fifo_r_enable = 1;
      @(negedge clk_out);
      fifo_r_enable = 0;
      
      $display("Reset test completed\n");
    end
  endtask
  
  // 写使能测试
  task test_w_enable;
    begin
      $display("Starting write enable test");
      
      // 禁用写使能时尝试写入
      @(negedge clk_in);
      fifo_w_enable = 0;
      data_to_fifo = $urandom();
      repeat(2) @(negedge clk_in);
      
      // 启用写使能
      @(negedge clk_in);
      fifo_w_enable = 1;
      data_to_fifo = $urandom();
      @(negedge clk_in);
      fifo_w_enable = 0;
      
      // 写满后继续写入
      while(!dut_full) begin
        @(negedge clk_in);
        fifo_w_enable = 1;
        data_to_fifo = $urandom();
      end
      
      // 满状态继续写
      @(negedge clk_in);
      fifo_w_enable = 1;
      data_to_fifo = $urandom();
      @(negedge clk_in);
      fifo_w_enable = 0;
      
      // 写入后读出验证
      repeat(2) @(negedge clk_out);
      fifo_r_enable = 1;
      @(negedge clk_out);
      fifo_r_enable = 0;
      
      $display("Write enable test completed\n");
    end
  endtask
  
  // 读使能测试
  task test_r_enable;
    begin
      $display("Starting read enable test");
      
      // 写入一个数据
      @(negedge clk_in);
      fifo_w_enable = 1;
      data_to_fifo = $urandom();
      @(negedge clk_in);
      fifo_w_enable = 0;
      
      // 禁用读使能时尝试读取
      repeat(2) @(negedge clk_out);
      fifo_r_enable = 0;
      
      // 启用读使能
      @(negedge clk_out);
      fifo_r_enable = 1;
      @(negedge clk_out);
      fifo_r_enable = 0;
      
      $display("Read enable test completed\n");
    end
  endtask
  
  // 随机读写测试
  task test_random;
    integer i;
    begin
      $display("Starting random read/write test");
      
      for(i=0; i<100; i=i+1) begin
        @(negedge clk_in);
        
        // 随机生成写操作 (仅在不满时允许写)
        fifo_w_enable = !dut_full && ($urandom_range(0,1));
        if(fifo_w_enable) 
          data_to_fifo = $urandom();
        
        @(negedge clk_out);
        
        // 随机生成读操作 (仅在非空时允许读)
        fifo_r_enable = !dut_empty && ($urandom_range(0,1));
        
        #1; // 确保在时钟边沿后采样
      end
      
      $display("Random read/write test completed\n");
    end
  endtask
  
  // 连续读写测试
  task test_continuous;
    integer i;
    begin
      $display("Starting continuous read/write test");
      
      // 连续写入直到满
      fifo_w_enable = 1;
      for(i=0; i<10; i=i+1) begin
        @(negedge clk_in);
        data_to_fifo = $urandom();
        if(dut_full) break;
      end
      fifo_w_enable = 0;
      
      // 同时读写
      fork
        begin // 写线程
          for(i=0; i<20; i=i+1) begin
            @(negedge clk_in);
            if(!dut_full) begin
              fifo_w_enable = 1;
              data_to_fifo = $urandom();
            end
            else begin
              fifo_w_enable = 0;
            end
          end
        end
        
        begin // 读线程
          for(i=0; i<20; i=i+1) begin
            @(negedge clk_out);
            if(!dut_empty) begin
              fifo_r_enable = 1;
            end
            else begin
              fifo_r_enable = 0;
            end
          end
        end
      join
      
      // 清理
      fifo_w_enable = 0;
      fifo_r_enable = 0;
      
      $display("Continuous read/write test completed\n");
    end
  endtask
  
endmodule
