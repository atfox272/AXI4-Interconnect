`timescale 1ns / 1ps
// Testbench configuration
`define NUM_TRANS       7
`define DIRECTED_TEST   0   // Directed Test or Random Test
// Ax channel
`define AX_START_MODE   0
`define AX_STALL_MODE   1
`define AX_STOP_MODE    2
// W channel
`define W_START_MODE    10
`define W_WLAST_MODE    11
`define W_STALL_MODE    12
`define W_STOP_MODE     13
// B channel
`define B_START_MODE    20
`define B_STALL_MODE    22
`define B_STOP_MODE     23
// R channel
`define R_START_MODE    30
`define R_RLAST_MODE    31
`define R_STALL_MODE    32
`define R_STOP_MODE     33

// Interconnect configuration
    parameter                       MST_AMT             = 4;
    parameter                       SLV_AMT             = 2;
    parameter                       OUTSTANDING_AMT     = 8;
    parameter [0:(MST_AMT*32)-1]    MST_WEIGHT          = {32'd5, 32'd3, 32'd2, 32'd1};
    parameter                       MST_ID_W            = $clog2(MST_AMT);
    parameter                       SLV_ID_W            = $clog2(SLV_AMT);
    // Transaction configuration
    parameter                       DATA_WIDTH          = 32;
    parameter                       ADDR_WIDTH          = 32;
    parameter                       TRANS_MST_ID_W      = 5;                            // Bus width of master transaction ID 
    parameter                       TRANS_SLV_ID_W      = TRANS_MST_ID_W + MST_ID_W;    // Bus width of slave transaction ID
    parameter                       TRANS_BURST_W       = 2;                            // Width of xBURST 
    parameter                       TRANS_DATA_LEN_W    = 3;                            // Bus width of xLEN
    parameter                       TRANS_DATA_SIZE_W   = 3;                            // Bus width of xSIZE
    parameter                       TRANS_WR_RESP_W     = 2;
    // Slave info configuration (address mapping mechanism)
    parameter                       SLV_ID_MSB_IDX      = 30;
    parameter                       SLV_ID_LSB_IDX      = 30;
    // Dispatcher DATA depth configuration
    parameter                       DSP_RDATA_DEPTH     = 16;

typedef struct {
    bit [TRANS_MST_ID_W-1:0]      AxID;
    bit [TRANS_BURST_W-1:0]       AxBURST;
    bit [SLV_ID_W-1:0]            AxADDR_slv_id;
    bit [ADDR_WIDTH-SLV_ID_W-2:0] AxADDR_addr;
    bit [TRANS_DATA_LEN_W-1:0]    AxLEN;
    bit [TRANS_DATA_SIZE_W-1:0]   AxSIZE;
} Ax_info;
typedef struct {
    bit [DATA_WIDTH-1:0] WDATA;
    bit                  WLAST;
} W_info;

typedef struct {
    bit [TRANS_SLV_ID_W-1:0]    BID;
    bit [TRANS_WR_RESP_W-1:0]   BRESP;
} B_info;

typedef struct {
    bit [TRANS_SLV_ID_W-1:0]    RID;
    bit [DATA_WIDTH-1:0]        RDATA;
    bit                         RLAST;
} R_info;
    

class m_Ax_transfer_rnd #(int mode = `AX_START_MODE);
        rand    bit [TRANS_MST_ID_W-1:0]        m_AxID;
        rand    bit [TRANS_BURST_W-1:0]         m_AxBURST;
        rand    bit [SLV_ID_W-1:0]              m_AxADDR_slv_id;
        rand    bit [ADDR_WIDTH-SLV_ID_W-2:0]   m_AxADDR_addr;
        rand    bit [TRANS_DATA_LEN_W-1:0]      m_AxLEN;
        rand    bit [TRANS_DATA_SIZE_W-1:0]     m_AxSIZE;
        rand    bit                             m_AxVALID;
        constraint m_Ax_cntr{
            if(mode == `AX_START_MODE) {
                m_AxADDR_addr%(1<<m_AxSIZE) == 0;// All transfers must be aligned
                m_AxVALID == 1;
            }
            else if (mode == `AX_STOP_MODE) {
                m_AxID == 0;
                m_AxBURST == 0;
                m_AxADDR_slv_id == 0;
                m_AxADDR_addr == 0;
                m_AxLEN == 0;
                m_AxSIZE == 0;
                m_AxVALID == 0;
            }
            else if (mode == `AX_STALL_MODE) {
                m_AxVALID == 0;
            }
        }
    endclass
    
class m_W_transfer_rnd #(int mode = `W_START_MODE);
    rand    bit [DATA_WIDTH-1:0]    m_WDATA;
    rand    bit                     m_WLAST;
    rand    bit                     m_WVALID;
    constraint m_W_cntr{
        if(mode == `W_WLAST_MODE) {
            m_WLAST == 1;
            m_WVALID == 1;
        }
        else if (mode == `W_START_MODE){
            m_WLAST == 0;
            m_WVALID == 1;
        }
        else if (mode == `W_STOP_MODE) {
            m_WDATA == 0;
            m_WLAST == 0;
            m_WVALID == 0;
        }
        else if (mode == `W_STALL_MODE) {
            m_WVALID == 0;
        }
        else {
            m_WDATA == 0;
            m_WLAST == 0;
            m_WVALID == 0;
        }
    }
endclass
    
class s_B_transfer_rnd #(int mode = `B_START_MODE);
    rand    bit [TRANS_SLV_ID_W-1:0]    s_BID;
    rand    bit [TRANS_WR_RESP_W-1:0]   s_BRESP;
    rand    bit                         s_BVALID;
    constraint m_W_cntr{
        if (mode == `B_START_MODE){
            s_BVALID == 1;
        }
        else if (mode == `B_STOP_MODE) {
            s_BID == 0;
            s_BRESP == 0;
            s_BVALID == 0;
        }
        else if (mode == `B_STALL_MODE) {
            s_BVALID == 0;
        }
        else {
            s_BID == 0;
            s_BRESP == 0;
            s_BVALID == 0;
        }
    }
endclass

class s_R_transfer_rnd #(int mode = `R_START_MODE);
    rand    bit [TRANS_SLV_ID_W-1:0]    s_RID;
    rand    bit [DATA_WIDTH-1:0]        s_RDATA;
    rand    bit                         s_RLAST;
    rand    bit                         s_RVALID;
    constraint m_R_cntr{
        if (mode == `B_START_MODE){
            s_RLAST     == 0;
            s_RVALID    == 1;
        }
        else if(mode == `R_RLAST_MODE) {
            s_RLAST     == 1;
            s_RVALID    == 1;
        }
        else if (mode == `B_STOP_MODE) {
            s_RID       == 0;  
            s_RDATA     == 0;
            s_RLAST     == 0;
            s_RVALID    == 0;
        }
        else if (mode == `B_STALL_MODE) {
            s_RVALID    == 0;
        }
        else {
            s_RID       == 0;  
            s_RDATA     == 0;
            s_RLAST     == 0;
            s_RVALID    == 0;
        }
    }
endclass

module axi_interconnect_tb;
    
    // Input declaration
    // -- Global signals
    logic                                   ACLK_i;
    logic                                   ARESETn_i;
    // -- To Master (slave interface of the interconnect)
    // ---- Write address channel
    wire    [TRANS_MST_ID_W*MST_AMT-1:0]    m_AWID_i;
    wire    [ADDR_WIDTH*MST_AMT-1:0]        m_AWADDR_i;
    wire    [TRANS_BURST_W*MST_AMT-1:0]     m_AWBURST_i;
    wire    [TRANS_DATA_LEN_W*MST_AMT-1:0]  m_AWLEN_i;
    wire    [TRANS_DATA_SIZE_W*MST_AMT-1:0] m_AWSIZE_i;
    wire    [MST_AMT-1:0]                   m_AWVALID_i;
    // ---- Write data channel
    wire    [DATA_WIDTH*MST_AMT-1:0]        m_WDATA_i;
    wire    [MST_AMT-1:0]                   m_WLAST_i;
    wire    [MST_AMT-1:0]                   m_WVALID_i;
    // ---- Write response channel
    wire    [MST_AMT-1:0]                   m_BREADY_i;
    // ---- Read address channel
    wire    [TRANS_MST_ID_W*MST_AMT-1:0]    m_ARID_i;
    wire    [ADDR_WIDTH*MST_AMT-1:0]        m_ARADDR_i;
    wire    [TRANS_BURST_W*MST_AMT-1:0]     m_ARBURST_i;
    wire    [TRANS_DATA_LEN_W*MST_AMT-1:0]  m_ARLEN_i;
    wire    [TRANS_DATA_SIZE_W*MST_AMT-1:0] m_ARSIZE_i;
    wire    [MST_AMT-1:0]                   m_ARVALID_i;
    // ---- Read data channel
    wire    [MST_AMT-1:0]                   m_RREADY_i;
    // -- To slave (master interface of the interconnect)
    // ---- Write address channel (master)
    wire    [SLV_AMT-1:0]                   s_AWREADY_i;
    // ---- Write data channel (master)
    wire    [SLV_AMT-1:0]                   s_WREADY_i;
    // ---- Write response channel (master)
    wire    [TRANS_SLV_ID_W*SLV_AMT-1:0]    s_BID_i;
    wire    [TRANS_WR_RESP_W*SLV_AMT-1:0]   s_BRESP_i;
    wire    [SLV_AMT-1:0]                   s_BVALID_i;
    // ---- Read address channel (master)
    wire    [SLV_AMT-1:0]                   s_ARREADY_i;
    // ---- Read data channel (master)
    wire    [TRANS_SLV_ID_W*SLV_AMT-1:0]    s_RID_i;
    wire    [DATA_WIDTH*SLV_AMT-1:0]        s_RDATA_i;
    wire    [TRANS_WR_RESP_W*SLV_AMT-1:0]   s_RRESP_i;
    wire    [SLV_AMT-1:0]                   s_RLAST_i;
    wire    [SLV_AMT-1:0]                   s_RVALID_i;
    
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Write address channel (master)
    wire    [MST_AMT-1:0]                   m_AWREADY_o;
    // ---- Write data channel (master)
    wire    [MST_AMT-1:0]                   m_WREADY_o;
    // ---- Write response channel (master)
    wire    [TRANS_MST_ID_W*MST_AMT-1:0]    m_BID_o;
    wire    [TRANS_WR_RESP_W*MST_AMT-1:0]   m_BRESP_o;
    wire    [MST_AMT-1:0]                   m_BVALID_o;
    // ---- Read address channel (master)
    wire    [MST_AMT-1:0]                   m_ARREADY_o;
    // ---- Read data channel (master)
    wire    [TRANS_MST_ID_W*MST_AMT-1:0]    m_RID_o;
    wire    [DATA_WIDTH*MST_AMT-1:0]        m_RDATA_o;
    wire    [TRANS_WR_RESP_W*MST_AMT-1:0]   m_RRESP_o;
    wire    [MST_AMT-1:0]                   m_RLAST_o;
    wire    [MST_AMT-1:0]                   m_RVALID_o;
    // -- To slave (master interface of the interconnect)
    // ---- Write address channel
    wire    [TRANS_SLV_ID_W*SLV_AMT-1:0]    s_AWID_o;
    wire    [ADDR_WIDTH*SLV_AMT-1:0]        s_AWADDR_o;
    wire    [TRANS_BURST_W*SLV_AMT-1:0]     s_AWBURST_o;
    wire    [TRANS_DATA_LEN_W*SLV_AMT-1:0]  s_AWLEN_o;
    wire    [TRANS_DATA_SIZE_W*SLV_AMT-1:0] s_AWSIZE_o;
    wire    [SLV_AMT-1:0]                   s_AWVALID_o;
    // ---- Write data channel
    wire    [DATA_WIDTH*SLV_AMT-1:0]        s_WDATA_o;
    wire    [SLV_AMT-1:0]                   s_WLAST_o;
    wire    [SLV_AMT-1:0]                   s_WVALID_o;
    // ---- Write response channel          
    wire    [SLV_AMT-1:0]                   s_BREADY_o;
    // ---- Read address channel            
    wire    [TRANS_SLV_ID_W*SLV_AMT-1:0]    s_ARID_o;
    wire    [ADDR_WIDTH*SLV_AMT-1:0]        s_ARADDR_o;
    wire    [TRANS_BURST_W*SLV_AMT-1:0]     s_ARBURST_o;
    wire    [TRANS_DATA_LEN_W*SLV_AMT-1:0]  s_ARLEN_o;
    wire    [TRANS_DATA_SIZE_W*SLV_AMT-1:0] s_ARSIZE_o;
    wire    [SLV_AMT-1:0]                   s_ARVALID_o;
    // ---- Read data channel
    wire    [SLV_AMT-1:0]                   s_RREADY_o;
    
    
    // Internal variable declaration
    genvar mst_idx;
    genvar slv_idx;
    
    // Internal signal declaration
    // -- To Master
    // -- -- Input
    // -- -- -- Write address channel
    reg     [TRANS_MST_ID_W-1:0]    m_AWID      [MST_AMT-1:0];
    reg     [ADDR_WIDTH-1:0]        m_AWADDR    [MST_AMT-1:0];
    reg     [TRANS_BURST_W-1:0]     m_AWBURST   [MST_AMT-1:0];
    reg     [TRANS_DATA_LEN_W-1:0]  m_AWLEN     [MST_AMT-1:0];
    reg     [TRANS_DATA_SIZE_W-1:0] m_AWSIZE    [MST_AMT-1:0];
    reg                             m_AWVALID   [MST_AMT-1:0];
    // -- -- -- Write data channel
    reg     [DATA_WIDTH-1:0]        m_WDATA     [MST_AMT-1:0];
    reg                             m_WLAST     [MST_AMT-1:0];
    reg                             m_WVALID    [MST_AMT-1:0];
    // -- -- -- Write response channel
    reg                             m_BREADY    [MST_AMT-1:0];
    // -- -- -- Read address channel
    reg     [TRANS_MST_ID_W-1:0]    m_ARID      [MST_AMT-1:0];
    reg     [ADDR_WIDTH-1:0]        m_ARADDR    [MST_AMT-1:0];
    reg     [TRANS_BURST_W-1:0]     m_ARBURST   [MST_AMT-1:0];
    reg     [TRANS_DATA_LEN_W-1:0]  m_ARLEN     [MST_AMT-1:0];
    reg     [TRANS_DATA_SIZE_W-1:0] m_ARSIZE    [MST_AMT-1:0];
    reg                             m_ARVALID   [MST_AMT-1:0];
    // -- -- -- Read data channel
    reg                             m_RREADY    [MST_AMT-1:0];
    // -- -- Output
    // -- -- -- Write address channel (master)
    wire                            m_AWREADY   [MST_AMT-1:0];
    // -- -- -- Write data channel (master)
    wire                            m_WREADY    [MST_AMT-1:0];
    // -- -- -- Write response channel (master)
    wire    [TRANS_MST_ID_W-1:0]    m_BID       [MST_AMT-1:0];
    wire    [TRANS_WR_RESP_W-1:0]   m_BRESP     [MST_AMT-1:0];
    wire                            m_BVALID    [MST_AMT-1:0];
    // -- -- -- Read address channel (master)
    wire                            m_ARREADY   [MST_AMT-1:0];
    // -- -- -- Read data channel (master)
    wire    [TRANS_MST_ID_W-1:0]    m_RID       [MST_AMT-1:0];
    wire    [DATA_WIDTH-1:0]        m_RDATA     [MST_AMT-1:0];
    wire    [TRANS_WR_RESP_W-1:0]   m_RRESP     [MST_AMT-1:0];
    wire                            m_RLAST     [MST_AMT-1:0];
    wire                            m_RVALID    [MST_AMT-1:0];
    // -- To Slave
    // -- -- Input
    // -- -- -- Write address channel (master)
    reg                             s_AWREADY   [SLV_AMT-1:0];
    // -- -- -- Write data channel (master)
    reg                             s_WREADY    [SLV_AMT-1:0];
    // -- -- -- Write response channel (master)
    reg     [TRANS_SLV_ID_W-1:0]    s_BID       [SLV_AMT-1:0];
    reg     [TRANS_WR_RESP_W-1:0]   s_BRESP     [SLV_AMT-1:0];
    reg                             s_BVALID    [SLV_AMT-1:0];
    // -- -- -- Read address channel (master)
    reg                             s_ARREADY   [SLV_AMT-1:0];
    // -- -- -- Read data channel (master)
    reg     [TRANS_SLV_ID_W-1:0]    s_RID       [SLV_AMT-1:0];
    reg     [DATA_WIDTH-1:0]        s_RDATA     [SLV_AMT-1:0];
    reg     [TRANS_WR_RESP_W-1:0]   s_RRESP     [SLV_AMT-1:0];
    reg                             s_RLAST     [SLV_AMT-1:0];
    reg                             s_RVALID    [SLV_AMT-1:0];
    // -- -- Output
    // -- -- -- Write address channel
    wire    [TRANS_SLV_ID_W-1:0]    s_AWID      [SLV_AMT-1:0];
    wire    [ADDR_WIDTH-1:0]        s_AWADDR    [SLV_AMT-1:0];
    wire    [TRANS_BURST_W-1:0]     s_AWBURST   [SLV_AMT-1:0];
    wire    [TRANS_DATA_LEN_W-1:0]  s_AWLEN     [SLV_AMT-1:0];
    wire    [TRANS_DATA_SIZE_W-1:0] s_AWSIZE    [SLV_AMT-1:0];
    wire                            s_AWVALID   [SLV_AMT-1:0];
    // -- -- -- Write data channel
    wire    [DATA_WIDTH-1:0]        s_WDATA     [SLV_AMT-1:0];
    wire                            s_WLAST     [SLV_AMT-1:0];
    wire                            s_WVALID    [SLV_AMT-1:0];
    // -- -- -- Write response channel          
    wire                            s_BREADY    [SLV_AMT-1:0];
    // -- -- -- Read address channel            
    wire    [TRANS_SLV_ID_W-1:0]    s_ARID      [SLV_AMT-1:0];
    wire    [ADDR_WIDTH-1:0]        s_ARADDR    [SLV_AMT-1:0];
    wire    [TRANS_BURST_W-1:0]     s_ARBURST   [SLV_AMT-1:0];
    wire    [TRANS_DATA_LEN_W-1:0]  s_ARLEN     [SLV_AMT-1:0];
    wire    [TRANS_DATA_SIZE_W-1:0] s_ARSIZE    [SLV_AMT-1:0];
    wire                            s_ARVALID   [SLV_AMT-1:0];
    // -- -- -- Read data channel
    wire                            s_RREADY    [SLV_AMT-1:0];
    
    generate
        // -- To Master
        for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin
            // -- -- Input
            assign m_AWID_i[TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W]        = m_AWID[mst_idx];
            assign m_AWADDR_i[ADDR_WIDTH*(mst_idx+1)-1-:ADDR_WIDTH]              = m_AWADDR[mst_idx];
            assign m_AWBURST_i[TRANS_BURST_W*(mst_idx+1)-1-:TRANS_BURST_W]       = m_AWBURST[mst_idx];
            assign m_AWLEN_i[TRANS_DATA_LEN_W*(mst_idx+1)-1-:TRANS_DATA_LEN_W]   = m_AWLEN[mst_idx];
            assign m_AWSIZE_i[TRANS_DATA_SIZE_W*(mst_idx+1)-1-:TRANS_DATA_SIZE_W]= m_AWSIZE[mst_idx];
            assign m_AWVALID_i[mst_idx]                                          = m_AWVALID[mst_idx];
            assign m_WDATA_i[DATA_WIDTH*(mst_idx+1)-1-:DATA_WIDTH]               = m_WDATA[mst_idx];
            assign m_WLAST_i[mst_idx]                                            = m_WLAST[mst_idx];
            assign m_WVALID_i[mst_idx]                                           = m_WVALID[mst_idx];
            assign m_BREADY_i[mst_idx]                                           = m_BREADY[mst_idx];
            assign m_ARID_i[TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W]        = m_ARID[mst_idx];
            assign m_ARADDR_i[ADDR_WIDTH*(mst_idx+1)-1-:ADDR_WIDTH]              = m_ARADDR[mst_idx];
            assign m_ARBURST_i[TRANS_BURST_W*(mst_idx+1)-1-:TRANS_BURST_W]       = m_ARBURST[mst_idx];
            assign m_ARLEN_i[TRANS_DATA_LEN_W*(mst_idx+1)-1-:TRANS_DATA_LEN_W]   = m_ARLEN[mst_idx];
            assign m_ARSIZE_i[TRANS_DATA_SIZE_W*(mst_idx+1)-1-:TRANS_DATA_SIZE_W]= m_ARSIZE[mst_idx];
            assign m_ARVALID_i[mst_idx]                                          = m_ARVALID[mst_idx];
            assign m_RREADY_i[mst_idx]                                           = m_RREADY[mst_idx];
            // -- -- Output
            assign m_AWREADY[mst_idx]                                           =  m_AWREADY_o[mst_idx];
            assign m_WREADY[mst_idx]                                            =  m_WREADY_o[mst_idx];
            assign m_BID[mst_idx]                                               =  m_BID_o[TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W];   
            assign m_BRESP[mst_idx]                                             =  m_BRESP_o[TRANS_WR_RESP_W*(mst_idx+1)-1-:TRANS_WR_RESP_W]; 
            assign m_BVALID[mst_idx]                                            =  m_BVALID_o[mst_idx];
            assign m_ARREADY[mst_idx]                                           =  m_ARREADY_o[mst_idx];
            assign m_RID[mst_idx]                                               =  m_RID_o[TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W];   
            assign m_RDATA[mst_idx]                                             =  m_RDATA_o[DATA_WIDTH*(mst_idx+1)-1-:DATA_WIDTH]; 
            assign m_RRESP[mst_idx]                                             =  m_RRESP_o[TRANS_WR_RESP_W*(mst_idx+1)-1-:TRANS_WR_RESP_W]; 
            assign m_RLAST[mst_idx]                                             =  m_RLAST_o[mst_idx]; 
            assign m_RVALID[mst_idx]                                            =  m_RVALID_o[mst_idx];
        end
        // -- To Slave
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin
            // -- -- Input
            assign s_AWREADY_i[slv_idx]                                         = s_AWREADY[slv_idx];
            assign s_WREADY_i[slv_idx]                                          = s_WREADY[slv_idx];
            assign s_BID_i[TRANS_SLV_ID_W*(slv_idx+1)-1-:TRANS_SLV_ID_W]        = s_BID[slv_idx];
            assign s_BRESP_i[TRANS_WR_RESP_W*(slv_idx+1)-1-:TRANS_WR_RESP_W]    = s_BRESP[slv_idx];
            assign s_BVALID_i[slv_idx]                                          = s_BVALID[slv_idx];
            assign s_ARREADY_i[slv_idx]                                         = s_ARREADY[slv_idx];
            assign s_RID_i[TRANS_SLV_ID_W*(slv_idx+1)-1-:TRANS_SLV_ID_W]        = s_RID[slv_idx];
            assign s_RDATA_i[DATA_WIDTH*(slv_idx+1)-1-:DATA_WIDTH]              = s_RDATA[slv_idx];
            assign s_RRESP_i[TRANS_WR_RESP_W*(slv_idx+1)-1-:TRANS_WR_RESP_W]    = s_RRESP[slv_idx];
            assign s_RLAST_i[slv_idx]                                           = s_RLAST[slv_idx];
            assign s_RVALID_i[slv_idx]                                          = s_RVALID[slv_idx];
            // -- -- Output
            assign s_AWID[slv_idx]                                              = s_AWID_o[TRANS_SLV_ID_W*(slv_idx+1)-1-:TRANS_SLV_ID_W];
            assign s_AWADDR[slv_idx]                                            = s_AWADDR_o[ADDR_WIDTH*(slv_idx+1)-1-:ADDR_WIDTH];
            assign s_AWBURST[slv_idx]                                           = s_AWBURST_o[TRANS_BURST_W*(slv_idx+1)-1-:TRANS_BURST_W];
            assign s_AWLEN[slv_idx]                                             = s_AWLEN_o[TRANS_DATA_LEN_W*(slv_idx+1)-1-:TRANS_DATA_LEN_W];
            assign s_AWSIZE[slv_idx]                                            = s_AWSIZE_o[TRANS_DATA_SIZE_W*(slv_idx+1)-1-:TRANS_DATA_SIZE_W];
            assign s_AWVALID[slv_idx]                                           = s_AWVALID_o[slv_idx];
            assign s_WDATA[slv_idx]                                             = s_WDATA_o[DATA_WIDTH*(slv_idx+1)-1-:DATA_WIDTH];
            assign s_WLAST[slv_idx]                                             = s_WLAST_o[slv_idx];
            assign s_WVALID[slv_idx]                                            = s_WVALID_o[slv_idx];
            assign s_BREADY[slv_idx]                                            = s_BREADY_o[slv_idx];
            assign s_ARID[slv_idx]                                              = s_ARID_o[TRANS_SLV_ID_W*(slv_idx+1)-1-:TRANS_SLV_ID_W];
            assign s_ARADDR[slv_idx]                                            = s_ARADDR_o[ADDR_WIDTH*(slv_idx+1)-1-:ADDR_WIDTH];
            assign s_ARBURST[slv_idx]                                           = s_ARBURST_o[TRANS_BURST_W*(slv_idx+1)-1-:TRANS_BURST_W];
            assign s_ARLEN[slv_idx]                                             = s_ARLEN_o[TRANS_DATA_LEN_W*(slv_idx+1)-1-:TRANS_DATA_LEN_W];
            assign s_ARSIZE[slv_idx]                                            = s_ARSIZE_o[TRANS_DATA_SIZE_W*(slv_idx+1)-1-:TRANS_DATA_SIZE_W];
            assign s_ARVALID[slv_idx]                                           = s_ARVALID_o[slv_idx];
            assign s_RREADY[slv_idx]                                            = s_RREADY_o[slv_idx];
        end
    endgenerate
    
    // Testcase generator
    // -- Master
    m_Ax_transfer_rnd   #(`AX_START_MODE)   m_AW_rnd;
    m_W_transfer_rnd    #(`W_START_MODE)    m_W_rnd;
    m_Ax_transfer_rnd   #(`AX_START_MODE)   m_AR_rnd;
    // -- Slave
    s_B_transfer_rnd    #(`B_START_MODE)    s_B_rnd;
    s_R_transfer_rnd    #(`R_START_MODE)    s_R_rnd;
    
    axi_interconnect #(
        .MST_AMT(MST_AMT),
        .SLV_AMT(SLV_AMT),
        .OUTSTANDING_AMT(OUTSTANDING_AMT),
        .MST_WEIGHT(MST_WEIGHT),
        .MST_ID_W(MST_ID_W),
        .SLV_ID_W(SLV_ID_W),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TRANS_MST_ID_W(TRANS_MST_ID_W),
        .TRANS_SLV_ID_W(TRANS_SLV_ID_W),
        .TRANS_BURST_W(TRANS_BURST_W),
        .TRANS_DATA_LEN_W(TRANS_DATA_LEN_W),
        .TRANS_DATA_SIZE_W(TRANS_DATA_SIZE_W),
        .TRANS_WR_RESP_W(TRANS_WR_RESP_W),
        .SLV_ID_MSB_IDX(SLV_ID_MSB_IDX),
        .SLV_ID_LSB_IDX(SLV_ID_LSB_IDX),
        .DSP_RDATA_DEPTH(DSP_RDATA_DEPTH)
    ) dut (
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),
        .m_AWID_i(m_AWID_i),
        .m_AWADDR_i(m_AWADDR_i),
        .m_AWBURST_i(m_AWBURST_i),
        .m_AWLEN_i(m_AWLEN_i),
        .m_AWSIZE_i(m_AWSIZE_i),
        .m_AWVALID_i(m_AWVALID_i),
        .m_WDATA_i(m_WDATA_i),
        .m_WLAST_i(m_WLAST_i),
        .m_WVALID_i(m_WVALID_i),
        .m_BREADY_i(m_BREADY_i),
        .m_ARID_i(m_ARID_i),
        .m_ARADDR_i(m_ARADDR_i),
        .m_ARBURST_i(m_ARBURST_i),
        .m_ARLEN_i(m_ARLEN_i),
        .m_ARSIZE_i(m_ARSIZE_i),
        .m_ARVALID_i(m_ARVALID_i),
        .m_RREADY_i(m_RREADY_i),
        .s_AWREADY_i(s_AWREADY_i),
        .s_WREADY_i(s_WREADY_i),
        .s_BID_i(s_BID_i),
        .s_BRESP_i(s_BRESP_i),
        .s_BVALID_i(s_BVALID_i),
        .s_ARREADY_i(s_ARREADY_i),
        .s_RID_i(s_RID_i),
        .s_RDATA_i(s_RDATA_i),
        .s_RRESP_i(s_RRESP_i),
        .s_RLAST_i(s_RLAST_i),
        .s_RVALID_i(s_RVALID_i),
        .m_AWREADY_o(m_AWREADY_o),
        .m_WREADY_o(m_WREADY_o),
        .m_BID_o(m_BID_o),
        .m_BRESP_o(m_BRESP_o),
        .m_BVALID_o(m_BVALID_o),
        .m_ARREADY_o(m_ARREADY_o),
        .m_RID_o(m_RID_o),
        .m_RDATA_o(m_RDATA_o),
        .m_RRESP_o(m_RRESP_o),
        .m_RLAST_o(m_RLAST_o),
        .m_RVALID_o(m_RVALID_o),
        .s_AWID_o(s_AWID_o),
        .s_AWADDR_o(s_AWADDR_o),
        .s_AWBURST_o(s_AWBURST_o),
        .s_AWLEN_o(s_AWLEN_o),
        .s_AWSIZE_o(s_AWSIZE_o),
        .s_AWVALID_o(s_AWVALID_o),
        .s_WDATA_o(s_WDATA_o),
        .s_WLAST_o(s_WLAST_o),
        .s_WVALID_o(s_WVALID_o),
        .s_BREADY_o(s_BREADY_o),
        .s_ARID_o(s_ARID_o),
        .s_ARADDR_o(s_ARADDR_o),
        .s_ARBURST_o(s_ARBURST_o),
        .s_ARLEN_o(s_ARLEN_o),
        .s_ARSIZE_o(s_ARSIZE_o),
        .s_ARVALID_o(s_ARVALID_o),
        .s_RREADY_o(s_RREADY_o)
    );
    
    initial begin
        ACLK_i <= 0;
        forever #1 ACLK_i <= ~ACLK_i;
    end
    
    initial begin
        localparam mst_idx = 0;
        ARESETn_i <= 0;
     

        #5; ARESETn_i <= 1;
    end
    
    // Queue declaration
    Ax_info     m_AW_queue  [MST_AMT][$];
    W_info      m_W_queue   [MST_AMT][$];
    B_info      m_B_queue   [MST_AMT][$];
    Ax_info     m_AR_queue  [MST_AMT][$];
    
    B_info      m_W_B_queue [MST_AMT][$];
    
    /********************** Directed test ***************************/
    `ifdef DIRECTED_TEST
    initial begin : MASTER_0_AR_channel
        localparam mst_idx = 0;
        #6; 
        
        m_AR_transfer(.mst_id(mst_idx), .ARID(1), .ARADDR({2'b00, 30'd01}), .ARBURST(0), .ARLEN(3), .ARSIZE(0));
        m_AR_transfer(.mst_id(mst_idx), .ARID(2), .ARADDR({2'b00, 30'd02}), .ARBURST(0), .ARLEN(0), .ARSIZE(0));
        m_AR_transfer(.mst_id(mst_idx), .ARID(3), .ARADDR({2'b00, 30'd03}), .ARBURST(0), .ARLEN(0), .ARSIZE(0));
        m_AR_transfer(.mst_id(mst_idx), .ARID(4), .ARADDR({2'b00, 30'd04}), .ARBURST(0), .ARLEN(0), .ARSIZE(0));
        
        // 4KB Crossing transaction
        m_AR_transfer(.mst_id(mst_idx), .ARID(4), .ARADDR({2'b01, 30'd4094}), .ARBURST(0), .ARLEN(4), .ARSIZE(0));
        // End
        @(posedge ACLK_i); #0.01;
        m_ARVALID[mst_idx]  <= 0;
    end
    initial begin : MASTER_1_AR_channel
        localparam mst_idx = 1;
        #6; 
        
        m_AR_transfer(.mst_id(mst_idx), .ARID(1), .ARADDR({2'b00, 30'd01}), .ARBURST(0), .ARLEN(0), .ARSIZE(0));
        m_AR_transfer(.mst_id(mst_idx), .ARID(2), .ARADDR({2'b01, 30'd02}), .ARBURST(0), .ARLEN(0), .ARSIZE(0));
        m_AR_transfer(.mst_id(mst_idx), .ARID(3), .ARADDR({2'b00, 30'd03}), .ARBURST(0), .ARLEN(0), .ARSIZE(0));
        m_AR_transfer(.mst_id(mst_idx), .ARID(4), .ARADDR({2'b01, 30'd04}), .ARBURST(0), .ARLEN(0), .ARSIZE(0));
        // End
        @(posedge ACLK_i); #0.01;
        m_ARVALID[mst_idx]  <= 0;
    end
    initial begin : MASTER_2_AR_channel
        localparam mst_idx = 2;
        #6; 
        
        m_AR_transfer(.mst_id(mst_idx), .ARID(1), .ARADDR({2'b01, 30'd01}), .ARBURST(0), .ARLEN(0), .ARSIZE(0));
        m_AR_transfer(.mst_id(mst_idx), .ARID(2), .ARADDR({2'b01, 30'd02}), .ARBURST(0), .ARLEN(0), .ARSIZE(0));
        // End
        @(posedge ACLK_i); #0.01;
        m_ARVALID[mst_idx]  <= 0;
    end
    initial begin : SLAVE_0_R_channel 
        localparam slv_idx = 0;
        #6; 
        // 1st read request
        s_R_transfer(.slv_id(slv_idx), .RID(1), .RDATA(10), .RLAST(0));
        s_R_transfer(.slv_id(slv_idx), .RID(1), .RDATA(20), .RLAST(0));
        s_R_transfer(.slv_id(slv_idx), .RID(1), .RDATA(30), .RLAST(0));
        s_R_transfer(.slv_id(slv_idx), .RID(1), .RDATA(40), .RLAST(1));
        // 2nd read request
        s_R_transfer(.slv_id(slv_idx), .RID(33), .RDATA(50), .RLAST(1));
        // 3rd read request
        s_R_transfer(.slv_id(slv_idx), .RID(2), .RDATA(60), .RLAST(1));
        // 4th read request
        s_R_transfer(.slv_id(slv_idx), .RID(35), .RDATA(70), .RLAST(1));
        // 5th read request
        s_R_transfer(.slv_id(slv_idx), .RID(3), .RDATA(80), .RLAST(1));
        // 6th read request
        s_R_transfer(.slv_id(slv_idx), .RID(4), .RDATA(90), .RLAST(1));
        // 7th
        s_R_transfer(.slv_id(slv_idx), .RID(64), .RDATA(100), .RLAST(1));
        
        @(posedge ACLK_i); #0.01;
        s_RVALID[slv_idx]  <= 0;
    end 
    initial begin : SLAVE_1_R_channel 
        localparam slv_idx = 1;
        #12; 
        // 1st read request
        s_R_transfer(.slv_id(slv_idx), .RID(65), .RDATA(110), .RLAST(1));
        // 2nd read request
        s_R_transfer(.slv_id(slv_idx), .RID(34), .RDATA(120), .RLAST(1));
        // 3rd read request
        s_R_transfer(.slv_id(slv_idx), .RID(66), .RDATA(130), .RLAST(1));
        // 4th read request
        s_R_transfer(.slv_id(slv_idx), .RID(36), .RDATA(140), .RLAST(1));
        // 5th read request
        s_R_transfer(.slv_id(slv_idx), .RID(4), .RDATA(200), .RLAST(0));
        s_R_transfer(.slv_id(slv_idx), .RID(4), .RDATA(210), .RLAST(1));
        // 6th read request
        s_R_transfer(.slv_id(slv_idx), .RID(4), .RDATA(220), .RLAST(0));
        s_R_transfer(.slv_id(slv_idx), .RID(4), .RDATA(230), .RLAST(0));
        s_R_transfer(.slv_id(slv_idx), .RID(4), .RDATA(240), .RLAST(1));
        
        @(posedge ACLK_i); #0.01;
        s_RVALID[slv_idx]  <= 0;
    end
    
    initial begin : MASTER_0_AW_channel
        localparam mst_idx = 0;
        #6; 
        // 4KB Crossing transaction
        m_AW_transfer(.mst_id(mst_idx), .AWID(0), .AWADDR({2'b00, 30'd02}), .AWBURST(0), .AWLEN(4), .AWSIZE(0));
        m_AW_transfer(.mst_id(mst_idx), .AWID(1), .AWADDR({2'b00, 30'd4094}), .AWBURST(0), .AWLEN(4), .AWSIZE(0));
        // End
        @(posedge ACLK_i); #0.01;
        m_AWVALID[mst_idx]  <= 0;
    end
    initial begin : MASTER_1_AW_channel
        localparam mst_idx = 1;
        #6; 
        // 4KB Crossing transaction
        m_AW_transfer(.mst_id(mst_idx), .AWID(2), .AWADDR({2'b00, 30'd2}), .AWBURST(0), .AWLEN(0), .AWSIZE(0));
        // End
        @(posedge ACLK_i); #0.01;
        m_AWVALID[mst_idx]  <= 0;
    end
    initial begin : MASTER_2_AW_channel
        localparam mst_idx = 2;
        #6; 
        // 4KB Crossing transaction
        m_AW_transfer(.mst_id(mst_idx), .AWID(2), .AWADDR({2'b00, 30'd3}), .AWBURST(0), .AWLEN(1), .AWSIZE(0));
        // End
        @(posedge ACLK_i); #0.01;
        m_AWVALID[mst_idx]  <= 0;
    end
    initial begin : MASTER_0_W_channel
        localparam mst_idx = 0;
        #12; 
        // Simple
        m_W_transfer(.mst_id(mst_idx), .WDATA(13), .WLAST(0));
        m_W_transfer(.mst_id(mst_idx), .WDATA(14), .WLAST(0));
        m_W_transfer(.mst_id(mst_idx), .WDATA(15), .WLAST(0));
        m_W_transfer(.mst_id(mst_idx), .WDATA(16), .WLAST(0));
        m_W_transfer(.mst_id(mst_idx), .WDATA(17), .WLAST(1));
        // 4KB Crossing transaction
        m_W_transfer(.mst_id(mst_idx), .WDATA(30), .WLAST(0));
        m_W_transfer(.mst_id(mst_idx), .WDATA(40), .WLAST(0));
        m_W_transfer(.mst_id(mst_idx), .WDATA(50), .WLAST(0));
        m_W_transfer(.mst_id(mst_idx), .WDATA(60), .WLAST(0));
        m_W_transfer(.mst_id(mst_idx), .WDATA(70), .WLAST(1));
        // End
        @(posedge ACLK_i); #0.01;
        m_WVALID[mst_idx]  <= 0;
    end
    initial begin : MASTER_1_W_channel
        localparam mst_idx = 1;
        #12; 
        m_W_transfer(.mst_id(mst_idx), .WDATA(11), .WLAST(1));
        // End
        @(posedge ACLK_i); #0.01;
        m_WVALID[mst_idx]  <= 0;
    end
    initial begin : MASTER_2_W_channel
        localparam mst_idx = 2;
        #12; 
        m_W_transfer(.mst_id(mst_idx), .WDATA(21), .WLAST(0));
        m_W_transfer(.mst_id(mst_idx), .WDATA(22), .WLAST(1));
        // End
        @(posedge ACLK_i); #0.01;
        m_WVALID[mst_idx]  <= 0;
    end
    initial begin : SLAVE_0_W_channel
        localparam slv_idx = 0;
        #14; 
        s_B_transfer(.slv_id(slv_idx), .BID(1), .BRESP(0));
        s_B_transfer(.slv_id(slv_idx), .BID(34), .BRESP(0));
        s_B_transfer(.slv_id(slv_idx), .BID(66), .BRESP(0));
        s_B_transfer(.slv_id(slv_idx), .BID(1), .BRESP(0));
        // End
        @(posedge ACLK_i); #0.01;
        s_BVALID[slv_idx]  <= 0;
    end
    /********************** Directed test ***************************/
    `else
    initial begin   : MASTER_DRIVER_0
        localparam mst_id = 0;
        #10;
        master_driver(mst_id);
    end
    initial begin   : MASTER_DRIVER_1
        localparam mst_id = 1;
        #10;
        master_driver(mst_id);
    end
