module edgedet
#(
    parameter RISING_EDGE = 1
)
(
    input   clk,
    input   i,
    input   en,
    output  o,
    input   rst_n
);
    reg prev_i;
    always @(posedge clk) begin
        if(~rst_n) prev_i <= 0;
        else if(en) prev_i <= i;
    end
    generate
        if(RISING_EDGE) begin
            assign o = ~prev_i & i;
        end
        else begin
            assign o = prev_i & ~i;
        end
    endgenerate 
endmodule
//edgedet 
//    #(
//    .RISING_EDGE()
//    )edgedet(
//    .clk(),
//    .i(),
//    .o(),
//    .rst_n()
//    );
