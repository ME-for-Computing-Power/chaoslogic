# 并行数据转串行数据输出

命名:`output_stage`

整体说明:本模块根据前面模块提供的信息，将数据发送到对应的通道并转为串行信号输出。根据`vld_ch`所输入的独热码，将输入的`data_gray`发送到对应的数据串行输出通道 (`data_out_ch1~8`)，同时将输入信号`crc_valid`发送到对应的数据有效信号通道  (`data_vld_ch1~8`)。根据`data_count`和`clk_out16x`，具体决定输出`data_vld_ch`的持续周期，即仅在输出时持续。


## 顶层IO

|信号|位宽|I/O|
|-----|-----|-----|
|rst_n|1|I|
|clk_out16x|1|I|
|data_gray|128|I|
|vld_ch|8|I|
|data_count|16|I|
|crc_valid|1|I|
|data_out_ch1|1|O|
|data_out_ch2|1|O|
|...|1|O|
|data_out_ch8|1|O|
|data_vld_ch1|1|O|
|data_vld_ch2|1|O|
|...|1|O|
|data_vld_ch8|1|O|

## 信号说明

- `rst_n`:异步复位信号，低电平有效
- `clk_out16x`:输出串行信号速率的时钟
- `data_gray`:输出数据的格雷码表示
- `vld_ch`:通道选择数据，8位宽独热码
- `data_count`:`data_gray`的具体数据长度
- `crc_valid`:CRC 校验成功信号，数据 CRC 校验正确输出周期内拉高
- `data_out_ch1~8`:数据串行输出通道
- `data_vld_ch1~8`:数据有效信号通道，对应输入信号的`crc_valid`