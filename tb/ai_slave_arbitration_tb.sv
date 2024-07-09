`timescale 1ns / 1ps
module ai_slave_arbitration_tb;
    // Interconnect configuration
    parameter                       MST_AMT             = 4;
    parameter                       OUTSTANDING_AMT     = 8;
    parameter [0:(MST_AMT*32)-1]    MST_WEIGHT          = {32'd5, 32'd3, 32'd2, 32'd1};
    parameter                       MST_ID_W            = $clog2(MST_AMT);
    // Transaction configuration
    parameter                       DATA_WIDTH          = 32;
    parameter                       ADDR_WIDTH          = 32;
    parameter                       TRANS_MST_ID_W      = 5;                                // Bus width of master transaction ID 
    parameter                       TRANS_SLV_ID_W      = TRANS_MST_ID_W + $clog2(MST_AMT); // Bus width of slave transaction ID
    parameter                       TRANS_BURST_W       = 2;                                // Width of xBURST 
    parameter                       TRANS_DATA_LEN_W    = 3;                                // Bus width of xLEN
    parameter                       TRANS_DATA_SIZE_W   = 3;                                // Bus width of xSIZE
    parameter                       TRANS_WR_RESP_W     = 2;
    // Slave info configuration
    parameter                       SLV_ID              = 0;
    parameter                       SLV_ID_MSB_IDX      = 30;
    parameter                       SLV_ID_LSB_IDX      = 30;
    
    // Input declaration
    // -- Global signals
    logic                                   ACLK_i;
    logic                                   ARESETn_i;
    // -- To Dispatcher
    // ---- Write address channel
    logic   [TRANS_MST_ID_W*MST_AMT-1:0]    dsp_AWID_i;
    logic   [ADDR_WIDTH*MST_AMT-1:0]        dsp_AWADDR_i;
    logic   [TRANS_BURST_W*MST_AMT-1:0]     dsp_AWBURST_i;
    logic   [TRANS_DATA_LEN_W*MST_AMT-1:0]  dsp_AWLEN_i;
    logic   [TRANS_DATA_SIZE_W*MST_AMT-1:0] dsp_AWSIZE_i;
    logic   [MST_AMT-1:0]                   dsp_AWVALID_i;
    logic   [MST_AMT-1:0]                   dsp_AW_outst_full_i;
    // ---- Write data channel
    logic   [DATA_WIDTH*MST_AMT-1:0]        dsp_WDATA_i;
    logic   [MST_AMT-1:0]                   dsp_WLAST_i;
    logic   [MST_AMT-1:0]                   dsp_WVALID_i;
    logic   [MST_AMT-1:0]                   dsp_slv_sel_i;
    // ---- Write response channel
    logic   [MST_AMT-1:0]                   dsp_BREADY_i;
    // ---- Read address channel
    logic   [TRANS_MST_ID_W*MST_AMT-1:0]    dsp_ARID_i;
    logic   [ADDR_WIDTH*MST_AMT-1:0]        dsp_ARADDR_i;
    logic   [TRANS_BURST_W*MST_AMT-1:0]     dsp_ARBURST_i;
    logic   [TRANS_DATA_LEN_W*MST_AMT-1:0]  dsp_ARLEN_i;
    logic   [TRANS_DATA_SIZE_W*MST_AMT-1:0] dsp_ARSIZE_i;
    logic   [MST_AMT-1:0]                   dsp_ARVALID_i;
    logic   [MST_AMT-1:0]                   dsp_AR_outst_full_i;
    // ---- Read data channel
    logic   [MST_AMT-1:0]                   dsp_RREADY_i;
    // -- To slave (master interface of the interconnect)
    // ---- Write address channel (master)
    logic                                   s_AWREADY_i;
    // ---- Write data channel (master)
    logic                                   s_WREADY_i;
    // ---- Write response channel (master)
    logic  [TRANS_SLV_ID_W-1:0]             s_BID_i;
    logic  [TRANS_WR_RESP_W-1:0]            s_BRESP_i;
    logic                                   s_BVALID_i;
    // ---- Read address channel (master)
    logic                                   s_ARREADY_i;
    // ---- Read data channel (master)
    logic  [TRANS_SLV_ID_W-1:0]             s_RID_i;
    logic  [DATA_WIDTH-1:0]                 s_RDATA_i;
    logic                                   s_RLAST_i;
    logic                                   s_RVALID_i;
    
    // Output declaration
    // -- To Dispatcher
    // ---- Write address channel (master)
    logic   [MST_AMT-1:0]                   dsp_AWREADY_o;
    // ---- Write data channel (master)
    logic   [MST_AMT-1:0]                   dsp_WREADY_o;
    // ---- Write response channel (master)
    logic   [TRANS_MST_ID_W*MST_AMT-1:0]    dsp_BID_o;
    logic   [TRANS_WR_RESP_W*MST_AMT-1:0]   dsp_BRESP_o;
    logic   [MST_AMT-1:0]                   dsp_BVALID_o;
    // ---- Read address channel (master)
    logic   [MST_AMT-1:0]                   dsp_ARREADY_o;
    // ---- Read data channel (master)
    logic   [TRANS_MST_ID_W*MST_AMT-1:0]    dsp_RID_o;
    logic   [DATA_WIDTH*MST_AMT-1:0]        dsp_RDATA_o;
    logic   [MST_AMT-1:0]                   dsp_RLAST_o;
    logic   [MST_AMT-1:0]                   dsp_RVALID_o;
    // -- To slave (master interface of the interconnect)
    // ---- Write address channel
    logic   [TRANS_SLV_ID_W-1:0]            s_AWID_o;
    logic   [ADDR_WIDTH-1:0]                s_AWADDR_o;
    logic   [TRANS_BURST_W-1:0]             s_AWBURST_o;
    logic   [TRANS_DATA_LEN_W-1:0]          s_AWLEN_o;
    logic   [TRANS_DATA_SIZE_W-1:0]         s_AWSIZE_o;
    logic                                   s_AWVALID_o;
    // ---- Write data channel
    logic   [DATA_WIDTH-1:0]                s_WDATA_o;
    logic                                   s_WLAST_o;
    logic                                   s_WVALID_o;
    // ---- Write response channel          
    logic                                   s_BREADY_o;
    // ---- Read address channel            
    logic   [TRANS_SLV_ID_W-1:0]            s_ARID_o;
    logic   [ADDR_WIDTH-1:0]                s_ARADDR_o;
    logic   [TRANS_BURST_W-1:0]             s_ARBURST_o;
    logic   [TRANS_DATA_LEN_W-1:0]          s_ARLEN_o;
    logic   [TRANS_DATA_SIZE_W-1:0]         s_ARSIZE_o;
    logic                                   s_ARVALID_o;
    // ---- Read data channel
    logic                                   s_RREADY_o;
    
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
        .SLV_ID(SLV_ID),
        .SLV_ID_MSB_IDX(SLV_ID_MSB_IDX),
        .SLV_ID_LSB_IDX(SLV_ID_LSB_IDX)
    ) uut (
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),
        .dsp_AWID_i(dsp_AWID_i),
        .dsp_AWADDR_i(dsp_AWADDR_i),
        .dsp_AWBURST_i(dsp_AWBURST_i),
        .dsp_AWLEN_i(dsp_AWLEN_i),
        .dsp_AWSIZE_i(dsp_AWSIZE_i),
        .dsp_AWVALID_i(dsp_AWVALID_i),
        .dsp_AW_outst_full_i(dsp_AW_outst_full_i),
        .dsp_WDATA_i(dsp_WDATA_i),
        .dsp_WLAST_i(dsp_WLAST_i),
        .dsp_WVALID_i(dsp_WVALID_i),
        .dsp_slv_sel_i(dsp_slv_sel_i),
        .dsp_BREADY_i(dsp_BREADY_i),
        .dsp_ARID_i(dsp_ARID_i),
        .dsp_ARADDR_i(dsp_ARADDR_i),
        .dsp_ARBURST_i(dsp_ARBURST_i),
        .dsp_ARLEN_i(dsp_ARLEN_i),
        .dsp_ARSIZE_i(dsp_ARSIZE_i),
        .dsp_ARVALID_i(dsp_ARVALID_i),
        .dsp_AR_outst_full_i(dsp_AR_outst_full_i),
        .dsp_RREADY_i(dsp_RREADY_i),
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
        .dsp_AWREADY_o(dsp_AWREADY_o),
        .dsp_WREADY_o(dsp_WREADY_o),
        .dsp_BID_o(dsp_BID_o),
        .dsp_BRESP_o(dsp_BRESP_o),
        .dsp_BVALID_o(dsp_BVALID_o),
        .dsp_ARREADY_o(dsp_ARREADY_o),
        .dsp_RID_o(dsp_RID_o),
        .dsp_RDATA_o(dsp_RDATA_o),
        .dsp_RLAST_o(dsp_RLAST_o),
        .dsp_RVALID_o(dsp_RVALID_o),
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
    
    // Write channel
    // -- -- Write Address channel
    reg   [TRANS_MST_ID_W:0]      dsp_AWID  [MST_AMT-1:0];
    reg   [ADDR_WIDTH-1:0]        dsp_AWADDR [MST_AMT-1:0];
    reg   [TRANS_BURST_W-1:0]     dsp_AWBURST [MST_AMT-1:0];
    reg   [TRANS_DATA_LEN_W-1:0]  dsp_AWLEN [MST_AMT-1:0];
    reg   [TRANS_DATA_SIZE_W-1:0] dsp_AWSIZE [MST_AMT-1:0];
    for(genvar i = 0; i < MST_AMT; i = i + 1) begin
        assign dsp_AWID_i[TRANS_MST_ID_W*(i+1)-1-:TRANS_MST_ID_W] = dsp_AWID[i];
        assign dsp_AWADDR_i[ADDR_WIDTH*(i+1)-1-:ADDR_WIDTH] = dsp_AWADDR[i];
        assign dsp_AWBURST_i[TRANS_BURST_W*(i+1)-1-:TRANS_BURST_W] = dsp_AWBURST[i];
        assign dsp_AWLEN_i[TRANS_DATA_LEN_W*(i+1)-1-:TRANS_DATA_LEN_W] = dsp_AWLEN[i];
        assign dsp_AWSIZE_i[TRANS_DATA_SIZE_W*(i+1)-1-:TRANS_DATA_SIZE_W] = dsp_AWSIZE[i];
    end
    // -- -- Write Data channel
    reg   [DATA_WIDTH-1:0] dsp_WDATA [MST_AMT-1:0];
    genvar mst_idx;
    for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin
        assign dsp_WDATA_i[DATA_WIDTH*(mst_idx+1)-1-:DATA_WIDTH] = dsp_WDATA[mst_idx];
    end
    // -- -- Write Response channel
    wire    [TRANS_MST_ID_W-1:0]    dsp_BID         [MST_AMT-1:0];
    wire    [TRANS_WR_RESP_W-1:0]   dsp_BRESP       [MST_AMT-1:0];
    for(genvar i = 0; i < MST_AMT; i = i + 1) begin
        assign dsp_BID[i] = dsp_BID_o[TRANS_MST_ID_W*(i+1)-1-:TRANS_MST_ID_W];
        assign dsp_BRESP[i] = dsp_BRESP_o[TRANS_WR_RESP_W*(i+1)-1-:TRANS_WR_RESP_W];
    end
    
    initial begin
        ACLK_i <= 0;
        forever #1 ACLK_i <= ~ACLK_i;
    end
    
    initial begin
        ARESETn_i <= 0;
        #5; ARESETn_i <= 1;
        
        dsp_slv_sel_i[0] <= 1;
        dsp_slv_sel_i[1] <= 1;
        dsp_slv_sel_i[2] <= 1;
        dsp_slv_sel_i[3] <= 1;
        s_WREADY_i <= 1;
        
        // Write response
        dsp_BREADY_i <= {MST_AMT{1'b1}};
        s_BID_i <= 0;
        s_BRESP_i <= 0;
        s_BVALID_i <= 0;
    end
    
    initial begin
        dsp_AW_outst_full_i <= 0;
        s_AWREADY_i <= 1;
        // 
        dsp_AWVALID_i[0] <= 0;
        dsp_AWID[0] <= 0;dsp_AWBURST[0] <= 1;dsp_AWSIZE[0] <= 0;
        dsp_AWADDR[0] <= 0;
        dsp_AWLEN[0] <= 0;
        //
        dsp_AWVALID_i[1] <= 0;
        dsp_AWID[1] <= 0;dsp_AWBURST[1] <= 0;dsp_AWSIZE[1] <= 0;
        dsp_AWADDR[1] <= 0;
        dsp_AWLEN[1] <= 0;
        //
        dsp_AWVALID_i[2] <= 0;
        dsp_AWID[2] <= 0;dsp_AWBURST[2] <= 1;dsp_AWSIZE[2] <= 0;
        dsp_AWADDR[2] <= 0;
        dsp_AWLEN[2] <= 0;
        //
        dsp_AWVALID_i[3] <= 0;
        dsp_AWID[3] <= 0;dsp_AWBURST[3] <= 1;dsp_AWSIZE[3] <= 0;
        dsp_AWADDR[3] <= 0;
        dsp_AWLEN[3] <= 0;
    end
    initial begin : MASTER_BLOCK_0
        localparam mst_id = 0;
        #6;
        
        @(posedge ACLK_i);#0.01;dsp_AWID[mst_id] <= 0;dsp_AWBURST[mst_id] <= 0;dsp_AWSIZE[mst_id] <= 0;
        dsp_AWVALID_i[mst_id] <= 1;
        dsp_AWADDR[mst_id] <= 01;
        dsp_AWLEN[mst_id] <= 0;
        
        @(posedge ACLK_i);#0.01;dsp_AWID[mst_id] <= 1;dsp_AWBURST[mst_id] <= 0;dsp_AWSIZE[mst_id] <= 0;
        dsp_AWVALID_i[mst_id] <= 1;
        dsp_AWADDR[mst_id] <= 4095;
        dsp_AWLEN[mst_id] <= 2;
        
        @(posedge ACLK_i);#0.01;dsp_AWID[mst_id] <= 2;dsp_AWBURST[mst_id] <= 0;dsp_AWSIZE[mst_id] <= 0;
        dsp_AWVALID_i[mst_id] <= 1;
        dsp_AWADDR[mst_id] <= 03;
        dsp_AWLEN[mst_id] <= 3;
        
        // End
        @(posedge ACLK_i);
        dsp_AWVALID_i[mst_id] <= 0;
    end
    initial begin : MASTER_BLOCK_1
        localparam mst_id = 1;
        #6;
        
        @(posedge ACLK_i);#0.01;dsp_AWID[mst_id] <= 0;dsp_AWBURST[mst_id] <= 0;dsp_AWSIZE[mst_id] <= 0;
        dsp_AWVALID_i[mst_id] <= 1;
        dsp_AWADDR[mst_id] <= 10;
        dsp_AWLEN[mst_id] <= 1;
        
        @(posedge ACLK_i);#0.01;dsp_AWID[mst_id] <= 1;dsp_AWBURST[mst_id] <= 0;dsp_AWSIZE[mst_id] <= 0;
        dsp_AWVALID_i[mst_id] <= 1;
        dsp_AWADDR[mst_id] <= 12;
        dsp_AWLEN[mst_id] <= 0;
        
        @(posedge ACLK_i);#0.01;dsp_AWID[mst_id] <= 2;dsp_AWBURST[mst_id] <= 0;dsp_AWSIZE[mst_id] <= 0;
        dsp_AWVALID_i[mst_id] <= 1;
        dsp_AWADDR[mst_id] <= 13;
        dsp_AWLEN[mst_id] <= 0;
        
        // End
        @(posedge ACLK_i);
        dsp_AWVALID_i[mst_id] <= 0;
    end
    initial begin : MASTER_BLOCK_2
        localparam mst_id = 2;
        #6;
        
        @(posedge ACLK_i);#0.01;dsp_AWID[mst_id] <= 0;dsp_AWBURST[mst_id] <= 0;dsp_AWSIZE[mst_id] <= 0;
        dsp_AWVALID_i[mst_id] <= 1;
        dsp_AWADDR[mst_id] <= 21;
        dsp_AWLEN[mst_id] <= 0;
        
        @(posedge ACLK_i);#0.01;dsp_AWID[mst_id] <= 1;dsp_AWBURST[mst_id] <= 0;dsp_AWSIZE[mst_id] <= 0;
        dsp_AWVALID_i[mst_id] <= 1;
        dsp_AWADDR[mst_id] <= 22;
        dsp_AWLEN[mst_id] <= 2;
        
        @(posedge ACLK_i);#0.01;dsp_AWID[mst_id] <= 2;dsp_AWBURST[mst_id] <= 0;dsp_AWSIZE[mst_id] <= 0;
        dsp_AWVALID_i[mst_id] <= 1;
        dsp_AWADDR[mst_id] <= 23;
        dsp_AWLEN[mst_id] <= 3;
        
        // End
        @(posedge ACLK_i);
        dsp_AWVALID_i[mst_id] <= 0;
    end
    initial begin : MASTER_BLOCK_3
        localparam mst_id = 3;
        #6;
        
        @(posedge ACLK_i);#0.01;dsp_AWID[mst_id] <= 0;dsp_AWBURST[mst_id] <= 0;dsp_AWSIZE[mst_id] <= 0;
        dsp_AWVALID_i[mst_id] <= 1;
        dsp_AWADDR[mst_id] <= 30;
        dsp_AWLEN[mst_id] <= 1;
        
        @(posedge ACLK_i);#0.01;dsp_AWID[mst_id] <= 1;dsp_AWBURST[mst_id] <= 0;dsp_AWSIZE[mst_id] <= 0;
        dsp_AWVALID_i[mst_id] <= 1;
        dsp_AWADDR[mst_id] <= 32;
        dsp_AWLEN[mst_id] <= 0;
        
        @(posedge ACLK_i);#0.01;dsp_AWID[mst_id] <= 2;dsp_AWBURST[mst_id] <= 0;dsp_AWSIZE[mst_id] <= 0;
        dsp_AWVALID_i[mst_id] <= 1;
        dsp_AWADDR[mst_id] <= 33;
        dsp_AWLEN[mst_id] <= 0;
        
        // End
        @(posedge ACLK_i);
        dsp_AWVALID_i[mst_id] <= 0;
    end
    
     
    initial begin : WDATA_0
        localparam mst_id = 0;
        #11.001;

        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 01;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 00;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 02;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 03;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 04;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 05;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 06;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 07;
        // End burst
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 0; 
    end
    
    initial begin : WDATA_1
        localparam mst_id = 1;
        #11.001;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 11;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 10;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 12;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 13;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 14;
        
        // End burst
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 0; 
    end
    
    initial begin : WDATA_2
        localparam mst_id = 2;
        #11.001;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 21;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 20;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 22;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 23;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 24;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 25;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 26;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 27;
        // End burst
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 0; 
    end
    
    initial begin : WDATA_3
        localparam mst_id = 3;
        #11.001;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 31;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 30;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 32;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 33;
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 1;dsp_WDATA[mst_id] <= 34;
        
        // End burst
        @(posedge ACLK_i);#0.001;dsp_WVALID_i[mst_id] <= 0; 
    end
    
    initial begin : FROM_SLAVE
        #6;
        
        ////
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd0, 5'd00};
        @(posedge ACLK_i); #0.01;s_BVALID_i <= 0;
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd1, 5'd00};
        @(posedge ACLK_i); #0.01;s_BVALID_i <= 0;
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd2, 5'd00};
        @(posedge ACLK_i); #0.01;s_BVALID_i <= 0;
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd3, 5'd00};
        @(posedge ACLK_i); #0.01;s_BVALID_i <= 0;
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd0, 5'd01};
        @(posedge ACLK_i); #0.01;s_BVALID_i <= 0;
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd1, 5'd01};
        @(posedge ACLK_i); #0.01;s_BVALID_i <= 0;
        
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd2, 5'd01};
        @(posedge ACLK_i); #0.01;s_BVALID_i <= 0;
        
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd0, 5'd01};
        @(posedge ACLK_i); #0.01;s_BVALID_i <= 0;
        
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd0, 5'd02};
        @(posedge ACLK_i); #0.01;s_BVALID_i <= 0;
        
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd1, 5'd02};
        @(posedge ACLK_i); #0.01;s_BVALID_i <= 0;
        
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd2, 5'd02};
        @(posedge ACLK_i); #0.01;s_BVALID_i <= 0;
        
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd3, 5'd02};
        @(posedge ACLK_i); #0.01;s_BVALID_i <= 0;
        
        
        
        @(posedge ACLK_i); #0.01;
//        @(s_BVALID_i & s_BREADY_o) #0.001;
        s_BVALID_i <= 0;
    end
    
    
    
    initial begin
        #300; $stop;
    end 
endmodule
