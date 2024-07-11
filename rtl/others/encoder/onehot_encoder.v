// Scalable logic optimized Onehot Encoder (only OR gates)
module onehot_encoder
#(
    parameter INPUT_W   = 8,
    parameter OUTPUT_W  = 3
)
(
    input   [INPUT_W-1:0]   i,
    output  [OUTPUT_W-1:0]  o
);
    // Local paramteters
    localparam EXT_BIT = 2**OUTPUT_W - INPUT_W;
    // Internal variable declaration
    genvar  o_bit_idx;
    genvar  i_bit_idx;
    // Internal signal declaration
    wire    [INPUT_W+EXT_BIT-1:0]   i_ext;
    wire    [2**(OUTPUT_W-1)-1:0]   o_bit_set   [0:OUTPUT_W-1];
    // Combination logic
    generate
    if(EXT_BIT == 0) begin  // Not Extend
        assign i_ext = i;
    end
    else begin              // Extend
        assign i_ext = {{EXT_BIT{1'b0}}, i};
    end
    endgenerate
    generate
        for(o_bit_idx = 0; o_bit_idx < OUTPUT_W; o_bit_idx = o_bit_idx + 1) begin
            for(i_bit_idx = 0; i_bit_idx < 2**OUTPUT_W; i_bit_idx = i_bit_idx + 1) begin
                if((i_bit_idx/(2**o_bit_idx))%2 == 1) begin
                    assign o_bit_set[o_bit_idx][(2**o_bit_idx)*(i_bit_idx/(2*(2**o_bit_idx)))+(i_bit_idx%(2**o_bit_idx))] = i_ext[i_bit_idx];
                end
            end
            assign o[o_bit_idx] = |o_bit_set[o_bit_idx];
        end
    endgenerate
endmodule
