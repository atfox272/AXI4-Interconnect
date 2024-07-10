module ai_dispatcher
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
    // ---- Write address channel (master)
    input   [SLV_AMT-1:0]                   sa_AWREADY_i,
    // ---- Write data channel (master)
    input   [SLV_AMT-1:0]                   sa_WREADY_i,
    // ---- Write response channel (master)
    input   [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_BID_i,
    input   [TRANS_WR_RESP_W*SLV_AMT-1:0]   sa_BRESP_i,
    input   [SLV_AMT-1:0]                   sa_BVALID_i,
    // ---- Read address channel (master)
    input   [SLV_AMT-1:0]                   sa_ARREADY_i,
    // ---- Read data channel (master)
    input   [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_RID_i,
    input   [DATA_WIDTH*SLV_AMT-1:0]        sa_RDATA_i,
    input   [SLV_AMT-1:0]                   sa_RLAST_i,
    input   [SLV_AMT-1:0]                   sa_RVALID_i,
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
    // ---- Read address channel (master)
    output                                  m_ARREADY_o,
    // ---- Read data channel (master)
    output  [TRANS_MST_ID_W-1:0]            m_RID_o,
    output  [DATA_WIDTH-1:0]                m_RDATA_o,
    output                                  m_RLAST_o,
    output                                  m_RVALID_o,
    // -- To Slave Arbitration
    // ---- Write address channel
    output  [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_AWID_o,
    output  [ADDR_WIDTH*SLV_AMT-1:0]        sa_AWADDR_o,
    output  [TRANS_BURST_W-1:0]             sa_AWBURST_o,
    output  [TRANS_DATA_LEN_W*SLV_AMT-1:0]  sa_AWLEN_o,
    output  [TRANS_DATA_SIZE_W*SLV_AMT-1:0] sa_AWSIZE_o,
    output  [SLV_AMT-1:0]                   sa_AWVALID_o,
    output  [SLV_AMT-1:0]                   sa_AW_outst_full_o,  // The Dispatcher is full
    // ---- Write data channel
    output  [DATA_WIDTH*SLV_AMT-1:0]        sa_WDATA_o,
    output  [SLV_AMT-1:0]                   sa_WLAST_o,
    output  [SLV_AMT-1:0]                   sa_WVALID_o,
    output  [SLV_AMT-1:0]                   sa_WDATA_sel_o,   // Slave Arbitration selection
    // ---- Write response channel          
    output  [SLV_AMT-1:0]                   sa_BREADY_o,
    // ---- Read address channel            
    output  [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_ARID_o,
    output  [ADDR_WIDTH*SLV_AMT-1:0]        sa_ARADDR_o,
    output  [TRANS_BURST_W-1:0]             sa_ARBURST_o,
    output  [TRANS_DATA_LEN_W*SLV_AMT-1:0]  sa_ARLEN_o,
    output  [TRANS_DATA_SIZE_W*SLV_AMT-1:0] sa_ARSIZE_o,
    output  [SLV_AMT-1:0]                   sa_ARVALID_o,
    output  [SLV_AMT-1:0]                   sa_AR_outst_full_o,  // The Dispatcher is full
    // ---- Read data channel
    output                                  sa_RREADY_o
);
    dsp_read_channel #(
    
    ) read_channel (
    
    );
    
    dsp_write_channel #(
    
    ) write_channel (
    
    );
endmodule
