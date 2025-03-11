module dsp_read_channel
#(
    // Dispatcher configuration
    parameter SLV_AMT           = 2,
    parameter OUTSTANDING_AMT   = 8,
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
    parameter SLV_ID_LSB_IDX    = 30,
    // Dispatcher DATA depth configuration
    parameter DSP_RDATA_DEPTH   = 16
)
(
    // Input declaration
    // -- Global signals
    input                                   ACLK_i,
    input                                   ARESETn_i,
    // -- To Master (slave interface of the interconnect)
    // ---- Read address channel
    input   [TRANS_MST_ID_W-1:0]            m_ARID_i,
    input   [ADDR_WIDTH-1:0]                m_ARADDR_i,
    input   [TRANS_BURST_W-1:0]             m_ARBURST_i,
    input   [TRANS_DATA_LEN_W-1:0]          m_ARLEN_i,
    input   [TRANS_DATA_SIZE_W-1:0]         m_ARSIZE_i,
    input                                   m_ARVALID_i,
    // ---- Read data channel
    input                                   m_RREADY_i,
    // -- To Slave Arbitration
    // ---- Read address channel (master)
    input   [SLV_AMT-1:0]                   sa_ARREADY_i,
    // ---- Read data channel (master)
    input   [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_RID_i,
    input   [DATA_WIDTH*SLV_AMT-1:0]        sa_RDATA_i,
    input   [TRANS_WR_RESP_W*SLV_AMT-1:0]   sa_RRESP_i,
    input   [SLV_AMT-1:0]                   sa_RLAST_i,
    input   [SLV_AMT-1:0]                   sa_RVALID_i,
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Read address channel (master)
    output                                  m_ARREADY_o,
    // ---- Read data channel (master)
    output  [TRANS_MST_ID_W-1:0]            m_RID_o,
    output  [DATA_WIDTH-1:0]                m_RDATA_o,
    output  [TRANS_WR_RESP_W-1:0]           m_RRESP_o,
    output                                  m_RLAST_o,
    output                                  m_RVALID_o,
    // -- To Slave Arbitration
    // ---- Read address channel            
    output  [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_ARID_o,
    output  [ADDR_WIDTH*SLV_AMT-1:0]        sa_ARADDR_o,
    output  [TRANS_BURST_W*SLV_AMT-1:0]     sa_ARBURST_o,
    output  [TRANS_DATA_LEN_W*SLV_AMT-1:0]  sa_ARLEN_o,
    output  [TRANS_DATA_SIZE_W*SLV_AMT-1:0] sa_ARSIZE_o,
    output  [SLV_AMT-1:0]                   sa_ARVALID_o,
    output  [SLV_AMT-1:0]                   sa_AR_outst_full_o,  // The Dispatcher is full
    // ---- Read data channel
    output  [SLV_AMT-1:0]                   sa_RREADY_o
);
    // Localparam initialization
    localparam OUTST_CTN_W = $clog2(OUTSTANDING_AMT) + 1;
    
    // Internal variable
    genvar slv_idx;
    
    // Internal signal declaration
    // -- AW channel to W channel 
    wire [SLV_ID_W-1:0]     AR_R_slv_id;
    wire                    AR_R_disable;
    // -- W channel to AW channel
    wire                    R_AR_RVALID_q1;
    wire                    R_AR_RREADY_q1;
    // -- AW channel Slave arbitration
    wire [OUTST_CTN_W-1:0]  Ax_outst_ctn;
    
    // Combinational logic
    generate
    for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_LOGIC
        assign sa_AR_outst_full_o[slv_idx] = Ax_outst_ctn == OUTSTANDING_AMT;
    end
    endgenerate
    // Module
    dsp_Ax_channel #(
        .SLV_AMT(SLV_AMT),
        .OUTSTANDING_AMT(OUTSTANDING_AMT),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TRANS_MST_ID_W(TRANS_MST_ID_W),
        .TRANS_BURST_W(TRANS_BURST_W),
        .TRANS_DATA_LEN_W(TRANS_DATA_LEN_W),
        .TRANS_DATA_SIZE_W(TRANS_DATA_SIZE_W),
        .SLV_ID_W(SLV_ID_W),
        .SLV_ID_MSB_IDX(SLV_ID_MSB_IDX),
        .SLV_ID_LSB_IDX(SLV_ID_LSB_IDX)
    ) AR_channel (
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),
        .m_AxID_i(m_ARID_i),
        .m_AxADDR_i(m_ARADDR_i),
        .m_AxBURST_i(m_ARBURST_i),
        .m_AxLEN_i(m_ARLEN_i),
        .m_AxSIZE_i(m_ARSIZE_i),
        .m_AxVALID_i(m_ARVALID_i),
        .m_xVALID_i(R_AR_RVALID_q1),
        .m_xREADY_i(R_AR_RREADY_q1),
        .sa_AxREADY_i(sa_ARREADY_i),
        .m_AxREADY_o(m_ARREADY_o),
        .sa_AxID_o(sa_ARID_o),
        .sa_AxADDR_o(sa_ARADDR_o),
        .sa_AxBURST_o(sa_ARBURST_o),
        .sa_AxLEN_o(sa_ARLEN_o),
        .sa_AxSIZE_o(sa_ARSIZE_o),
        .sa_AxVALID_o(sa_ARVALID_o),
        .sa_Ax_outst_ctn_o(Ax_outst_ctn),
        .dsp_xDATA_slv_id_o(AR_R_slv_id),
        .dsp_xDATA_disable_o(AR_R_disable),
        .dsp_WRESP_slv_id_o(),  // N/C
        .dsp_WRESP_shift_en_o() // N/C
    );

    dsp_R_channel #(
        .SLV_AMT(SLV_AMT),
        .DATA_WIDTH(DATA_WIDTH),
        .TRANS_MST_ID_W(TRANS_MST_ID_W),
        .TRANS_WR_RESP_W(TRANS_WR_RESP_W),
        .SLV_ID_W(SLV_ID_W),
        .DSP_RDATA_DEPTH(DSP_RDATA_DEPTH)
    ) R_channel (
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),
        .m_RREADY_i(m_RREADY_i),
        .sa_RID_i(sa_RID_i),
        .sa_RDATA_i(sa_RDATA_i),
        .sa_RRESP_i(sa_RRESP_i),
        .sa_RLAST_i(sa_RLAST_i),
        .sa_RVALID_i(sa_RVALID_i),
        .dsp_AR_slv_id_i(AR_R_slv_id),
        .dsp_AR_disable_i(AR_R_disable),
        .m_RID_o(m_RID_o),
        .m_RDATA_o(m_RDATA_o),
        .m_RRESP_o(m_RRESP_o),
        .m_RLAST_o(m_RLAST_o),
        .m_RVALID_o(m_RVALID_o),
        .sa_RREADY_o(sa_RREADY_o),
        .dsp_RVALID_q1_o(R_AR_RVALID_q1),
        .dsp_RREADY_q1_o(R_AR_RREADY_q1)
    );

endmodule
