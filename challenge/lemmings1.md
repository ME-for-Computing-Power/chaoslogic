用有限状态机（finite state machine）来模拟老鼠。
在老鼠的二维世界中，它仅处于两种状态之一：向左走或向右走。如果遇到障碍物，它会改变方向。具体来说，如果老鼠撞到左边，它就会向右走；如果撞到右边，则会向左走；如果同时撞到两侧，它仍然会改变方向。
实现一个具有两个状态、两个输入和一个输出的Moore型有限状态机，以模拟这种行为。

模块声明：
module top_module(
    input clk,
    input areset,    // Freshly brainwashed Lemmings walk left.
    input bump_left,
    input bump_right,
    output walk_left,
    output walk_right); 