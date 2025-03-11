module dsp_write_channel
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
    parameter SLV_ID_LSB_IDX    = 30
)
(
    // Input declaration
    // -- Global signals
    input                                   ACLK_i,
    input                                   ARESETn_i,
    // -- To Master (slave interface of the interconnect)
    // ---- Write address channel
    input   [TRANS_MST_ID_W-1:0]            m_AWID_i,
    input   [ADDR_WIDTH-1:0]                m_AWADDR_i,
    input   [TRANS_BURST_W-1:0]             m_AWBURST_i,
    input   [TRANS_DATA_LEN_W-1:0]          m_AWLEN_i,
    input   [TRANS_DATA_SIZE_W-1:0]         m_AWSIZE_i,
    input                                   m_AWVALID_i,
    // ---- Write data channel
    input   [DATA_WIDTH-1:0]                m_WDATA_i,
    input                                   m_WLAST_i,
    input                                   m_WVALID_i,
    // ---- Write response channel
    input                                   m_BREADY_i,
    // -- To Slave Arbitration
    // ---- Write address channel (master)
    input   [SLV_AMT-1:0]                   sa_AWREADY_i,
    // ---- Write data channel (master)
    input   [SLV_AMT-1:0]                   sa_WREADY_i,
    // ---- Write response channel (master)
    input   [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_BID_i,
    input   [TRANS_WR_RESP_W*SLV_AMT-1:0]   sa_BRESP_i,
    input   [SLV_AMT-1:0]                   sa_BVALID_i,
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Write address channel (master)
    output                                  m_AWREADY_o,
    // ---- Write data channel (master)
    output                                  m_WREADY_o,
    // ---- Write response channel (master)
    output  [TRANS_MST_ID_W-1:0]            m_BID_o,
    output  [TRANS_WR_RESP_W-1:0]           m_BRESP_o,
    output                                  m_BVALID_o,
    // -- To Slave Arbitration
    // ---- Write address channel
    output  [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_AWID_o,
    output  [ADDR_WIDTH*SLV_AMT-1:0]        sa_AWADDR_o,
    output  [TRANS_BURST_W*SLV_AMT-1:0]     sa_AWBURST_o,
    output  [TRANS_DATA_LEN_W*SLV_AMT-1:0]  sa_AWLEN_o,
    output  [TRANS_DATA_SIZE_W*SLV_AMT-1:0] sa_AWSIZE_o,
    output  [SLV_AMT-1:0]                   sa_AWVALID_o,
    output  [SLV_AMT-1:0]                   sa_AW_outst_full_o,  // The Dispatcher is full
    // ---- Write data channel
    output  [DATA_WIDTH*SLV_AMT-1:0]        sa_WDATA_o,
    output  [SLV_AMT-1:0]                   sa_WLAST_o,
    output  [SLV_AMT-1:0]                   sa_WVALID_o,
    // ---- Write response channel          
    output  [SLV_AMT-1:0]                   sa_BREADY_o
);
    // Localparam initialization
    localparam OUTST_CTN_W = $clog2(OUTSTANDING_AMT) + 1;
    // Internal variable declaration
    genvar slv_idx;
    
    // Internal signal declaration
    // -- AW channel to W channel 
    wire [SLV_ID_W-1:0]     AW_W_slv_id;
    wire                    AW_W_disable;
    // -- AW channel to B channel
    wire [SLV_ID_W-1:0]     AW_B_slv_id;
    wire                    AW_B_shift_en;
    // -- To AW channel Slave arbitration
    wire [OUTST_CTN_W-1:0]  AW_outst_ctn;
    wire [OUTST_CTN_W-1:0]  B_outst_ctn;
    // -- Interconnect
    wire                    W_AW_WVALID;
    wire                    W_AW_WREADY;
        
    // Combinational logic
    generate
    for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_LOGIC
        assign sa_AW_outst_full_o[slv_idx] = (AW_outst_ctn + B_outst_ctn) == OUTSTANDING_AMT;
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
    ) AW_channel (
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),
        .m_AxID_i(m_AWID_i),
        .m_AxADDR_i(m_AWADDR_i),
        .m_AxBURST_i(m_AWBURST_i),
        .m_AxLEN_i(m_AWLEN_i),
        .m_AxSIZE_i(m_AWSIZE_i),
        .m_AxVALID_i(m_AWVALID_i),
        .m_xVALID_i(W_AW_WVALID),
        .m_xREADY_i(W_AW_WREADY),
        .sa_AxREADY_i(sa_AWREADY_i),
        .m_AxREADY_o(m_AWREADY_o),
        .sa_AxID_o(sa_AWID_o),
        .sa_AxADDR_o(sa_AWADDR_o),
        .sa_AxBURST_o(sa_AWBURST_o),
        .sa_AxLEN_o(sa_AWLEN_o),
        .sa_AxSIZE_o(sa_AWSIZE_o),
        .sa_AxVALID_o(sa_AWVALID_o),
        .sa_Ax_outst_ctn_o(AW_outst_ctn),
        .dsp_xDATA_slv_id_o(AW_W_slv_id),
        .dsp_xDATA_disable_o(AW_W_disable),
        .dsp_WRESP_slv_id_o(AW_B_slv_id),
        .dsp_WRESP_shift_en_o(AW_B_shift_en)
    );
    
    dsp_W_channel #(
        .SLV_AMT(SLV_AMT),
        .DATA_WIDTH(DATA_WIDTH),
        .SLV_ID_W(SLV_ID_W),
        .SLV_ID_MSB_IDX(SLV_ID_MSB_IDX),
        .SLV_ID_LSB_IDX(SLV_ID_LSB_IDX)
    ) W_channel (
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),
        .m_WDATA_i(m_WDATA_i),
        .m_WLAST_i(m_WLAST_i),
        .m_WVALID_i(m_WVALID_i),
        .sa_WREADY_i(sa_WREADY_i),
        .dsp_AW_slv_id_i(AW_W_slv_id),
        .dsp_AW_disable_i(AW_W_disable),
        .m_WREADY_o(m_WREADY_o),
        .sa_WDATA_o(sa_WDATA_o),
        .sa_WLAST_o(sa_WLAST_o),
        .sa_WVALID_o(sa_WVALID_o),
        .dsp_AW_WVALID_o(W_AW_WVALID),
        .dsp_AW_WREADY_o(W_AW_WREADY)
    );
    
    dsp_B_channel #(
        .SLV_AMT(SLV_AMT),
        .OUTSTANDING_AMT(OUTSTANDING_AMT),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TRANS_MST_ID_W(TRANS_MST_ID_W),
        .TRANS_BURST_W(TRANS_BURST_W),
        .TRANS_DATA_LEN_W(TRANS_DATA_LEN_W),
        .TRANS_DATA_SIZE_W(TRANS_DATA_SIZE_W),
        .TRANS_WR_RESP_W(TRANS_WR_RESP_W),
        .SLV_ID_W(SLV_ID_W),
        .SLV_ID_MSB_IDX(SLV_ID_MSB_IDX),
        .SLV_ID_LSB_IDX(SLV_ID_LSB_IDX)
    ) B_channel (
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),
        .m_BREADY_i(m_BREADY_i),
        .sa_BID_i(sa_BID_i),
        .sa_BRESP_i(sa_BRESP_i),
        .sa_BVALID_i(sa_BVALID_i),
        .dsp_AW_slv_id_i(AW_B_slv_id),
        .dsp_AW_shift_en_i(AW_B_shift_en),
        .m_BID_o(m_BID_o),
        .m_BRESP_o(m_BRESP_o),
        .m_BVALID_o(m_BVALID_o),
        .sa_B_outst_ctn_o(B_outst_ctn),
        .sa_BREADY_o(sa_BREADY_o)
    );

endmodule
