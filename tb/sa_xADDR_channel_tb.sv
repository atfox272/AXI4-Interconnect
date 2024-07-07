`timescale 1ns / 1ps
module sa_xADDR_channel_tb;
    // Interconnect configuration
    parameter                       MST_AMT             = 3;
    parameter                       OUTSTANDING_AMT     = 8;
    parameter [0:(MST_AMT*32)-1]    MST_WEIGHT          = {32'd5, 32'd3, 32'd2};
    parameter                       MST_ID_W            = $clog2(MST_AMT);
    // Transaction configuration
    parameter                       DATA_WIDTH          = 32;
    parameter                       ADDR_WIDTH          = 32;
    parameter                       TRANS_MST_ID_W      = 5;                                // Bus width of master transaction ID 
    parameter                       TRANS_SLV_ID_W      = TRANS_MST_ID_W + $clog2(MST_AMT); // Bus width of slave transaction ID
    parameter                       TRANS_BURST_W       = 2;                                // Width of xBURST 
    
    parameter                       TRANS_DATA_LEN_W    = 3;                                // Bus width of xLEN
    parameter                       TRANS_DATA_SIZE_W   = 3;                                // Bus width of xSIZE
    // Slave info configuration
    parameter                       SLV_ID              = 0;
    parameter                       SLV_ID_MSB_IDX      = 30;
    parameter                       SLV_ID_LSB_IDX      = 30;
    
    // Input declaration
    // -- Global signals
    logic                                   ACLK_i;
    logic                                   ARESETn_i;
    logic                                   xDATA_stall_i;
    // -- To Dispatcher
    logic   [TRANS_MST_ID_W*MST_AMT-1:0]    dsp_AxID_i;
    logic   [ADDR_WIDTH*MST_AMT-1:0]        dsp_AxADDR_i;
    logic   [TRANS_BURST_W*MST_AMT-1:0]     dsp_AxBURST_i;
    logic   [TRANS_DATA_LEN_W*MST_AMT-1:0]  dsp_AxLEN_i;
    logic   [TRANS_DATA_SIZE_W*MST_AMT-1:0] dsp_AxSIZE_i;
    logic   [MST_AMT-1:0]                   dsp_AxVALID_i;
    logic   [MST_AMT-1:0]                   dsp_dispatcher_full_i;
    // -- To slave (master interface of the interconnect)
    logic                                   s_AxREADY_i;
    
    // Output declaration
    // -- To Dispatcher
    logic   [MST_AMT-1:0]                   dsp_AxREADY_o;
    // -- To slave (master interface of the interconnect)
    logic   [TRANS_SLV_ID_W-1:0]            s_AxID_o;
    logic   [ADDR_WIDTH-1:0]                s_AxADDR_o;
    logic   [TRANS_BURST_W-1:0]             s_AxBURST_o;
    logic   [TRANS_DATA_LEN_W-1:0]          s_AxLEN_o;
    logic   [TRANS_DATA_SIZE_W-1:0]         s_AxSIZE_o;
    logic                                   s_AxVALID_o;
    
    sa_xADDR_channel #(
    
    ) dut (
        .ACLK_i(ACLK_i),              
        .ARESETn_i(ARESETn_i),           
        .xDATA_stall_i(xDATA_stall_i),   
        .dsp_AxID_i(dsp_AxID_i),          
        .dsp_AxADDR_i(dsp_AxADDR_i),
        .dsp_AxBURST_i(dsp_AxBURST_i),        
        .dsp_AxLEN_i(dsp_AxLEN_i),         
        .dsp_AxSIZE_i(dsp_AxSIZE_i),        
        .dsp_AxVALID_i(dsp_AxVALID_i),       
        .dsp_dispatcher_full_i(dsp_dispatcher_full_i),
        .s_AxREADY_i(s_AxREADY_i),         
        .dsp_AxREADY_o(dsp_AxREADY_o),       
        .s_AxID_o(s_AxID_o),            
        .s_AxADDR_o(s_AxADDR_o),   
        .s_AxBURST_o(s_AxBURST_o),       
        .s_AxLEN_o(s_AxLEN_o),           
        .s_AxSIZE_o(s_AxSIZE_o),          
        .s_AxVALID_o(s_AxVALID_o),
        .xDATA_mst_id_o(),           
        .xDATA_crossing_flag_o(),  
        .xDATA_AxLEN_o(),          
        .xDATA_fifo_order_wr_en_o()        
    );
    reg clk;
    
    reg   [TRANS_MST_ID_W:0]      dsp_AxID  [MST_AMT-1:0];
    reg   [ADDR_WIDTH-1:0]        dsp_AxADDR [MST_AMT-1:0];
    reg   [TRANS_BURST_W-1:0]     dsp_AxBURST [MST_AMT-1:0];
    reg   [TRANS_DATA_LEN_W-1:0]  dsp_AxLEN [MST_AMT-1:0];
    reg   [TRANS_DATA_SIZE_W-1:0] dsp_AxSIZE [MST_AMT-1:0];
    
    assign ACLK_i = clk;
    
    for(genvar i = 0; i < MST_AMT; i = i + 1) begin
        assign dsp_AxID_i[TRANS_MST_ID_W*(i+1)-1-:TRANS_MST_ID_W] = dsp_AxID[i];
        assign dsp_AxADDR_i[ADDR_WIDTH*(i+1)-1-:ADDR_WIDTH] = dsp_AxADDR[i];
        assign dsp_AxBURST_i[TRANS_BURST_W*(i+1)-1-:TRANS_BURST_W] = dsp_AxBURST[i];
        assign dsp_AxLEN_i[TRANS_DATA_LEN_W*(i+1)-1-:TRANS_DATA_LEN_W] = dsp_AxLEN[i];
        assign dsp_AxSIZE_i[TRANS_DATA_SIZE_W*(i+1)-1-:TRANS_DATA_SIZE_W] = dsp_AxSIZE[i];
    end
    
    initial begin
        clk <= 0;
        forever #1 clk <= ~clk;
    end
    initial begin
       ARESETn_i <= 0;
       #5; 
       ARESETn_i <= 1; 
    end
    initial begin
        xDATA_stall_i <= 0;
        dsp_dispatcher_full_i <= 0;
        s_AxREADY_i <= 1;
        
        // 
        dsp_AxVALID_i[0] <= 0;
        dsp_AxID[0] <= 0;dsp_AxBURST[0] <= 1;dsp_AxSIZE[0] <= 0;
        dsp_AxADDR[0] <= 0;
        dsp_AxLEN[0] <= 0;
        
        // 
        dsp_AxVALID_i[1] <= 0;
        dsp_AxID[1] <= 0;dsp_AxBURST[1] <= 0;dsp_AxSIZE[1] <= 0;
        dsp_AxADDR[1] <= 0;
        dsp_AxLEN[1] <= 0;
        
        // 
        dsp_AxVALID_i[2] <= 0;
        dsp_AxID[2] <= 0;dsp_AxBURST[2] <= 1;dsp_AxSIZE[2] <= 0;
        dsp_AxADDR[2] <= 0;
        dsp_AxLEN[2] <= 0;
        
       
        #60;$stop;
    end
    
    initial begin : MASTER_BLOCK_0
        localparam mst_id = 0;
        #6;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 01;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 00;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 02;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 03;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 04;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 05;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 06;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 07;
        dsp_AxLEN[mst_id] <= 0;
        
        // End
        @(posedge clk);
        dsp_AxVALID_i[mst_id] <= 0;
    end
    
    initial begin : MASTER_BLOCK_1
        localparam mst_id = 1;
        #6;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 10;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 11;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 12;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 13;
        dsp_AxLEN[mst_id] <= 0;
        
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 14;
        dsp_AxLEN[mst_id] <= 0;
        
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 15;
        dsp_AxLEN[mst_id] <= 0;
        
        // End
        @(posedge clk);
        dsp_AxVALID_i[mst_id] <= 0;
    end
    
    initial begin : MASTER_BLOCK_2
        localparam mst_id = 2;
        #6;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 20;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 21;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 22;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 23;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 24;
        dsp_AxLEN[mst_id] <= 0;
        
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 25;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 26;
        dsp_AxLEN[mst_id] <= 0;
        
        @(posedge clk);#0.01;dsp_AxID[mst_id] <= 0;dsp_AxBURST[mst_id] <= 0;dsp_AxSIZE[mst_id] <= 0;
        dsp_AxVALID_i[mst_id] <= 1;
        dsp_AxADDR[mst_id] <= 27;
        dsp_AxLEN[mst_id] <= 0;
        
        // End
        @(posedge clk);
        dsp_AxVALID_i[mst_id] <= 0;
    end
endmodule
