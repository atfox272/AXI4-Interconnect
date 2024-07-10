`timescale 1ns / 1ps
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
    parameter TRANS_DATA_SIZE_W = 3,     // Bus width of xSIZE
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
    input   [SLV_AMT-1:0]                   sa_RLAST_i,
    input   [SLV_AMT-1:0]                   sa_RVALID_i,
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Read address channel (master)
    output                                  m_ARREADY_o,
    // ---- Read data channel (master)
    output  [TRANS_MST_ID_W-1:0]            m_RID_o,
    output  [DATA_WIDTH-1:0]                m_RDATA_o,
    output                                  m_RLAST_o,
    output                                  m_RVALID_o,
    // -- To Slave Arbitration
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



endmodule
