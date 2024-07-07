`timescale 1ns / 1ps
module sa_WDATA_channel_tb;
    // Interconnect configuration
    parameter                       MST_AMT             = 3;
    parameter                       OUTSTANDING_AMT     = 8;
    parameter                       MST_ID_W            = $clog2(MST_AMT);
    // Transaction configuration
    parameter                       DATA_WIDTH          = 32;
    parameter                       ADDR_WIDTH          = 32;
    parameter                       TRANS_DATA_LEN_W    = 3;          
    
    // Input declaration
    // -- Global signals
    logic                                 ACLK_i;
    logic                                 ARESETn_i;
    // -- To Dispatcher
    // ---- Write data channel
    logic [DATA_WIDTH*MST_AMT-1:0]        dsp_WDATA_i;
    logic [MST_AMT-1:0]                   dsp_WLAST_i;
    logic [MST_AMT-1:0]                   dsp_WVALID_i;
    // ---- Control
    logic [MST_AMT-1:0]                   dsp_slv_sel_i;
    // -- To slave (master interface of the interconnect)
    // ---- Write data channel (master)
    logic                                 s_WREADY_i;
    // -- To Ax channel
    logic   [MST_ID_W-1:0]                  AW_mst_id_i;
    logic   [TRANS_DATA_LEN_W-1:0]          AW_AxLEN_i;
    logic                                   AW_fifo_order_wr_en_i;
    
    // Output declaration
    // -- To Dispatcher
    // ---- Write data channel (master)
    logic   [MST_AMT-1:0]                   dsp_WREADY_o;
    // -- To slave (master interface of the interconnect)
    // ---- Write data channel
    logic  [DATA_WIDTH-1:0]                s_WDATA_o;
    logic                                  s_WLAST_o;
    logic                                  s_WVALID_o;
    // -- To Ax channel
    logic                                  AW_stall_o;    // stall shift_en of xADDR channel  
    
    // External things
    logic   clk;
    logic   [DATA_WIDTH-1:0] dsp_WDATA_m [MST_AMT-1:0];
    
    genvar mst_idx;
    for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin
        assign dsp_WDATA_i[DATA_WIDTH*(mst_idx+1)-1-:DATA_WIDTH] = dsp_WDATA_m[mst_idx];
    end
    assign ACLK_i = clk;
        
    sa_WDATA_channel #(
    
    ) uut (
    .ACLK_i(ACLK_i),                                       
    .ARESETn_i(ARESETn_i),                                    
    .dsp_WDATA_i(dsp_WDATA_i),                                  
    .dsp_WLAST_i(dsp_WLAST_i),                                  
    .dsp_WVALID_i(dsp_WVALID_i),                                 
    .dsp_slv_sel_i(dsp_slv_sel_i),                                 
    .s_WREADY_i(s_WREADY_i),                                   
    .AW_mst_id_i(AW_mst_id_i),                                         
    .AW_AxLEN_i(AW_AxLEN_i),                                   
    .AW_fifo_order_wr_en_i(AW_fifo_order_wr_en_i),                        
    .dsp_WREADY_o(dsp_WREADY_o),                                 
    .s_WDATA_o(s_WDATA_o),                                    
    .s_WLAST_o(s_WLAST_o),                                    
    .s_WVALID_o(s_WVALID_o),                                   
    .AW_stall_o(AW_stall_o)    
    );
    
    initial begin
        clk <= 0;
        forever #1 clk <= ~clk;
    end
    
    initial begin
        ARESETn_i <= 0;
        
        dsp_WDATA_m[0] <= 0;
        dsp_WDATA_m[1] <= 0;
        dsp_WDATA_m[2] <= 0;
        
        dsp_WLAST_i[0] <= 0;
        dsp_WLAST_i[1] <= 0;
        dsp_WLAST_i[2] <= 0;
        
        dsp_WVALID_i[0] <= 0;
        dsp_WVALID_i[1] <= 0;
        dsp_WVALID_i[2] <= 0;
        
        dsp_slv_sel_i[0] <= 1;
        dsp_slv_sel_i[1] <= 1;
        dsp_slv_sel_i[2] <= 1;
        s_WREADY_i <= 1;
        
        AW_mst_id_i <= 0;
        AW_AxLEN_i <= 0;
        AW_fifo_order_wr_en_i <= 0;
        #10;
        ARESETn_i <= 1;
        
    end
    
    initial begin : WDATA_0
        #11.001;
        
        dsp_WVALID_i[0] <= 1;
        dsp_WDATA_m[0] <= 5;
        
        @(posedge clk);#0.001;dsp_WVALID_i[0] <= 1;
        dsp_WDATA_m[0] <= 6;
        
        @(posedge clk);#0.001;dsp_WVALID_i[0] <= 1;
        dsp_WDATA_m[0] <= 7;
        
        @(posedge clk);#0.001;dsp_WVALID_i[0] <= 1;
        dsp_WDATA_m[0] <= 8;
        
        @(posedge clk);#0.001;dsp_WVALID_i[0] <= 1;
        dsp_WDATA_m[0] <= 9;
        
        @(posedge clk);#0.001;dsp_WVALID_i[0] <= 1;
        dsp_WDATA_m[0] <= 10;
        
        // End burst
        @(posedge clk);#0.001;dsp_WVALID_i[0] <= 0; 
        
        
        #50;
        @(posedge clk);#0.001;dsp_WVALID_i[0] <= 1;
        dsp_WDATA_m[0] <= 10;

        // End burst
        @(posedge clk);#0.001;dsp_WVALID_i[0] <= 0; 
        
    end
    
    initial begin : WDATA_1
        #11.001;
        
        dsp_WVALID_i[1] <= 1;
        dsp_WDATA_m[1] <= 15;
        
        @(posedge clk);#0.001;dsp_WVALID_i[1] <= 1;
        dsp_WDATA_m[1] <= 16;
        
        @(posedge clk);#0.001;dsp_WVALID_i[1] <= 1;
        dsp_WDATA_m[1] <= 17;
        
        @(posedge clk);#0.001;dsp_WVALID_i[1] <= 1;
        dsp_WDATA_m[1] <= 18;
        
        @(posedge clk);#0.001;dsp_WVALID_i[1] <= 1;
        dsp_WDATA_m[1] <= 19;
        
        @(posedge clk);#0.001;dsp_WVALID_i[1] <= 1;
        dsp_WDATA_m[1] <= 20;
        
        // End burst
        @(posedge clk);#0.001;dsp_WVALID_i[1] <= 0; 

    end
    
    initial begin
        #21.001;
        
        @(posedge clk);#0.001;AW_fifo_order_wr_en_i <= 1;
        AW_mst_id_i <= 0;
        AW_AxLEN_i <= 3;
        
        @(posedge clk);#0.001;AW_fifo_order_wr_en_i <= 1;
        AW_mst_id_i <= 1;
        AW_AxLEN_i <= 5;
        
        
        @(posedge clk);#0.001;AW_fifo_order_wr_en_i <= 1;
        AW_mst_id_i <= 0;
        AW_AxLEN_i <= 2;
        
        @(posedge clk);#0.001;AW_fifo_order_wr_en_i <= 0;
    end
    
endmodule
