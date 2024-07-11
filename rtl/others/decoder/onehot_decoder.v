module onehot_decoder
#(
    parameter INPUT_W   = 3,
    parameter OUTPUT_W  = 1<<INPUT_W
)
(
    input   [INPUT_W-1:0]   i,
    output  [OUTPUT_W-1:0]  o
);

    // Internal variable
    genvar bit_ctn;
    
    // Combinational logic
    generate
        for(bit_ctn = 0; bit_ctn < OUTPUT_W; bit_ctn = bit_ctn + 1) begin
            assign o[bit_ctn] = (i == bit_ctn);
        end
    endgenerate

endmodule
