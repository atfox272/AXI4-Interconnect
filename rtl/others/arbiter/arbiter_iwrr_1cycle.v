module arbiter_iwrr_1cycle
#(
    // Requester number
    parameter                               P_REQUESTER_NUM     = 4,       
    // Weight value of each requester (requester_weight[0] = max_weight)
    parameter   [0:(P_REQUESTER_NUM*32)-1]  P_REQUESTER_WEIGHT  = {32'd5, 32'd3, 32'd2, 32'd1},
    parameter                               P_WEIGHT_W          = $clog2(P_REQUESTER_WEIGHT[0*32+:32]),
    parameter                               P_NUM_GRANT_REQ_W   = 3    // Max number of requested grant is 2**P_NUM_GRANT_REQ_W
)
(   
    // Input declaration
    input                           clk,
    input                           rst_n,
    input   [P_REQUESTER_NUM-1:0]   req_i,
    input   [P_NUM_GRANT_REQ_W-1:0] num_grant_req_i,
    input                           grant_ready_i,
    // Output declaration
    output  [P_REQUESTER_NUM-1:0]   grant_valid_o
);
    // Local parameters
    // Data width
    localparam REQ_NUM_W        = $clog2(P_REQUESTER_NUM);
    
    // Internal variable
//    integer i;
    genvar i;
    // Internal signal declaration
    // wire declaration
    wire    [0:P_REQUESTER_NUM*P_WEIGHT_W - 1]  req_weight_nxt;         // Next requester weight    
    wire    [0:P_REQUESTER_NUM*P_WEIGHT_W - 1]  req_weight_decr;        // Decreased requester weight    
    wire    [P_REQUESTER_NUM - 1:0]             req_weight_remain;      // weight of a requester is remain
    wire    [P_REQUESTER_NUM - 1:0]             req_weight_completed;   // requester weight completed (== 0)
    wire    [REQ_NUM_W - 1:0]                   req_grant_enc;          // granted requester encoder
    wire    [REQ_NUM_W - 1:0]                   grant_mux_enc           [0:P_REQUESTER_NUM - 1];          // Onehot MUXs sequence
    wire    [REQ_NUM_W - 1:0]                   interleaving_ptr_nxt;   // interleaving pointer next
    wire    [REQ_NUM_W - 1:0]                   interleaving_ptr_incr;  // interleaving pointer increment
    wire                                        round_comp;             // Round completion flag
    wire    [P_REQUESTER_NUM - 1:0]             prior_grant             [0:P_REQUESTER_NUM - 1];
    // reg declaration
    reg     [0:P_REQUESTER_NUM*P_WEIGHT_W - 1]  req_weight_r;    // requester weight
    reg     [REQ_NUM_W - 1:0]                   interleaving_ptr_r; // interleaving pointer register 
    
    // combinational logic
    generate
        for(i = 0; i < P_REQUESTER_NUM; i = i + 1) begin
            arb_prior_granter #(
                .P_REQUESTER_NUM(P_REQUESTER_NUM),
                .P_HIGHEST_PRIOR_IDX(i)
            )prior_granter(
                .request(req_i),
                .request_weight_completed(req_weight_completed),
                .prior_grant(prior_grant[i])
            );
        end
    endgenerate
    arb_round_comp_detector #(
        .P_REQUESTER_NUM(P_REQUESTER_NUM),
        .P_WEIGHT_W(P_WEIGHT_W)
    )round_comp_detector(
        // Input
        .req_weight_i(req_weight_r),
        .req_weight_remain_i(req_weight_remain),
        .grant_i(grant_valid_o),
        // Output
        .round_comp_o(round_comp)
    );
    assign grant_valid_o = prior_grant[interleaving_ptr_r];
    assign req_grant_enc = grant_mux_enc[P_REQUESTER_NUM - 1];
    assign interleaving_ptr_incr = (grant_valid_o[P_REQUESTER_NUM - 1]) ? 0 : req_grant_enc + 1'b1;
    assign interleaving_ptr_nxt = (|grant_valid_o) ? interleaving_ptr_incr : interleaving_ptr_r;
    generate
        for(i = 0; i < P_REQUESTER_NUM; i = i + 1) begin
            assign req_weight_remain[i] = num_grant_req_i < req_weight_r[((i+1)*P_WEIGHT_W-1)-:P_WEIGHT_W];
            assign req_weight_completed[i] = ~|req_weight_r[((i+1)*P_WEIGHT_W-1)-:P_WEIGHT_W];	// (r_weight == 0)
            assign req_weight_decr[((i+1)*P_WEIGHT_W-1)-:P_WEIGHT_W] = (req_weight_remain[i]) ? req_weight_r[((i+1)*P_WEIGHT_W-1)-:P_WEIGHT_W] - num_grant_req_i : 0;
            assign req_weight_nxt[((i+1)*P_WEIGHT_W-1)-:P_WEIGHT_W] = (round_comp) ? P_REQUESTER_WEIGHT[i*32+:32] : (grant_valid_o[i]) ? req_weight_decr[((i+1)*P_WEIGHT_W-1)-:P_WEIGHT_W] : req_weight_r[((i+1)*P_WEIGHT_W-1)-:P_WEIGHT_W];
            // Onehot encoder sequence
            if(i == 0) assign grant_mux_enc[i] = grant_valid_o[i] ? i : 0;
            else assign grant_mux_enc[i] = grant_valid_o[i] ? i : grant_mux_enc[i - 1];
        end
    endgenerate
    
    // flip-flop
    // -- Weight updater
    generate
        for(i = 0; i < P_REQUESTER_NUM; i = i + 1) begin
            always @(posedge clk) begin
                if(~rst_n) begin
                    req_weight_r[((i+1)*P_WEIGHT_W-1)-:P_WEIGHT_W] <= P_REQUESTER_WEIGHT[i*32+:32];
                end
                else if(grant_ready_i) begin
                    req_weight_r[((i+1)*P_WEIGHT_W-1)-:P_WEIGHT_W] <= req_weight_nxt[((i+1)*P_WEIGHT_W-1)-:P_WEIGHT_W];
                end
            end
        end
    endgenerate
    // -- Interleaving pointer
    always @(posedge clk) begin
        if(~rst_n) begin
            interleaving_ptr_r <= 0;
        end
        else if(grant_ready_i) begin
            interleaving_ptr_r <= interleaving_ptr_nxt;
        end
    end
endmodule