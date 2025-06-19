# 并行数据转串行数据输出

命名:`output_stage`

整体说明:本模块根据前面模块提供的信息，将数据发送到对应的通道并转为串行信号输出。根据`vld_ch`所输入的独热码，将输入的`data_gray`发送到对应的数据串行输出通道 (`data_out_ch1~8`)，同时拉高对应通道的数据有效信号  (`data_vld_ch1~8`)。根据`data_count`，具体决定输出`data_vld_ch`的持续周期数，即`data_vld_ch`仅在输出时拉高。

定义俩个状态，空闲状态和发射状态

空闲状态：
    检测到 vld_ch 上的独热码后进入发射状态
    将data_count存入data_count_reg，将data_gray存入shift_reg，将vld_ch存入vld_latched

发射状态：
    将shift_reg左1移位并计数，当计数的bit_cnt + 16'd1等于data_count_reg后返回空闲状态

输出逻辑：
    在发射状态，根据vld_latched选择通道，输出shift_reg[127]
    CRC 有效信号：任一通道有效则高

## 顶层IO

|信号|位宽|I/O|
|-----|-----|-----|
|rst_n|1|I|
|clk_out16x|1|I|
|data_gray|128|I|
|vld_ch|8|I|
|data_count|16|I|
|crc_valid|1|O|
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
- `crc_valid`:任一`data_vld_ch*`拉高时即拉高
- `data_out_ch1~8`:数据串行输出通道，输出时高位在前
- `data_vld_ch1~8`:数据有效信号通道，仅在输出时拉高