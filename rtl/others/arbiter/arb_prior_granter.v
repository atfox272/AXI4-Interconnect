module arb_prior_granter
#(
    parameter P_REQUESTER_NUM       = 3,
    parameter P_HIGHEST_PRIOR_IDX   = 0
)
(
    // Input declaration
    input   [P_REQUESTER_NUM - 1:0] request,
    input   [P_REQUESTER_NUM - 1:0] request_weight_completed,
    // Output declaration
    output  [P_REQUESTER_NUM - 1:0] prior_grant
);
    // Internal signal declaration
    // wire declaration
    wire    [P_REQUESTER_NUM - 1:0] request_valid;          // blue
    wire    [P_REQUESTER_NUM - 1:0] request_exception;      // orange
    wire    [P_REQUESTER_NUM - 1:0] higher_prior_grant;     // red
    wire    [P_REQUESTER_NUM - 1:0] request_active;         // gray
    wire    [P_REQUESTER_NUM - 1:0] request_filtered;       // pink
    wire    [P_REQUESTER_NUM - 1:0] other_request_valid [0:P_REQUESTER_NUM - 1];    // violet
    
    // combinational logic
    for(genvar i = 0; i < P_REQUESTER_NUM; i = i + 1) begin
        for(genvar n = 0; n < P_REQUESTER_NUM; n = n + 1) begin
            if(n == i) assign other_request_valid[i][n] = 1'b0;
            else assign other_request_valid[i][n] = request_valid[n];
        end
        assign request_valid[i] = request[i] & ~request_weight_completed[i];
        assign request_exception[i] = (~|other_request_valid[i]) & request[i];
        assign request_active[i] = request_valid[i] | request_exception[i];
        assign request_filtered[i] = request_active[i] & ~higher_prior_grant[i];
        if(i == P_HIGHEST_PRIOR_IDX) begin
            assign higher_prior_grant[P_HIGHEST_PRIOR_IDX] = 1'b0 | 1'b0;
        end
        else begin
            integer higher_prior_idx = (i - 1 < 0) ? P_REQUESTER_NUM - 1 : i - 1;
            assign higher_prior_grant[i] = request_active[higher_prior_idx] | higher_prior_grant[higher_prior_idx];
        end 
        assign prior_grant[i] = request_filtered[i];
    end

endmodule