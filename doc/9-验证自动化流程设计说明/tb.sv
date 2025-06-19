module tb;
  reg [139:0] data_from_fifo;
  wire [127:0] dut_data_gray, ref_data_gray;
  wire [7:0] dut_vld_ch, ref_vld_ch;
  wire [15:0] dut_data_count, ref_data_count;
  
  fifo_data_resolu dut (
    .data_from_fifo(data_from_fifo),
    .data_gray(dut_data_gray),
    .vld_ch(dut_vld_ch),
    .data_count(dut_data_count)
  );
  
  ref_model ref_inst (
    .data_from_fifo(data_from_fifo),
    .data_gray(ref_data_gray),
    .vld_ch(ref_vld_ch),
    .data_count(ref_data_count)
  );
  
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);
  end
  
  always @* begin
    #10;
    
    if (dut_vld_ch !== ref_vld_ch) begin
      $display("[ERROR] vld_ch mismatch at time %t", $time);
      $display("  Input: %h", data_from_fifo);
      $display("  DUT vld_ch = %h", dut_vld_ch);
      $display("  REF vld_ch = %h", ref_vld_ch);
      $finish;
    end
    
    if (dut_data_count !== ref_data_count) begin
      $display("[ERROR] data_count mismatch at time %t", $time);
      $display("  Input: %h", data_from_fifo);
      $display("  DUT data_count = %h", dut_data_count);
      $display("  REF data_count = %h", ref_data_count);
      $finish;
    end
    
    if (dut_data_gray !== ref_data_gray) begin
      $display("[ERROR] data_gray mismatch at time %t", $time);
      $display("  Input: %h", data_from_fifo);
      $display("  DUT data_gray = %h", dut_data_gray);
      $display("  REF data_gray = %h", ref_data_gray);
      $finish;
    end
  end
  
  integer i;
  reg [3:0] test_length;
  reg [127:0] test_data;
  
  initial begin
    test_data = 128'hA5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5;
    test_length = 4'd8;
    data_from_fifo = {test_data, 8'hFF, test_length};
    #100;
    
    test_data = 128'h5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A;
    test_length = 4'd4;
    data_from_fifo = {test_data, 8'hAA, test_length};
    #100;
    
    for (i = 0; i <= 15; i = i + 1) begin
      test_length = i[3:0];
      test_data = $random;
      data_from_fifo = {test_data, $random, test_length};
      #100;
    end
    
    data_from_fifo = 140'd0;
    #100;
    
    data_from_fifo = {128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 8'hFF, 4'h8};
    #100;
    
    test_data = 128'h55555555555555555555555555555555;
    data_from_fifo = {test_data, $random, 4'h8};
    #100;
    
    test_data = 128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    data_from_fifo = {test_data, $random, 4'h8};
    #100;
    
    for (i = 0; i < 50; i = i + 1) begin
      data_from_fifo = {$random, $random, $random} & 140'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      #100;
    end
    
    for (i = 0; i < 8; i = i + 1) begin
      data_from_fifo[11:4] = (1 << i);
      #100;
    end
    
    data_from_fifo[11:4] = 8'hFF;
    #100;
    
    data_from_fifo = 140'd0;
    #100;
    
    data_from_fifo = 140'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    #100;
    
    data_from_fifo[3:0] = 4'hF;
    #100;
    
    repeat (20) begin
      data_from_fifo = {$random, $random, $random} & 140'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      #1;
    end
    
    $display("All tests passed successfully!");
    $finish;
  end
endmodule
