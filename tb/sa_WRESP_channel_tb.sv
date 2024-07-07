`timescale 1ns / 1ps
module sa_WRESP_channel_tb;
    // Interconnect configuration
    parameter MST_AMT           = 3;
    parameter OUTSTANDING_AMT   = 8;
    parameter MST_ID_W          = $clog2(MST_AMT);
    // Transaction configuration
    parameter TRANS_MST_ID_W    = 5;    // Width of master transaction ID 
    parameter TRANS_SLV_ID_W    = TRANS_MST_ID_W + $clog2(MST_AMT);// Width of slave transaction ID
    parameter TRANS_WR_RESP_W   = 2;
    
    // Input declaration
    // -- Global signals
    logic                                   ACLK_i;
    logic                                   ARESETn_i;
    // -- To Dispatcher
    // ---- Write response channel
    logic   [MST_AMT-1:0]                   dsp_BREADY_i;
    // -- To slave (master interface of the interconnect)
    // ---- Write response channel (master)
    logic   [TRANS_SLV_ID_W-1:0]            s_BID_i;
    logic   [TRANS_WR_RESP_W-1:0]           s_BRESP_i;
    logic                                   s_BVALID_i;
    // -- To Write Address channel
    logic   [TRANS_SLV_ID_W-1:0]            AW_AxID_i;
    logic                                   AW_crossing_flag_i;
    logic                                   AW_shift_en_i;
    // Output declaration
    // -- To Dispatcher
    // ---- Write response channel (master)
    logic   [TRANS_SLV_ID_W*MST_AMT-1:0]    dsp_BID_o;
    logic   [TRANS_WR_RESP_W*MST_AMT-1:0]   dsp_BRESP_o;
    logic   [MST_AMT-1:0]                   dsp_BVALID_o;
    // -- To slave (master interface of the interconnect)
    // ---- Write response channel          
    logic                                   s_BREADY_o;
    // To Write Address channel
    logic                                   AW_stall_o;
    
    wire    [TRANS_SLV_ID_W-1:0]            dsp_BID         [MST_AMT-1:0];
    wire    [TRANS_WR_RESP_W-1:0]           dsp_BRESP       [MST_AMT-1:0];
    sa_WRESP_channel #(
        .MST_AMT(MST_AMT),
        .OUTSTANDING_AMT(OUTSTANDING_AMT),
        .MST_ID_W(MST_ID_W),
        .TRANS_MST_ID_W(TRANS_MST_ID_W),
        .TRANS_SLV_ID_W(TRANS_SLV_ID_W),
        .TRANS_WR_RESP_W(TRANS_WR_RESP_W)
    ) uut (
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),
        .dsp_BREADY_i(dsp_BREADY_i),
        .s_BID_i(s_BID_i),
        .s_BRESP_i(s_BRESP_i),
        .s_BVALID_i(s_BVALID_i),
        .AW_AxID_i(AW_AxID_i),
        .AW_crossing_flag_i(AW_crossing_flag_i),
        .AW_shift_en_i(AW_shift_en_i),
        .dsp_BID_o(dsp_BID_o),
        .dsp_BRESP_o(dsp_BRESP_o),
        .dsp_BVALID_o(dsp_BVALID_o),
        .s_BREADY_o(s_BREADY_o),
        .AW_stall_o(AW_stall_o)
    );
    
    for(genvar i = 0; i < MST_AMT; i = i + 1) begin
        assign dsp_BID[i] = dsp_BID_o[TRANS_SLV_ID_W*(i+1)-1-:TRANS_SLV_ID_W];
        assign dsp_BRESP[i] = dsp_BRESP_o[TRANS_WR_RESP_W*(i+1)-1-:TRANS_WR_RESP_W];
    end
    
    initial begin
        ACLK_i <= 0;
        forever #1 ACLK_i <= ~ACLK_i;
    end
    
    initial begin
        ARESETn_i <= 0;
        
        dsp_BREADY_i <= {MST_AMT{1'b1}};
        
        s_BID_i <= 0;
        s_BRESP_i <= 0;
        s_BVALID_i <= 0;
        
        AW_AxID_i <= 0;
        AW_crossing_flag_i <= 0;
        AW_shift_en_i <= 0;
        
        #5; ARESETn_i <= 1;
        
    end
    
    initial begin : FROM_WADDR
        #6;
        
        @(posedge ACLK_i); #0.01;
        AW_AxID_i <= {2'd1, 5'd01};
        AW_crossing_flag_i <= 1'b1;
        AW_shift_en_i <= 1;
        
        // No crossing
        @(posedge ACLK_i); #0.01;
        AW_AxID_i <= {2'd0, 5'd01};
        AW_crossing_flag_i <= 1'b0;
        AW_shift_en_i <= 1;
        
        
        @(posedge ACLK_i); #0.01;
        AW_AxID_i <= {2'd2, 5'd02};
        AW_crossing_flag_i <= 1'b1;
        AW_shift_en_i <= 1;
        
        // Stop
        @(posedge ACLK_i); #0.01;
        AW_shift_en_i <= 0;
    end
    
    initial begin : FROM_SLAVE
        #6;
        
        ////
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd0, 5'd01};
        
        @(posedge ACLK_i); #0.01;
//        @(s_BVALID_i & s_BREADY_o) #0.001;
        s_BVALID_i <= 0;
        
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd1, 5'd01};
        
        @(posedge ACLK_i); #0.01;
//        @(s_BVALID_i & s_BREADY_o) #0.001;
        s_BVALID_i <= 0;
        
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd2, 5'd01};
        
        @(posedge ACLK_i); #0.01;
//        @(s_BVALID_i & s_BREADY_o) #0.001;
        s_BVALID_i <= 0;
        
        
        //// 
        @(posedge ACLK_i); #0.01; s_BVALID_i <= 1; s_BRESP_i <= 0;
        s_BID_i <= {2'd2, 5'd02};
        
        @(posedge ACLK_i); #0.01;
//        @(s_BVALID_i & s_BREADY_o) #0.001;
        s_BVALID_i <= 0;
    end
    
    initial begin
        #150; $stop;
    end
    
endmodule
