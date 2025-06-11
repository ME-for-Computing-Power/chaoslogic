// SystemVerilog行为级异步FIFO参考模型，仅用于仿真，不可综合
module ref_model (
    input  logic         clk_in,
    input  logic         clk_out,
    input  logic         rst_n,
    input  logic         fifo_w_enable,
    input  logic         fifo_r_enable,
    input  logic [139:0] data_to_fifo,
    output logic [139:0] data_from_fifo,
    output logic         fifo_empty,
    output logic         fifo_full
);
    localparam int DEPTH = 2;
    localparam int WIDTH = 140;

    logic [WIDTH-1:0] mem[DEPTH];
    int wr_ptr, rd_ptr, count;
    ref fifo_empty_reg1, fifo_empty_reg2;
    ref fifo_full_reg1, fifo_full_reg2;

    // 初始化
    initial begin
        wr_ptr = 0;
        rd_ptr = 0;
        count = 0;
        data_from_fifo = '0;
        fifo_empty = 1;
        fifo_full = 0;
    end

    // 写操作（clk_in域）
    always_ff @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (fifo_w_enable && !fifo_full) begin
            mem[wr_ptr] <= data_to_fifo;
            wr_ptr <= (wr_ptr + 1) % DEPTH;
        end
    end

    // 读操作（clk_out域）
    always_ff @(posedge clk_out or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            data_from_fifo <= '0;
        end else if (fifo_r_enable && !fifo_empty) begin
            data_from_fifo <= mem[rd_ptr];
            rd_ptr <= (rd_ptr + 1) % DEPTH;
        end else if (fifo_empty) begin
            data_from_fifo <= '0;
        end
    end

    always_ff @(posedge clk_out or negedge rst_n) begin
        if (!rst_n) begin
            fifo_empty <= 1;
        end else begin
            fifo_empty_reg1 <= (count == 0);
            fifo_empty_reg2 <= fifo_empty_reg1;
            fifo_empty <= fifo_empty_reg2;
        end
    end

    always_ff @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            fifo_full <= 0;
        end else begin
            fifo_full_reg1 <= (count == DEPTH);
            fifo_full_reg2 <= fifo_full_reg1;
            fifo_full <= fifo_full_reg2;
        end
    end

    // 计数更新（行为级，非综合）
    always_ff @(posedge clk_in or posedge clk_out or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            if ((fifo_w_enable && !fifo_full) && !(fifo_r_enable && !fifo_empty))
                count <= count + 1;
            else if ((fifo_r_enable && !fifo_empty) && !(fifo_w_enable && !fifo_full))
                count <= count - 1;
        end
    end
endmodule
