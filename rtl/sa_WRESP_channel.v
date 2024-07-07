module sa_WRESP_channel 
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
    output  [TRANS_SLV_ID_W*MST_AMT-1:0]    dsp_BID_o,
    output  [TRANS_WR_RESP_W*MST_AMT-1:0]   dsp_BRESP_o,
    output  [MST_AMT-1:0]                   dsp_BVALID_o,
    // -- To slave (master interface of the interconnect)
    // ---- Write response channel          
    output                                  s_BREADY_o,
    // To Write Address channel
    output                                  AW_stall_o
);
    // Local parameters initialization
    localparam FILTER_INFO_W = TRANS_SLV_ID_W;
    
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
    wire    [TRANS_SLV_ID_W-1:0]    filter_AWID;
    wire                            filter_AWID_match;
    wire                            filter_condition;
    wire                            filter_BVALID;
    wire                            filter_BREADY_gen;
    // -- Handshake detector
    wire                            slv_handshake_occur;
    // -- Master mapping
    wire    [MST_ID_W-1:0]          mst_id;
    wire                            dsp_BREADY_valid;
    
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
        .rst_n(ARESETn_i)
    );
    
    // Combinational logic
    // -- FIFO WRESP filter
    assign filter_info = AW_AxID_i;
    assign fifo_filter_wr_en = AW_shift_en_i & AW_crossing_flag_i;
    assign fifo_filter_rd_en = slv_handshake_occur & filter_condition;
    // -- Write response filter
    assign filter_AWID = filter_info_valid;
    assign filter_AWID_match = filter_AWID == s_BID_i;
    assign filter_condition = filter_AWID_match & ~fifo_filter_empty;
    assign filter_BVALID = s_BVALID_i & ~filter_condition;
    assign filter_BREADY_gen = dsp_BREADY_valid | filter_condition;
    // -- Handshake detector
    assign slv_handshake_occur = s_BVALID_i & s_BREADY_o;
    // -- Master mapping
    assign mst_id = s_BID_i[(TRANS_SLV_ID_W-1)-:MST_ID_W];
    // -- Slave Output
    assign s_BREADY_o = filter_BREADY_gen;
    // -- Dispatcher Output
    assign dsp_BREADY_valid = dsp_BREADY_i[mst_id];
    generate
        for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin
            assign dsp_BVALID_o[mst_idx] = (mst_id == mst_idx) & filter_BVALID;
            assign dsp_BID_o[TRANS_SLV_ID_W*(mst_idx+1)-1-:TRANS_SLV_ID_W] = s_BID_i;
            assign dsp_BRESP_o[TRANS_WR_RESP_W*(mst_idx+1)-1-:TRANS_WR_RESP_W] = s_BRESP_i;
        end
    endgenerate
    // -- Write Address channel Output
    assign AW_stall_o = fifo_filter_full;
    
endmodule