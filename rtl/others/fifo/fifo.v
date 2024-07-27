module fifo
    #(
    parameter  DATA_WIDTH    = 8,
    parameter  FIFO_DEPTH    = 32,
    // Do not configure
    parameter  ADDR_WIDTH    = $clog2(FIFO_DEPTH)
    )
    (
    input                       clk,
    
    input   [DATA_WIDTH - 1:0]  data_i,
    output  [DATA_WIDTH - 1:0]  data_o,
    
    input                       wr_valid_i,
    input                       rd_valid_i,
    
    output                      empty_o,
    output                      full_o,
    output                      almost_empty_o,
    output                      almost_full_o,
    
    output  [ADDR_WIDTH:0]      counter,
    input                       rst_n
    );
    // Internal variable declaration
    genvar addr;
    
    // Internal signal declaration
    // wire declaration
    wire[ADDR_WIDTH:0]      wr_addr_inc;
    wire[ADDR_WIDTH - 1:0]  wr_addr_map;
    wire[ADDR_WIDTH:0]      rd_addr_inc;
    wire[ADDR_WIDTH - 1:0]  rd_addr_map;
    wire[DATA_WIDTH - 1:0]  buffer_nxt [0:FIFO_DEPTH - 1];
    // reg declaration
	reg [DATA_WIDTH - 1:0]  buffer     [0:FIFO_DEPTH - 1];
	reg [ADDR_WIDTH:0]      wr_addr;
    reg [ADDR_WIDTH:0]      rd_addr;
    
    // combinational logic
    assign data_o = buffer[rd_addr_map];
    
    assign wr_addr_inc = wr_addr + 1'b1;
    assign rd_addr_inc = rd_addr + 1'b1;
    assign wr_addr_map = wr_addr[ADDR_WIDTH - 1:0];
    assign rd_addr_map = rd_addr[ADDR_WIDTH - 1:0];
    
    assign empty_o = wr_addr == rd_addr;
    assign almost_empty_o = rd_addr_inc ==  wr_addr;
    assign full_o = (wr_addr_map == rd_addr_map) & (wr_addr[ADDR_WIDTH] ^ rd_addr[ADDR_WIDTH]);
    assign almost_full_o = wr_addr_map + 1'b1 == rd_addr_map;
    
    assign counter = wr_addr - rd_addr;
    generate
        for(addr = 0; addr < FIFO_DEPTH; addr = addr + 1) begin
            assign buffer_nxt[addr] = (wr_addr_map == addr) ? data_i : buffer[addr];
        end
    endgenerate
    
    // flip-flop logic
    // -- Buffer updater
    generate
        for(addr = 0; addr < FIFO_DEPTH; addr = addr + 1) begin
            always @(posedge clk) begin
                if(!rst_n) begin 
                    buffer[addr] <= {DATA_WIDTH{1'b0}};
                end
                else if(wr_valid_i & !full_o) begin
                    buffer[addr] <= buffer_nxt[addr];
                end
            end
        end
    endgenerate
    // -- Write pointer updater
    always @(posedge clk) begin
        if(!rst_n) begin 
            wr_addr <= 0;        
        end
        else if(wr_valid_i & !full_o) begin
            wr_addr <= wr_addr_inc;
        end
    end
    // -- Read pointer updater
    always @(posedge clk) begin
        if(!rst_n) begin
            rd_addr <= 0;
        end
        else if(rd_valid_i & !empty_o) begin
            rd_addr <= rd_addr_inc;
        end
        
    end
endmodule
//    fifo 
//        #(
//        .DATA_WIDTH(),
//        .FIFO_DEPTH(32)
//        ) fifo (
//        .clk(clk),
//        .data_i(),
//        .data_o(),
//        .rd_valid_i(),
//        .wr_valid_i(),
//        .empty_o(),
//        .full_o(),
//        .almost_empty_o(),
//        .almost_full_o(),
//        .rst_n(rst_n)
//        );