# 帧格式识别

命名：`input_stage`

整体说明：该模块旨在检测输入数据流中的特定帧格式，并提取有效数据。每帧输入16位数据，输出5种状态的指示信号。具体帧格式如下:
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

## 状态机状态定义：

`1.​IDLE​（空闲状态）`

    - 初始状态，等待帧头起始
    
    - 行为：清零crc、crc_err、data_count、data_to_crc、fifo_w_enable
    
    - 转换条件：设计一个32位的 data_buffer 每周期低位存入输入的16位 data_in ，当 data_buffer == 32'he0e0e0e0 时，再等两个周期进入 ​CHANNEL​（通道选择状态）
        
`2.​CHANNEL​（通道选择状态）`

    -读取通道选择字段
    
    -行为：存储data_buffer[39:32]（表示8位通道选择信号）到存储ch_sel 寄存器
    
    -转换条件：无条件进入 DATA 状态（仅需1周期）
    
`3.​DATA​（数据接收状态）`

    -接收数据字段和后续字段
    
    -行为：
        启动4位计数器（data_count）从0开始计数，每次增加16表示数据位宽
        将data_buffer[47:32]发送给data_to_crc，同时接收data_from_crc为crc，保存data_buffer[47:32]到128位整段data寄存器
        当检测到 data_buffer[31:0] == 32'h0e0e0e0e且crc校验成功输出data_to_fifo为{data[15:0],112'd0,ch_sel[7:0],data_count[7:4]} 同时输出crc_err和fifo_w_enable
        
    -转换条件：
        当检测到 data_buffer[31:0] == 32'h0e0e0e0e 时返回 IDLE
        如果data_count大于128表示数据超长，丢弃数据返回 IDLE；没有超长保留在 ​DATA​（数据接收状态）

        
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
|crc|16|O|
|data_from_crc|16|I|


## 信号说明

- `clk_in`: 输入时钟
- `rst_n`:异步复位信号，低电平有效
- `data_in`: 16位并行输入数据
- `crc_err`: CRC校验结果，错误时为真
- `data_to_fifo`: 输出到fifo的数据
- `fifo_w_enable`: fifo模块的写使能信号
- `data_to_crc`:输入到CRC校验模块的待校验数据
- `crc`:输出到帧格式识别模块crc校验初始值
- `data_from_crc`:从CRC校验模块返回的数据校验值

