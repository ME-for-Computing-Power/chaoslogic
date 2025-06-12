//---------<模块及端口声名>------------------------------------------------------
module async_fifo1 #(parameter FIFO_WIDTH = 140  ,//FIFO输入数据位宽
                              FIFO_DEPTH = 4 //FIFO深度
)(
    //Write clock domain
    wrclk   ,//写时钟
    wrrst_n ,//写侧复位，异步复位，低有效
    wren    ,//写使能
    wrdata  ,//写数据输入
    wrempty ,//写侧空标志
    wrfull  ,//写侧满标志
    wrusedw ,//写时钟域下可读数据量
    //Read clock domain
    rdclk   ,//读时钟
    rdrst_n ,//读侧复位，异步复位，低有效
    rden    ,//读使能
    rddata  ,//读数据输出
    rdempty ,//读侧空标志
    rdfull  ,//读侧满标志
    rdusedw  //读时钟域下可读数据量
);			
 
//参数声明
    localparam  ADDR_W = log2b(FIFO_DEPTH),//指针位宽
                DATA_W = FIFO_WIDTH;//FIFO深度
 
//function声明
/************* 用取对数的方法计算地址指针的位宽 ************************/
    function integer log2b(input integer data);
        begin 
            for(log2b=0;data>0;log2b=log2b+1)begin
                data = data>>1;
            end
                
            log2b = log2b - 1;
        end  
    endfunction
 
//---------<内部信号定义>-----------------------------------------------------
    //端口声明
    //Write clock domain
    input                               wrclk   ;//写时钟
    input                               wrrst_n ;//写侧复位，异步复位，低有效
    input                               wren    ;//写使能
    input           [DATA_W-1:0]        wrdata  ;//写数据输入
    output                              wrempty ;//写侧空标志
    output                              wrfull  ;//写侧满标志
    output          [ADDR_W-1:0]        wrusedw ;//写时钟域下可读数据量
    //Read clock domain
    input                               rdclk   ;//读时钟
    input                               rdrst_n ;//读侧复位，异步复位，低有效
    input                               rden    ;//读使能
    output          [DATA_W-1:0]        rddata  ;//读数据输出
    output                              rdempty ;//读侧空标志
    output                              rdfull  ;//读侧满标志
    output          [ADDR_W-1:0]        rdusedw ;//读时钟域下可读数据量
    
    reg         [DATA_W-1:0]    fifo_mem[FIFO_DEPTH - 1:0]    ;//FIFO存储阵列
    // reg         [ADDR_W-1:0]    fifo_mem[0:(1'b1<<ADDR_W)-1]    ;//两种写法皆可
 
    wire        [ADDR_W-1:0]    wr_addr     ;//写地址
    wire        [ADDR_W-1:0]    rd_addr     ;//读地址
 
    reg         [ADDR_W:0]      wr_ptr      ;//二进制写指针
    reg         [ADDR_W:0]      rd_ptr      ;//二进制读指针
 
    wire        [ADDR_W:0]      wr_ptr_gray ;//格雷码写指针
    reg         [ADDR_W:0]      wr_ptr_gray1;//打2拍，写指针同步寄存器
    reg         [ADDR_W:0]      wr_ptr_gray2;
 
    wire        [ADDR_W:0]      rd_ptr_gray ;//格雷码读指针
    reg         [ADDR_W:0]      rd_ptr_gray1;//打2拍，读指针同步寄存器
    reg         [ADDR_W:0]      rd_ptr_gray2;
 
    reg         [ADDR_W:0]      wr_gray2_bin;//将同步至读时钟域的格雷码写指针转换为二进制
    reg         [ADDR_W:0]      rd_gray2_bin;//将同步至写时钟域的格雷码读指针转换为二进制
 
    reg         [DATA_W-1:0]    rd_data_r   ;//读出数据输出寄存器
 
    reg         [ADDR_W-1:0]    wr_usedw_r  ;//写时钟域下可读数据量寄存器
    reg         [ADDR_W-1:0]    rd_usedw_r  ;//读时钟域下可读数据量寄存器
 
    integer i;
 
//****************************************************************
//--wr_ptr、rd_ptr
//****************************************************************
    //写指针
    always @(posedge wrclk or negedge wrrst_n)begin 
        if(!wrrst_n)begin
            wr_ptr <= 'd0;
        end 
        else if(wren && ~wrfull)begin 
            wr_ptr <= wr_ptr + 1'b1;
        end 
    end
 
    //读指针
    always @(posedge rdclk or negedge rdrst_n)begin 
        if(!rdrst_n)begin
            rd_ptr <= 'd0;
        end 
        else if(rden && ~rdempty)begin 
            rd_ptr <= rd_ptr + 1'b1;
        end 
    end
 
