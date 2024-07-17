module arb_round_comp_detector
#(
    parameter P_REQUESTER_NUM   = 3,
    parameter P_WEIGHT_W        = 2
)
(
    // Input declaration
    input   [0:P_REQUESTER_NUM*P_WEIGHT_W - 1]  req_weight_i,
    input   [P_REQUESTER_NUM - 1:0]             req_weight_remain_i,
    input   [P_REQUESTER_NUM - 1:0]             grant_i,
    // Output declaration
    output                                      round_comp_o
);
    // Internal variable
    genvar i;
    genvar n;
    
    // Internal signal declaration
    // wire declaration
    wire    [P_REQUESTER_NUM - 1:0] req_weight_mask     [P_REQUESTER_NUM - 1:0];
    wire    [P_REQUESTER_NUM - 1:0] weight_comp_match;
    wire    [P_REQUESTER_NUM - 1:0] weight_rst_en;
    wire    [P_REQUESTER_NUM - 1:0] weight_remain;
    
    // combinational logic
    generate
        for(i = 0; i < P_REQUESTER_NUM; i = i + 1) begin
            for(n = 0; n < P_REQUESTER_NUM; n = n + 1) begin
                if(i == n) begin
                    assign req_weight_mask[i][n] = ~(req_weight_i[((n+1)*P_WEIGHT_W-1)-:P_WEIGHT_W] == 0);
                end
                else begin
                    assign req_weight_mask[i][n] = (req_weight_i[((n+1)*P_WEIGHT_W-1)-:P_WEIGHT_W] == 0);
                end
            end
            assign weight_comp_match[i] = (&req_weight_mask[i]) & (~req_weight_remain_i[i]);
            assign weight_rst_en[i] = weight_comp_match[i] & grant_i[i];
        end
    endgenerate
    assign round_comp_o = |weight_rst_en;

endmodule
