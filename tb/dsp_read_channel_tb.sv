`timescale 1ns / 1ps
module dsp_read_channel_tb;
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
    // ---- Read address channel
    logic   [TRANS_MST_ID_W-1:0]            m_ARID_i;
    logic   [ADDR_WIDTH-1:0]                m_ARADDR_i;
    logic   [TRANS_BURST_W-1:0]             m_ARBURST_i;
    logic   [TRANS_DATA_LEN_W-1:0]          m_ARLEN_i;
    logic   [TRANS_DATA_SIZE_W-1:0]         m_ARSIZE_i;
    logic                                   m_ARVALID_i;
    // ---- Read data channel
    logic                                   m_RREADY_i;
    // -- To Slave Arbitration
    // ---- Read address channel (master)
    logic   [SLV_AMT-1:0]                   sa_ARREADY_i;
    // ---- Read data channel (master)
    wire    [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_RID_i;
    wire    [DATA_WIDTH*SLV_AMT-1:0]        sa_RDATA_i;
    wire    [SLV_AMT-1:0]                   sa_RLAST_i;
    logic   [SLV_AMT-1:0]                   sa_RVALID_i;
    
    logic   [TRANS_MST_ID_W-1:0]    sa_RID      [SLV_AMT-1:0];
    logic   [DATA_WIDTH-1:0]        sa_RDATA    [SLV_AMT-1:0];
    logic                           sa_RLAST    [SLV_AMT-1:0];
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Read address channel (master)
    logic                                   m_ARREADY_o;
    // ---- Read data channel (master)
    logic   [TRANS_MST_ID_W-1:0]            m_RID_o;
    logic   [DATA_WIDTH-1:0]                m_RDATA_o;
    logic                                   m_RLAST_o;
    logic                                   m_RVALID_o;
    // -- To Slave Arbitration
    // ---- Read address channel            
    logic   [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_ARID_o;
    logic   [ADDR_WIDTH*SLV_AMT-1:0]        sa_ARADDR_o;
    logic   [TRANS_BURST_W*SLV_AMT-1:0]     sa_ARBURST_o;
    logic   [TRANS_DATA_LEN_W*SLV_AMT-1:0]  sa_ARLEN_o;
    logic   [TRANS_DATA_SIZE_W*SLV_AMT-1:0] sa_ARSIZE_o;
    logic   [SLV_AMT-1:0]                   sa_ARVALID_o;
    logic   [SLV_AMT-1:0]                   sa_AR_outst_full_o;  // The Dispatcher is full
    // ---- Read data channel
    logic   [SLV_AMT-1:0]                   sa_RREADY_o;
    
    genvar i;
    for (i = 0; i < SLV_AMT; i = i + 1) begin
        assign sa_RID_i[TRANS_MST_ID_W*(i+1)-1-:TRANS_MST_ID_W] = sa_RID[i];
        assign sa_RDATA_i[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = sa_RDATA[i];
        assign sa_RLAST_i[i] = sa_RLAST[i];
    end
    
    dsp_read_channel #(
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
    ) read_channel (
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),
        .m_ARID_i(m_ARID_i),
        .m_ARADDR_i(m_ARADDR_i),
        .m_ARBURST_i(m_ARBURST_i),
        .m_ARLEN_i(m_ARLEN_i),
        .m_ARSIZE_i(m_ARSIZE_i),
        .m_ARVALID_i(m_ARVALID_i),
        .m_RREADY_i(m_RREADY_i),
        .sa_ARREADY_i(sa_ARREADY_i),
        .sa_RID_i(sa_RID_i),
        .sa_RDATA_i(sa_RDATA_i),
        .sa_RLAST_i(sa_RLAST_i),
        .sa_RVALID_i(sa_RVALID_i),
        .m_ARREADY_o(m_ARREADY_o),
        .m_RID_o(m_RID_o),
        .m_RDATA_o(m_RDATA_o),
        .m_RLAST_o(m_RLAST_o),
        .m_RVALID_o(m_RVALID_o),
        .sa_ARID_o(sa_ARID_o),
        .sa_ARADDR_o(sa_ARADDR_o),
        .sa_ARBURST_o(sa_ARBURST_o),
        .sa_ARLEN_o(sa_ARLEN_o),
        .sa_ARSIZE_o(sa_ARSIZE_o),
        .sa_ARVALID_o(sa_ARVALID_o),
        .sa_AR_outst_full_o(sa_AR_outst_full_o),
        .sa_RREADY_o(sa_RREADY_o)
    );
    
    
    initial begin
        ACLK_i <= 0;
        forever #1 ACLK_i <= ~ACLK_i;
    end
    
    initial begin
        ARESETn_i <= 0;
        
        m_ARID_i <= 0;    
        m_ARADDR_i <= 0;  
        m_ARBURST_i <= 0; 
        m_ARLEN_i <= 0;   
        m_ARSIZE_i <= 0;  
        m_ARVALID_i <= 0; 
                     
        m_RREADY_i <= 1;  
                     
                     
        sa_ARREADY_i <= 2'b11;
                     
        sa_RID[0] <= 0;    
        sa_RDATA[0] <= 0;  
        sa_RLAST[0] <= 0;  
        sa_RVALID_i[0] <= 0; 
        
        sa_RID[1] <= 0;    
        sa_RDATA[1] <= 0;  
        sa_RLAST[1] <= 0;  
        sa_RVALID_i[1] <= 0; 
        
        #5; ARESETn_i <= 1;
    end
    
    initial begin
        #6; 
        @(posedge ACLK_i); #0.01;m_ARID_i <= 0;m_ARBURST_i <= 0;m_ARLEN_i <= 0;m_ARSIZE_i <= 0;  
        m_ARADDR_i <= {2'b00, 30'd0};
        m_ARVALID_i <= 1;
        @(posedge ACLK_i); #0.01;m_ARID_i <= 0;m_ARBURST_i <= 0;m_ARLEN_i <= 1;m_ARSIZE_i <= 0;  
        m_ARADDR_i <= {2'b01, 30'd30};
        m_ARVALID_i <= 1;
        @(posedge ACLK_i); #0.01;m_ARID_i <= 0;m_ARBURST_i <= 0;m_ARLEN_i <= 1;m_ARSIZE_i <= 0;  
        m_ARADDR_i <= {2'b01, 30'd40};
        m_ARVALID_i <= 1;
        @(posedge ACLK_i); #0.01;m_ARID_i <= 0;m_ARBURST_i <= 0;m_ARLEN_i <= 2;m_ARSIZE_i <= 0;  
        m_ARADDR_i <= {2'b00, 30'd40};
        m_ARVALID_i <= 1;
        
        // End
        @(posedge ACLK_i); #0.01;m_ARID_i <= 0;m_ARBURST_i <= 0;m_ARLEN_i <= 0;m_ARSIZE_i <= 0;  
        m_ARVALID_i <= 0;
    end
    
    initial begin
       localparam mst_id = 0;
       #6;
       
        @(posedge ACLK_i);sa_RID[mst_id] <= 0;sa_RDATA[mst_id] <= 11;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;
       
        @(posedge ACLK_i);sa_RID[mst_id] <= 01;sa_RDATA[mst_id] <= 01;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;
       
        @(posedge ACLK_i);sa_RID[mst_id] <= 01;sa_RDATA[mst_id] <= 01;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;
       
        @(posedge ACLK_i);sa_RID[mst_id] <= 2;sa_RDATA[mst_id] <= 02;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;  
       
        @(posedge ACLK_i);sa_RID[mst_id] <= 3;sa_RDATA[mst_id] <= 03;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;
          
        @(posedge ACLK_i);sa_RID[mst_id] <= 4;sa_RDATA[mst_id] <= 03;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;
        
        @(posedge ACLK_i);sa_RID[mst_id] <= 99;sa_RDATA[mst_id] <= 99;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;
        
        // End
        @(posedge ACLK_i);sa_RID[mst_id] <= 99;sa_RDATA[mst_id] <= 99;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 0;
    end 
    initial begin
       localparam mst_id = 1;
       #6;
       
        @(posedge ACLK_i);sa_RID[mst_id] <= 10;sa_RDATA[mst_id] <= 11;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;
       
        @(posedge ACLK_i);sa_RID[mst_id] <= 11;sa_RDATA[mst_id] <= 01;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;
       
        @(posedge ACLK_i);sa_RID[mst_id] <= 11;sa_RDATA[mst_id] <= 01;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;
       
        @(posedge ACLK_i);sa_RID[mst_id] <= 12;sa_RDATA[mst_id] <= 02;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;  
       
        @(posedge ACLK_i);sa_RID[mst_id] <= 13;sa_RDATA[mst_id] <= 03;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;
          
        @(posedge ACLK_i);sa_RID[mst_id] <= 14;sa_RDATA[mst_id] <= 03;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;
        
        @(posedge ACLK_i);sa_RID[mst_id] <= 88;sa_RDATA[mst_id] <= 88;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 1;
        
        // End
        @(posedge ACLK_i);sa_RID[mst_id] <= 99;sa_RDATA[mst_id] <= 99;sa_RLAST[mst_id] <= 0;  
        sa_RVALID_i[mst_id] <= 0;
    end 
    
    
endmodule
