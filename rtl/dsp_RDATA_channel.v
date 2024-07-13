module dsp_RDATA_channel
#(
    // Dispatcher configuration
    parameter SLV_AMT           = 2,
    // Transaction configuration
    parameter DATA_WIDTH        = 32,
    parameter TRANS_MST_ID_W    = 5,    // Bus width of master transaction ID 
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
    output                                  m_RLAST_o,
    output                                  m_RVALID_o,
    // -- To Slave Arbitration
    // ---- Read data channel
    output  [SLV_AMT-1:0]                   sa_RREADY_o
);
    // Local parameter 
    localparam DATA_INFO_W = TRANS_MST_ID_W + DATA_WIDTH + 1;   // RID_W + DATA_W + RLAST_W

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
    wire                        sa_RLAST_valid      [SLV_AMT-1:0];
    
    // Module
    // -- RDATA FIFO
    generate
    for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin
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
            .rst_n(ARESETn_i)
        );
    end
    endgenerate
    // Combinational logic
    // -- RDATA FIFO
    generate
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin
            assign data_info[slv_idx] = {sa_RID_i[TRANS_MST_ID_W*(slv_idx+1)-1-:TRANS_MST_ID_W], sa_RDATA_i[DATA_WIDTH*(slv_idx+1)-1-:DATA_WIDTH], sa_RLAST_i[slv_idx]};
            assign {sa_RID_valid[slv_idx], sa_RDATA_valid[slv_idx], sa_RLAST_valid[slv_idx]} = data_info_valid[slv_idx];
            assign fifo_rdata_wr_en[slv_idx] = sa_handshake_occur[slv_idx];
            assign fifo_rdata_rd_en[slv_idx] = m_handshake_occur & (dsp_AR_slv_id_i == slv_idx);
        end
    endgenerate
    // -- Handshake detector
    generate
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin
            assign sa_handshake_occur[slv_idx] = sa_RVALID_i[slv_idx] & sa_RREADY_o[slv_idx];
        end
    endgenerate
    assign m_handshake_occur = m_RVALID_o & m_RREADY_i;
    // -- Output
    // -- -- Output to Master
    assign m_RID_o = sa_RID_valid[dsp_AR_slv_id_i];
    assign m_RDATA_o = sa_RDATA_valid[dsp_AR_slv_id_i];
    assign m_RLAST_o = sa_RLAST_valid[dsp_AR_slv_id_i];
    assign m_RVALID_o = ~(fifo_rdata_empty[dsp_AR_slv_id_i] | dsp_AR_disable_i);
    // -- -- Output to Slave arbitration
    generate
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin
            assign sa_RREADY_o[slv_idx]= ~fifo_rdata_full[slv_idx];
        end
    endgenerate

endmodule
