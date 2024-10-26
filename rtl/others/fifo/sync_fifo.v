module sync_fifo
#(
    // FIFO configuration
    parameter FIFO_TYPE     = 0,
    parameter DATA_WIDTH    = 8,
    parameter FIFO_DEPTH    = 32,
    // Do not configure
    parameter ADDR_WIDTH    = $clog2(FIFO_DEPTH)
)
(
    input                               clk,
    
    input           [DATA_WIDTH - 1:0]  data_i,
    output  wire    [DATA_WIDTH-1:0]    data_o,
    
    input                               wr_valid_i,
    input                               rd_valid_i,
    
    output                              empty_o,
    output                              full_o,
    output                              wr_ready_o,     // Optional
    output                              rd_ready_o,     // Optional
    output  wire                        almost_empty_o, // Optional
    output  wire                        almost_full_o,  // Optional
    
    output  [ADDR_WIDTH:0]              counter,        // Optional
    input                               rst_n
);
// Internal variable declaration
genvar addr;
    
generate
if(FIFO_TYPE == 1) begin : NORMAL_FIFO
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
    assign empty_o      = ~|(rd_ptr^wr_ptr);
    assign full_o       = (rd_ptr[ADDR_WIDTH]^wr_ptr[ADDR_WIDTH]) & (~|(rd_ptr[ADDR_WIDTH-1:0]^wr_ptr[ADDR_WIDTH-1:0]));
    assign wr_ready_o   = (~full_o);
    assign rd_ready_o   = (~empty_o);
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
end
else if(FIFO_TYPE == 2) begin : FWD_FLOP
    // Internal signal
    // -- wire   
    wire                    rd_handshake;
    wire                    wr_handshake;
    wire                    po_bwd_valid;
    wire                    po_bwd_ready;
    wire                    po_fwd_valid;
    // -- reg
    reg [DATA_WIDTH-1:0]    mem     [FIFO_DEPTH-1:0];
    reg [ADDR_WIDTH:0]      rd_ptr;
    reg [ADDR_WIDTH:0]      wr_ptr;
    
    // Internal module
    skid_buffer #(
        .SBUF_TYPE  (0),
        .DATA_WIDTH (DATA_WIDTH)
    ) pipe_out (
        .clk        (clk),        
        .rst_n      (rst_n),      
        .bwd_data_i (mem[rd_ptr[ADDR_WIDTH-1:0]]), 
        .bwd_valid_i(po_bwd_valid),
        .fwd_ready_i(rd_valid_i),
        .fwd_data_o (data_o), 
        .bwd_ready_o(po_bwd_ready),
        .fwd_valid_o(po_fwd_valid)
    );
    
    // Combination logic
    assign empty_o      = ~po_fwd_valid;
    assign full_o       = (rd_ptr[ADDR_WIDTH]^wr_ptr[ADDR_WIDTH]) & (~|(rd_ptr[ADDR_WIDTH-1:0]^wr_ptr[ADDR_WIDTH-1:0]));
    assign wr_ready_o   = (~full_o);
    assign rd_ready_o   = po_fwd_valid;
    assign po_bwd_valid = |(rd_ptr^wr_ptr);
    assign rd_handshake = po_bwd_valid & po_bwd_ready;
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
end
else if(FIFO_TYPE == 0) begin : HALF_FLOP
    // Internal signal declaration
    // wire declaration
    // -- Common
    wire                    full_r_en;
    wire                    empty_r_en;
    wire                    full_nxt;
    wire                    empty_nxt;
    // -- Write handle
    wire                    wr_handshake;
    wire[ADDR_WIDTH:0]      wr_addr_inc;
    wire[ADDR_WIDTH - 1:0]  wr_addr_map;
    // -- Read handle
    wire                    rd_handshake;
    wire[ADDR_WIDTH:0]      rd_addr_inc;
    wire[ADDR_WIDTH - 1:0]  rd_addr_map;
    
    // reg declaration
	reg [DATA_WIDTH - 1:0]  mem        [0:FIFO_DEPTH - 1];
	reg [ADDR_WIDTH:0]      wr_addr;
    reg [ADDR_WIDTH:0]      rd_addr;
    reg                     empty_q;
    reg                     full_q;
    reg                     rd_ready;
    reg                     wr_ready;
    
    // combinational logic
    // -- Common
    assign data_o           = mem[rd_addr_map];
    // -- Write handle
    assign wr_addr_inc      = wr_addr + 1'b1;
    assign wr_addr_map      = wr_addr[ADDR_WIDTH - 1:0];
    assign wr_handshake     = wr_valid_i & !full_o;
    assign full_o           = full_q;
    assign wr_ready_o       = wr_ready;
    // -- Read handle
    assign rd_addr_inc      = rd_addr + 1'b1;
    assign rd_addr_map      = rd_addr[ADDR_WIDTH - 1:0];
    assign rd_handshake     = rd_valid_i & !empty_o;
    assign empty_o          = empty_q;
    assign rd_ready_o       = rd_ready;
    // -- Common
    assign empty_r_en       = wr_handshake | rd_handshake;
    assign full_r_en        = wr_handshake | rd_handshake;
    assign empty_nxt        = (rd_handshake & almost_empty_o) & (~wr_handshake);
    assign full_nxt         = (wr_handshake & almost_full_o) & (~rd_handshake);
    assign almost_empty_o   = rd_addr_inc ==  wr_addr;
    assign almost_full_o    = wr_addr_map + 1'b1 == rd_addr_map;
    assign counter          = wr_addr - rd_addr;
    
    // flip-flop logic
    // -- Buffer updater
    always @(posedge clk) begin
        if(wr_handshake) begin
            mem[wr_addr_map] <= data_i;
        end
    end
    always @(posedge clk) begin
    
    end
    // -- Write pointer updater
    always @(posedge clk) begin
        if(!rst_n) begin 
            wr_addr <= 0;        
        end
        else if(wr_handshake) begin
            wr_addr <= wr_addr_inc;
        end
    end
    // -- Read pointer updater
    always @(posedge clk) begin
        if(!rst_n) begin
            rd_addr <= 0;
        end
        else if(rd_handshake) begin
            rd_addr <= rd_addr_inc;
        end
    end
    // -- Full signal update
    always @(posedge clk) begin
        if(!rst_n) begin
            full_q <= 1'b0;
        end
        else if(full_r_en) begin
            full_q <= full_nxt;
        end
    end
    // -- Write Ready update (optional)
    always @(posedge clk) begin
        if(!rst_n) begin
            wr_ready <= 1'b1;
        end
        else if(full_r_en) begin
            wr_ready <= ~full_nxt;
        end
    end
    // -- Empty signal update
    always @(posedge clk) begin
        if(!rst_n) begin
            empty_q <= 1'b1;
        end
        else if(empty_r_en) begin
            empty_q <= empty_nxt;
        end
    end
    // -- Read ready update
    always @(posedge clk) begin
        if(!rst_n) begin
            rd_ready <= 1'b0;
        end
        else if(empty_r_en) begin
            rd_ready <= ~empty_nxt;
        end
    end
end
endgenerate
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