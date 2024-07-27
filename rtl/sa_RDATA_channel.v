module sa_RDATA_channel 
#(
    // Interconnect configuration
    parameter                       MST_AMT             = 3,
    parameter                       OUTSTANDING_AMT     = 8,
    parameter                       MST_ID_W            = $clog2(MST_AMT),
    // Transaction configuration
    parameter                       DATA_WIDTH          = 32,
    parameter                       ADDR_WIDTH          = 32,
    parameter                       TRANS_MST_ID_W      = 5,                            // Bus width of master transaction ID 
    parameter                       TRANS_SLV_ID_W      = TRANS_MST_ID_W + MST_ID_W,    // Bus width of slave transaction ID
    parameter                       TRANS_WR_RESP_W     = 2
)
(
    // Input declaration
    // -- Global signals
    input                                   ACLK_i,
    input                                   ARESETn_i,
    // -- To Dispatcher
    // ---- Read data channel
    input   [MST_AMT-1:0]                   dsp_RREADY_i,
    // -- To slave (master interface of the interconnect)
    // ---- Read data channel 
    input   [TRANS_SLV_ID_W-1:0]            s_RID_i,
    input   [DATA_WIDTH-1:0]                s_RDATA_i,
    input   [TRANS_WR_RESP_W-1:0]           s_RRESP_i,
    input                                   s_RLAST_i,
    input                                   s_RVALID_i,
    // -- To Read Address channel
    input   [TRANS_SLV_ID_W-1:0]            AR_AxID_i,
    input                                   AR_crossing_flag_i,
    input                                   AR_shift_en_i,
    
    // Output declaration
    // -- To Dispatcher
    // ---- Read data channel (master)
    output  [TRANS_MST_ID_W*MST_AMT-1:0]    dsp_RID_o,
    output  [DATA_WIDTH*MST_AMT-1:0]        dsp_RDATA_o,
    output  [TRANS_WR_RESP_W*MST_AMT-1:0]   dsp_RRESP_o,
    output  [MST_AMT-1:0]                   dsp_RLAST_o,
    output  [MST_AMT-1:0]                   dsp_RVALID_o,
    // -- To slave (master interface of the interconnect)
    // ---- Read data channel
    output                                  s_RREADY_o,
    // To Write Address channel
    output                                  AR_stall_o
);

    // Local parameters initialization
    localparam FILTER_INFO_W = TRANS_SLV_ID_W + 1; // crossing flag + transaction ID
    
    // Internal variable declaration 
    genvar mst_idx;
    // Internal signal declaration
    // -- wire declaration
    // ---- FIFO RLAST filter
    wire    [FILTER_INFO_W-1:0]     filter_info;
    wire    [FILTER_INFO_W-1:0]     filter_info_valid;
    wire                            fifo_filter_wr_en;
    wire                            fifo_filter_rd_en;
    wire                            fifo_filter_full;
    wire                            fifo_filter_empty;
    // ---- Write response filter
    wire    [TRANS_SLV_ID_W-1:0]    ARID_valid;
    wire    [TRANS_SLV_ID_W-1:0]    crossing_flag_valid;
    wire                            filter_ARID_match;
    wire                            filter_condition;
    wire                            filter_RLAST;
    // -- Handshake detector
    wire                            slv_handshake_occur;
    // -- Master mapping
    wire    [MST_ID_W-1:0]          mst_id;
    wire                            dsp_RREADY_valid;
    
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
    
    // Combinational logic
    // -- FIFO WRESP filter
    assign filter_info = {AR_crossing_flag_i, AR_AxID_i};
    assign fifo_filter_wr_en = AR_shift_en_i;
    assign fifo_filter_rd_en = slv_handshake_occur & s_RLAST_i;
    // -- Write response filter
    assign {crossing_flag_valid, ARID_valid} = filter_info_valid;
    assign filter_ARID_match = ARID_valid == s_RID_i;
    assign filter_condition = filter_ARID_match & (~fifo_filter_empty) & crossing_flag_valid;
    assign filter_RLAST = s_RLAST_i & ~filter_condition;
    // -- Handshake detector
    assign slv_handshake_occur = s_RVALID_i & s_RREADY_o;
    // -- Master mapping
    assign mst_id = s_RID_i[(TRANS_SLV_ID_W-1)-:MST_ID_W];
    // -- Slave Output
    assign s_RREADY_o = dsp_RREADY_i[mst_id];
    // -- Dispatcher Output
    generate
        for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin
            assign dsp_RVALID_o[mst_idx] = (mst_id == mst_idx) & s_RVALID_i;
            assign dsp_RID_o[TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W] = s_RID_i[TRANS_MST_ID_W-1:0];
            assign dsp_RDATA_o[DATA_WIDTH*(mst_idx+1)-1-:DATA_WIDTH] = s_RDATA_i;
            assign dsp_RRESP_o[TRANS_WR_RESP_W*(mst_idx+1)-1-:TRANS_WR_RESP_W] = s_RRESP_i;
            assign dsp_RLAST_o[mst_idx] = filter_RLAST;
        end
    endgenerate
    // -- Write Address channel Output
    assign AR_stall_o = fifo_filter_full;

endmodule