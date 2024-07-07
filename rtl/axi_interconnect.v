module axi_interconnect
#(
    // Interconnect configuration
    parameter                       MST_AMT             = 3,
    parameter                       SLV_AMT             = 2,
    parameter                       OUTSTANDING_AMT     = 8,
    parameter [0:(MST_AMT*32)-1]    MST_WEIGHT          = {32'd5, 32'd3, 32'd2},
    parameter                       MST_ID_W            = $clog2(MST_AMT),
    parameter                       SLV_ID_W            = $clog2(SLV_AMT),
    // Transaction configuration
    parameter                       DATA_WIDTH          = 32,
    parameter                       ADDR_WIDTH          = 32,
    parameter                       TRANS_MST_ID_W      = 5,                            // Bus width of master transaction ID 
    parameter                       TRANS_SLV_ID_W      = TRANS_MST_ID_W + MST_ID_W,    // Bus width of slave transaction ID
    parameter                       TRANS_DATA_LEN_W    = 3,                            // Bus width of xLEN
    parameter                       TRANS_DATA_SIZE_W   = 3,                            // Bus width of xSIZE
    parameter                       TRANS_WR_RESP_W     = 2,
    // Slave info configuration (address mapping mechanism)
    parameter   [0:(SLV_AMT*32)-1]  SLV_ID              = {32'd0, 32'd1, 32'd2},
    parameter                       SLV_ID_MSB_IDX      = 30,
    parameter                       SLV_ID_LSB_IDX      = 30
)
(
    // Input declaration
    // -- Global signals
    input                                   ACLK_i,
    input                                   ARESETn_i,
    // -- To Master (slave interface of the interconnect)
    // ---- Write address channel
    input   [0:TRANS_MST_ID_W*MST_AMT-1]    m_AWID_i,
    input   [0:ADDR_WIDTH*MST_AMT-1]        m_AWADDR_i,
    input   [0:TRANS_DATA_LEN_W*MST_AMT-1]  m_AWLEN_i,
    input   [0:TRANS_DATA_SIZE_W*MST_AMT-1] m_AWSIZE_i,
    input   [0:MST_AMT-1]                   m_AWVALID_i,
    // ---- Write data channel
    input   [0:DATA_WIDTH*MST_AMT-1]        m_WDATA_i,
    input   [0:MST_AMT-1]                   m_WLAST_i,
    input   [0:MST_AMT-1]                   m_WVALID_i,
    // ---- Write response channel
    input   [0:MST_AMT-1]                   m_BREADY_i,
    // ---- Read address channel
    input   [0:TRANS_MST_ID_W*MST_AMT-1]    m_ARID_i,
    input   [0:ADDR_WIDTH*MST_AMT-1]        m_ARADDR_i,
    input   [0:TRANS_DATA_LEN_W*MST_AMT-1]  m_ARLEN_i,
    input   [0:TRANS_DATA_SIZE_W*MST_AMT-1] m_ARSIZE_i,
    input   [0:MST_AMT-1]                   m_ARVALID_i,
    // ---- Read data channel
    input   [0:MST_AMT-1]                   m_RREADY_i,
    // -- To slave (master interface of the interconnect)
    // ---- Write address channel (master)
    input   [0:SLV_AMT-1]                   s_AWREADY_i,
    // ---- Write data channel (master)
    input   [0:SLV_AMT-1]                   s_WREADY_i,
    // ---- Write response channel (master)
    input   [0:TRANS_SLV_ID_W*SLV_AMT-1]    s_BID_i,
    input   [0:TRANS_WR_RESP_W*SLV_AMT-1]   s_BRESP_i,
    input                                   s_BVALID_i,
    // ---- Read address channel (master)
    input   [0:SLV_AMT-1]                   s_ARREADY_i,
    // ---- Read data channel (master)
    input   [0:TRANS_SLV_ID_W*SLV_AMT-1]    s_RID_i,
    input   [0:DATA_WIDTH*SLV_AMT-1]        s_RDATA_i,
    input   [0:SLV_AMT-1]                   s_RLAST_i,
    input   [0:SLV_AMT-1]                   s_RVALID_i,
    
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Write address channel (master)
    output  [0:MST_AMT-1]                   m_AWREADY_o,
    // ---- Write data channel (master)
    output  [0:MST_AMT-1]                   m_WREADY_o,
    // ---- Write response channel (master)
    output  [0:TRANS_MST_ID_W*MST_AMT-1]    m_BID_o,
    output  [0:TRANS_WR_RESP_W*MST_AMT-1]   m_BRESP_o,
    output  [0:MST_AMT-1]                   m_BVALID_o,
    // ---- Read address channel (master)
    output  [0:MST_AMT-1]                   m_ARREADY_o,
    // ---- Read data channel (master)
    output  [0:TRANS_MST_ID_W*MST_AMT-1]    m_RID_o,
    output  [0:DATA_WIDTH*MST_AMT-1]        m_RDATA_o,
    output  [0:MST_AMT-1]                   m_RLAST_o,
    output  [0:MST_AMT-1]                   m_RVALID_o,
    // -- To slave (master interface of the interconnect)
    // ---- Write address channel
    output  [0:TRANS_SLV_ID_W*SLV_AMT-1]    s_AWID_o,
    output  [0:ADDR_WIDTH*SLV_AMT-1]        s_AWADDR_o,
    output  [0:TRANS_DATA_LEN_W*SLV_AMT-1]  s_AWLEN_o,
    output  [0:TRANS_DATA_SIZE_W*SLV_AMT-1] s_AWSIZE_o,
    output  [0:SLV_AMT-1]                   s_AWVALID_o,
    // ---- Write data channel
    output  [0:DATA_WIDTH*SLV_AMT-1]        s_WDATA_o,
    output  [0:SLV_AMT-1]                   s_WLAST_o,
    output  [0:SLV_AMT-1]                   s_WVALID_o,
    // ---- Write response channel          
    output                                  s_BREADY_o,
    // ---- Read address channel            
    output  [0:TRANS_SLV_ID_W*SLV_AMT-1]    s_ARID_o,
    output  [0:ADDR_WIDTH*SLV_AMT-1]        s_ARADDR_o,
    output  [0:TRANS_DATA_LEN_W*SLV_AMT-1]  s_ARLEN_o,
    output  [0:TRANS_DATA_SIZE_W*SLV_AMT-1] s_ARSIZE_o,
    output  [0:SLV_AMT-1]                   s_ARVALID_o,
    // ---- Read data channel
    output  [0:SLV_AMT-1]                   s_RREADY_o
);

    // Localparameter 
    
    // Internal variable declaration
    genvar dsp_gen;
    genvar slv_arb_gen;
    
    generate
        for(dsp_gen = 0; dsp_gen < MST_AMT; dsp_gen = dsp_gen + 1) begin
            ai_dispatcher #(
                .SLV_AMT(SLV_AMT),  
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .TRANS_MST_ID_W(TRANS_MST_ID_W),
                .TRANS_DATA_LEN_W(TRANS_DATA_LEN_W),
                .TRANS_DATA_SIZE_W(TRANS_DATA_SIZE_W),
                .TRANS_WR_RESP_W(TRANS_WR_RESP_W)
            ) dispatcher (
                .ACLK_i(ACLK_i),
                .ARESETn_i(ARESETn_i)
            );
        end
        for(slv_arb_gen = 0; slv_arb_gen < SLV_AMT; slv_arb_gen = slv_arb_gen + 1) begin
            ai_slave_arbitration #(
                .MST_AMT(MST_AMT),  
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .TRANS_MST_ID_W(TRANS_MST_ID_W),
                .TRANS_SLV_ID_W(TRANS_SLV_ID_W),
                .TRANS_DATA_LEN_W(TRANS_DATA_LEN_W),
                .TRANS_DATA_SIZE_W(TRANS_DATA_SIZE_W),
                .TRANS_WR_RESP_W(TRANS_WR_RESP_W)
            ) slave_arbitration (
                .ACLK_i(ACLK_i),
                .ARESETn_i(ARESETn_i)
            );
        end
        
    endgenerate

endmodule
