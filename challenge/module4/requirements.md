# 并行数据转串行数据输出

命名：`output_stage`

整体说明：将并行格雷码数据data_gray根据vld_ch选择数据串行输出通道 1~8 (`data_out_ch1~8`)、数据有效信号通道 1~8 (`data_vld_ch1~8`)和顶层crc_valid。根据data_count和16*clk_out，具体决定输出data_vld_ch的持续周期，即整个输出周期。

## 顶层IO

|信号|位宽|I/O|
|-----|-----|-----|
|16*clk_out|1|I|
|data_gray|128|I|
|vld_ch|8|I|
|data_count|16|I|
|crc_valid|1|I|
|data_out_ch1|1|O|
|data_out_ch2|1|O|
|data_out_ch3|1|O|
|data_out_ch4|1|O|
|data_out_ch5|1|O|
|data_out_ch6|1|O|
|data_out_ch7|1|O|
|data_out_ch8|1|O|
|data_vld_ch1|1|O|
|data_vld_ch2|1|O|
|data_vld_ch3|1|O|
|data_vld_ch4|1|O|
|data_vld_ch5|1|O|
|data_vld_ch6|1|O|
|data_vld_ch7|1|O|
|data_vld_ch8|1|O|

## 信号说明

`16*clk_out`: 输出串行信号速率的时钟
`data_gray`：输出数据的格雷码表示
`vld_ch`：通道选择数据
`data_count`：具体数据长度位
`crc_valid`：CRC 校验成功信号，数据 CRC 校验正确输出周期内拉高
`data_out_ch1~8`：数据串行输出通道
`data_vld_ch1~8`：数据有效信号通道