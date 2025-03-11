module splitting_4kb_masker
#(
    parameter ADDR_WIDTH    = 32,
    parameter LEN_WIDTH     = 3,
    parameter SIZE_WIDTH    = 3
)
(
    // Input declaration
    input   [ADDR_WIDTH-1:0]    ADDR_i,
    input   [LEN_WIDTH-1:0]     LEN_i,
    input   [SIZE_WIDTH-1:0]    SIZE_i,
    input                       mask_sel_i, // Mask selection
    // Output declaration
    output  [ADDR_WIDTH-1:0]    ADDR_split_o,
    output  [LEN_WIDTH-1:0]     LEN_split_o,
    output                      crossing_flag
);
    // Local parameters intiialization
    localparam BIT_OFFSET_4KB = 12; // log2(4096) = 12
    localparam TRANS_SIZE_EXT = (BIT_OFFSET_4KB+1) - (LEN_WIDTH+1+2**SIZE_WIDTH-1);
    
    // Internal signal declaration
    // wire declaration
    wire [(LEN_WIDTH+1+2**SIZE_WIDTH-1)-1:0]trans_size;
    wire [BIT_OFFSET_4KB-1:0]               trans_size_ext;
    wire [(LEN_WIDTH+1+2**SIZE_WIDTH-1)-1:0]trans_size_rem;
    wire [BIT_OFFSET_4KB:0]                 addr_end;
    wire [(LEN_WIDTH+1+2**SIZE_WIDTH-1)-1:0]trans_size_sll      [0:2**SIZE_WIDTH-1];
    wire [(LEN_WIDTH+1+2**SIZE_WIDTH-1)-1:0]trans_size_rem_srl  [0:2**SIZE_WIDTH-1];
    wire [(LEN_WIDTH+1+2**SIZE_WIDTH-1)-1:0]LEN_rem_srl;
    wire [LEN_WIDTH:0]                      LEN_incr;                        
    wire [LEN_WIDTH-1:0]                    LEN_msk_1;                        
    wire [LEN_WIDTH-1:0]                    LEN_msk_2;    
    wire [ADDR_WIDTH-1:0]                   ADDR_msk_1;                        
    wire [ADDR_WIDTH-1:0]                   ADDR_msk_2;                        
    
    // combinational logic
    assign LEN_incr = LEN_i + 1'b1;
    genvar shamt;
    generate
        for(shamt = 0; shamt < 2**SIZE_WIDTH; shamt = shamt + 1) begin : SHIFTER
            assign trans_size_sll[shamt] = LEN_incr << shamt;
            assign trans_size_rem_srl[shamt] = trans_size_rem >> shamt;
        end
    endgenerate
    
    // 4KB crossing detector
    assign trans_size = trans_size_sll[SIZE_i];
    generate
        if(TRANS_SIZE_EXT <= 0) begin
            assign trans_size_ext = trans_size;
        end
        else begin
            assign trans_size_ext = {{TRANS_SIZE_EXT{1'b0}}, trans_size};
        end
    endgenerate
    assign addr_end = {1'b0, ADDR_i[BIT_OFFSET_4KB-1:0]} + trans_size_ext;
    assign crossing_flag = (addr_end[BIT_OFFSET_4KB] == 1'b1) & (|addr_end[BIT_OFFSET_4KB-1:0]); // crossing_flag = (addr_end / 4KB) > 1
    // LEN masker
    assign trans_size_rem = addr_end[BIT_OFFSET_4KB-1:0];
    assign LEN_rem_srl = trans_size_rem_srl[SIZE_i];
    assign LEN_msk_2 = LEN_rem_srl;
    assign LEN_msk_1 = LEN_incr - LEN_msk_2;
    assign LEN_split_o = (crossing_flag) ? ((mask_sel_i) ? LEN_msk_2 : LEN_msk_1) - 1'b1 : LEN_i;
    // ADDR masker
    assign ADDR_msk_1 = ADDR_i;
    assign ADDR_msk_2 = {ADDR_i[ADDR_WIDTH-1:BIT_OFFSET_4KB-1] + 1'b1, {(BIT_OFFSET_4KB-1){1'b0}}};
    assign ADDR_split_o = (mask_sel_i) ? ADDR_msk_2 : ADDR_msk_1;

endmodule
