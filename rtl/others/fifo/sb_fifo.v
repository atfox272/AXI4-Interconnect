module sb_fifo
#(
    // FIFO configuration
    parameter DATA_WIDTH    = 8,
    parameter FIFO_DEPTH    = 2,
    // Do not configure
    parameter ADDR_WIDTH    = $clog2(FIFO_DEPTH)
)
(
    input                               clk,
    
    input           [DATA_WIDTH - 1:0]  data_i,
    output          [DATA_WIDTH-1:0]    data_o,
    
    input                               wr_valid_i,
    input                               rd_valid_i,
    
    output                              wr_ready_o,     // Optional
    output                              rd_ready_o,     // Optional
    
    input                               rst_n
);
    // Internal variable declaration
    genvar addr;
    // Internal signal
    // -- wire   
    wire                    rd_handshake;
    wire                    wr_handshake;
    // -- reg
    reg [DATA_WIDTH-1:0]    mem     [FIFO_DEPTH-1:0];
    reg [ADDR_WIDTH:0]      rd_ptr;
    reg [ADDR_WIDTH:0]      wr_ptr;
    
    // Combination logic
    assign data_o       = mem[rd_ptr[ADDR_WIDTH-1:0]];
    assign wr_ready_o   = (~((rd_ptr[ADDR_WIDTH]^wr_ptr[ADDR_WIDTH]) & (~|(rd_ptr[ADDR_WIDTH-1:0]^wr_ptr[ADDR_WIDTH-1:0]))));
    assign rd_ready_o   = |(rd_ptr^wr_ptr);
    assign rd_handshake = rd_valid_i & rd_ready_o;
    assign wr_handshake = wr_valid_i & wr_ready_o;
    
    // Flip-flop/RAM
    always @(posedge clk) begin
        if(wr_handshake) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= data_i;
        end
    end
    always @(posedge clk) begin
        if(!rst_n) begin
            wr_ptr <= {(ADDR_WIDTH+1){1'b0}};
        end
        else if(wr_handshake) begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end
    always @(posedge clk) begin
        if(!rst_n) begin
            rd_ptr <= {(ADDR_WIDTH+1){1'b0}};
        end
        else if(rd_handshake) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end
endmodule
//    sync_fifo 
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