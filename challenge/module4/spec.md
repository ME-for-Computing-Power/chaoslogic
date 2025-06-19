
### 1. 模块概述

`output_stage` 模块用于将并行数据（`data_gray`）按客户指定的通道热编码（`vld_ch`）转为串行输出，并在数据有效期间拉高相应通道的有效信号，同时输出全局 `crc_valid` 信号

### 2. 功能说明

* 根据 `vld_ch`（8 位独热码）选择一条输出通道，最多只允许一个通道有效。
* 将 `data_gray`（128 位）按高位在前的顺序，通过所选通道在 `clk_out16x` 时钟域下串行发送，共计 `data_count` 个比特周期。
* 在串行数据有效输出期间，对应的 `data_vld_chX` 信号拉高；一旦任意通道的 `data_vld_chX` 拉高，`crc_valid` 也立即拉高。
* 当 `data_count` 个比特发送完毕后，所有 `data_vld_chX` 及 `crc_valid` 均复位。

### 3. 顶层接口定义

#### 3.1 时钟与复位

* `input  wire        rst_n         `：异步复位，低电平有效
* `input  wire        clk_out16x    `：串行发送时钟，高速（并行位宽 ×16 倍）

#### 3.2 数据与控制

* `input  wire [127:0] data_gray     `：待发送的并行数据，128 位
* `input  wire [7:0]   vld_ch        `：通道选择独热码，8 位，其中 `vld_ch[i]=1` 表示第 i+1 通道有效
* `input  wire [15:0]  data_count    `：实际要发送的比特数，最大 128

#### 3.3 串行输出

* `output reg         data_out_ch1  `
* `output reg         data_out_ch2  `
* …
* `output reg         data_out_ch8  `

串行输出高位在前

#### 3.4 数据有效指示

* `output reg         data_vld_ch1  `
* `output reg         data_vld_ch2  `
* …
* `output reg         data_vld_ch8  `

#### 3.5 校验有效

* `output reg         crc_valid     `：任一 `data_vld_chX` 高有效

### 4. Verilog IO 声明示例

```verilog
module output_stage (
    // 时钟复位
    input  wire        rst_n,        // 异步复位，低有效
    input  wire        clk_out16x,   // 串行输出速率时钟

    // 并行数据与控制
    input  wire [127:0] data_gray,   // 并行灰度码数据
    input  wire [7:0]   vld_ch,      // 独热通道选择
    input  wire [15:0]  data_count,  // 有效数据位数

    // 串行数据输出
    output reg         data_out_ch1,
    output reg         data_out_ch2,
    output reg         data_out_ch3,
    output reg         data_out_ch4,
    output reg         data_out_ch5,
    output reg         data_out_ch6,
    output reg         data_out_ch7,
    output reg         data_out_ch8,

    // 数据有效指示
    output reg         data_vld_ch1,
    output reg         data_vld_ch2,
    output reg         data_vld_ch3,
    output reg         data_vld_ch4,
    output reg         data_vld_ch5,
    output reg         data_vld_ch6,
    output reg         data_vld_ch7,
    output reg         data_vld_ch8,

    // CRC 有效指示
    output reg         crc_valid     // 任意 data_vld_chX 有效时置位
);
```


### 5. 时序与时钟域注意事项

* `data_gray`、`vld_ch`、`data_count` 应在 `clk_out16x` 的上升沿稳定，需先做跨时钟域同步（CDC）。
* `rst_n` 为异步复位，建议在 `clk_out16x` 域内做一级同步，以消除毛刺。

### 6. 运行流程

1. **空闲状态**：所有 `data_vld_chX`、`crc_valid` 保持 0。
2. **启动输出**：当检测到 `vld_ch` 单热码有效且 `data_count>0`，模块进入发送状态。
3. **位计数**：内部计数器自 0 增加至 `data_count-1`，每一个 `clk_out16x` 周期输出一位。
4. **数据输出**：根据 `data_gray[127:0]` 的高位优先顺序，依次从高到低输出。
5. **有效信号**：在每次输出周期内，所选 `data_vld_chX` 置 1；同时 `crc_valid` 置 1。
6. **结束**：当计数完成，所有有效信号复位，模块回到空闲。

### 7. 参数与定制

* 若需支持更宽的通道或不同位宽，只需调整 `vld_ch` 和 `data_gray` 宽度，并相应扩展输出数组。
* `data_count` 可动态变化，建议在上次发送完成前锁定，以防中途变更导致输出不确定。

