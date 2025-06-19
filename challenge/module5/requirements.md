# CRC校验模块

命名：`crc_module`

整体说明：设计一个CRC校验模块，采用CRC-16/CCITT算法，多项式：0x1021，初始值：为输入的crc信号，输入不反转，输出不反转，输出异或值：0x0000。


## 顶层IO

|信号|位宽|I/O|
|-----|-----|-----|
|data_to_crc|16|I|
|crc|16|I|
|data_from_crc|16|O|


## 信号说明

`data_to_crc`:从帧格式识别模块输入的待校验数据
`crc`:从帧格式识别模块输入的crc校验初始值
`data_from_crc`:输出数据的CRC校验值