//    initial begin   : MASTER_DRIVER_2
//        localparam mst_id = 2;
//        #10;
//        master_driver(mst_id);
//    end
//    initial begin   : MASTER_DRIVER_3
//        localparam mst_id = 3;
//        #10;
//        master_driver(mst_id);
//    end
    
    
    `endif
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // ------- DeepCode :v ------------
    
    
    int idx = 0;
    initial begin : INIT_VALUE_BLOCK
        for(idx = 0; idx < MST_AMT; idx = idx + 1) begin
            // R
            m_ARID[idx]     <= 0;
            m_ARADDR[idx]   <= 0;
            m_ARBURST[idx]  <= 0;
            m_ARLEN[idx]    <= 0;
            m_ARSIZE[idx]   <= 0;
            m_ARVALID[idx]  <= 0;
            m_RREADY[idx]   <= 1'b1;
            // W
            m_AWID[idx]     <= 0;
            m_AWADDR[idx]   <= 0;
            m_AWBURST[idx]  <= 0;
            m_AWLEN[idx]    <= 0;
            m_AWSIZE[idx]   <= 0;
            m_AWVALID[idx]  <= 0;
            m_WDATA[idx]    <= 0;
            m_WLAST[idx]    <= 0;
            m_WVALID[idx]   <= 0;
            m_BREADY[idx]   <= 1'b1;
        end
        for(idx = 0; idx < SLV_AMT; idx = idx + 1) begin
            s_AWREADY[idx]  <= 1'b1;
            s_WREADY[idx]   <= 1'b1;
            s_BID[idx]      <= 0;
            s_BRESP[idx]    <= 0;
            s_BVALID[idx]   <= 0;
            s_ARREADY[idx]  <= 1'b1;
            s_RID[idx]      <= 0;
            s_RDATA[idx]    <= 0;
            s_RLAST[idx]    <= 0;
            s_RVALID[idx]   <= 0;
        end
    end
   
    task automatic master_driver (input int mst_id);
        int AW_started;
        int AW_completed;
        
        m_AW_rnd    = new();
        m_W_rnd     = new();
        m_AR_rnd    = new();
//        assert(m_AW_rnd.randomize()) else $error("AR channel randomization failed");
//        assert(m_W_rnd.randomize()) else $error("W channel randomization failed");
//        assert(m_AR_rnd.randomize()) else $error("AR channel randomization failed");

        fork
            begin   : AW_channel
                Ax_info temp;
                for(int i = 0; i < `NUM_TRANS; i = i + 1) begin
                    // Randomize
                    assert(m_AW_rnd.randomize()) else $error("AR channel randomization failed");
                    // Start a AW transfer
                    m_AW_transfer(  
                        .mst_id(mst_id),
                        .AWID(i%OUTSTANDING_AMT),  
                        .AWADDR({0, m_AW_rnd.m_AxADDR_slv_id, m_AW_rnd.m_AxADDR_addr}),
                        .AWBURST(m_AW_rnd.m_AxBURST),
                        .AWLEN(m_AW_rnd.m_AxLEN),
                        .AWSIZE(m_AW_rnd.m_AxSIZE)
                    );
                    // Wait for AWREADY                            
                    wait(m_AWREADY[mst_id] == 1);
                    // Push ADDR info to queue
                    temp.AxID           = i%OUTSTANDING_AMT;
                    temp.AxBURST        = m_AW_rnd.m_AxBURST;
                    temp.AxADDR_slv_id  = m_AW_rnd.m_AxADDR_slv_id;
                    temp.AxADDR_addr    = m_AW_rnd.m_AxADDR_addr;
                    temp.AxLEN          = m_AW_rnd.m_AxLEN;
                    temp.AxSIZE         = m_AW_rnd.m_AxSIZE;
                    m_AW_queue[mst_id].push_back(temp);
