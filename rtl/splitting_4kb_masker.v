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
    output  [SIZE_WIDTH-1:0]    SIZE_o,
    output                      crossing_flag
);

    localparam BIT_OFFSET_4KB = 12; // log2(4096) = 12
    
    // Internal signal declaration
    // wire declaration
    wire [(LEN_WIDTH+2**SIZE_WIDTH)-1:0]    trans_size;
    wire [(LEN_WIDTH+2**SIZE_WIDTH)-1:0]    trans_size_rem;
    wire [BIT_OFFSET_4KB:0]                 addr_end;
    wire [(LEN_WIDTH+2**SIZE_WIDTH)-1:0]    trans_size_sll      [0:2**SIZE_WIDTH-1];
    wire [(LEN_WIDTH+2**SIZE_WIDTH)-1:0]    trans_size_rem_srl  [0:2**SIZE_WIDTH-1];
    wire [(LEN_WIDTH+2**SIZE_WIDTH)-1:0]    LEN_rem_srl;
    wire [LEN_WIDTH-1:0]                    LEN_msk_1;                        
    wire [LEN_WIDTH-1:0]                    LEN_msk_2;    
    wire [ADDR_WIDTH-1:0]                   ADDR_msk_1;                        
    wire [ADDR_WIDTH-1:0]                   ADDR_msk_2;                        
    
    // combinational logic
    genvar shamt;
    generate
        for(shamt = 0; shamt < 2**SIZE_WIDTH; shamt = shamt + 1) begin
            assign trans_size_sll[shamt] = LEN_i << shamt;
            assign trans_size_rem_srl[shamt] = trans_size_rem >> shamt;
        end
    endgenerate
    
    // 4KB crossing detector
    assign trans_size = trans_size_sll[SIZE_i];
    assign addr_end = {1'b0, ADDR_i[BIT_OFFSET_4KB-1:0]} + {1'b0, {(BIT_OFFSET_4KB-(LEN_WIDTH+2**SIZE_WIDTH)){1'b0}}, trans_size};
    assign crossing_flag = addr_end[BIT_OFFSET_4KB];
    // LEN masker
    assign trans_size_rem = addr_end[BIT_OFFSET_4KB-1:0];
    assign LEN_rem_srl = trans_size_rem_srl[SIZE_i];
    assign LEN_msk_2 = LEN_rem_srl;
    assign LEN_msk_1 = LEN_i - LEN_msk_2;
    assign LEN_split_o = (crossing_flag) ? ((mask_sel_i) ? LEN_msk_2 : LEN_msk_1) : LEN_i;
    // ADDR masker
    assign ADDR_msk_1 = ADDR_i;
    assign ADDR_msk_2 = {ADDR_i[ADDR_WIDTH-1:BIT_OFFSET_4KB-1] + 1'b1, {(BIT_OFFSET_4KB-1){1'b0}}};
    assign ADDR_split_o = (mask_sel_i) ? ADDR_msk_2 : ADDR_msk_1;
    // Size
    assign SIZE_o = SIZE_i;

endmodule