module sa_W_channel
#(
    // Interconnect configuration
    parameter                       MST_AMT             = 3,
    parameter                       OUTSTANDING_AMT     = 8,
    parameter                       MST_ID_W            = $clog2(MST_AMT),
    // Transaction configuration
    parameter                       DATA_WIDTH          = 32,
    parameter                       ADDR_WIDTH          = 32,
    parameter                       TRANS_DATA_LEN_W    = 3                                 // Bus width of xLEN
)
(
    // Input declaration
    // -- Global signals
    input                                   ACLK_i,
    input                                   ARESETn_i,
    // -- To Dispatcher
    // ---- Write data channel
    input   [DATA_WIDTH*MST_AMT-1:0]        dsp_WDATA_i,
    input   [MST_AMT-1:0]                   dsp_WLAST_i,
    input   [MST_AMT-1:0]                   dsp_WVALID_i,
    // ---- Control
    input   [MST_AMT-1:0]                   dsp_slv_sel_i,
    // -- To slave (master interface of the interconnect)
    // ---- Write data channel (master)
    input                                   s_WREADY_i,
    // -- To Write Address channel
    input   [MST_ID_W-1:0]                  AW_mst_id_i,
    input   [TRANS_DATA_LEN_W-1:0]          AW_AxLEN_i,
    input                                   AW_fifo_order_wr_en_i,
    
    // Output declaration
    // -- To Dispatcher
    // ---- Write data channel (master)
    output  [MST_AMT-1:0]                   dsp_WREADY_o,
    // -- To slave (master interface of the interconnect)
    // ---- Write data channel
    output  [DATA_WIDTH-1:0]                s_WDATA_o,
    output                                  s_WLAST_o,
    output                                  s_WVALID_o,
    // -- To Ax channel
    output                                  AW_stall_o      // stall shift_en of xADDR channel
);
    // Local parameters declaration
    localparam WLAST_W      = 1;
    localparam DATA_INFO_W  = DATA_WIDTH; 
    localparam ADDR_INFO_W  = MST_ID_W + TRANS_DATA_LEN_W;
    localparam W_INFO_W     = DATA_WIDTH + 1;
    // Internal variable declaration
    genvar mst_idx;
    
    // Internal signal declaration
    // Wire declaration
    // -- FIFO WDATA ordering
    wire    [ADDR_INFO_W-1:0]       ADDR_info;
    wire    [ADDR_INFO_W-1:0]       ADDR_info_valid;
    wire                            fifo_order_rd_en;
    wire                            fifo_order_full;
    wire                            fifo_order_empt;
    wire    [MST_ID_W-1:0]          Ax_mst_id_valid;       
    wire    [TRANS_DATA_LEN_W-1:0]  Ax_AxLEN_valid;
    wire                            mst_sel                 [MST_AMT-1:0];
    // -- FIFO WDATA in                                              
    wire    [DATA_INFO_W-1:0]       DATA_info               [MST_AMT-1:0];
    wire    [DATA_INFO_W-1:0]       DATA_info_valid         [MST_AMT-1:0];
    wire                            fifo_wdata_wr_en        [MST_AMT-1:0];
    wire                            fifo_wdata_rd_en        [MST_AMT-1:0];
    wire                            fifo_wdata_full         [MST_AMT-1:0];
    wire                            fifo_wdata_empt         [MST_AMT-1:0];
    wire                            dsp_WVALID_dec          [MST_AMT-1:0];
    wire    [DATA_WIDTH-1:0]        dsp_WDATA_valid         [MST_AMT-1:0];
    wire                            dsp_WLAST_valid         [MST_AMT-1:0];
    // -- Handshake detector
    wire                            dsp_handshake_occur     [MST_AMT-1:0];
    wire                            slv_handshake_occur;
    // -- Master MUX
    wire    [DATA_WIDTH-1:0]        s_WDATA_o_nxt;
    wire                            s_WLAST_o_nxt;
    wire                            s_WVALID_o_nxt;
    // -- Booting condition
    wire                            transaction_en;
    // -- Transaction booter
    wire                            transaction_boot;
    // -- Transaction stopper
    wire                            transaction_stop;
    // -- Transfer counter
    wire    [TRANS_DATA_LEN_W-1:0]  transfer_ctn_nxt;
    wire    [TRANS_DATA_LEN_W-1:0]  transfer_ctn_incr;
    wire                            shift_en_trans_ctn;
    // -- Output control 
    wire                            WDATA_channel_shift_en;
    // -- Slave skid buffer
    wire    [W_INFO_W-1:0]          ssb_bwd_data;
    wire                            ssb_bwd_valid;
    wire                            ssb_bwd_ready;
    wire    [W_INFO_W-1:0]          ssb_fwd_data;
    wire                            ssb_fwd_valid;
    wire                            ssb_fwd_ready;
    wire    [DATA_WIDTH-1:0]        ssb_fwd_WDATA;
    wire                            ssb_fwd_WLAST;
    
    // Reg declaration
    // -- Output control
    reg     [DATA_WIDTH-1:0]        s_WDATA_o_r;
    reg                             s_WLAST_o_r;
    reg                             s_WVALID_o_r;
    // -- Transfer counter
    reg     [TRANS_DATA_LEN_W-1:0]  transfer_ctn_r;
    fifo 
    #(
        .DATA_WIDTH(ADDR_INFO_W),
        .FIFO_DEPTH(OUTSTANDING_AMT)
    ) fifo_wdata_order (
        .clk(ACLK_i),
        .data_i(ADDR_info),
        .data_o(ADDR_info_valid),
        .rd_valid_i(fifo_order_rd_en),
        .wr_valid_i(AW_fifo_order_wr_en_i),
        .empty_o(fifo_order_empt),
        .full_o(fifo_order_full),
        .almost_empty_o(),
        .almost_full_o(),
        .counter(),
        .rst_n(ARESETn_i)
    );
    // Slave skid buffer (pipelined in/out)
    skid_buffer #(
        .SBUF_TYPE(3),
        .DATA_WIDTH(W_INFO_W)
    ) slv_skid_buffer (
        .clk        (ACLK_i),
        .rst_n      (ARESETn_i),
        .bwd_data_i (ssb_bwd_data),
        .bwd_valid_i(ssb_bwd_valid),
        .fwd_ready_i(ssb_fwd_ready),
        .fwd_data_o (ssb_fwd_data),
        .bwd_ready_o(ssb_bwd_ready),
        .fwd_valid_o(ssb_fwd_valid)
    );
