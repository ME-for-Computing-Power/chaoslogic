# 异步fifo

## IO

|信号|位宽|I/O|
|-----|-----|-----|
|clk_in|1|I|
|clk_out|1|I|
|fifo_w_enable|1|I|
|fifo_r_enable|1|I|
|data_to_fifo|136|I|
|data_from_fifo|136|O|
|fifo_empty|1|O|
|fifo_full|1|O|

## 信号说明

`clk_in`：fifo输入时钟域的时钟
`clk_out`: fifo输出时钟域的时钟
`fifo_w_enable`：fifo写使能信号
`fifo_r_enable`：fifo读使能信号
`data_to_fifo`：fifo输入数据
`data_from_fifo`：fifo输出数据
`fifo_empty`：fifo空信号
`fifo_full`：fifo满信号
