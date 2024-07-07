module ai_slave_arbitration
#(
    // Interconnect configuration
    parameter MST_AMT           = 3,
    parameter MST_ID_W          = $clog2(MST_AMT),
    // Transaction configuration
    parameter DATA_WIDTH        = 32,
    parameter ADDR_WIDTH        = 32,
    parameter TRANS_MST_ID_W    = 5,    // Bus width of master transaction ID 
    parameter TRANS_SLV_ID_W    = 7,    // Bus width of slave transaction ID
    parameter TRANS_BURST_W     = 2,                                // Width of xBURST 
    parameter TRANS_DATA_LEN_W  = 3,    // Bus width of xLEN
    parameter TRANS_DATA_SIZE_W = 3,    // Bus width of xSIZE
    parameter TRANS_WR_RESP_W   = 2
)
(
    // Input declaration
    // -- Global signals
    input                                   ACLK_i,
    input                                   ARESETn_i,
    // -- To Dispatcher
    // ---- Write address channel
    input   [0:TRANS_MST_ID_W*MST_AMT-1]    dsp_AWID_i,
    input   [0:ADDR_WIDTH*MST_AMT-1]        dsp_AWADDR_i,
    input   [TRANS_BURST_W*MST_AMT-1:0]     dsp_AxBURST_i,
    input   [0:TRANS_DATA_LEN_W*MST_AMT-1]  dsp_AWLEN_i,
    input   [0:TRANS_DATA_SIZE_W*MST_AMT-1] dsp_AWSIZE_i,
    input   [0:MST_AMT-1]                   dsp_AWVALID_i,
    // ---- Write data channel
    input   [0:DATA_WIDTH*MST_AMT-1]        dsp_WDATA_i,
    input   [0:MST_AMT-1]                   dsp_WLAST_i,
    input   [0:MST_AMT-1]                   dsp_WVALID_i,
    // ---- Write response channel
    input   [0:MST_AMT-1]                   dsp_BREADY_i,
    // ---- Read address channel
    input   [0:TRANS_MST_ID_W*MST_AMT-1]    dsp_ARID_i,
    input   [0:ADDR_WIDTH*MST_AMT-1]        dsp_ARADDR_i,
    input   [0:TRANS_DATA_LEN_W*MST_AMT-1]  dsp_ARLEN_i,
    input   [0:TRANS_DATA_SIZE_W*MST_AMT-1] dsp_ARSIZE_i,
    input   [0:MST_AMT-1]                   dsp_ARVALID_i,
    // ---- Read data channel
    input   [0:MST_AMT-1]                   dsp_RREADY_i,
    // -- To slave (master interface of the interconnect)
    // ---- Write address channel (master)
    input                                   s_AWREADY_i,
    // ---- Write data channel (master)
    input                                   s_WREADY_i,
    // ---- Write response channel (master)
    input  [0:TRANS_SLV_ID_W-1]             s_BID_i,
    input  [0:TRANS_WR_RESP_W-1]            s_BRESP_i,
    input                                   s_BVALID_i,
    // ---- Read address channel (master)
    input                                   s_ARREADY_i,
    // ---- Read data channel (master)
    input  [0:TRANS_SLV_ID_W-1]             s_RID_i,
    input  [0:DATA_WIDTH-1]                 s_RDATA_i,
    input                                   s_RLAST_i,
    input                                   s_RVALID_i,
    
    // Output declaration
    // -- To Dispatcher
    // ---- Write address channel (master)
    output  [0:MST_AMT-1]                   dsp_AWREADY_o,
    // ---- Write data channel (master)
    output  [0:MST_AMT-1]                   dsp_WREADY_o,
    // ---- Write response channel (master)
    output  [0:TRANS_MST_ID_W*MST_AMT-1]    dsp_BID_o,
    output  [0:TRANS_WR_RESP_W*MST_AMT-1]   dsp_BRESP_o,
    output  [0:MST_AMT-1]                   dsp_BVALID_o,
    // ---- Read address channel (master)
    output  [0:MST_AMT-1]                   dsp_ARREADY_o,
    // ---- Read data channel (master)
    output  [0:TRANS_MST_ID_W*MST_AMT-1]    dsp_RID_o,
    output  [0:DATA_WIDTH*MST_AMT-1]        dsp_RDATA_o,
    output  [0:MST_AMT-1]                   dsp_RLAST_o,
    output  [0:MST_AMT-1]                   dsp_RVALID_o,
    // -- To slave (master interface of the interconnect)
    // ---- Write address channel
    output  [0:TRANS_SLV_ID_W-1]            s_AWID_o,
    output  [0:ADDR_WIDTH-1]                s_AWADDR_o,
    output  [TRANS_BURST_W-1:0]             s_AxBURST_o,
    output  [0:TRANS_DATA_LEN_W-1]          s_AWLEN_o,
    output  [0:TRANS_DATA_SIZE_W-1]         s_AWSIZE_o,
    output                                  s_AWVALID_o,
    // ---- Write data channel
    output  [0:DATA_WIDTH-1]                s_WDATA_o,
    output                                  s_WLAST_o,
    output                                  s_WVALID_o,
    // ---- Write response channel          
    output                                  s_BREADY_o,
    // ---- Read address channel            
    output  [0:TRANS_SLV_ID_W-1]            s_ARID_o,
    output  [0:ADDR_WIDTH-1]                s_ARADDR_o,
    output  [0:TRANS_DATA_LEN_W-1]          s_ARLEN_o,
    output  [0:TRANS_DATA_SIZE_W-1]         s_ARSIZE_o,
    output                                  s_ARVALID_o,
    // ---- Read data channel
    output                                  s_RREADY_o
);

endmodule
