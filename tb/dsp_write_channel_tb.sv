`timescale 1ns / 1ps
module dsp_write_channel_tb;
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
    // ---- Write data channel
    logic   [DATA_WIDTH-1:0]                m_WDATA_i;
    logic                                   m_WLAST_i;
    logic                                   m_WVALID_i;
    // ---- Write response channel
    logic                                   m_BREADY_i;
    // -- To Slave Arbitration
    // ---- Write address channel (master)
    logic   [SLV_AMT-1:0]                   sa_AWREADY_i;
    // ---- Write data channel (master)
    logic   [SLV_AMT-1:0]                   sa_WREADY_i;
    // ---- Write response channel (master)
    wire    [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_BID_i;
    wire    [TRANS_WR_RESP_W*SLV_AMT-1:0]   sa_BRESP_i;
    logic   [SLV_AMT-1:0]                   sa_BVALID_i;
    
    logic   [TRANS_MST_ID_W-1:0]            sa_BID      [SLV_AMT-1:0];
    logic   [TRANS_WR_RESP_W-1:0]           sa_BRESP    [SLV_AMT-1:0];
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Write address channel (master)
    logic                                   m_AWREADY_o;
    // ---- Write data channel (master)
    logic                                   m_WREADY_o;
    // ---- Write response channel (master)
    logic   [TRANS_MST_ID_W-1:0]            m_BID_o;
    logic   [TRANS_WR_RESP_W-1:0]           m_BRESP_o;
    logic                                   m_BVALID_o;
    // -- To Slave Arbitration
    // ---- Write address channel
    logic   [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_AWID_o;
    logic   [ADDR_WIDTH*SLV_AMT-1:0]        sa_AWADDR_o;
    logic   [TRANS_BURST_W-1:0]             sa_AWBURST_o;
    logic   [TRANS_DATA_LEN_W*SLV_AMT-1:0]  sa_AWLEN_o;
    logic   [TRANS_DATA_SIZE_W*SLV_AMT-1:0] sa_AWSIZE_o;
    logic   [SLV_AMT-1:0]                   sa_AWVALID_o;
    logic   [SLV_AMT-1:0]                   sa_AW_outst_full_o;  // The Dispatcher is full
    // ---- Write data channel
    logic   [DATA_WIDTH*SLV_AMT-1:0]        sa_WDATA_o;
    logic   [SLV_AMT-1:0]                   sa_WLAST_o;
    logic   [SLV_AMT-1:0]                   sa_WVALID_o;
    logic   [SLV_AMT-1:0]                   sa_WDATA_sel_o;     // Slave Arbitration selection
    // ---- Write response channel          
    logic   [SLV_AMT-1:0]                   sa_BREADY_o;
    
    
    dsp_write_channel #(
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
        .m_WDATA_i(m_WDATA_i),
        .m_WLAST_i(m_WLAST_i),
        .m_WVALID_i(m_WVALID_i),
        .m_BREADY_i(m_BREADY_i),
        .sa_AWREADY_i(sa_AWREADY_i),
        .sa_WREADY_i(sa_WREADY_i),
        .sa_BID_i(sa_BID_i),
        .sa_BRESP_i(sa_BRESP_i),
        .sa_BVALID_i(sa_BVALID_i),
        .m_AWREADY_o(m_AWREADY_o),
        .m_WREADY_o(m_WREADY_o),
        .m_BID_o(m_BID_o),
        .m_BRESP_o(m_BRESP_o),
        .m_BVALID_o(m_BVALID_o),
        .sa_AWID_o(sa_AWID_o),
        .sa_AWADDR_o(sa_AWADDR_o),
        .sa_AWBURST_o(sa_AWBURST_o),
        .sa_AWLEN_o(sa_AWLEN_o),
        .sa_AWSIZE_o(sa_AWSIZE_o),
        .sa_AWVALID_o(sa_AWVALID_o),
        .sa_AW_outst_full_o(sa_AW_outst_full_o),
        .sa_WDATA_o(sa_WDATA_o),
        .sa_WLAST_o(sa_WLAST_o),
        .sa_WVALID_o(sa_WVALID_o),
        .sa_WDATA_sel_o(sa_WDATA_sel_o),
        .sa_BREADY_o(sa_BREADY_o)       
    );
    
    genvar slv_idx;
    generate
    for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin
        assign sa_BID_i[TRANS_MST_ID_W*(slv_idx+1)-1-:TRANS_MST_ID_W] = sa_BID[slv_idx];
        assign sa_BRESP_i[TRANS_WR_RESP_W*(slv_idx+1)-1-:TRANS_WR_RESP_W] = sa_BRESP[slv_idx];
    end
    endgenerate
    
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
                     
        m_WDATA_i <= 0;   
        m_WLAST_i <= 0;   
        m_WVALID_i <= 0;  
                     
        m_BREADY_i <= 1;  
                     
                     
        sa_AWREADY_i <= 2'b11;
                     
        sa_WREADY_i <= 2'b11;
        
        sa_BID[0] <= 0;    
        sa_BRESP[0] <= 0;  
        sa_BVALID_i[0] <= 0; 
        
        sa_BID[1] <= 0;    
        sa_BRESP[1] <= 0;  
        sa_BVALID_i[1] <= 0;
        
        #5; ARESETn_i <= 1;
    end
    
    initial begin
        #6;
        
        @(posedge ACLK_i); #0.01;m_AWID_i <= 0;m_AWBURST_i <= 0;m_AWLEN_i <= 0;m_AWSIZE_i <= 0;  
        m_AWADDR_i <= {2'b00, 30'd0};
        m_AWVALID_i <= 1;
        @(posedge ACLK_i); #0.01;m_AWID_i <= 0;m_AWBURST_i <= 0;m_AWLEN_i <= 1;m_AWSIZE_i <= 0;  
        m_AWADDR_i <= {2'b01, 30'd30};
        m_AWVALID_i <= 1;
        @(posedge ACLK_i); #0.01;m_AWID_i <= 0;m_AWBURST_i <= 0;m_AWLEN_i <= 2;m_AWSIZE_i <= 0;  
        m_AWADDR_i <= {2'b01, 30'd40};
        m_AWVALID_i <= 1;
        @(posedge ACLK_i); #0.01;m_AWID_i <= 0;m_AWBURST_i <= 0;m_AWLEN_i <= 2;m_AWSIZE_i <= 0;  
        m_AWADDR_i <= {2'b00, 30'd40};
        m_AWVALID_i <= 1;
        
        // End
        @(posedge ACLK_i); #0.01;m_AWID_i <= 0;m_AWBURST_i <= 0;m_AWLEN_i <= 0;m_AWSIZE_i <= 0;  
        m_AWVALID_i <= 0;
        
    end
    
    initial begin
        #7; 
        @(posedge ACLK_i);
        
        @(posedge ACLK_i);m_WDATA_i <= 100;m_WLAST_i <= 0;
        m_WVALID_i <= 1;
        
        @(posedge ACLK_i);;m_WDATA_i <= 200;m_WLAST_i <= 0;
        m_WVALID_i <= 1;
        
        @(posedge ACLK_i);;m_WDATA_i <= 300;m_WLAST_i <= 0;
        m_WVALID_i <= 1;
        
        @(posedge ACLK_i);;m_WDATA_i <= 400;m_WLAST_i <= 0;
        m_WVALID_i <= 1;
        
        @(posedge ACLK_i);;m_WDATA_i <= 500;m_WLAST_i <= 0;
        m_WVALID_i <= 1;
        
        @(posedge ACLK_i);;m_WDATA_i <= 600;m_WLAST_i <= 0;
        m_WVALID_i <= 1;
        
        @(posedge ACLK_i);;m_WDATA_i <= 700;m_WLAST_i <= 0;
        m_WVALID_i <= 1;
        
//        @(posedge ACLK_i);;m_WDATA_i <= 800;m_WLAST_i <= 0;
//        m_WVALID_i <= 0;
    end
    
    initial begin
        #6;
        @(posedge ACLK_i);sa_BID[1] <= 10;sa_BRESP[1] <= 0;  
        sa_BVALID_i[1] <= 1;
        
        @(posedge ACLK_i);sa_BID[1] <= 11;sa_BRESP[1] <= 0;  
        sa_BVALID_i[1] <= 1;
        
        @(posedge ACLK_i);sa_BID[0] <= 00;sa_BRESP[0] <= 0;  
        sa_BVALID_i[1] <= 0;
        sa_BVALID_i[0] <= 1;
        
        @(posedge ACLK_i);sa_BID[0] <= 01;sa_BRESP[0] <= 0;  
        sa_BVALID_i[0] <= 1;
        
        // End
        @(posedge ACLK_i);  
        sa_BVALID_i[0] <= 0;
        sa_BVALID_i[1] <= 0;
    end
    
endmodule
