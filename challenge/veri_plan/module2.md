## 1. 空满信号测试

测试`fifo_empty`与`fifo_full`两个端口的信号

- 首先使用随机数填满fifo，等待两个时钟周期，检查 `fifo_full` 的输出应为1，`fifo_empty`应为0
- 然后读空fifo，等待两个时钟周期，检查 `fifo_empty` 的输出应为1，`fifo_full`应为0
- 在写满和读空过程中，持续检查写入和读出的数据与预期一致
- 检查fifo在接近满和接近空状态时的信号边界行为
- 检查fifo_empty和fifo_full信号的延迟不超过2个时钟周期

## 2. 复位测试

检查`rst_n`输入信号是否有效

- 首先使用随机数填满fifo，检查`fifo_empty`状态应为0
- 拉低`rst_n`，等待若干时钟后释放，检查fifo内部数据被清空，`fifo_empty`应为1，`fifo_full`应为0
- 复位后尝试读出数据，确认无数据输出
- 复位后重新写入和读出，功能应恢复正常

## 3. 写使能信号测试

检查`fifo_w_enable`是否有效

- 在`fifo_w_enable`为0时尝试写入数据，fifo内容不应变化
- 在`fifo_w_enable`为1时写入数据，fifo应正确接收数据
- 写满后继续写入，fifo_full为1时写入无效，已写入数据不应被覆盖
- 写入后读出，检查数据与写入顺序一致

## 4. 读使能信号测试

检查`fifo_r_enable`是否有效

- 在`fifo_r_enable`为0时尝试读出，fifo内容不应变化
- 在`fifo_r_enable`为1时读出数据，fifo应正确输出数据
- `fifo_empty`为1时读出140‘b0

## 5. 随机写入读出测试

- 在FIFO未满时进行随机的数据写入，在FIFO不为空时进行随机的数据读出，提升测试覆盖率
- 只有当`fifo_full`为0时才有可能将`fifo_w_enable`拉高
- 只有当`fifo_empty`为0时才有可能将`fifo_r_enable`拉高

# 注意

- 两时钟之间差180度的相位；testbench应在任何验证出错的情况下立刻停止或输出详细错误信息
- 所有测试均需与参考模型比对，确保数据一致性
- 读出数据时数据会在`fifo_r_enable`被拉高的下一个周期被读出