`timescale 1ns / 1ps
module dsp_WADDR_channel_tb;
    // Dispatcher configuration
    parameter SLV_AMT           = 2;
    parameter OUTSTANDING_AMT   = 8;
    // Transaction configuration
    parameter DATA_WIDTH        = 32;
    parameter ADDR_WIDTH        = 32;
    parameter TRANS_MST_ID_W    = 5;    // Bus width of master transaction ID 
    parameter TRANS_BURST_W     = 2;    // Width of xBURST 
    parameter TRANS_DATA_LEN_W  = 3;    // Bus width of xLEN
    parameter TRANS_DATA_SIZE_W = 3;    // Bus width of xSIZE
    parameter TRANS_WR_RESP_W   = 2;
    // Slave configuration
    parameter SLV_ID_W          = $clog2(SLV_AMT);
    parameter SLV_ID_MSB_IDX    = 30;
    parameter SLV_ID_LSB_IDX    = 30;
    
    // Input declaration
    // -- Global signals
    logic                                   ACLK_i;
    logic                                   ARESETn_i;
    // -- To Master (slave interface of the interconnect)
    // ---- Write address channel
    logic   [TRANS_MST_ID_W-1:0]            m_AWID_i;
    logic   [ADDR_WIDTH-1:0]                m_AWADDR_i;
    logic   [TRANS_BURST_W-1:0]             m_AWBURST_i;
    logic   [TRANS_DATA_LEN_W-1:0]          m_AWLEN_i;
    logic   [TRANS_DATA_SIZE_W-1:0]         m_AWSIZE_i;
    logic                                   m_AWVALID_i;
    // -- To WDATA channel Dispatcher
    logic                                   m_WVALID_i;
    logic                                   m_WREADY_i;
    // -- To Slave Arbitration
    // ---- Write address channel (master)
    logic   [SLV_AMT-1:0]                   sa_AWREADY_i;
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Write address channel (master)
    logic                                   m_AWREADY_o;
    // -- To Slave Arbitration
    // ---- Write address channel
    logic   [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_AWID_o;
    logic   [ADDR_WIDTH*SLV_AMT-1:0]        sa_AWADDR_o;
    logic   [TRANS_BURST_W-1:0]             sa_AWBURST_o;
    logic   [TRANS_DATA_LEN_W*SLV_AMT-1:0]  sa_AWLEN_o;
    logic   [TRANS_DATA_SIZE_W*SLV_AMT-1:0] sa_AWSIZE_o;
    logic   [SLV_AMT-1:0]                   sa_AWVALID_o;
    logic   [SLV_AMT-1:0]                   sa_AW_outst_full_o;     // The Dispatcher is full
    // ---- Write Address channel
    logic   [SLV_ID_W-1:0]                  dsp_WDATA_slv_id_o;   
    logic                                   dsp_WDATA_disable_o;   
    // -- To WRESP channel Dispatcher
    logic   [SLV_ID_W-1:0]                  dsp_WRESP_slv_id_o;
    logic                                   dsp_WRESP_shift_en_o;
    
    dsp_WADDR_channel #(
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
    ) uut (
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),
        .m_AWID_i(m_AWID_i),
        .m_AWADDR_i(m_AWADDR_i),
        .m_AWBURST_i(m_AWBURST_i),
        .m_AWLEN_i(m_AWLEN_i),
        .m_AWSIZE_i(m_AWSIZE_i),
        .m_AWVALID_i(m_AWVALID_i),
        .m_WVALID_i(m_WVALID_i),
        .m_WREADY_i(m_WREADY_i),
        .sa_AWREADY_i(sa_AWREADY_i),
        .m_AWREADY_o(m_AWREADY_o),
        .sa_AWID_o(sa_AWID_o),
        .sa_AWADDR_o(sa_AWADDR_o),
        .sa_AWBURST_o(sa_AWBURST_o),
        .sa_AWLEN_o(sa_AWLEN_o),
        .sa_AWSIZE_o(sa_AWSIZE_o),
        .sa_AWVALID_o(sa_AWVALID_o),
        .sa_AW_outst_full_o(sa_AW_outst_full_o),
        .dsp_WDATA_slv_id_o(dsp_WDATA_slv_id_o),
        .dsp_WDATA_disable_o(dsp_WDATA_disable_o),
        .dsp_WRESP_slv_id_o(dsp_WRESP_slv_id_o),
        .dsp_WRESP_shift_en_o(dsp_WRESP_shift_en_o)
    );
    
    initial begin
        ACLK_i <= 0;
        forever #1 ACLK_i <= ~ACLK_i;
    end
    
    initial begin
        ARESETn_i <= 0;
        
        m_AWID_i <= 0;
        m_AWADDR_i <= 0;
        m_AWBURST_i <= 0;
        m_AWLEN_i <= 0;
        m_AWSIZE_i <= 0;
        m_AWVALID_i <= 0;
        
        sa_AWREADY_i <= 2'b11;
        
        m_WVALID_i <= 0;
        m_WREADY_i <= 0;
        
        #5; ARESETn_i <= 1;
    end
    
    initial begin
        #6;
        @(posedge ACLK_i) #0.01;m_AWID_i <= 0;m_AWADDR_i <= {2'b00, 30'd0};m_AWBURST_i <= 0;m_AWLEN_i <= 0;m_AWSIZE_i <= 0;
        m_AWVALID_i <= 1;
        
        @(posedge ACLK_i) #0.01;m_AWID_i <= 0;m_AWADDR_i <= {2'b01, 30'd0};m_AWBURST_i <= 0;m_AWLEN_i <= 1;m_AWSIZE_i <= 0;
        m_AWVALID_i <= 1;
        
        @(posedge ACLK_i) #0.01;m_AWID_i <= 0;m_AWADDR_i <= {2'b00, 30'd0};m_AWBURST_i <= 0;m_AWLEN_i <= 2;m_AWSIZE_i <= 0;
        m_AWVALID_i <= 1;
        
        @(posedge ACLK_i) #0.01;m_AWID_i <= 0;m_AWADDR_i <= {2'b01, 30'd0};m_AWBURST_i <= 0;m_AWLEN_i <= 3;m_AWSIZE_i <= 0;
        m_AWVALID_i <= 1;
        
        @(posedge ACLK_i) #0.01;
        m_AWVALID_i <= 0;
        
        #100;
        @(posedge ACLK_i) #0.01;
        m_WVALID_i <= 1;
        m_WREADY_i <= 1;
    end
    
endmodule
