# 输入与解帧

整体说明：输入16位数据，先进入解帧状态机。解帧状态机内置一个32位REG用于识别CRC校验字段，一个128位REG用于存储数据字段（不足16位的数据进行高位0扩展），一个139位REG用于存储写入FIFO数据。128位REG的数据字段进入CRC计算模块，输出结果与32位REG存储的CRC校验字段作比较，最终输出crc_err信号与fifo_w_enable信号。139位REG具体是由128位数据位+8位通道选择位+3位数据长度表示位（分别表示128 112 96 80 64 48 32 16）。

## IO

|信号|位宽|I/O|
|-----|-----|-----|
|clk_in|1|I|
|data_in|16|I|
|crc_err|1|O|
|data_to_fifo|139|O|
|fifo_w_enable|1|O|

## 信号说明

`clk_in`: 输入时钟，时钟频率范围为 50MHz 到 100 MHz
`data_in`: 16位并行输入数据
`crc_err`: CRC校验结果，错误时为真
`data_to_fifo`: 输出到fifo的数据
`fifo_w_enable`: fifo模块的写使能信号

