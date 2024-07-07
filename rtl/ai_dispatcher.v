module ai_dispatcher
#(
    // Dispatcher configuration
    parameter SLV_AMT           = 2,
    // Transaction configuration
    parameter DATA_WIDTH        = 32,
    parameter ADDR_WIDTH        = 32,
    parameter TRANS_MST_ID_W    = 5,    // Bus width of master transaction ID 
    parameter TRANS_DATA_LEN_W  = 3,    // Bus width of xLEN
    parameter TRANS_DATA_SIZE_W = 3,    // Bus width of xSIZE
    parameter TRANS_WR_RESP_W   = 2
)
(
    // Input declaration
    // -- Global signals
    input                                   ACLK_i,
    input                                   ARESETn_i,
    // -- To Master (slave interface of the interconnect)
    // ---- Write address channel
    input   [0:TRANS_MST_ID_W-1]            m_AWID_i,
    input   [0:ADDR_WIDTH-1]                m_AWADDR_i,
    input   [0:TRANS_DATA_LEN_W-1]          m_AWLEN_i,
    input   [0:TRANS_DATA_SIZE_W-1]         m_AWSIZE_i,
    input                                   m_AWVALID_i,
    // ---- Write data channel
    input   [0:DATA_WIDTH-1]                m_WDATA_i,
    input                                   m_WLAST_i,
    input                                   m_WVALID_i,
    // ---- Write response channel
    input                                   m_BREADY_i,
    // ---- Read address channel
    input   [0:TRANS_MST_ID_W-1]            m_ARID_i,
    input   [0:ADDR_WIDTH-1]                m_ARADDR_i,
    input   [0:TRANS_DATA_LEN_W-1]          m_ARLEN_i,
    input   [0:TRANS_DATA_SIZE_W-1]         m_ARSIZE_i,
    input                                   m_ARVALID_i,
    // ---- Read data channel
    input                                   m_RREADY_i,
    // -- To Slave Arbitration
    // ---- Write address channel (master)
    input   [0:SLV_AMT-1]                   sa_AWREADY_i,
    // ---- Write data channel (master)
    input   [0:SLV_AMT-1]                   sa_WREADY_i,
    // ---- Write response channel (master)
    input   [0:TRANS_MST_ID_W*SLV_AMT-1]    sa_BID_i,
    input   [0:TRANS_WR_RESP_W*SLV_AMT-1]   sa_BRESP_i,
    input   [0:SLV_AMT-1]                   sa_BVALID_i,
    // ---- Read address channel (master)
    input   [0:SLV_AMT-1]                   sa_ARREADY_i,
    // ---- Read data channel (master)
    input   [0:TRANS_MST_ID_W*SLV_AMT-1]    sa_RID_i,
    input   [0:DATA_WIDTH*SLV_AMT-1]        sa_RDATA_i,
    input   [0:SLV_AMT-1]                   sa_RLAST_i,
    input   [0:SLV_AMT-1]                   sa_RVALID_i,
    // ---- Control module signal
    output  [0:SLV_AMT-1]                   sa_dsp_full_o,  // The Dispatcher is full
    output  [0:SLV_AMT-1]                   sa_slv_sel_o,   // Slave Arbitration selection
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Write address channel (master)
    output                                  m_AWREADY_o,
    // ---- Write data channel (master)
    output                                  m_WREADY_o,
    // ---- Write response channel (master)
    output  [0:TRANS_MST_ID_W-1]            m_BID_o,
    output  [0:TRANS_WR_RESP_W-1]           m_BRESP_o,
    output                                  m_BVALID_o,
    // ---- Read address channel (master)
    output                                  m_ARREADY_o,
    // ---- Read data channel (master)
    output  [0:TRANS_MST_ID_W-1]            m_RID_o,
    output  [0:DATA_WIDTH-1]                m_RDATA_o,
    output                                  m_RLAST_o,
    output                                  m_RVALID_o,
    // -- To Slave Arbitration
    // ---- Write address channel
    output  [0:TRANS_MST_ID_W*SLV_AMT-1]    sa_AWID_o,
    output  [0:ADDR_WIDTH*SLV_AMT-1]        sa_AWADDR_o,
    output  [0:TRANS_DATA_LEN_W*SLV_AMT-1]  sa_AWLEN_o,
    output  [0:TRANS_DATA_SIZE_W*SLV_AMT-1] sa_AWSIZE_o,
    output                                  sa_AWVALID_o,
    // ---- Write data channel
    output  [0:DATA_WIDTH*SLV_AMT-1]        sa_WDATA_o,
    output  [0:SLV_AMT-1]                   sa_WLAST_o,
    output  [0:SLV_AMT-1]                   sa_WVALID_o,
    // ---- Write response channel          
    output  [0:SLV_AMT-1]                   sa_BREADY_o,
    // ---- Read address channel            
    output  [0:TRANS_MST_ID_W*SLV_AMT-1]    sa_ARID_o,
    output  [0:ADDR_WIDTH*SLV_AMT-1]        sa_ARADDR_o,
    output  [0:TRANS_DATA_LEN_W*SLV_AMT-1]  sa_ARLEN_o,
    output  [0:TRANS_DATA_SIZE_W*SLV_AMT-1] sa_ARSIZE_o,
    output  [0:SLV_AMT-1]                   sa_ARVALID_o,
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
