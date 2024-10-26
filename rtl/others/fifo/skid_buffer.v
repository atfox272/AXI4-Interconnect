module skid_buffer
#(
    parameter   SBUF_TYPE   = 0,
    parameter   DATA_WIDTH  = 8
)
(
    // Global declaration
    input                       clk,
    input                       rst_n,
    // Input declaration
    input   [DATA_WIDTH-1:0]    bwd_data_i,
    input                       bwd_valid_i,
    input                       fwd_ready_i,
    // Output declaration
    output  [DATA_WIDTH-1:0]    fwd_data_o,
    output                      bwd_ready_o,
    output                      fwd_valid_o
);
generate
    if(SBUF_TYPE == 0) begin : FULL_REGISTERED
        // Internal signal 
        // -- wire declaration
        wire                        bwd_handshake;
        wire                        fwd_handshake;
        reg     [DATA_WIDTH-1:0]    bwd_data_d;
        reg     [DATA_WIDTH-1:0]    fwd_data_d;
        reg                         bwd_ready_d;
        reg                         fwd_valid_d;
        // -- reg declaration 
        reg     [DATA_WIDTH-1:0]    bwd_data_q;
        reg     [DATA_WIDTH-1:0]    fwd_data_q;
        reg                         bwd_ready_q;
        reg                         fwd_valid_q;
        
        // Combinational logic
        // -- Output
        assign fwd_data_o       = fwd_data_q;
        assign fwd_valid_o      = fwd_valid_q;
        assign bwd_ready_o      = bwd_ready_q;
        // -- Internal connection
        assign bwd_handshake    = bwd_valid_i & bwd_ready_o;
        assign fwd_handshake    = fwd_valid_o & fwd_ready_i;
        always @* begin
            bwd_data_d  = bwd_data_q;
            fwd_data_d  = fwd_data_q;
            bwd_ready_d = bwd_ready_q;
            fwd_valid_d = fwd_valid_q;
            if(bwd_handshake & fwd_handshake) begin 
                fwd_data_d = bwd_data_i;
            end
            else if (bwd_handshake) begin
                if(fwd_valid_q) begin // Have a valid data in the skid buffer
                    bwd_data_d  = bwd_data_i;
                    bwd_ready_d = 1'b0;
                end
                else begin  // The skid buffer is empty
                    fwd_data_d  = bwd_data_i;
                    fwd_valid_d = 1'b1;
                end
            end
            else if (fwd_handshake) begin
                if(bwd_ready_q) begin   // Have 1 empty slot in the skid buffer
                    fwd_valid_d = 1'b0;
                end
                else begin // The skid buffer is full
                    fwd_data_d  = bwd_data_q;
                    bwd_ready_d = 1'b1;
                end
            end
        end
        
        // Flip-flop
        // -- Foward 
        always @(posedge clk) begin
            if(!rst_n) begin
                fwd_valid_q <= 1'b0;
            end
            else begin
                fwd_data_q  <= fwd_data_d;
                fwd_valid_q <= fwd_valid_d;
            end
        end
        // -- Backward
        always @(posedge clk) begin
            if(!rst_n) begin
                bwd_ready_q <= 1'b1;
            end
            else begin
                bwd_data_q  <= bwd_data_d;
                bwd_ready_q <= bwd_ready_d;
            end
        end
    end
    else if(SBUF_TYPE == 1) begin   : REGISTERED_INPUT
        
        // Internal signal
        // -- wire declaration
        // -- -- Backward
        wire                        bwd_ready_d;
        // -- -- Common
        wire                        bwd_handshake;
        wire                        fwd_handshake;
        // -- -- FIFO
        wire    [DATA_WIDTH-1:0]    inter_fifo_data_i;
        wire    [DATA_WIDTH-1:0]    inter_fifo_data_o;
        wire                        inter_fifo_empty;
        wire                        inter_fifo_full;
        wire                        inter_fifo_almost_full;
        wire    [2:0]               inter_fifo_counter;
        wire                        inter_fifo_wr_en;
        wire                        inter_fifo_rd_en;
        // -- reg declaration
        reg     [DATA_WIDTH-1:0]    bwd_data_q;
        reg                         bwd_valid_q;
        reg                         bwd_ready_q;
        reg                         bwd_ready_prev_q;
        
        // Internal module
        fifo #(
            .DATA_WIDTH(DATA_WIDTH),
            .FIFO_DEPTH(4)
        ) fifo (
            .clk(clk),
            .data_i(inter_fifo_data_i),
            .data_o(inter_fifo_data_o),
            .rd_valid_i(inter_fifo_rd_en),
            .wr_valid_i(inter_fifo_wr_en),
            .empty_o(inter_fifo_empty),
            .full_o(inter_fifo_full),
            .almost_empty_o(),
            .almost_full_o(inter_fifo_almost_full),
            .counter(inter_fifo_counter),
            .rst_n(rst_n)
            );
        
        // Combinational logic
        // -- Output
        assign bwd_ready_o      = bwd_ready_q;
        assign bwd_ready_d      = ~(inter_fifo_counter == 2'd2) & ~inter_fifo_almost_full & ~inter_fifo_full;
        assign fwd_data_o       = (inter_fifo_empty) ? bwd_data_q : inter_fifo_data_o;
        assign fwd_valid_o      = bwd_handshake | (~inter_fifo_empty);
        // -- FIFO
        assign inter_fifo_data_i= bwd_data_q;
        assign inter_fifo_wr_en = bwd_handshake & ((~inter_fifo_empty) | (~fwd_handshake));
        assign inter_fifo_rd_en = fwd_handshake;
        // -- Common
        assign bwd_handshake    = bwd_ready_prev_q & bwd_valid_q;
        assign fwd_handshake    = fwd_ready_i & fwd_valid_o;
        
        always @(posedge clk) begin
            if(!rst_n) begin
            
            end
            else begin
                bwd_data_q <= bwd_data_i;
            end
        end
        
        always @(posedge clk) begin
            if(!rst_n) begin
                bwd_valid_q <= 1'b0;
            end
            else begin
                bwd_valid_q <= bwd_valid_i;
            end
        end
        
        always @(posedge clk) begin
            if(!rst_n) begin
                bwd_ready_q      <= 1'b1;
                bwd_ready_prev_q <= 1'b1;
            end
            else begin
                bwd_ready_q      <= bwd_ready_d;
                bwd_ready_prev_q <= bwd_ready_q;
            end
        end
        
    end
    else if(SBUF_TYPE == 2) begin   : LIGHT_WEIGHT
        // Internal signal 
        // -- wire declaration
        wire                        bwd_handshake;
        wire                        fwd_handshake;
        // -- reg declaration 
        reg                         bwd_ptr;
        reg                         fwd_ptr;
        reg     [DATA_WIDTH-1:0]    buffer;
        
        // Combination logic
        assign fwd_data_o       = buffer;
        assign bwd_ready_o      = ~fwd_valid_o;
        assign fwd_valid_o      = bwd_ptr ^ fwd_ptr;
        assign bwd_handshake    = bwd_valid_i & bwd_ready_o;
        assign fwd_handshake    = fwd_ready_i & fwd_valid_o;
        
        // Flip-flop logic
        // -- Backward pointer
        always @(posedge clk) begin
            if(!rst_n) begin
                bwd_ptr <= 1'b0;
            end
            else if(bwd_handshake) begin
                bwd_ptr <= ~bwd_ptr;
            end
        end
        // -- Forward pointer
        always @(posedge clk) begin
            if(!rst_n) begin
                fwd_ptr <= 1'b0;
            end
            else if(fwd_handshake) begin
                fwd_ptr <= ~fwd_ptr;
            end
        end
        // -- Buffer
        always @(posedge clk) begin
            if(!rst_n) begin
            
            end
            else if(bwd_handshake) begin
                buffer <= bwd_data_i;
            end
        end
    end
endgenerate
endmodule