//    onehot_encoder #(
//        .INPUT_W(MST_AMT),
//        .OUTPUT_W(MST_ID_W)
//    ) master_id_encoder (
//        .i(Ax_mst_id_valid),
//        .o(Ax_mst_id_valid)
//    );

//    edgedet #(
//        .RISING_EDGE(1'b1)
//    )transaction_booter(
//        .clk(ACLK_i),
//        .i(transaction_en),
//        .en(1'b1),
//        .o(transaction_boot),
//        .rst_n(ARESETn_i)
//    );    
    ////////////////////////////////////////////////////////////////////////////
    assign transaction_boot = (~s_WVALID_o_r) & s_WVALID_o_nxt;
    ////////////////////////////////////////////////////////////////////////////
    
    edgedet #(
        .RISING_EDGE(1'b0)
    )transaction_stopper(
        .clk(ACLK_i),
        .i(transaction_en),
        .en(WDATA_channel_shift_en),
        .o(transaction_stop),
        .rst_n(ARESETn_i)
    );
    
    ////////////////////////////////////////////////////////////////////////////
//    assign transaction_stop = s_WVALID_o_r & (~s_WVALID_o_nxt);
    ////////////////////////////////////////////////////////////////////////////
    
    generate
        for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : MST_W_FIFO
            fifo 
            #(
                .DATA_WIDTH(DATA_INFO_W),
                .FIFO_DEPTH(32)
            ) fifo_wdata (
                .clk(ACLK_i),
                .data_i(DATA_info[mst_idx]),
                .data_o(DATA_info_valid[mst_idx]),
                .rd_valid_i(fifo_wdata_rd_en[mst_idx]),
                .wr_valid_i(fifo_wdata_wr_en[mst_idx]),
                .empty_o(fifo_wdata_empt[mst_idx]),
                .full_o(fifo_wdata_full[mst_idx]),
                .almost_empty_o(),
                .almost_full_o(),
                .counter(),
                .rst_n(ARESETn_i)
            );
        end
    endgenerate
    
    // Combinational logic
    // -- FIFO WDATA ordering
    assign ADDR_info                            = {AW_mst_id_i, AW_AxLEN_i};
    assign {Ax_mst_id_valid, Ax_AxLEN_valid}    = ADDR_info_valid;
    assign fifo_order_rd_en                     = s_WLAST_o_nxt & shift_en_trans_ctn;
    generate
        for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : MST_LOGIC
            // Onehot decoder - Master ID
            assign mst_sel[mst_idx]             = Ax_mst_id_valid == mst_idx;
            // FIFO WDATA
            assign DATA_info[mst_idx]           = {dsp_WDATA_i[DATA_WIDTH*(mst_idx+1)-1-:DATA_WIDTH]};
            assign dsp_WDATA_valid[mst_idx]     = DATA_info_valid[mst_idx];
            assign dsp_WVALID_dec[mst_idx]      = dsp_WVALID_i[mst_idx] & dsp_slv_sel_i[mst_idx];
            assign fifo_wdata_wr_en[mst_idx]    = dsp_handshake_occur[mst_idx];
            assign fifo_wdata_rd_en[mst_idx]    = mst_sel[mst_idx] & WDATA_channel_shift_en & transaction_en;
            // Handshake detector
            assign dsp_handshake_occur[mst_idx] = dsp_WVALID_dec[mst_idx] & dsp_WREADY_o[mst_idx];
            // Dispatcher Interface 
            assign dsp_WREADY_o[mst_idx]        = ~fifo_wdata_full[mst_idx];
        end
    endgenerate
    // Booting condition 
    assign transaction_en           = ~fifo_wdata_empt[Ax_mst_id_valid] & ~fifo_order_empt;
    // Transfer counter
    assign shift_en_trans_ctn       = transaction_en & WDATA_channel_shift_en;
    assign transfer_ctn_incr        = transfer_ctn_r + 1'b1;
    assign transfer_ctn_nxt         = (Ax_AxLEN_valid == transfer_ctn_r) ? {TRANS_DATA_LEN_W{1'b0}} : transfer_ctn_incr;
    // Handshake detector
    assign slv_handshake_occur      = ssb_bwd_valid & ssb_bwd_ready;
    // Output control 
    assign WDATA_channel_shift_en   = transaction_boot | (transaction_stop & slv_handshake_occur) | slv_handshake_occur;
    assign AW_stall_o               = fifo_order_full;
    assign s_WVALID_o_nxt           = transaction_en;
    assign s_WLAST_o_nxt            = (Ax_AxLEN_valid == transfer_ctn_r) & transaction_en;
    assign s_WDATA_o_nxt            = dsp_WDATA_valid[Ax_mst_id_valid];
    assign s_WVALID_o               = ssb_fwd_valid;
    assign s_WLAST_o                = ssb_fwd_WLAST;
    assign s_WDATA_o                = ssb_fwd_WDATA;
    // -- Slave skid buffer
    assign ssb_bwd_data             = {s_WDATA_o_r, s_WLAST_o_r};
    assign ssb_bwd_valid            = s_WVALID_o_r;
    assign ssb_fwd_ready            = s_WREADY_i;
    assign {ssb_fwd_WDATA, ssb_fwd_WLAST}   = ssb_fwd_data;
    
    // Flip-flop logic
    always @(posedge ACLK_i) begin
        if(~ARESETn_i) begin
            transfer_ctn_r <= {TRANS_DATA_LEN_W{1'b0}};
        end
        else if(shift_en_trans_ctn) begin
            transfer_ctn_r <= transfer_ctn_nxt;
        end
    end
    
    always @(posedge ACLK_i) begin
        if(~ARESETn_i) begin
            s_WVALID_o_r <= 1'b0;
            s_WLAST_o_r <= 1'b0;
            s_WDATA_o_r <= {DATA_WIDTH{1'b0}};
        end
        else if(WDATA_channel_shift_en) begin
            s_WVALID_o_r <= s_WVALID_o_nxt;
            s_WLAST_o_r <= s_WLAST_o_nxt;
            s_WDATA_o_r <= s_WDATA_o_nxt;
        end
    end

endmodule
