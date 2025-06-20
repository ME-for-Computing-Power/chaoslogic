module tb;
  reg rst_n;
  reg clk_out16x;
  reg [127:0] data_gray;
  reg [7:0] vld_ch;
  reg [15:0] data_count;
  wire crc_valid;
  wire data_out_ch1, data_out_ch2, data_out_ch3, data_out_ch4;
  wire data_out_ch5, data_out_ch6, data_out_ch7, data_out_ch8;
  wire data_vld_ch1, data_vld_ch2, data_vld_ch3, data_vld_ch4;
  wire data_vld_ch5, data_vld_ch6, data_vld_ch7, data_vld_ch8;
  wire ref_crc_valid;
  wire ref_data_out_ch1, ref_data_out_ch2, ref_data_out_ch3, ref_data_out_ch4;
  wire ref_data_out_ch5, ref_data_out_ch6, ref_data_out_ch7, ref_data_out_ch8;
  wire ref_data_vld_ch1, ref_data_vld_ch2, ref_data_vld_ch3, ref_data_vld_ch4;
  wire ref_data_vld_ch5, ref_data_vld_ch6, ref_data_vld_ch7, ref_data_vld_ch8;
  output_stage dut (
    .rst_n(rst_n),
    .clk_out16x(clk_out16x),
    .data_gray(data_gray),
    .vld_ch(vld_ch),
    .data_count(data_count),
    .crc_valid(crc_valid),
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
    .data_vld_ch8(data_vld_ch8)
  );
  ref_model ref_inst (
    .rst_n(rst_n),
    .clk_out16x(clk_out16x),
    .data_gray(data_gray),
    .vld_ch(vld_ch),
    .data_count(data_count),
    .crc_valid(ref_crc_valid),
    .data_out_ch1(ref_data_out_ch1),
    .data_out_ch2(ref_data_out_ch2),
    .data_out_ch3(ref_data_out_ch3),
    .data_out_ch4(ref_data_out_ch4),
    .data_out_ch5(ref_data_out_ch5),
    .data_out_ch6(ref_data_out_ch6),
    .data_out_ch7(ref_data_out_ch7),
    .data_out_ch8(ref_data_out_ch8),
    .data_vld_ch1(ref_data_vld_ch1),
    .data_vld_ch2(ref_data_vld_ch2),
    .data_vld_ch3(ref_data_vld_ch3),
    .data_vld_ch4(ref_data_vld_ch4),
    .data_vld_ch5(ref_data_vld_ch5),
    .data_vld_ch6(ref_data_vld_ch6),
    .data_vld_ch7(ref_data_vld_ch7),
    .data_vld_ch8(ref_data_vld_ch8)
  );
  always #5 clk_out16x = ~clk_out16x;
  integer error_count = 0;
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);
    clk_out16x = 0;
    rst_n = 0;
    data_gray = 0;
    vld_ch = 0;
    data_count = 0;
    #100 rst_n = 1;
    #10;
    for (int test_num = 0; test_num < 1000; test_num++) begin
      vld_ch = $urandom_range(0, 255);
      data_count = (test_num % 3 == 0) ? $urandom_range(0, 127) :
                 (test_num % 3 == 1) ? 0 : 65535;
      if (test_num % 10 == 0) data_gray = 128'h0;
      else if (test_num % 10 == 1) data_gray = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
      else if (test_num % 10 == 2) data_gray = 128'hAAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA;
      else if (test_num % 10 == 3) data_gray = 128'h5555_5555_5555_5555_5555_5555_5555_5555;
      else data_gray = {$random, $random, $random, $random};
      repeat($urandom_range(1, 10)) @(negedge clk_out16x);
    end
    #500;
    $display("\nTest Complete. Errors found: %0d", error_count);
    $finish;
  end
  always @(negedge clk_out16x) begin
    if (rst_n) begin
      reg [7:0] dut_data_vld = {
        data_vld_ch8, data_vld_ch7, data_vld_ch6, data_vld_ch5,
        data_vld_ch4, data_vld_ch3, data_vld_ch2, data_vld_ch1
      };
      reg [7:0] dut_data_out = {
        data_out_ch8, data_out_ch7, data_out_ch6, data_out_ch5,
        data_out_ch4, data_out_ch3, data_out_ch2, data_out_ch1
      };
      reg [7:0] ref_data_vld = {
        ref_data_vld_ch8, ref_data_vld_ch7, ref_data_vld_ch6, ref_data_vld_ch5,
        ref_data_vld_ch4, ref_data_vld_ch3, ref_data_vld_ch2, ref_data_vld_ch1
      };
      reg [7:0] ref_data_out = {
        ref_data_out_ch8, ref_data_out_ch7, ref_data_out_ch6, ref_data_out_ch5,
        ref_data_out_ch4, ref_data_out_ch3, ref_data_out_ch2, ref_data_out_ch1
      };
      for (int i = 0; i < 8; i++) begin
        if (ref_data_vld[i] !== dut_data_vld[i]) begin
          $error("Data_vld_ch%0d mismatch! DUT: %b, REF: %b", i+1, dut_data_vld[i], ref_data_vld[i]);
          error_count++;
        end
      end
      if (|ref_data_vld) begin
        for (int i = 0; i < 8; i++) begin
          if (ref_data_vld[i] && (ref_data_out[i] !== dut_data_out[i])) begin
            $error("Data_out_ch%0d mismatch! DUT: %b, REF: %b", i+1, dut_data_out[i], ref_data_out[i]);
            error_count++;
          end
        end
      end
      if (crc_valid !== ref_crc_valid) begin
        $error("CRC_valid mismatch! DUT: %b, REF: %b", crc_valid, ref_crc_valid);
        error_count++;
      end
      if (error_count > 10) begin
        $fatal(1, "Excessive errors detected. Stopping simulation.");
      end
    end
  end
endmodule