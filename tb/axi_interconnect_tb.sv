`timescale 1ns / 1ps
module axi_interconnect_tb;
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
    
    initial begin localparam mst_idx = 0;
        m_AWID[mst_idx]    <= 0;m_AWADDR[mst_idx]  <= {2'b00, 30'd0};m_AWBURST[mst_idx] <= 0;m_AWLEN[mst_idx]   <= 0;m_AWSIZE[mst_idx]  <= 0;
        m_AWVALID[mst_idx] <= 0;
        
        m_WDATA[mst_idx]  <= 0;m_WLAST[mst_idx]  <= 0;
        m_WVALID[mst_idx] <= 0;
        
        m_BREADY[mst_idx] <= 0;
    end
    
    initial begin localparam mst_idx = 0;
        m_ARID[mst_idx]     <= 0;
        m_ARADDR[mst_idx]   <= 0;
        m_ARBURST[mst_idx]  <= 0;
        m_ARLEN[mst_idx]    <= 0;
        m_ARSIZE[mst_idx]   <= 0;
        m_ARVALID[mst_idx]  <= 0;
        
        m_RREADY[mst_idx]   <= 0;
    end
    
endmodule