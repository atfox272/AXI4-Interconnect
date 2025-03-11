module axi_interconnect 
#(
    // Interconnect configuration
    parameter                       MST_AMT             = 4,
    parameter                       SLV_AMT             = 4,
    parameter                       OUTSTANDING_AMT     = 8,
    parameter [0:(MST_AMT*32)-1]    MST_WEIGHT          = {32'd5, 32'd3, 32'd2, 32'd1},
    parameter                       MST_ID_W            = $clog2(MST_AMT),
    parameter                       SLV_ID_W            = $clog2(SLV_AMT),
    // Transaction configuration
    parameter                       DATA_WIDTH          = 32,
    parameter                       ADDR_WIDTH          = 32,
    parameter                       TRANS_MST_ID_W      = 5,                            // Bus width of master transaction ID 
    parameter                       TRANS_SLV_ID_W      = TRANS_MST_ID_W + MST_ID_W,    // Bus width of slave transaction ID
    parameter                       TRANS_BURST_W       = 2,                            // Width of xBURST 
    parameter                       TRANS_DATA_LEN_W    = 3,                            // Bus width of xLEN
    parameter                       TRANS_DATA_SIZE_W   = 3,                            // Bus width of xSIZE
    parameter                       TRANS_WR_RESP_W     = 2,
    // Slave info configuration (address mapping mechanism) (Default: The upper bits)
    parameter                       SLV_ID_MSB_IDX      = ADDR_WIDTH - 1,
    parameter                       SLV_ID_LSB_IDX      = ADDR_WIDTH - $clog2(SLV_AMT),
    // Dispatcher DATA depth configuration
    parameter                       DSP_RDATA_DEPTH     = 16
)
(
    // Input declaration
    // -- Global signals
    input                                   ACLK_i,
    input                                   ARESETn_i,
    // -- To Master (slave interface of the interconnect)
    // ---- Write address channel
    input   [TRANS_MST_ID_W*MST_AMT-1:0]    m_AWID_i,
    input   [ADDR_WIDTH*MST_AMT-1:0]        m_AWADDR_i,
    input   [TRANS_BURST_W*MST_AMT-1:0]     m_AWBURST_i,
    input   [TRANS_DATA_LEN_W*MST_AMT-1:0]  m_AWLEN_i,
    input   [TRANS_DATA_SIZE_W*MST_AMT-1:0] m_AWSIZE_i,
    input   [MST_AMT-1:0]                   m_AWVALID_i,
    // ---- Write data channel
    input   [DATA_WIDTH*MST_AMT-1:0]        m_WDATA_i,
    input   [MST_AMT-1:0]                   m_WLAST_i,
    input   [MST_AMT-1:0]                   m_WVALID_i,
    // ---- Write response channel
    input   [MST_AMT-1:0]                   m_BREADY_i,
    // ---- Read address channel
    input   [TRANS_MST_ID_W*MST_AMT-1:0]    m_ARID_i,
    input   [ADDR_WIDTH*MST_AMT-1:0]        m_ARADDR_i,
    input   [TRANS_BURST_W*MST_AMT-1:0]     m_ARBURST_i,
    input   [TRANS_DATA_LEN_W*MST_AMT-1:0]  m_ARLEN_i,
    input   [TRANS_DATA_SIZE_W*MST_AMT-1:0] m_ARSIZE_i,
    input   [MST_AMT-1:0]                   m_ARVALID_i,
    // ---- Read data channel
    input   [MST_AMT-1:0]                   m_RREADY_i,
    // -- To slave (master interface of the interconnect)
    // ---- Write address channel (master)
    input   [SLV_AMT-1:0]                   s_AWREADY_i,
    // ---- Write data channel (master)
    input   [SLV_AMT-1:0]                   s_WREADY_i,
    // ---- Write response channel (master)
    input   [TRANS_SLV_ID_W*SLV_AMT-1:0]    s_BID_i,
    input   [TRANS_WR_RESP_W*SLV_AMT-1:0]   s_BRESP_i,
    input   [SLV_AMT-1:0]                   s_BVALID_i,
    // ---- Read address channel (master)
    input   [SLV_AMT-1:0]                   s_ARREADY_i,
    // ---- Read data channel (master)
    input   [TRANS_SLV_ID_W*SLV_AMT-1:0]    s_RID_i,
    input   [DATA_WIDTH*SLV_AMT-1:0]        s_RDATA_i,
    input   [TRANS_WR_RESP_W*SLV_AMT-1:0]   s_RRESP_i,
    input   [SLV_AMT-1:0]                   s_RLAST_i,
    input   [SLV_AMT-1:0]                   s_RVALID_i,
    
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Write address channel (master)
    output  [MST_AMT-1:0]                   m_AWREADY_o,
    // ---- Write data channel (master)
    output  [MST_AMT-1:0]                   m_WREADY_o,
    // ---- Write response channel (master)
    output  [TRANS_MST_ID_W*MST_AMT-1:0]    m_BID_o,
    output  [TRANS_WR_RESP_W*MST_AMT-1:0]   m_BRESP_o,
    output  [MST_AMT-1:0]                   m_BVALID_o,
    // ---- Read address channel (master)
    output  [MST_AMT-1:0]                   m_ARREADY_o,
    // ---- Read data channel (master)
    output  [TRANS_MST_ID_W*MST_AMT-1:0]    m_RID_o,
    output  [DATA_WIDTH*MST_AMT-1:0]        m_RDATA_o,
    output  [TRANS_WR_RESP_W*MST_AMT-1:0]   m_RRESP_o,
    output  [MST_AMT-1:0]                   m_RLAST_o,
    output  [MST_AMT-1:0]                   m_RVALID_o,
    // -- To slave (master interface of the interconnect)
    // ---- Write address channel
    output  [TRANS_SLV_ID_W*SLV_AMT-1:0]    s_AWID_o,
    output  [ADDR_WIDTH*SLV_AMT-1:0]        s_AWADDR_o,
    output  [TRANS_BURST_W*SLV_AMT-1:0]     s_AWBURST_o,
    output  [TRANS_DATA_LEN_W*SLV_AMT-1:0]  s_AWLEN_o,
    output  [TRANS_DATA_SIZE_W*SLV_AMT-1:0] s_AWSIZE_o,
    output  [SLV_AMT-1:0]                   s_AWVALID_o,
    // ---- Write data channel
    output  [DATA_WIDTH*SLV_AMT-1:0]        s_WDATA_o,
    output  [SLV_AMT-1:0]                   s_WLAST_o,
    output  [SLV_AMT-1:0]                   s_WVALID_o,
    // ---- Write response channel          
    output  [SLV_AMT-1:0]                   s_BREADY_o,
    // ---- Read address channel            
    output  [TRANS_SLV_ID_W*SLV_AMT-1:0]    s_ARID_o,
    output  [ADDR_WIDTH*SLV_AMT-1:0]        s_ARADDR_o,
    output  [TRANS_BURST_W*SLV_AMT-1:0]     s_ARBURST_o,
    output  [TRANS_DATA_LEN_W*SLV_AMT-1:0]  s_ARLEN_o,
    output  [TRANS_DATA_SIZE_W*SLV_AMT-1:0] s_ARSIZE_o,
    output  [SLV_AMT-1:0]                   s_ARVALID_o,
    // ---- Read data channel
    output  [SLV_AMT-1:0]                   s_RREADY_o
);

    // Localparameter 

    // Internal variable declaration
    genvar mst_idx;
    genvar slv_idx;
    
    // Internal signal declaration
    // -- To Master
    // -- -- Input
    // -- -- -- Write address channel
    wire    [TRANS_MST_ID_W-1:0]    m_AWID      [MST_AMT-1:0];
    wire    [ADDR_WIDTH-1:0]        m_AWADDR    [MST_AMT-1:0];
    wire    [TRANS_BURST_W-1:0]     m_AWBURST   [MST_AMT-1:0];
    wire    [TRANS_DATA_LEN_W-1:0]  m_AWLEN     [MST_AMT-1:0];
    wire    [TRANS_DATA_SIZE_W-1:0] m_AWSIZE    [MST_AMT-1:0];
    wire                            m_AWVALID   [MST_AMT-1:0];
    // -- -- -- Write data channel
    wire    [DATA_WIDTH-1:0]        m_WDATA     [MST_AMT-1:0];
    wire                            m_WLAST     [MST_AMT-1:0];
    wire                            m_WVALID    [MST_AMT-1:0];
    // -- -- -- Write response channel
    wire                            m_BREADY    [MST_AMT-1:0];
    // -- -- -- Read address channel
    wire    [TRANS_MST_ID_W-1:0]    m_ARID      [MST_AMT-1:0];
    wire    [ADDR_WIDTH-1:0]        m_ARADDR    [MST_AMT-1:0];
    wire    [TRANS_BURST_W-1:0]     m_ARBURST   [MST_AMT-1:0];
    wire    [TRANS_DATA_LEN_W-1:0]  m_ARLEN     [MST_AMT-1:0];
    wire    [TRANS_DATA_SIZE_W-1:0] m_ARSIZE    [MST_AMT-1:0];
    wire                            m_ARVALID   [MST_AMT-1:0];
    // -- -- -- Read data channel
    wire                            m_RREADY    [MST_AMT-1:0];
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
    wire                            s_AWREADY   [SLV_AMT-1:0];
    // -- -- -- Write data channel (master)
    wire                            s_WREADY    [SLV_AMT-1:0];
    // -- -- -- Write response channel (master)
    wire    [TRANS_SLV_ID_W-1:0]    s_BID       [SLV_AMT-1:0];
    wire    [TRANS_WR_RESP_W-1:0]   s_BRESP     [SLV_AMT-1:0];
    wire                            s_BVALID    [SLV_AMT-1:0];
    // -- -- -- Read address channel (master)
    wire                            s_ARREADY   [SLV_AMT-1:0];
    // -- -- -- Read data channel (master)
    wire    [TRANS_SLV_ID_W-1:0]    s_RID       [SLV_AMT-1:0];
    wire    [DATA_WIDTH-1:0]        s_RDATA     [SLV_AMT-1:0];
    wire    [TRANS_WR_RESP_W-1:0]   s_RRESP     [SLV_AMT-1:0];
    wire                            s_RLAST     [SLV_AMT-1:0];
    wire                            s_RVALID    [SLV_AMT-1:0];
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
    // -- Dispatcher
    // -- -- Input
    // -- -- -- Write address channel (master)
    wire    [SLV_AMT-1:0]                   dsp_sa_AWREADY_i        [MST_AMT-1:0];
    // -- -- Write data channel (master)
    wire    [SLV_AMT-1:0]                   dsp_sa_WREADY_i         [MST_AMT-1:0];
    // -- -- Write response channel (master)
    wire    [TRANS_MST_ID_W*SLV_AMT-1:0]    dsp_sa_BID_i            [MST_AMT-1:0];
    wire    [TRANS_WR_RESP_W*SLV_AMT-1:0]   dsp_sa_BRESP_i          [MST_AMT-1:0];
    wire    [SLV_AMT-1:0]                   dsp_sa_BVALID_i         [MST_AMT-1:0];
    // -- -- -- Read address channel (master)  
    wire    [SLV_AMT-1:0]                   dsp_sa_ARREADY_i        [MST_AMT-1:0];
    // -- -- -- Read data channel (master)     
    wire    [TRANS_MST_ID_W*SLV_AMT-1:0]    dsp_sa_RID_i            [MST_AMT-1:0];
    wire    [DATA_WIDTH*SLV_AMT-1:0]        dsp_sa_RDATA_i          [MST_AMT-1:0];
    wire    [TRANS_WR_RESP_W*SLV_AMT-1:0]   dsp_sa_RRESP_i          [MST_AMT-1:0];
    wire    [SLV_AMT-1:0]                   dsp_sa_RLAST_i          [MST_AMT-1:0];
    wire    [SLV_AMT-1:0]                   dsp_sa_RVALID_i         [MST_AMT-1:0];
    // -- -- Output
    // -- -- -- Write address channel
    wire    [TRANS_MST_ID_W*SLV_AMT-1:0]    dsp_sa_AWID_o           [MST_AMT-1:0];
    wire    [ADDR_WIDTH*SLV_AMT-1:0]        dsp_sa_AWADDR_o         [MST_AMT-1:0];
    wire    [TRANS_BURST_W*SLV_AMT-1:0]     dsp_sa_AWBURST_o        [MST_AMT-1:0];
    wire    [TRANS_DATA_LEN_W*SLV_AMT-1:0]  dsp_sa_AWLEN_o          [MST_AMT-1:0];
    wire    [TRANS_DATA_SIZE_W*SLV_AMT-1:0] dsp_sa_AWSIZE_o         [MST_AMT-1:0];
    wire    [SLV_AMT-1:0]                   dsp_sa_AWVALID_o        [MST_AMT-1:0];
    wire    [SLV_AMT-1:0]                   dsp_sa_AW_outst_full_o  [MST_AMT-1:0];
    // -- -- -- Write data channel             
    wire    [DATA_WIDTH*SLV_AMT-1:0]        dsp_sa_WDATA_o          [MST_AMT-1:0];
    wire    [SLV_AMT-1:0]                   dsp_sa_WLAST_o          [MST_AMT-1:0];
    wire    [SLV_AMT-1:0]                   dsp_sa_WVALID_o         [MST_AMT-1:0];
    // -- -- -- Write response channel         
    wire    [SLV_AMT-1:0]                   dsp_sa_BREADY_o         [MST_AMT-1:0];
    // -- -- -- Read address channel           
    wire    [TRANS_MST_ID_W*SLV_AMT-1:0]    dsp_sa_ARID_o           [MST_AMT-1:0];
    wire    [ADDR_WIDTH*SLV_AMT-1:0]        dsp_sa_ARADDR_o         [MST_AMT-1:0];
    wire    [TRANS_BURST_W*SLV_AMT-1:0]     dsp_sa_ARBURST_o        [MST_AMT-1:0];
    wire    [TRANS_DATA_LEN_W*SLV_AMT-1:0]  dsp_sa_ARLEN_o          [MST_AMT-1:0];
    wire    [TRANS_DATA_SIZE_W*SLV_AMT-1:0] dsp_sa_ARSIZE_o         [MST_AMT-1:0];
    wire    [SLV_AMT-1:0]                   dsp_sa_ARVALID_o        [MST_AMT-1:0];
    wire    [SLV_AMT-1:0]                   dsp_sa_AR_outst_full_o  [MST_AMT-1:0];
    // -- -- -- Read data channel              
    wire    [SLV_AMT-1:0]                   dsp_sa_RREADY_o         [MST_AMT-1:0];
    // -- Slave Arbitration
    // -- -- Input
    // -- -- -- Write address channel
    wire    [TRANS_MST_ID_W*MST_AMT-1:0]    sa_dsp_AWID_i           [SLV_AMT-1:0];
    wire    [ADDR_WIDTH*MST_AMT-1:0]        sa_dsp_AWADDR_i         [SLV_AMT-1:0];
    wire    [TRANS_BURST_W*MST_AMT-1:0]     sa_dsp_AWBURST_i        [SLV_AMT-1:0];
    wire    [TRANS_DATA_LEN_W*MST_AMT-1:0]  sa_dsp_AWLEN_i          [SLV_AMT-1:0];
    wire    [TRANS_DATA_SIZE_W*MST_AMT-1:0] sa_dsp_AWSIZE_i         [SLV_AMT-1:0];
    wire    [MST_AMT-1:0]                   sa_dsp_AWVALID_i        [SLV_AMT-1:0];
    wire    [MST_AMT-1:0]                   sa_dsp_AW_outst_full_i  [SLV_AMT-1:0];
    // -- -- -- Write data channel
    wire    [DATA_WIDTH*MST_AMT-1:0]        sa_dsp_WDATA_i          [SLV_AMT-1:0];
    wire    [MST_AMT-1:0]                   sa_dsp_WLAST_i          [SLV_AMT-1:0];
    wire    [MST_AMT-1:0]                   sa_dsp_WVALID_i         [SLV_AMT-1:0];
    // -- -- -- Write response channel
    wire    [MST_AMT-1:0]                   sa_dsp_BREADY_i         [SLV_AMT-1:0];
    // -- -- -- Read address channel
    wire    [TRANS_MST_ID_W*MST_AMT-1:0]    sa_dsp_ARID_i           [SLV_AMT-1:0];
    wire    [ADDR_WIDTH*MST_AMT-1:0]        sa_dsp_ARADDR_i         [SLV_AMT-1:0];
    wire    [TRANS_BURST_W*MST_AMT-1:0]     sa_dsp_ARBURST_i        [SLV_AMT-1:0];
    wire    [TRANS_DATA_LEN_W*MST_AMT-1:0]  sa_dsp_ARLEN_i          [SLV_AMT-1:0];
    wire    [TRANS_DATA_SIZE_W*MST_AMT-1:0] sa_dsp_ARSIZE_i         [SLV_AMT-1:0];
    wire    [MST_AMT-1:0]                   sa_dsp_ARVALID_i        [SLV_AMT-1:0];
    wire    [MST_AMT-1:0]                   sa_dsp_AR_outst_full_i  [SLV_AMT-1:0];
    // -- -- -- Read data channel
    wire    [MST_AMT-1:0]                   sa_dsp_RREADY_i         [SLV_AMT-1:0];
    // -- -- Output 
    // -- -- -- Write address channel (master)
    wire    [MST_AMT-1:0]                   sa_dsp_AWREADY_o        [SLV_AMT-1:0];
    // -- -- -- Write data channel (master)     
    wire    [MST_AMT-1:0]                   sa_dsp_WREADY_o         [SLV_AMT-1:0];
    // -- -- -- Write response channel (master) 
    wire    [TRANS_MST_ID_W*MST_AMT-1:0]    sa_dsp_BID_o            [SLV_AMT-1:0];
    wire    [TRANS_WR_RESP_W*MST_AMT-1:0]   sa_dsp_BRESP_o          [SLV_AMT-1:0];
    wire    [MST_AMT-1:0]                   sa_dsp_BVALID_o         [SLV_AMT-1:0];
    // -- -- -- Read address channel (master)   
    wire    [MST_AMT-1:0]                   sa_dsp_ARREADY_o        [SLV_AMT-1:0];
    // -- -- -- Read data channel (master)      
    wire    [TRANS_MST_ID_W*MST_AMT-1:0]    sa_dsp_RID_o            [SLV_AMT-1:0];
    wire    [DATA_WIDTH*MST_AMT-1:0]        sa_dsp_RDATA_o          [SLV_AMT-1:0];
    wire    [TRANS_WR_RESP_W*MST_AMT-1:0]   sa_dsp_RRESP_o          [SLV_AMT-1:0];
    wire    [MST_AMT-1:0]                   sa_dsp_RLAST_o          [SLV_AMT-1:0];
    wire    [MST_AMT-1:0]                   sa_dsp_RVALID_o         [SLV_AMT-1:0];
    
    // Combinational logic
    generate
        // Port mapping (de-flatten)
        // -- To Master
        for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : MST_DEFLAT
            // -- -- AW channel
            // -- -- -- Input
            assign m_AWID[mst_idx]                                          = m_AWID_i[TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W];
            assign m_AWADDR[mst_idx]                                        = m_AWADDR_i[ADDR_WIDTH*(mst_idx+1)-1-:ADDR_WIDTH];
            assign m_AWBURST[mst_idx]                                       = m_AWBURST_i[TRANS_BURST_W*(mst_idx+1)-1-:TRANS_BURST_W];
            assign m_AWLEN[mst_idx]                                         = m_AWLEN_i[TRANS_DATA_LEN_W*(mst_idx+1)-1-:TRANS_DATA_LEN_W];
            assign m_AWSIZE[mst_idx]                                        = m_AWSIZE_i[TRANS_DATA_SIZE_W*(mst_idx+1)-1-:TRANS_DATA_SIZE_W];
            assign m_AWVALID[mst_idx]                                       = m_AWVALID_i[mst_idx];
            // -- -- -- Output
            assign m_AWREADY_o[mst_idx]                                     = m_AWREADY[mst_idx];
            // -- -- W channel
            // -- -- -- Input
            assign m_WDATA[mst_idx]                                         = m_WDATA_i[DATA_WIDTH*(mst_idx+1)-1-:DATA_WIDTH];
            assign m_WLAST[mst_idx]                                         = m_WLAST_i[mst_idx];
            assign m_WVALID[mst_idx]                                        = m_WVALID_i[mst_idx];
            // -- -- -- Output
            assign m_WREADY_o[mst_idx]                                      = m_WREADY[mst_idx];
            // -- -- B channel
            // -- -- -- Input
            assign m_BREADY[mst_idx]                                        = m_BREADY_i[mst_idx];
            // -- -- -- Output
            assign m_BID_o[TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W]    = m_BID[mst_idx];
            assign m_BRESP_o[TRANS_WR_RESP_W*(mst_idx+1)-1-:TRANS_WR_RESP_W]= m_BRESP[mst_idx];
            assign m_BVALID_o[mst_idx]                                      = m_BVALID[mst_idx];
            // -- -- AR channel
            // -- -- -- Input
            assign m_ARID[mst_idx]                                          = m_ARID_i[TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W];
            assign m_ARADDR[mst_idx]                                        = m_ARADDR_i[ADDR_WIDTH*(mst_idx+1)-1-:ADDR_WIDTH];
            assign m_ARBURST[mst_idx]                                       = m_ARBURST_i[TRANS_BURST_W*(mst_idx+1)-1-:TRANS_BURST_W];
            assign m_ARLEN[mst_idx]                                         = m_ARLEN_i[TRANS_DATA_LEN_W*(mst_idx+1)-1-:TRANS_DATA_LEN_W];
            assign m_ARSIZE[mst_idx]                                        = m_ARSIZE_i[TRANS_DATA_SIZE_W*(mst_idx+1)-1-:TRANS_DATA_SIZE_W];
            assign m_ARVALID[mst_idx]                                       = m_ARVALID_i[mst_idx];
            // -- -- -- Output
            assign m_ARREADY_o[mst_idx]                                     = m_ARREADY[mst_idx];
            // -- -- R channel
            // -- -- -- Input
            assign m_RREADY[mst_idx]                                        = m_RREADY_i[mst_idx];
            // -- -- -- Output
            assign m_RID_o[TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W]    = m_RID[mst_idx];
            assign m_RDATA_o[DATA_WIDTH*(mst_idx+1)-1-:DATA_WIDTH]          = m_RDATA[mst_idx];
            assign m_RRESP_o[TRANS_WR_RESP_W*(mst_idx+1)-1-:TRANS_WR_RESP_W]= m_RRESP[mst_idx];
            assign m_RLAST_o[mst_idx]                                       = m_RLAST[mst_idx];
            assign m_RVALID_o[mst_idx]                                      = m_RVALID[mst_idx];
        end
        // -- To Slave
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_DEFLAT
            // -- -- AW channel
            // -- -- -- Input
            assign s_AWREADY[slv_idx]                                               = s_AWREADY_i[slv_idx];
            // -- -- -- Output
            assign s_AWID_o[TRANS_SLV_ID_W*(slv_idx+1)-1-:TRANS_SLV_ID_W]           = s_AWID[slv_idx];
            assign s_AWADDR_o[ADDR_WIDTH*(slv_idx+1)-1-:ADDR_WIDTH]                 = s_AWADDR[slv_idx];
            assign s_AWBURST_o[TRANS_BURST_W*(slv_idx+1)-1-:TRANS_BURST_W]          = s_AWBURST[slv_idx];
            assign s_AWLEN_o[TRANS_DATA_LEN_W*(slv_idx+1)-1-:TRANS_DATA_LEN_W]      = s_AWLEN[slv_idx];
            assign s_AWSIZE_o[TRANS_DATA_SIZE_W*(slv_idx+1)-1-:TRANS_DATA_SIZE_W]   = s_AWSIZE[slv_idx];
            assign s_AWVALID_o[slv_idx]                                             = s_AWVALID[slv_idx];
            // -- -- W channel
            // -- -- -- Input
            assign s_WREADY[slv_idx]                                                = s_WREADY_i[slv_idx];
            // -- -- -- Output
            assign s_WDATA_o[DATA_WIDTH*(slv_idx+1)-1-:DATA_WIDTH]                  = s_WDATA[slv_idx];
            assign s_WLAST_o[slv_idx]                                               = s_WLAST[slv_idx];
            assign s_WVALID_o[slv_idx]                                              = s_WVALID[slv_idx];
            // -- -- B channel
            // -- -- -- Input
            assign s_BID[slv_idx]                                                   = s_BID_i[TRANS_SLV_ID_W*(slv_idx+1)-1-:TRANS_SLV_ID_W];
            assign s_BRESP[slv_idx]                                                 = s_BRESP_i[TRANS_WR_RESP_W*(slv_idx+1)-1-:TRANS_WR_RESP_W];
            assign s_BVALID[slv_idx]                                                = s_BVALID_i[slv_idx];
            // -- -- -- Output
            assign s_BREADY_o[slv_idx]                                              = s_BREADY[slv_idx];
            // -- -- AR channel
            // -- -- -- Input
            assign s_ARREADY[slv_idx] = s_ARREADY_i[slv_idx];
            // -- -- -- Output
            assign s_ARID_o[TRANS_SLV_ID_W*(slv_idx+1)-1-:TRANS_SLV_ID_W]           = s_ARID[slv_idx];
            assign s_ARADDR_o[ADDR_WIDTH*(slv_idx+1)-1-:ADDR_WIDTH]                 = s_ARADDR[slv_idx];
            assign s_ARBURST_o[TRANS_BURST_W*(slv_idx+1)-1-:TRANS_BURST_W]          = s_ARBURST[slv_idx];
            assign s_ARLEN_o[TRANS_DATA_LEN_W*(slv_idx+1)-1-:TRANS_DATA_LEN_W]      = s_ARLEN[slv_idx];
            assign s_ARSIZE_o[TRANS_DATA_SIZE_W*(slv_idx+1)-1-:TRANS_DATA_SIZE_W]   = s_ARSIZE[slv_idx];
            assign s_ARVALID_o[slv_idx]                                             = s_ARVALID[slv_idx];
            // -- -- R channel
            // -- -- -- Input
            assign s_RID[slv_idx]                                                   = s_RID_i[TRANS_SLV_ID_W*(slv_idx+1)-1-:TRANS_SLV_ID_W];
            assign s_RDATA[slv_idx]                                                 = s_RDATA_i[DATA_WIDTH*(slv_idx+1)-1-:DATA_WIDTH];
            assign s_RRESP[slv_idx]                                                 = s_RRESP_i[TRANS_WR_RESP_W*(slv_idx+1)-1-:TRANS_WR_RESP_W];
            assign s_RLAST[slv_idx]                                                 = s_RLAST_i[slv_idx];
            assign s_RVALID[slv_idx]                                                = s_RVALID_i[slv_idx];
            // -- -- -- Output
            assign s_RREADY_o[slv_idx]                                              = s_RREADY[slv_idx];
        end
        // -- Internal connectio 
        for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : NETWORK_CONNECTION
            for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SUB_NETWORK_CONNECTION
            // -- -- Slave Arbitration to Dispatcher
            assign dsp_sa_AWREADY_i[mst_idx][slv_idx]                                           = sa_dsp_AWREADY_o[slv_idx][mst_idx];
            assign dsp_sa_WREADY_i[mst_idx][slv_idx]                                            = sa_dsp_WREADY_o[slv_idx][mst_idx];
            assign dsp_sa_BID_i[mst_idx][TRANS_MST_ID_W*(slv_idx+1)-1-:TRANS_MST_ID_W]          = sa_dsp_BID_o[slv_idx][TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W];
            assign dsp_sa_BRESP_i[mst_idx][TRANS_WR_RESP_W*(slv_idx+1)-1-:TRANS_WR_RESP_W]      = sa_dsp_BRESP_o[slv_idx][TRANS_WR_RESP_W*(mst_idx+1)-1-:TRANS_WR_RESP_W];
            assign dsp_sa_BVALID_i[mst_idx][slv_idx]                                            = sa_dsp_BVALID_o[slv_idx][mst_idx];
            assign dsp_sa_ARREADY_i[mst_idx][slv_idx]                                           = sa_dsp_ARREADY_o[slv_idx][mst_idx];
            assign dsp_sa_RID_i[mst_idx][TRANS_MST_ID_W*(slv_idx+1)-1-:TRANS_MST_ID_W]          = sa_dsp_RID_o[slv_idx][TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W];
            assign dsp_sa_RDATA_i[mst_idx][DATA_WIDTH*(slv_idx+1)-1-:DATA_WIDTH]                = sa_dsp_RDATA_o[slv_idx][DATA_WIDTH*(mst_idx+1)-1-:DATA_WIDTH];
            assign dsp_sa_RRESP_i[mst_idx][TRANS_WR_RESP_W*(slv_idx+1)-1-:TRANS_WR_RESP_W]      = sa_dsp_RRESP_o[slv_idx][TRANS_WR_RESP_W*(mst_idx+1)-1-:TRANS_WR_RESP_W];
            assign dsp_sa_RLAST_i[mst_idx][slv_idx]                                             = sa_dsp_RLAST_o[slv_idx][mst_idx];
            assign dsp_sa_RVALID_i[mst_idx][slv_idx]                                            = sa_dsp_RVALID_o[slv_idx][mst_idx];
            // -- -- Dispatcher to Slave Arbitration
            assign sa_dsp_AWID_i[slv_idx][TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W]         = dsp_sa_AWID_o[mst_idx][TRANS_MST_ID_W*(slv_idx+1)-1-:TRANS_MST_ID_W];
            assign sa_dsp_AWADDR_i[slv_idx][ADDR_WIDTH*(mst_idx+1)-1-:ADDR_WIDTH]               = dsp_sa_AWADDR_o[mst_idx][ADDR_WIDTH*(slv_idx+1)-1-:ADDR_WIDTH];
            assign sa_dsp_AWBURST_i[slv_idx][TRANS_BURST_W*(mst_idx+1)-1-:TRANS_BURST_W]        = dsp_sa_AWBURST_o[mst_idx][TRANS_BURST_W*(slv_idx+1)-1-:TRANS_BURST_W];
            assign sa_dsp_AWLEN_i[slv_idx][TRANS_DATA_LEN_W*(mst_idx+1)-1-:TRANS_DATA_LEN_W]    = dsp_sa_AWLEN_o[mst_idx][TRANS_DATA_LEN_W*(slv_idx+1)-1-:TRANS_DATA_LEN_W];
            assign sa_dsp_AWSIZE_i[slv_idx][TRANS_DATA_SIZE_W*(mst_idx+1)-1-:TRANS_DATA_SIZE_W] = dsp_sa_AWSIZE_o[mst_idx][TRANS_DATA_SIZE_W*(slv_idx+1)-1-:TRANS_DATA_SIZE_W];
            assign sa_dsp_AWVALID_i[slv_idx][mst_idx]                                           = dsp_sa_AWVALID_o[mst_idx][slv_idx];
            assign sa_dsp_AW_outst_full_i[slv_idx][mst_idx]                                     = dsp_sa_AW_outst_full_o[mst_idx][slv_idx];
            assign sa_dsp_WDATA_i[slv_idx][DATA_WIDTH*(mst_idx+1)-1-:DATA_WIDTH]                = dsp_sa_WDATA_o[mst_idx][DATA_WIDTH*(slv_idx+1)-1-:DATA_WIDTH];
            assign sa_dsp_WLAST_i[slv_idx][mst_idx]                                             = dsp_sa_WLAST_o[mst_idx][slv_idx];
            assign sa_dsp_WVALID_i[slv_idx][mst_idx]                                            = dsp_sa_WVALID_o[mst_idx][slv_idx];
            assign sa_dsp_BREADY_i[slv_idx][mst_idx]                                            = dsp_sa_BREADY_o[mst_idx][slv_idx];
            assign sa_dsp_ARID_i[slv_idx][TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W]         = dsp_sa_ARID_o[mst_idx][TRANS_MST_ID_W*(slv_idx+1)-1-:TRANS_MST_ID_W];
            assign sa_dsp_ARADDR_i[slv_idx][ADDR_WIDTH*(mst_idx+1)-1-:ADDR_WIDTH]               = dsp_sa_ARADDR_o[mst_idx][ADDR_WIDTH*(slv_idx+1)-1-:ADDR_WIDTH];
            assign sa_dsp_ARBURST_i[slv_idx][TRANS_BURST_W*(mst_idx+1)-1-:TRANS_BURST_W]        = dsp_sa_ARBURST_o[mst_idx][TRANS_BURST_W*(slv_idx+1)-1-:TRANS_BURST_W];
            assign sa_dsp_ARLEN_i[slv_idx][TRANS_DATA_LEN_W*(mst_idx+1)-1-:TRANS_DATA_LEN_W]    = dsp_sa_ARLEN_o[mst_idx][TRANS_DATA_LEN_W*(slv_idx+1)-1-:TRANS_DATA_LEN_W];
            assign sa_dsp_ARSIZE_i[slv_idx][TRANS_DATA_SIZE_W*(mst_idx+1)-1-:TRANS_DATA_SIZE_W] = dsp_sa_ARSIZE_o[mst_idx][TRANS_DATA_SIZE_W*(slv_idx+1)-1-:TRANS_DATA_SIZE_W];
            assign sa_dsp_ARVALID_i[slv_idx][mst_idx]                                           = dsp_sa_ARVALID_o[mst_idx][slv_idx];
            assign sa_dsp_AR_outst_full_i[slv_idx][mst_idx]                                     = dsp_sa_AR_outst_full_o[mst_idx][slv_idx];
            assign sa_dsp_RREADY_i[slv_idx][mst_idx]                                            = dsp_sa_RREADY_o[mst_idx][slv_idx];
            end
        end     
    endgenerate
    
    // Internal module
    generate
        for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : DSP_GEN
            ai_dispatcher #(
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
                .SLV_ID_LSB_IDX(SLV_ID_LSB_IDX),
                .DSP_RDATA_DEPTH(DSP_RDATA_DEPTH)
            ) dispatcher (
                .ACLK_i(ACLK_i),
                .ARESETn_i(ARESETn_i),
                .m_AWID_i(m_AWID[mst_idx]),
                .m_AWADDR_i(m_AWADDR[mst_idx]),
                .m_AWBURST_i(m_AWBURST[mst_idx]),
                .m_AWLEN_i(m_AWLEN[mst_idx]),
                .m_AWSIZE_i(m_AWSIZE[mst_idx]),
                .m_AWVALID_i(m_AWVALID[mst_idx]),
                .m_WDATA_i(m_WDATA[mst_idx]),
                .m_WLAST_i(m_WLAST[mst_idx]),
                .m_WVALID_i(m_WVALID[mst_idx]),
                .m_BREADY_i(m_BREADY[mst_idx]),
                .m_ARID_i(m_ARID[mst_idx]),
                .m_ARADDR_i(m_ARADDR[mst_idx]),
                .m_ARBURST_i(m_ARBURST[mst_idx]),
                .m_ARLEN_i(m_ARLEN[mst_idx]),
                .m_ARSIZE_i(m_ARSIZE[mst_idx]),
                .m_ARVALID_i(m_ARVALID[mst_idx]),
                .m_RREADY_i(m_RREADY[mst_idx]),
                .sa_AWREADY_i(dsp_sa_AWREADY_i[mst_idx]),
                .sa_WREADY_i(dsp_sa_WREADY_i[mst_idx]),
                .sa_BID_i(dsp_sa_BID_i[mst_idx]),
                .sa_BRESP_i(dsp_sa_BRESP_i[mst_idx]),
                .sa_BVALID_i(dsp_sa_BVALID_i[mst_idx]),
                .sa_ARREADY_i(dsp_sa_ARREADY_i[mst_idx]),
                .sa_RID_i(dsp_sa_RID_i[mst_idx]),
                .sa_RDATA_i(dsp_sa_RDATA_i[mst_idx]),
                .sa_RRESP_i(dsp_sa_RRESP_i[mst_idx]),
                .sa_RLAST_i(dsp_sa_RLAST_i[mst_idx]),
                .sa_RVALID_i(dsp_sa_RVALID_i[mst_idx]),
                .m_AWREADY_o(m_AWREADY[mst_idx]),
                .m_WREADY_o(m_WREADY[mst_idx]),
                .m_BID_o(m_BID[mst_idx]),
                .m_BRESP_o(m_BRESP[mst_idx]),
                .m_BVALID_o(m_BVALID[mst_idx]),
                .m_ARREADY_o(m_ARREADY[mst_idx]),
                .m_RID_o(m_RID[mst_idx]),
                .m_RDATA_o(m_RDATA[mst_idx]),
                .m_RRESP_o(m_RRESP[mst_idx]),
                .m_RLAST_o(m_RLAST[mst_idx]),
                .m_RVALID_o(m_RVALID[mst_idx]),
                .sa_AWID_o(dsp_sa_AWID_o[mst_idx]),
                .sa_AWADDR_o(dsp_sa_AWADDR_o[mst_idx]),
                .sa_AWBURST_o(dsp_sa_AWBURST_o[mst_idx]),
                .sa_AWLEN_o(dsp_sa_AWLEN_o[mst_idx]),
                .sa_AWSIZE_o(dsp_sa_AWSIZE_o[mst_idx]),
                .sa_AWVALID_o(dsp_sa_AWVALID_o[mst_idx]),
                .sa_AW_outst_full_o(dsp_sa_AW_outst_full_o[mst_idx]),
                .sa_WDATA_o(dsp_sa_WDATA_o[mst_idx]),
                .sa_WLAST_o(dsp_sa_WLAST_o[mst_idx]),
                .sa_WVALID_o(dsp_sa_WVALID_o[mst_idx]),
                .sa_BREADY_o(dsp_sa_BREADY_o[mst_idx]),
                .sa_ARID_o(dsp_sa_ARID_o[mst_idx]),
                .sa_ARADDR_o(dsp_sa_ARADDR_o[mst_idx]),
                .sa_ARBURST_o(dsp_sa_ARBURST_o[mst_idx]),
                .sa_ARLEN_o(dsp_sa_ARLEN_o[mst_idx]),
                .sa_ARSIZE_o(dsp_sa_ARSIZE_o[mst_idx]),
                .sa_ARVALID_o(dsp_sa_ARVALID_o[mst_idx]),
                .sa_AR_outst_full_o(dsp_sa_AR_outst_full_o[mst_idx]),
                .sa_RREADY_o(dsp_sa_RREADY_o[mst_idx])
            );
        end
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SA_GEN
            if(MST_AMT > 1) begin   // Multiple masters -> Need arbitrate between masters
                ai_slave_arbitration #(
                    .MST_AMT(MST_AMT),
                    .OUTSTANDING_AMT(OUTSTANDING_AMT),
                    .MST_WEIGHT(MST_WEIGHT),
                    .MST_ID_W(MST_ID_W),
                    .DATA_WIDTH(DATA_WIDTH),
                    .ADDR_WIDTH(ADDR_WIDTH),
                    .TRANS_MST_ID_W(TRANS_MST_ID_W),
                    .TRANS_SLV_ID_W(TRANS_SLV_ID_W),
                    .TRANS_BURST_W(TRANS_BURST_W),
                    .TRANS_DATA_LEN_W(TRANS_DATA_LEN_W),
                    .TRANS_DATA_SIZE_W(TRANS_DATA_SIZE_W),
                    .TRANS_WR_RESP_W(TRANS_WR_RESP_W),
                    .SLV_ID(slv_idx),
                    .SLV_ID_MSB_IDX(SLV_ID_MSB_IDX),
                    .SLV_ID_LSB_IDX(SLV_ID_LSB_IDX)
                ) slave_arbitration (
                    .ACLK_i(ACLK_i),
                    .ARESETn_i(ARESETn_i),
                    .dsp_AWID_i(sa_dsp_AWID_i[slv_idx]),
                    .dsp_AWADDR_i(sa_dsp_AWADDR_i[slv_idx]),
                    .dsp_AWBURST_i(sa_dsp_AWBURST_i[slv_idx]),
                    .dsp_AWLEN_i(sa_dsp_AWLEN_i[slv_idx]),
                    .dsp_AWSIZE_i(sa_dsp_AWSIZE_i[slv_idx]),
                    .dsp_AWVALID_i(sa_dsp_AWVALID_i[slv_idx]),
                    .dsp_AW_outst_full_i(sa_dsp_AW_outst_full_i[slv_idx]),
                    .dsp_WDATA_i(sa_dsp_WDATA_i[slv_idx]),
                    .dsp_WLAST_i(sa_dsp_WLAST_i[slv_idx]),
                    .dsp_WVALID_i(sa_dsp_WVALID_i[slv_idx]),
                    .dsp_slv_sel_i({MST_AMT{1'b1}}),   // Move this encoding logic to Dispatcher module 
                    .dsp_BREADY_i(sa_dsp_BREADY_i[slv_idx]),
                    .dsp_ARID_i(sa_dsp_ARID_i[slv_idx]),
                    .dsp_ARADDR_i(sa_dsp_ARADDR_i[slv_idx]),
                    .dsp_ARBURST_i(sa_dsp_ARBURST_i[slv_idx]),
                    .dsp_ARLEN_i(sa_dsp_ARLEN_i[slv_idx]),
                    .dsp_ARSIZE_i(sa_dsp_ARSIZE_i[slv_idx]),
                    .dsp_ARVALID_i(sa_dsp_ARVALID_i[slv_idx]),
                    .dsp_AR_outst_full_i(sa_dsp_AR_outst_full_i[slv_idx]),
                    .dsp_RREADY_i(sa_dsp_RREADY_i[slv_idx]),
                    .s_AWREADY_i(s_AWREADY[slv_idx]),
                    .s_WREADY_i(s_WREADY[slv_idx]),
                    .s_BID_i(s_BID[slv_idx]),
                    .s_BRESP_i(s_BRESP[slv_idx]),
                    .s_BVALID_i(s_BVALID[slv_idx]),
                    .s_ARREADY_i(s_ARREADY[slv_idx]),
                    .s_RID_i(s_RID[slv_idx]),
                    .s_RDATA_i(s_RDATA[slv_idx]),
                    .s_RRESP_i(s_RRESP[slv_idx]),
                    .s_RLAST_i(s_RLAST[slv_idx]),
                    .s_RVALID_i(s_RVALID[slv_idx]),
                    .dsp_AWREADY_o(sa_dsp_AWREADY_o[slv_idx]),
                    .dsp_WREADY_o(sa_dsp_WREADY_o[slv_idx]),
                    .dsp_BID_o(sa_dsp_BID_o[slv_idx]),
                    .dsp_BRESP_o(sa_dsp_BRESP_o[slv_idx]),
                    .dsp_BVALID_o(sa_dsp_BVALID_o[slv_idx]),
                    .dsp_ARREADY_o(sa_dsp_ARREADY_o[slv_idx]),
                    .dsp_RID_o(sa_dsp_RID_o[slv_idx]),
                    .dsp_RDATA_o(sa_dsp_RDATA_o[slv_idx]),
                    .dsp_RRESP_o(sa_dsp_RRESP_o[slv_idx]),
                    .dsp_RLAST_o(sa_dsp_RLAST_o[slv_idx]),
                    .dsp_RVALID_o(sa_dsp_RVALID_o[slv_idx]),
                    .s_AWID_o(s_AWID[slv_idx]),
                    .s_AWADDR_o(s_AWADDR[slv_idx]),
                    .s_AWBURST_o(s_AWBURST[slv_idx]),
                    .s_AWLEN_o(s_AWLEN[slv_idx]),
                    .s_AWSIZE_o(s_AWSIZE[slv_idx]),
                    .s_AWVALID_o(s_AWVALID[slv_idx]),
                    .s_WDATA_o(s_WDATA[slv_idx]),
                    .s_WLAST_o(s_WLAST[slv_idx]),
                    .s_WVALID_o(s_WVALID[slv_idx]),
                    .s_BREADY_o(s_BREADY[slv_idx]),
                    .s_ARID_o(s_ARID[slv_idx]),
                    .s_ARADDR_o(s_ARADDR[slv_idx]),
                    .s_ARBURST_o(s_ARBURST[slv_idx]),
                    .s_ARLEN_o(s_ARLEN[slv_idx]),
                    .s_ARSIZE_o(s_ARSIZE[slv_idx]),
                    .s_ARVALID_o(s_ARVALID[slv_idx]),
                    .s_RREADY_o(s_RREADY[slv_idx])
                );
            end 
            else begin      // Single Master -> Do not need to arbitrate between master
                // Bypass
                assign s_AWID[slv_idx]              = sa_dsp_AWID_i[slv_idx];
                assign s_AWADDR[slv_idx]            = sa_dsp_AWADDR_i[slv_idx];
                assign s_AWBURST[slv_idx]           = sa_dsp_AWBURST_i[slv_idx];
                assign s_AWLEN[slv_idx]             = sa_dsp_AWLEN_i[slv_idx];
                assign s_AWSIZE[slv_idx]            = sa_dsp_AWSIZE_i[slv_idx];
                assign s_AWVALID[slv_idx]           = sa_dsp_AWVALID_i[slv_idx];
                assign sa_dsp_AWREADY_o[slv_idx]    = s_AWREADY[slv_idx];

                assign s_WDATA[slv_idx]             = sa_dsp_WDATA_i[slv_idx];
                assign s_WLAST[slv_idx]             = sa_dsp_WLAST_i[slv_idx];
                assign s_WVALID[slv_idx]            = sa_dsp_WVALID_i[slv_idx];
                assign sa_dsp_WREADY_o[slv_idx]     = s_WREADY[slv_idx];

                assign sa_dsp_BID_o[slv_idx]        = s_BID[slv_idx];
                assign sa_dsp_BRESP_o[slv_idx]      = s_BRESP[slv_idx];
                assign sa_dsp_BVALID_o[slv_idx]     = s_BVALID[slv_idx];
                assign s_BREADY[slv_idx]            = sa_dsp_BREADY_i[slv_idx];

                assign s_ARID[slv_idx]              = sa_dsp_ARID_i[slv_idx];
                assign s_ARADDR[slv_idx]            = sa_dsp_ARADDR_i[slv_idx];
                assign s_ARBURST[slv_idx]           = sa_dsp_ARBURST_i[slv_idx];
                assign s_ARLEN[slv_idx]             = sa_dsp_ARLEN_i[slv_idx];
                assign s_ARSIZE[slv_idx]            = sa_dsp_ARSIZE_i[slv_idx];
                assign s_ARVALID[slv_idx]           = sa_dsp_ARVALID_i[slv_idx];
                assign sa_dsp_ARREADY_o[slv_idx]    = s_ARREADY[slv_idx];

                assign sa_dsp_RID_o[slv_idx]        = s_RID[slv_idx];
                assign sa_dsp_RDATA_o[slv_idx]      = s_RDATA[slv_idx];
                assign sa_dsp_RRESP_o[slv_idx]      = s_RRESP[slv_idx];
                assign sa_dsp_RLAST_o[slv_idx]      = s_RLAST[slv_idx];
                assign sa_dsp_RVALID_o[slv_idx]     = s_RVALID[slv_idx];
                assign s_RREADY[slv_idx]            = sa_dsp_RREADY_i[slv_idx];
            end
        end
        
    endgenerate

endmodule
