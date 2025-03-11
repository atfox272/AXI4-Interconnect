module dsp_B_channel
#(
    // Dispatcher configuration
    parameter SLV_AMT           = 2,
    parameter OUTSTANDING_AMT   = 8,
    parameter OUTST_CTN_W       = $clog2(OUTSTANDING_AMT) + 1,
    // Transaction configuration
    parameter DATA_WIDTH        = 32,
    parameter ADDR_WIDTH        = 32,
    parameter TRANS_MST_ID_W    = 5,    // Bus width of master transaction ID 
    parameter TRANS_BURST_W     = 2,    // Width of xBURST 
    parameter TRANS_DATA_LEN_W  = 3,    // Bus width of xLEN
    parameter TRANS_DATA_SIZE_W = 3,    // Bus width of xSIZE
    parameter TRANS_WR_RESP_W   = 2,
    // Slave configuration
    parameter SLV_ID_W          = $clog2(SLV_AMT),
    parameter SLV_ID_MSB_IDX    = 30,
    parameter SLV_ID_LSB_IDX    = 30
)
(
    // Input declaration
    // -- Global signals
    input                                   ACLK_i,
    input                                   ARESETn_i,
    // -- To Master (slave interface of the interconnect)
    // -- -- Write response channel
    input                                   m_BREADY_i,
    // -- To Slave Arbitration
    // -- -- Write response channel
    input   [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_BID_i,
    input   [TRANS_WR_RESP_W*SLV_AMT-1:0]   sa_BRESP_i,
    input   [SLV_AMT-1:0]                   sa_BVALID_i,
    // -- To AW channel Dispatcher
    input   [SLV_ID_W-1:0]                  dsp_AW_slv_id_i,
    input                                   dsp_AW_shift_en_i,
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // -- -- Write response channel (master)
    output  [TRANS_MST_ID_W-1:0]            m_BID_o,
    output  [TRANS_WR_RESP_W-1:0]           m_BRESP_o,
    output                                  m_BVALID_o,
    // -- To Slave Arbitration
    // -- -- Write address channel
    output  [OUTST_CTN_W-1:0]               sa_B_outst_ctn_o,
    // -- -- Write response channel
    output  [SLV_AMT-1:0]                   sa_BREADY_o
);
    // Local parameter
    localparam SLV_INFO_W = SLV_ID_W;
    localparam RESP_INFO_W = TRANS_MST_ID_W + TRANS_WR_RESP_W;
    // Internal variable declaration
    genvar slv_idx;
    
    // Internal signal declaration
    // -- Slave order FIFO
    wire    [SLV_INFO_W-1:0]        slv_info;
    wire    [SLV_INFO_W-1:0]        slv_info_valid;
    wire                            fifo_slv_ord_wr_en;
    wire                            fifo_slv_ord_rd_en;
    wire                            fifo_slv_ord_empty;
    // -- Slave resp FIFO
    wire    [RESP_INFO_W-1:0]       resp_info           [SLV_AMT-1:0];
    wire    [RESP_INFO_W-1:0]       resp_info_valid     [SLV_AMT-1:0];
    wire                            fifo_wresp_wr_en    [SLV_AMT-1:0];
    wire                            fifo_wresp_rd_en    [SLV_AMT-1:0];
    wire                            fifo_wresp_empty    [SLV_AMT-1:0];
    wire                            fifo_wresp_full     [SLV_AMT-1:0];
    // -- Handshake detector
    wire                            sa_handshake_occur  [SLV_AMT-1:0];
    wire                            m_handshake_occur;
    // -- Misc
    wire    [TRANS_MST_ID_W-1:0]    sa_BID_valid        [SLV_AMT-1:0];
    wire    [TRANS_WR_RESP_W-1:0]   sa_BRESP_valid      [SLV_AMT-1:0];
    // -- Master skid buffer 
    wire    [RESP_INFO_W-1:0]       msb_bwd_data;
    wire                            msb_bwd_valid;
    wire                            msb_bwd_ready;
    wire    [RESP_INFO_W-1:0]       msb_fwd_data;
    wire                            msb_fwd_valid;
    wire                            msb_fwd_ready;
    wire    [TRANS_MST_ID_W-1:0]    msb_fwd_BID;
    wire    [TRANS_WR_RESP_W-1:0]   msb_fwd_BRESP;
    // Module
    // -- Slave order FIFO
    fifo #(
        .DATA_WIDTH(SLV_INFO_W),
        .FIFO_DEPTH(OUTSTANDING_AMT)
    ) fifo_slv_order (
        .clk(ACLK_i),
        .data_i(slv_info),
        .data_o(slv_info_valid),
        .rd_valid_i(fifo_slv_ord_rd_en),
        .wr_valid_i(fifo_slv_ord_wr_en),
        .empty_o(fifo_slv_ord_empty),
        .full_o(),
        .almost_empty_o(),
        .almost_full_o(),
        .counter(sa_B_outst_ctn_o),
        .rst_n(ARESETn_i) 
    );
    // -- Slave Response FIFO
    generate 
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_FIFO
            fifo #(
                .DATA_WIDTH(RESP_INFO_W),
                .FIFO_DEPTH(OUTSTANDING_AMT)
            ) fifo_WRESP_slv (
                .clk(ACLK_i),
                .data_i(resp_info[slv_idx]),
                .data_o(resp_info_valid[slv_idx]),
                .rd_valid_i(fifo_wresp_rd_en[slv_idx]),
                .wr_valid_i(fifo_wresp_wr_en[slv_idx]),
                .empty_o(fifo_wresp_empty[slv_idx]),
                .full_o(fifo_wresp_full[slv_idx]),
                .almost_empty_o(),
                .almost_full_o(),
                .counter(),
                .rst_n(ARESETn_i) 
            );
        end
    endgenerate
    // -- Master skid buffer
    skid_buffer #(
        .SBUF_TYPE(3),
        .DATA_WIDTH(RESP_INFO_W)
    ) mst_skid_buffer (
        .clk        (ACLK_i),
        .rst_n      (ARESETn_i),
        .bwd_data_i (msb_bwd_data),
        .bwd_valid_i(msb_bwd_valid),
        .fwd_ready_i(msb_fwd_ready),
        .fwd_data_o (msb_fwd_data),
        .bwd_ready_o(msb_bwd_ready),
        .fwd_valid_o(msb_fwd_valid)
    );
    
    // Combinational logic
    // -- Slave order FIFO
    assign slv_info = dsp_AW_slv_id_i;
    assign fifo_slv_ord_wr_en = dsp_AW_shift_en_i;
    assign fifo_slv_ord_rd_en = m_handshake_occur;
    // -- Slave resp FIFO
    generate
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_LOGIC
            assign resp_info[slv_idx] = {sa_BID_i[TRANS_MST_ID_W*(slv_idx+1)-1-:TRANS_MST_ID_W], sa_BRESP_i[TRANS_WR_RESP_W*(slv_idx+1)-1-:TRANS_WR_RESP_W]};
            assign {sa_BID_valid[slv_idx], sa_BRESP_valid[slv_idx]} = resp_info_valid[slv_idx];
            assign fifo_wresp_wr_en[slv_idx] = sa_handshake_occur[slv_idx];
            assign fifo_wresp_rd_en[slv_idx] = m_handshake_occur & (slv_info_valid == slv_idx);
        end
    endgenerate
    // -- Handshake detector
    assign m_handshake_occur = msb_bwd_valid & msb_bwd_ready;
    generate
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_HSK
            assign sa_handshake_occur[slv_idx] = sa_BVALID_i[slv_idx] & sa_BREADY_o[slv_idx];
        end
    endgenerate
    // -- Output to Master
    assign m_BID_o = msb_fwd_BID;
    assign m_BRESP_o = msb_fwd_BRESP;
    assign m_BVALID_o = msb_fwd_valid;
    // -- Output to Slave arbitration
    generate
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_OUT
            assign sa_BREADY_o[slv_idx] = ~fifo_wresp_full[slv_idx];
        end
    endgenerate
    // -- Master skid buffer
    assign msb_bwd_data     = {sa_BID_valid[slv_info_valid], sa_BRESP_valid[slv_info_valid]};
    assign msb_bwd_valid    = ~(fifo_slv_ord_empty | fifo_wresp_empty[slv_info_valid]);
    assign msb_fwd_ready    = m_BREADY_i;
    assign {msb_fwd_BID, msb_fwd_BRESP} = msb_fwd_data;
endmodule
