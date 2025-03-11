module sa_B_channel 
#(
    // Interconnect configuration
    parameter MST_AMT           = 3,
    parameter OUTSTANDING_AMT   = 8,
    parameter MST_ID_W          = $clog2(MST_AMT),
    // Transaction configuration
    parameter TRANS_MST_ID_W    = 5,                                // Width of master transaction ID 
    parameter TRANS_SLV_ID_W    = TRANS_MST_ID_W + $clog2(MST_AMT), // Width of slave transaction ID
    parameter TRANS_WR_RESP_W   = 2
)
(
    // Input declaration
    // -- Global signals
    input                                   ACLK_i,
    input                                   ARESETn_i,
    // -- To Dispatcher
    // ---- Write response channel
    input   [MST_AMT-1:0]                   dsp_BREADY_i,
    // -- To slave (master interface of the interconnect)
    // ---- Write response channel (master)
    input   [TRANS_SLV_ID_W-1:0]            s_BID_i,
    input   [TRANS_WR_RESP_W-1:0]           s_BRESP_i,
    input                                   s_BVALID_i,
    // -- To Write Address channel
    input   [TRANS_SLV_ID_W-1:0]            AW_AxID_i,
    input                                   AW_crossing_flag_i,
    input                                   AW_shift_en_i,
    // Output declaration
    // -- To Dispatcher
    // ---- Write response channel (master)
    output  [TRANS_MST_ID_W*MST_AMT-1:0]    dsp_BID_o,
    output  [TRANS_WR_RESP_W*MST_AMT-1:0]   dsp_BRESP_o,
    output  [MST_AMT-1:0]                   dsp_BVALID_o,
    // -- To slave (master interface of the interconnect)
    // ---- Write response channel          
    output                                  s_BREADY_o,
    // To Write Address channel
    output                                  AW_stall_o
);
    // Local parameters initialization
    localparam FILTER_INFO_W    = TRANS_SLV_ID_W + 1;  // crossing flag + Transaction ID
    localparam B_INFO_W         = TRANS_SLV_ID_W + TRANS_WR_RESP_W;
    
    // Internal variable declaration 
    genvar mst_idx;
    // Internal signal declaration
    // -- wire declaration
    // ---- FIFO WRESP filter
    wire    [FILTER_INFO_W-1:0]     filter_info;
    wire    [FILTER_INFO_W-1:0]     filter_info_valid;
    wire                            fifo_filter_wr_en;
    wire                            fifo_filter_rd_en;
    wire                            fifo_filter_full;
    wire                            fifo_filter_empty;
    // ---- Write response filter
    wire    [TRANS_SLV_ID_W-1:0]    AWID_valid;
    wire    [TRANS_SLV_ID_W-1:0]    crossing_flag_valid;
    wire                            filter_AWID_match;
    wire                            filter_condition;
    wire                            filter_BVALID;
    wire                            filter_BREADY_gen;
    // -- Handshake detector
    wire                            slv_handshake_occur;
    // -- Master mapping
    wire    [MST_ID_W-1:0]          mst_id;
    wire                            dsp_BREADY_valid;
    // -- Slave skid buffer
    wire    [B_INFO_W-1:0]          ssb_bwd_data;
    wire                            ssb_bwd_valid;
    wire                            ssb_bwd_ready;
    wire    [B_INFO_W-1:0]          ssb_fwd_data;
    wire                            ssb_fwd_valid;
    wire                            ssb_fwd_ready;
    wire    [TRANS_SLV_ID_W-1:0]    ssb_fwd_BID;
    wire    [TRANS_WR_RESP_W-1:0]   ssb_fwd_BRESP;
    // Module
    // -- FIFO WRESP ordering
    fifo 
    #(
        .DATA_WIDTH(FILTER_INFO_W),
        .FIFO_DEPTH(OUTSTANDING_AMT)
    ) fifo_wresp_filter (
        .clk(ACLK_i),
        .data_i(filter_info),
        .data_o(filter_info_valid),
        .rd_valid_i(fifo_filter_rd_en),
        .wr_valid_i(fifo_filter_wr_en),
        .empty_o(fifo_filter_empty),
        .full_o(fifo_filter_full),
        .almost_empty_o(),
        .almost_full_o(),
        .counter(),
        .rst_n(ARESETn_i)
    );
    // Slave skid buffer (pipelined in/out)
    skid_buffer #(
        .SBUF_TYPE(1),
        .DATA_WIDTH(B_INFO_W)
    ) slv_skid_buffer (
        .clk        (ACLK_i),
        .rst_n      (ARESETn_i),
        .bwd_data_i (ssb_bwd_data),
        .bwd_valid_i(ssb_bwd_valid),
        .fwd_ready_i(ssb_fwd_ready),
        .fwd_data_o (ssb_fwd_data),
        .bwd_ready_o(ssb_bwd_ready),
        .fwd_valid_o(ssb_fwd_valid)
    );
    // Combinational logic
    // -- FIFO WRESP filter
    assign filter_info = {AW_crossing_flag_i, AW_AxID_i};
//    assign fifo_filter_wr_en = AW_shift_en_i & AW_crossing_flag_i;
//    assign fifo_filter_rd_en = slv_handshake_occur & filter_condition;
    assign fifo_filter_wr_en = AW_shift_en_i;
    assign fifo_filter_rd_en = slv_handshake_occur;
    // -- Write response filter
    assign {crossing_flag_valid, AWID_valid} = filter_info_valid;
    assign filter_AWID_match = (AWID_valid == ssb_fwd_BID) & crossing_flag_valid;
    assign filter_condition = filter_AWID_match & ~fifo_filter_empty;
    assign filter_BVALID = ssb_fwd_valid & ~filter_condition;
    assign filter_BREADY_gen = dsp_BREADY_valid | filter_condition;
    // -- Handshake detector
    assign slv_handshake_occur = ssb_fwd_valid & ssb_fwd_ready;
    // -- Master mapping
    assign mst_id = ssb_fwd_BID[(TRANS_SLV_ID_W-1)-:MST_ID_W];
    // -- Slave Output
    assign s_BREADY_o = ssb_bwd_ready;
    // -- Dispatcher Output
    assign dsp_BREADY_valid = dsp_BREADY_i[mst_id];
    generate
        for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : MST_LOGIC
            assign dsp_BVALID_o[mst_idx] = (mst_id == mst_idx) & filter_BVALID;
            assign dsp_BID_o[TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W] = ssb_fwd_BID[TRANS_MST_ID_W-1:0];
            assign dsp_BRESP_o[TRANS_WR_RESP_W*(mst_idx+1)-1-:TRANS_WR_RESP_W] = ssb_fwd_BRESP;
        end
    endgenerate
    // -- Slave skid buffer
    assign ssb_bwd_data     = {s_BID_i, s_BRESP_i};
    assign ssb_bwd_valid    = s_BVALID_i;
    assign ssb_fwd_ready    = filter_BREADY_gen;
    assign {ssb_fwd_BID, ssb_fwd_BRESP} = ssb_fwd_data;
    // -- Write Address channel Output
    assign AW_stall_o = fifo_filter_full;
    
endmodule