//****************************************************************
//--wr_addr、rd_addr
//****************************************************************
    assign wr_addr = wr_ptr[ADDR_W-1:0];//数据写入地址
    assign rd_addr = rd_ptr[ADDR_W-1:0];//数据读出地址
 
//****************************************************************
//--写入数据、读出数据
//****************************************************************
    //写入数据
    always @(posedge wrclk or negedge wrrst_n)begin 
        if(!wrrst_n)begin
            for (i=0;i<(1'b1<<ADDR_W);i=i+1) begin  //利用for循环循环清零fifo_ram
                fifo_mem[i] <= 'd0;
            end
        end 
        else if(wren && ~wrfull)begin              //只要写使能有效就一直写入数据，数据数据量超过fifo深度，则会重新覆盖
            fifo_mem[wr_addr] <= wrdata;
        end  
    end
    //读出数据
    always @(posedge rdclk or negedge rdrst_n)begin 
        if(!rdrst_n)begin
            rd_data_r <= 'd0;
        end 
        else if(rden & !rdempty)begin 
            rd_data_r <= fifo_mem[rd_addr];
        end 
    end
 
//****************************************************************
//--二进制转格雷码
//****************************************************************
    assign wr_ptr_gray = wr_ptr^(wr_ptr>>1);//写指针格雷码
    assign rd_ptr_gray = rd_ptr^(rd_ptr>>1);//读指针格雷码
 
//****************************************************************
//--格雷码同步
//****************************************************************
    //将写指针格雷码同步到读时钟域 
    always @(posedge rdclk or negedge rdrst_n)begin 
        if(!rdrst_n)begin
            wr_ptr_gray1 <= 'd0;
            wr_ptr_gray2 <= 'd0;
        end 
        else begin 
            wr_ptr_gray1 <= wr_ptr_gray;
            wr_ptr_gray2 <= wr_ptr_gray1;
        end 
    end
 
    //将读指针格雷码同步到写时钟域
    always @(posedge wrclk or negedge wrrst_n)begin 
        if(!wrrst_n)begin
            rd_ptr_gray1 <= 'd0;
            rd_ptr_gray2 <= 'd0;
        end 
        else begin 
            rd_ptr_gray1 <= rd_ptr_gray;
            rd_ptr_gray2 <= rd_ptr_gray1;
        end 
    end
 
//****************************************************************
//--格雷码转二进制
//****************************************************************
    /*
    格雷码转二进制：格雷码的最高位作为二进制的最高位，二进制次高位产生过程是
    使用二进制的高位和格雷码次高位相异或得到
    */
 
    //将同步至读时钟域的写指针格雷码转换为二进制
    always @(*)begin 
        wr_gray2_bin[ADDR_W] = wr_ptr_gray2[ADDR_W];
        for (i=ADDR_W-1;i>=0;i=i-1) begin
            wr_gray2_bin[i] = wr_gray2_bin[i+1]^wr_ptr_gray2[i];
        end
    end
 
    //将同步至写时钟域的格雷码读指针转换为二进制
    always @(*)begin 
        rd_gray2_bin[ADDR_W] = rd_ptr_gray2[ADDR_W];
        for (i=ADDR_W-1;i>=0;i=i-1) begin
            rd_gray2_bin[i] = rd_gray2_bin[i+1]^rd_ptr_gray2[i];
        end
    end
 
//****************************************************************
//--输出
//****************************************************************
    //空标志
    assign wrempty = wr_ptr == rd_gray2_bin;
    assign rdempty = rd_ptr == wr_gray2_bin;
 
    //满标志
    assign wrfull = (wr_ptr != rd_gray2_bin) && (wr_ptr[ADDR_W-1:0] == rd_gray2_bin[ADDR_W-1:0]);
    assign rdfull = (rd_ptr != wr_gray2_bin) && (rd_ptr[ADDR_W-1:0] == wr_gray2_bin[ADDR_W-1:0]);
 
    //读出数据
    assign rddata = rdempty?0:fifo_mem[rd_addr];
 
    //可读数据量
    always @(posedge wrclk or negedge wrrst_n)begin 
        if(!wrrst_n)begin
            wr_usedw_r <= 'd0;
        end 
        else begin 
            wr_usedw_r <= wr_ptr - rd_gray2_bin;
        end 
    end
    always @(posedge rdclk or negedge rdrst_n)begin 
        if(!rdrst_n)begin
            rd_usedw_r <= 'd0;
        end 
        else begin 
            rd_usedw_r <= wr_gray2_bin - rd_ptr;
        end 
    end
 
    assign wrusedw = wr_usedw_r;
    assign rdusedw = rd_usedw_r;
 
endmodule
 
