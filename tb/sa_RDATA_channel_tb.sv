`timescale 1ns / 1ps
module sa_RDATA_channel_tb;
    // Interconnect configuration
    parameter                       MST_AMT             = 3;
    parameter                       OUTSTANDING_AMT     = 8;
    parameter                       MST_ID_W            = $clog2(MST_AMT);
    // Transaction configuration
    parameter                       DATA_WIDTH          = 32;
    parameter                       ADDR_WIDTH          = 32;
    parameter                       TRANS_MST_ID_W      = 5;                            // Bus width of master transaction ID 
    parameter                       TRANS_SLV_ID_W      = TRANS_MST_ID_W + MST_ID_W;     // Bus width of slave transaction ID
    
    // Input declaration
    // -- Global signals
    logic                                   ACLK_i;
    logic                                   ARESETn_i;
    // -- To Dispatcher
    // ---- Read data channel
    logic   [MST_AMT-1:0]                   dsp_RREADY_i;
    // -- To slave (master interface of the interconnect)
    // ---- Read data channel 
    logic   [TRANS_SLV_ID_W-1:0]            s_RID_i;
    logic   [DATA_WIDTH-1:0]                s_RDATA_i;
    logic                                   s_RLAST_i;
    logic                                   s_RVALID_i;
    // -- To Read Address channel
    logic   [TRANS_SLV_ID_W-1:0]            AR_AxID_i;
    logic                                   AR_crossing_flag_i;
    logic                                   AR_shift_en_i;
    
    // Output declaration
    // -- To Dispatcher
    // ---- Read data channel (master)
    logic   [TRANS_MST_ID_W*MST_AMT-1:0]    dsp_RID_o;
    logic   [DATA_WIDTH*MST_AMT-1:0]        dsp_RDATA_o;
    logic   [MST_AMT-1:0]                   dsp_RLAST_o;
    logic   [MST_AMT-1:0]                   dsp_RVALID_o;
    // -- To slave (master interface of the interconnect)
    // ---- Read data channel
    logic                                   s_RREADY_o;
    // To Write Address channel
    logic                                   AR_stall_o;
    
    wire    [TRANS_MST_ID_W-1:0]            dsp_RID [MST_AMT-1:0];
    for(genvar i = 0; i < MST_AMT; i = i + 1) begin
        assign dsp_RID[i] = dsp_RID_o[TRANS_MST_ID_W*(i+1)-1-:TRANS_MST_ID_W];
    end 
    
    sa_RDATA_channel #(
        .MST_AMT(MST_AMT),
        .OUTSTANDING_AMT(OUTSTANDING_AMT),
        .MST_ID_W(MST_ID_W),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TRANS_MST_ID_W(TRANS_MST_ID_W), 
        .TRANS_SLV_ID_W(TRANS_SLV_ID_W) 
    ) uut (
        .ACLK_i(ACLK_i),            
        .ARESETn_i(ARESETn_i),         
        .dsp_RREADY_i(dsp_RREADY_i),      
        .s_RID_i(s_RID_i),           
        .s_RDATA_i(s_RDATA_i),         
        .s_RLAST_i(s_RLAST_i),         
        .s_RVALID_i(s_RVALID_i),        
        .AR_AxID_i(AR_AxID_i),         
        .AR_crossing_flag_i(AR_crossing_flag_i),
        .AR_shift_en_i(AR_shift_en_i),     
        .dsp_RID_o(dsp_RID_o),         
        .dsp_RDATA_o(dsp_RDATA_o),       
        .dsp_RLAST_o(dsp_RLAST_o),       
        .dsp_RVALID_o(dsp_RVALID_o),      
        .s_RREADY_o(s_RREADY_o),        
        .AR_stall_o(AR_stall_o)         
    );
    
    initial begin
        ACLK_i <= 0;
        forever #1 ACLK_i <= ~ACLK_i;
    end
    
    initial begin
        ARESETn_i <= 0;
        #5; ARESETn_i <= 1;
    end 
    
    initial begin
        dsp_RREADY_i <= {MST_AMT{1'b1}};     

        s_RID_i <= 0;          
        s_RDATA_i <= 0;        
        s_RLAST_i <= 0;        
        s_RVALID_i <= 0;       
                          
        AR_AxID_i <= 0;        
        AR_crossing_flag_i <= 0;
        AR_shift_en_i <= 0;  
    end
    
    initial begin : FROM_RADDR
        #6;
        
        @(posedge ACLK_i); #0.01;
        AR_AxID_i <= {2'd01, 5'd01};        
        AR_crossing_flag_i <= 1; AR_shift_en_i <= 1;
        
        @(posedge ACLK_i); #0.01;
        AR_AxID_i <= {2'd0, 5'd02};        
        AR_crossing_flag_i <= 1; AR_shift_en_i <= 1;
        
        @(posedge ACLK_i); #0.01;
        AR_AxID_i <= {2'd2, 5'd00};        
        AR_crossing_flag_i <= 1; AR_shift_en_i <= 1;  
        
        // Stop
        @(posedge ACLK_i); #0.01;
        AR_crossing_flag_i <= 1; AR_shift_en_i <= 0;  
        
    end 
    
    initial begin
        #6;
        
        // First transaction
        @(posedge ACLK_i); #0.01;
        s_RID_i <= {2'd01, 5'd02};          
        s_RDATA_i <= 1;        
        s_RLAST_i <= 1;        
        s_RVALID_i <= 1;
        
        
        // Second transaction
        @(posedge ACLK_i); #0.01;
        s_RID_i <= {2'd01, 5'd03};          
        s_RDATA_i <= 0;        
        s_RLAST_i <= 1;        
        s_RVALID_i <= 1;
        
        // Third transaction
        @(posedge ACLK_i); #0.01;
        s_RID_i <= {2'd01, 5'd01};          
        s_RDATA_i <= 1;        
        s_RLAST_i <= 0;        
        s_RVALID_i <= 1;
        @(posedge ACLK_i); #0.01;
        s_RDATA_i <= 0;        
        s_RLAST_i <= 0;        
        s_RVALID_i <= 1;
        @(posedge ACLK_i); #0.01;
        s_RDATA_i <= 2;        
        s_RLAST_i <= 1;        
        s_RVALID_i <= 1;
        
        // Fourth transaction
        @(posedge ACLK_i); #0.01;
        s_RID_i <= {2'd00, 5'd02};          
        s_RDATA_i <= 1;        
        s_RLAST_i <= 0;        
        s_RVALID_i <= 1;
        @(posedge ACLK_i); #0.01;
        s_RDATA_i <= 0;        
        s_RLAST_i <= 0;        
        s_RVALID_i <= 1;
        @(posedge ACLK_i); #0.01;
        s_RDATA_i <= 2;        
        s_RLAST_i <= 1;        
        s_RVALID_i <= 1;
        
        
        // Fifth transaction
        @(posedge ACLK_i); #0.01;
        s_RID_i <= {2'd00, 5'd02};          
        s_RDATA_i <= 1;        
        s_RLAST_i <= 0;        
        s_RVALID_i <= 1;
        @(posedge ACLK_i); #0.01;
        s_RDATA_i <= 0;        
        s_RLAST_i <= 0;        
        s_RVALID_i <= 1;
        @(posedge ACLK_i); #0.01;
        s_RDATA_i <= 2;        
        s_RLAST_i <= 1;        
        s_RVALID_i <= 1;
        
    end
    
endmodule
