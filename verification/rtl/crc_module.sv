//-----------------------------------------------------------------------------
// CRC module for data[15:0] ,   crc[15:0]=1+x^5+x^12+x^16, reset active low 0x0000
//-----------------------------------------------------------------------------
module crc_module(
  input [15:0] data_to_crc,   // 输入数据
  input [15:0] crc,
  output [15:0] data_from_crc  // CRC计算结果
);

  wire [15:0] lfsr_q;
  reg [15:0] lfsr_c;    // CRC状态寄存器
  assign lfsr_q = crc;
  assign data_from_crc = lfsr_c;

  always @(*) begin
    // CRC计算逻辑
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
  end

endmodule
