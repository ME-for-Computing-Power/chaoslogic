# CRC校验模块

命名：`crc_cacul`

整体说明：设计一个CRC校验模块，采用CRC-16/CCITT算法，计算128位数据信号data_to_crc的CRC校验值，计算完成时将crc_en信号拉高。

## 顶层IO

|信号|位宽|I/O|
|-----|-----|-----|
|clk_in|1|I|
|rst_n|1|I|
|data_to_crc|128|I|
|data_from_crc|16|O|
|crc_en|1|O|

## 信号说明

`clk_in`: 输入时钟，时钟频率范围为 50MHz 到 100 MHz
`rst_n`:异步复位信号，低电平有效
`data_to_crc`:从帧格式识别模块输入的待校验数据
`data_from_crc`:输出数据的CRC校验值
`crc_en`:输出数据的CRC校验值有效信号，高电平有效