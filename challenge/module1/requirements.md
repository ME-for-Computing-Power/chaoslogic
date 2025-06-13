# 帧格式识别

命名：`input_stage`

整体说明：每帧输入16位数据，输出5种状态的指示信号。具体帧格式如下:
    - 帧头:
    `32` 位，取值为 `E0E0E0E0`
    - 通道选择:
    `8` 位, 独热码，高位数据丢弃
    - 数据:
    `N` 位（可变长度，限制在`16` 位到`128` 位之间，是`16`的整数倍，按照 Big-Endian 方式输入）
    - CRC 校验字段:
    `16` 位
    - 帧尾:
    `32` 位，取值为 `0E0E0E0E`

状态机状态定义：
`1.​IDLE​（空闲状态）`
    - 初始状态，等待帧头起始
    - 行为：持续监测输入数据是否为帧头的第一部分 E0E0
    - 转换条件：当 data_in == 16'hE0E0 时进入 HEAD_CHECK
`2.HEAD_CHECK​（帧头校验状态）`
    -验证完整的32位帧头
    -行为：检查第二个16位数据是否为 E0E0
    -转换条件：
        若 data_in == 16'hE0E0 进入 CHANNEL
        否则返回 IDLE
`3.​CHANNEL​（通道选择状态）`
    -读取通道选择字段
    -行为：存储输入数据的低8位（高8位丢弃）到 data_ch 寄存器
    -转换条件：无条件进入 DATA 状态（仅需1周期）
`4.​DATA​（数据接收状态）`
    -接收数据字段和后续字段
    -行为：
        启动4位计数器（data_counter）从0开始计数
        每个周期将32位寄存器 tail_detec_reg（用于帧尾检测，初始化全0）左移16位，并存入输入数据data_in
        每个周期将160位寄存器 full_data_reg（用于存储数据字段，初始化全0）左移16位，并存入输入数据data_in
        计数器递增，溢出时丢弃数据
    -转换条件：
        当检测到帧尾 0E0E0E0E 时进入 CRC_OUTPUT，停止寄存器tail_detec_reg和full_data_reg的存储
        若计数器溢出（≥15）返回 IDLE
`5.​CRC_OUTPUT​（CRC提取状态）`
    -提取CRC字段并计算数据长度
    -行为：
        从32位寄存器tail_detec_reg中获取CRC字段（帧尾前1周期的数据）
        计算数据长度：data_count = data_counter - 2
        截取 full_data_reg 的高128位作为 data_128,
    -转换条件：无条件进入 WAIT_CRC（仅需1周期）
`6.​WAIT_CRC​（CRC校验等待状态）`
    -等待CRC校验结果
    -行为：
        拉高 crc16_valid 启动CRC校验模块，维持 crc16_valid 高电平，维持周期为data_count的值;crc16_valid拉高周期同时，每个周期从  data_128低位开始每16位作为data_to_crc发送给CRC校验模块
    -转换条件：
        当 crc16_done == 1 时：
        若校验成功（data_from_crc == 保存的CRC字段），输出 fifo_w_enable=1 且 crc_err=0，输出140位data_to_fifo信号，直接连接128位数据位输出信号data_128+8位通道数据data_ch+4位数据长度表示位data_count。
        否则输出 crc_err=1
        返回 IDLE

## 顶层IO

|信号|位宽|I/O|
|-----|-----|-----|
|clk_in|1|I|
|rst_n|1|I|
|data_in|16|I|
|crc_err|1|O|
|data_to_fifo|140|O|
|fifo_w_enable|1|O|
|data_to_crc|16|O|
|data_from_crc|16|I|
|crc16_done|1|I|
|crc16_valid|1|O|

## 信号说明

`clk_in`: 输入时钟，时钟频率范围为 50MHz 到 100 MHz
`rst_n`:异步复位信号，低电平有效
`data_in`: 16位并行输入数据
`crc_err`: CRC校验结果，错误时为真
`data_to_fifo`: 输出到fifo的数据
`fifo_w_enable`: fifo模块的写使能信号
`data_to_crc`:输入到CRC校验模块的待校验数据
`data_from_crc`:从CRC校验模块返回的数据校验值
`crc16_done`:从CRC校验模块返回的数据校验值有效信号，高电平有效
`crc16_valid`:发送给CRC校验模块的使能信号，高电平有效