//                    $display("DEBUG: temp.AxID - temp.AxBURST - temp.AxLEN - temp.AxSIZE", temp.AxID, temp.AxBURST, temp.AxLEN, temp.AxSIZE);
                    $display("INFO: Send AW transfer from Master %d with AWID:%d and AWADDR:(%h, %h) and AWLEN: %d", mst_id, temp.AxID, temp.AxADDR_slv_id, temp.AxADDR_addr, temp.AxLEN);
                    AW_started = 1;
                end
                cl;
                m_AWVALID[mst_id] <= 0;
                AW_completed = 1;
            end
            begin   : W_channel
                Ax_info AW_cur;
                B_info  B_nxt;
                bit WLAST_nxt;
                // Start W channel after the first AW transfer completed
                wait(AW_started == 1);
                for(int trans_ctn = 0; trans_ctn < `NUM_TRANS;) begin 
                    if(m_AW_queue[mst_id].size() > 0) begin
                        AW_cur = m_AW_queue[mst_id].pop_back();
                        for(int i = 0; i <= AW_cur.AxLEN; i = i + 1) begin
                            WLAST_nxt = i == AW_cur.AxLEN;
                            // Randomize
                            assert(m_W_rnd.randomize()) else $error("W channel randomization failed"); 
                            // Start a W transfer
                            m_W_transfer(   
                                .mst_id(mst_id),
                                .WDATA(m_W_rnd.m_WDATA),
                                .WLAST(WLAST_nxt)
                            );
                            wait(m_WREADY[mst_id] == 1);
                            // Push ADDR info to queue
                            $display("INFO: Send a W transfer from Master %d with WDATA: %d and WLAST: %d and i=%d and AW_cur.AxLEN=%d", mst_id, m_W_rnd.m_WDATA, WLAST_nxt, i, AW_cur.AxLEN);
                        end
                        $display("INFO: W channel completed: %d", trans_ctn);
                        trans_ctn = trans_ctn + 1;
                        // Push ID to BID_list
                        B_nxt.BID = AW_cur.AxID;
                        B_nxt.BRESP = 0;
                        m_W_B_queue[mst_id].push_back(B_nxt);
                    end 
                    else begin
                        // Wait for AW channel
                        cl;
                        m_WVALID[mst_id] <= 0;
                    end
                end
            end
            begin   : B_channel
//                int cur_BID;
//                int cur_BRESP;
//                m_B_receive (   
//                    .mst_id(mst_id),
//                    .BID(cur_BID),
//                    .BRESP(cur_BRESP)
//                );
//                $display("INFO: B channel received: BID %d", cur_BID);
                // Find the transaction ID in ID list
            end
            begin   : AR_channel
                // Todo:
            end
            begin   : R_channel
                // Todo:
            end 
        join
        $display("INFO: Master %d completed", mst_id);
    endtask 
   
    task automatic slave_driver (input int slv_id);
        fork
            begin   : AW_channel
//                int AWID;
//                int AWADDR;
//                int AWBURST;
//                int AWLEN;
//                int AWSIZE;
//                s_AW_receive(
//                    .slv_id(slv_id),
//                    .AWID(AWID),
//                    .AWADDR(AWADDR),
//                    .AWBURST(AWBURST),
//                    .AWLEN(AWLEN),
//                    .AWSIZE(AWSIZE)
//                );
                // Todo:
            end
            begin   : W_channel
                
            end
            begin   : B_channel
                
            end
            begin   : AR_channel
                
            end
            begin   : R_channel
            
            end 
        join
    endtask
   
   
    task automatic cl;
        @(posedge ACLK_i); #0.01;
    endtask
    
    task automatic m_AR_transfer(
        input [MST_ID_W-1:0]            mst_id,
        input [TRANS_MST_ID_W-1:0]      ARID,
        input [ADDR_WIDTH-1:0]          ARADDR,
        input [TRANS_BURST_W-1:0]       ARBURST,
        input [TRANS_DATA_LEN_W-1:0]    ARLEN,
        input [TRANS_DATA_SIZE_W-1:0]   ARSIZE
    );
        cl;
        m_ARID[mst_id]     <= ARID;
        m_ARADDR[mst_id]   <= ARADDR;
        m_ARBURST[mst_id]  <= ARBURST;
        m_ARLEN[mst_id]    <= ARLEN;
        m_ARSIZE[mst_id]   <= ARSIZE;
        m_ARVALID[mst_id]  <= 1;
    endtask
    
    task automatic m_AW_transfer(
        input [MST_ID_W-1:0]            mst_id,
        input [TRANS_MST_ID_W-1:0]      AWID,
        input [ADDR_WIDTH-1:0]          AWADDR,
        input [TRANS_BURST_W-1:0]       AWBURST,
        input [TRANS_DATA_LEN_W-1:0]    AWLEN,
        input [TRANS_DATA_SIZE_W-1:0]   AWSIZE
    );
        cl;
        m_AWID[mst_id]     <= AWID;
        m_AWADDR[mst_id]   <= AWADDR;
        m_AWBURST[mst_id]  <= AWBURST;
        m_AWLEN[mst_id]    <= AWLEN;
        m_AWSIZE[mst_id]   <= AWSIZE;
        m_AWVALID[mst_id]  <= 1'b1;
    endtask
    
    task automatic m_W_transfer (
        input [MST_ID_W-1:0]            mst_id,
        input [DATA_WIDTH-1:0]          WDATA,
        input                           WLAST
    );
        cl;
        m_WDATA[mst_id]     <= WDATA;
        m_WLAST[mst_id]     <= WLAST;
        m_WVALID[mst_id]    <= 1'b1;
    endtask
    
//    task automatic m_B_receive (
//        input       [MST_ID_W-1:0]          mst_id,
//        output  reg [TRANS_SLV_ID_W-1:0]    BID,
//        output  reg [TRANS_WR_RESP_W-1:0]   BRESP
//    );
//        // Wait for BVALID
//        wait(m_BVALID[mst_id] == 1);
//        #0.01;
//        BID     <= m_BID[mst_id];
//        BRESP   <= m_BRESP[mst_id];
//        // Handshake occur
//        cl;
//    endtask
    
    task automatic s_AW_receive(
        input       [MST_ID_W-1:0]            slv_id,
        output  reg [TRANS_MST_ID_W-1:0]      AWID,
        output  reg [ADDR_WIDTH-1:0]          AWADDR,
        output  reg [TRANS_BURST_W-1:0]       AWBURST,
        output  reg [TRANS_DATA_LEN_W-1:0]    AWLEN,
        output  reg [TRANS_DATA_SIZE_W-1:0]   AWSIZE
    );
        // Wait for BVALID
        wait(s_AWVALID[slv_id] == 1);
        #0.01;
        AWID    <= s_AWID[slv_id];
        AWADDR  <= s_AWADDR[slv_id];
        AWBURST <= s_AWBURST[slv_id];
        AWLEN   <= s_AWLEN[slv_id]; 
        AWSIZE  <= s_AWSIZE[slv_id]; 
        cl;
    endtask
    task automatic s_R_transfer (
        input [SLV_ID_W-1:0]            slv_id,
        input [TRANS_SLV_ID_W-1:0]      RID, 
        input [DATA_WIDTH-1:0]          RDATA,
        input                           RLAST
    );
        cl;
        s_RID[slv_id]       <= RID;
        s_RDATA[slv_id]     <= RDATA;
        s_RLAST[slv_id]     <= RLAST;
        s_RVALID[slv_id]    <= 1'b1;
    endtask
    
    task automatic s_B_transfer (
        input [SLV_ID_W-1:0]        slv_id,
        input [TRANS_SLV_ID_W-1:0]  BID,
        input [TRANS_WR_RESP_W-1:0] BRESP
    );
        cl;
        s_BID[slv_id]       <= BID;
        s_BRESP[slv_id]     <= BRESP;
        s_BVALID[slv_id]    <= 1'b1;
    endtask
    
endmodule






