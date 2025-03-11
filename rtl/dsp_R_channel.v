module dsp_R_channel
#(
    // Dispatcher configuration
    parameter SLV_AMT           = 2,
    // Transaction configuration
    parameter DATA_WIDTH        = 32,
    parameter TRANS_MST_ID_W    = 5,    // Bus width of master transaction ID 
    parameter TRANS_WR_RESP_W   = 2,
    // Slave configuration
    parameter SLV_ID_W          = $clog2(SLV_AMT),
    // Dispatcher DATA depth configuration
    parameter DSP_RDATA_DEPTH   = 16
)
(
    // Input declaration
    // -- Global signals
    input                                   ACLK_i,
    input                                   ARESETn_i,
    // -- To Master (slave interface of the interconnect)
    // ---- Read data channel
    input                                   m_RREADY_i,
    // -- To Slave Arbitration
    // ---- Read data channel (master)
    input   [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_RID_i,
    input   [DATA_WIDTH*SLV_AMT-1:0]        sa_RDATA_i,
    input   [TRANS_WR_RESP_W*SLV_AMT-1:0]   sa_RRESP_i,
    input   [SLV_AMT-1:0]                   sa_RLAST_i,
    input   [SLV_AMT-1:0]                   sa_RVALID_i,
    // -- To AR channel Dispatcher
    input   [SLV_ID_W-1:0]                  dsp_AR_slv_id_i,
    input                                   dsp_AR_disable_i,
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Read data channel (master)
    output  [TRANS_MST_ID_W-1:0]            m_RID_o,
    output  [DATA_WIDTH-1:0]                m_RDATA_o,
    output  [TRANS_WR_RESP_W-1:0]           m_RRESP_o,
    output                                  m_RLAST_o,
    output                                  m_RVALID_o,
    // -- To Slave Arbitration
    // ---- Read data channel
    output  [SLV_AMT-1:0]                   sa_RREADY_o,
    // -- To DSP AR chanenl
    output                                  dsp_RVALID_q1_o,
    output                                  dsp_RREADY_q1_o
);
    // Local parameter 
    localparam DATA_INFO_W = TRANS_MST_ID_W + DATA_WIDTH + TRANS_WR_RESP_W + 1;   // RID_W + DATA_W + RRESP + RLAST_W

    // Internal variable declaration
    genvar slv_idx;
    
    // Internal signal declaration
    // -- RDATA FIFO
    wire    [DATA_INFO_W-1:0]   data_info           [SLV_AMT-1:0];
    wire    [DATA_INFO_W-1:0]   data_info_valid     [SLV_AMT-1:0];
    wire                        fifo_rdata_wr_en    [SLV_AMT-1:0];
    wire                        fifo_rdata_rd_en    [SLV_AMT-1:0];
    wire                        fifo_rdata_empty    [SLV_AMT-1:0];
    wire                        fifo_rdata_full     [SLV_AMT-1:0];
    // -- Handshake detector
    wire                        sa_handshake_occur  [SLV_AMT-1:0];
    wire                        m_handshake_occur;
    // -- Misc
    wire   [TRANS_MST_ID_W-1:0] sa_RID_valid        [SLV_AMT-1:0];
    wire   [DATA_WIDTH-1:0]     sa_RDATA_valid      [SLV_AMT-1:0];
    wire   [TRANS_WR_RESP_W-1:0]sa_RRESP_valid      [SLV_AMT-1:0];
    wire                        sa_RLAST_valid      [SLV_AMT-1:0];
    // -- Master skid buffer 
    wire    [DATA_INFO_W-1:0]       msb_bwd_data;
    wire                            msb_bwd_valid;
    wire                            msb_bwd_ready;
    wire    [DATA_INFO_W-1:0]       msb_fwd_data;
    wire                            msb_fwd_valid;
    wire                            msb_fwd_ready;
    wire    [TRANS_MST_ID_W-1:0]    msb_fwd_RID;
    wire    [DATA_WIDTH-1:0]        msb_fwd_RDATA;
    wire    [TRANS_WR_RESP_W-1:0]   msb_fwd_RRESP;
    wire                            msb_fwd_RLAST;
    
    // Module
    // -- RDATA FIFO
    generate
    for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_FIFO
        fifo 
            #(
            .DATA_WIDTH(DATA_INFO_W),
            .FIFO_DEPTH(DSP_RDATA_DEPTH)
        ) fifo_rdata (
            .clk(ACLK_i),
            .data_i(data_info[slv_idx]),
            .data_o(data_info_valid[slv_idx]),
            .rd_valid_i(fifo_rdata_rd_en[slv_idx]),
            .wr_valid_i(fifo_rdata_wr_en[slv_idx]),
            .empty_o(fifo_rdata_empty[slv_idx]),
            .full_o(fifo_rdata_full[slv_idx]),
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
        .DATA_WIDTH(DATA_INFO_W)
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
    // -- RDATA FIFO
    generate
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_LOGIC
            assign data_info[slv_idx] = {sa_RID_i[TRANS_MST_ID_W*(slv_idx+1)-1-:TRANS_MST_ID_W], sa_RDATA_i[DATA_WIDTH*(slv_idx+1)-1-:DATA_WIDTH], sa_RRESP_i[TRANS_WR_RESP_W*(slv_idx+1)-1-:TRANS_WR_RESP_W], sa_RLAST_i[slv_idx]};
            assign {sa_RID_valid[slv_idx], sa_RDATA_valid[slv_idx], sa_RRESP_valid[slv_idx], sa_RLAST_valid[slv_idx]} = data_info_valid[slv_idx];
            assign fifo_rdata_wr_en[slv_idx] = sa_handshake_occur[slv_idx];
            assign fifo_rdata_rd_en[slv_idx] = m_handshake_occur & (dsp_AR_slv_id_i == slv_idx);
        end
    endgenerate
    // -- Handshake detector
    generate
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_HSK
            assign sa_handshake_occur[slv_idx] = sa_RVALID_i[slv_idx] & sa_RREADY_o[slv_idx];
        end
    endgenerate
    assign m_handshake_occur = msb_bwd_valid & msb_bwd_ready;
    // -- Output
    // -- -- Output to Master
    assign m_RID_o = msb_fwd_RID;
    assign m_RDATA_o = msb_fwd_RDATA;
    assign m_RRESP_o = msb_fwd_RRESP;
    assign m_RLAST_o = msb_fwd_RLAST;
    assign m_RVALID_o = msb_fwd_valid;
    // -- -- Output to Slave arbitration
    generate
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_OUT
            assign sa_RREADY_o[slv_idx]= ~fifo_rdata_full[slv_idx];
        end
    endgenerate
    // -- -- Output to DSP AR
    assign dsp_RVALID_q1_o  = msb_bwd_valid;
    assign dsp_RREADY_q1_o  = msb_bwd_ready;
    // -- Master skid buffer 
    assign msb_bwd_data     = {sa_RID_valid[dsp_AR_slv_id_i], sa_RDATA_valid[dsp_AR_slv_id_i], sa_RRESP_valid[dsp_AR_slv_id_i], sa_RLAST_valid[dsp_AR_slv_id_i]};
    assign msb_bwd_valid    = ~(fifo_rdata_empty[dsp_AR_slv_id_i] | dsp_AR_disable_i);
    assign msb_fwd_ready    = m_RREADY_i;
    assign {msb_fwd_RID, msb_fwd_RDATA, msb_fwd_RRESP, msb_fwd_RLAST} = msb_fwd_data;
endmodule
