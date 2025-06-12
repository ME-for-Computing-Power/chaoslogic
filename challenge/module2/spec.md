# 异步FIFO设计规范

## 模块定义
```verilog
module async_fifo (
  input        clk_in,         // 写时钟域时钟
  input        clk_out,        // 读时钟域时钟（同频异步）
  input        rst_n,          // 异步复位（低有效）
  input        fifo_w_enable,  // 写使能信号
  input        fifo_r_enable,  // 读使能信号
  input  [139:0] data_to_fifo, // 140位输入数据
  output [139:0] data_from_fifo, // 140位输出数据
  output       fifo_empty,     // FIFO空标志
  output       fifo_full       // FIFO满标志
);
```

## 功能描述
1. **存储结构**
   - 数据宽度：140位
   - 存储深度：2级

2. **写操作**
   - 当`fifo_w_enable=1`且`fifo_full=0`时，在`clk_in`上升沿将`data_to_fifo`写入FIFO
   - 写操作在使能信号拉高的单周期内完成

3. **读操作**
   - 当`fifo_r_enable=1`且`fifo_empty=0`时，在`clk_out`上升沿从FIFO读出数据到`data_from_fifo`
   - 当`fifo_empty=1`时，`data_from_fifo`输出140'b0
   - 当在`clk_out`上升沿时，如果`fifo_r_enable=1`，`data_from_fifo`应立即变换

4. **状态标志**
   - `fifo_full`: 当FIFO写指针到达最后位置时拉高
   - `fifo_empty`: 当FIFO读指针等于写指针时拉高

5. **时钟域**
   - 写操作同步于`clk_in`时钟域
   - 读操作同步于`clk_out`时钟域（与`clk_in`同频异步）

6. **复位机制**
   - 异步复位信号`rst_n`低电平有效
   - 复位时清空FIFO，状态标志置位：`fifo_empty=1`, `fifo_full=0`
