# 输入与解帧

## IO

|信号|位宽|I/O|
|-----|-----|-----|
|clk_in|1|I|
|data_in|16|I|
|crc_err|1|O|
|data_to_fifo|136|O|
|fifo_w_enable|1|O|

## 信号说明

`clk_in`: 输入时钟
`data_in`: 16位并行输入数据
`crc_err`: CRC校验结果，错误时为真
`data_to_fifo`: 输出到fifo的数据
`fifo_w_enable`: fifo模块的写使能信号

