# 异步fifo

命名：`async_fifo`

整体说明: 传统的异步fifo，宽度为140位，深度为4，提供 fifo 空、fifo 满信号状态指示

## 顶层IO

|信号|位宽|I/O|
|-----|-----|-----|
|clk_in|1|I|
|clk_out|1|I|
|rst_n|1|I|
|fifo_w_enable|1|I|
|fifo_r_enable|1|I|
|data_to_fifo|140|I|
|data_from_fifo|140|O|
|fifo_empty|1|O|
|fifo_full|1|O|

## 信号说明

`clk_in`：fifo输入时钟域的时钟

`clk_out`: fifo输出时钟域的时钟，与 `clk_in` 为同频异步。

`rst_n`:异步复位信号，低电平有效

`fifo_w_enable`：fifo写使能信号

`fifo_r_enable`：fifo读使能信号

`data_to_fifo`：fifo输入数据

`data_from_fifo`：fifo输出数据，当`fifo_empty`为1时应读出140‘b0

`fifo_empty`：fifo空信号

`fifo_full`：fifo满信号

## 时序说明

数据将在`fifo_w_enable`被拉高的时钟周期内被写入

数据将在`fifo_r_enable`被拉高的时钟周期内被读出