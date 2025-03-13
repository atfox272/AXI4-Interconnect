module sa_Ax_channel 
#(
    // Interconnect configuration
    parameter                       MST_AMT             = 3,
    parameter                       OUTSTANDING_AMT     = 8,
    parameter [0:(MST_AMT*32)-1]    MST_WEIGHT          = {32'd5, 32'd3, 32'd2},
    parameter                       MST_ID_W            = $clog2(MST_AMT),
    // Transaction configuration
    parameter                       DATA_WIDTH          = 32,
    parameter                       ADDR_WIDTH          = 32,
    parameter                       TRANS_MST_ID_W      = 5,                                // Width of master transaction ID 
    parameter                       TRANS_SLV_ID_W      = TRANS_MST_ID_W + $clog2(MST_AMT), // Width of slave transaction ID
    parameter                       TRANS_BURST_W       = 2,                                // Width of xBURST 
    parameter                       TRANS_DATA_LEN_W    = 3,                                // Width of xLEN
    parameter                       TRANS_DATA_SIZE_W   = 3,                                // Width of xSIZE
    // Slave info configuration
    parameter                       SLV_ID              = 0,
    parameter                       SLV_ID_MSB_IDX      = 30,
    parameter                       SLV_ID_LSB_IDX      = 30
)
(
    // Input declaration
    // -- Global signals
    input                                   ACLK_i,
    input                                   ARESETn_i,
    input                                   xDATA_stall_i,
    // -- To Dispatcher x3
    input   [TRANS_MST_ID_W*MST_AMT-1:0]    dsp_AxID_i,
    input   [ADDR_WIDTH*MST_AMT-1:0]        dsp_AxADDR_i,
    input   [TRANS_BURST_W*MST_AMT-1:0]     dsp_AxBURST_i,
    input   [TRANS_DATA_LEN_W*MST_AMT-1:0]  dsp_AxLEN_i,
    input   [TRANS_DATA_SIZE_W*MST_AMT-1:0] dsp_AxSIZE_i,
    input   [MST_AMT-1:0]                   dsp_AxVALID_i,
    input   [MST_AMT-1:0]                   dsp_dispatcher_full_i,
    // -- To slave (master interface of the interconnect)
    input                                   s_AxREADY_i,
    
    // Output declaration
    // -- To Dispatcher
    output  [MST_AMT-1:0]                   dsp_AxREADY_o,
    // -- To slave (master interface of the interconnect)
    output  [TRANS_SLV_ID_W-1:0]            s_AxID_o,
    output  [ADDR_WIDTH-1:0]                s_AxADDR_o,
    output  [TRANS_BURST_W-1:0]             s_AxBURST_o,
    output  [TRANS_DATA_LEN_W-1:0]          s_AxLEN_o,
    output  [TRANS_DATA_SIZE_W-1:0]         s_AxSIZE_o,
    output                                  s_AxVALID_o,
    // -- To xDATA channel
    output  [TRANS_SLV_ID_W-1:0]            xDATA_AxID_o,
    output  [TRANS_DATA_LEN_W-1:0]          xDATA_AxLEN_o,
    output  [MST_ID_W-1:0]                  xDATA_mst_id_o,
    output                                  xDATA_crossing_flag_o,
    output                                  xDATA_fifo_order_wr_en_o
);
    // Local parameters initialization
    localparam ADDR_INFO_W  = TRANS_MST_ID_W + ADDR_WIDTH + TRANS_BURST_W + TRANS_DATA_LEN_W + TRANS_DATA_SIZE_W;
    localparam AX_INFO_W    = TRANS_SLV_ID_W + ADDR_WIDTH + TRANS_BURST_W + TRANS_DATA_LEN_W + TRANS_DATA_SIZE_W;
    
    // Internal variable declaration
    genvar mst_idx;
    
    // Internal signal declaration
    // wire declaration
    // ---- Pre Arbitration
    wire    [ADDR_INFO_W-1:0]       ADDR_info               [MST_AMT-1:0];
    wire    [ADDR_INFO_W-1:0]       ADDR_info_valid         [MST_AMT-1:0];
    wire    [ADDR_WIDTH-1:0]        AxADDR_i                [MST_AMT-1:0];  // De-flatten wire 
    wire    [TRANS_MST_ID_W-1:0]    AxID_valid              [MST_AMT-1:0];
    wire    [ADDR_WIDTH-1:0]        AxADDR_valid            [MST_AMT-1:0];
    wire    [TRANS_BURST_W-1:0]     AxBURST_valid           [MST_AMT-1:0];
    wire    [TRANS_DATA_LEN_W-1:0]  AxLEN_valid             [MST_AMT-1:0];
    wire    [TRANS_DATA_SIZE_W-1:0] AxSIZE_valid            [MST_AMT-1:0];
    wire    [ADDR_WIDTH-1:0]        AxADDR_valid_split      [MST_AMT-1:0];
    wire    [TRANS_DATA_LEN_W-1:0]  AxLEN_valid_split       [MST_AMT-1:0];
    wire                            fifo_addr_info_full     [MST_AMT-1:0];
    wire                            fifo_addr_info_empt     [MST_AMT-1:0];
    wire                            fifo_addr_info_wr_en    [MST_AMT-1:0];
    wire                            fifo_addr_info_rd_en    [MST_AMT-1:0];
    wire                            dsp_handshake_occur     [MST_AMT-1:0];  
    wire                            dsp_AxVALID_dec         [MST_AMT-1:0];  // decoded AxVALID
    wire                            slv_addr_decoder        [MST_AMT-1:0];
    wire                            msk_addr_crossing_flag  [MST_AMT-1:0];
    wire                            msk_addr_crossing_valid [MST_AMT-1:0];
    wire                            msk_split_addr_sel_nxt  [MST_AMT-1:0];
    wire                            msk_split_addr_sel_en   [MST_AMT-1:0];
    wire                            rd_addr_info            [MST_AMT-1:0];
    // ---- In Arbitration
    wire    [MST_AMT-1:0]           arb_req;
    wire    [MST_AMT-1:0]           arb_grant_valid;
    wire                            arb_grant_ready;
    wire    [TRANS_DATA_LEN_W-1:0]  arb_num_grant_req;
    wire    [MST_ID_W-1:0]          granted_mst_id;
    wire                            arb_req_remain;
    // ---- Post arbitration
    wire    [TRANS_SLV_ID_W-1:0]    AxID_o_nxt;
    wire    [ADDR_WIDTH-1:0]        AxADDR_o_nxt;
    wire    [TRANS_BURST_W-1:0]     AxBURST_o_nxt;
    wire    [TRANS_DATA_LEN_W-1:0]  AxLEN_o_nxt;
    wire    [TRANS_DATA_SIZE_W-1:0] AxSIZE_o_nxt;
    wire                            AxVALID_o_nxt;
    wire                            slv_handshake_occur;
    wire                            tbr_trans_boot;
    // 
    wire                            xADDR_channel_shift_en;
    wire                            x_channel_shift_en;
    // -- Slave skid buffer
    wire    [AX_INFO_W-1:0]         ssb_bwd_data;
    wire                            ssb_bwd_valid;
    wire                            ssb_bwd_ready;
    wire    [AX_INFO_W-1:0]         ssb_fwd_data;
    wire                            ssb_fwd_valid;
    wire                            ssb_fwd_ready;
    wire    [TRANS_SLV_ID_W-1:0]    ssb_fwd_AxID;
    wire    [ADDR_WIDTH-1:0]        ssb_fwd_AxADDR;
    wire    [TRANS_BURST_W-1:0]     ssb_fwd_AxBURST;
    wire    [TRANS_DATA_LEN_W-1:0]  ssb_fwd_AxLEN;
    wire    [TRANS_DATA_SIZE_W-1:0] ssb_fwd_AxSIZE;
    
    // reg declaration
    reg     [TRANS_SLV_ID_W-1:0]    AxID_o_r;
    reg     [ADDR_WIDTH-1:0]        AxADDR_o_r;
    reg     [TRANS_BURST_W-1:0]     AxBURST_o_r;
    reg     [TRANS_DATA_LEN_W-1:0]  AxLEN_o_r;
    reg     [TRANS_DATA_SIZE_W-1:0] AxSIZE_o_r;
    reg                             AxVALID_o_r;
    reg                             msk_split_addr_sel      [MST_AMT-1:0];
    reg                             trans_booter_flag;
    
    // Module initialization
    generate
        for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : MST_FIFO
            // ADDR info FIFO
            sync_fifo #(
                .FIFO_TYPE(2),              // Full flop
                .DATA_WIDTH(ADDR_INFO_W),
                .FIFO_DEPTH(OUTSTANDING_AMT)
            ) fifo_Ax_channel (
                .clk(ACLK_i),
                .data_i(ADDR_info[mst_idx]),
                .data_o(ADDR_info_valid[mst_idx]),
                .rd_valid_i(fifo_addr_info_rd_en[mst_idx]),
                .wr_valid_i(fifo_addr_info_wr_en[mst_idx]),
                .empty_o(fifo_addr_info_empt[mst_idx]),
                .full_o(fifo_addr_info_full[mst_idx]),
                .wr_ready_o(),
                .rd_ready_o(),
                .almost_empty_o(),
                .almost_full_o(),
                .counter(),
                .rst_n(ARESETn_i)
            );
            // 4KB masker
            splitting_4kb_masker #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .LEN_WIDTH(TRANS_DATA_LEN_W),
                .SIZE_WIDTH(TRANS_DATA_SIZE_W)
            ) splitting_4kb_masker (
                .ADDR_i(AxADDR_valid[mst_idx]),      
                .LEN_i(AxLEN_valid[mst_idx]),
                .SIZE_i(AxSIZE_valid[mst_idx]),      
                .mask_sel_i(msk_split_addr_sel[mst_idx]),
                .ADDR_split_o(AxADDR_valid_split[mst_idx]),
                .LEN_split_o(AxLEN_valid_split[mst_idx]), 
                .crossing_flag(msk_addr_crossing_flag[mst_idx])
            );
        end
    endgenerate
    arbiter_iwrr_1cycle #(
        .P_REQUESTER_NUM(MST_AMT),
        .P_REQUESTER_WEIGHT(MST_WEIGHT),
        .P_NUM_GRANT_REQ_W(1)
    ) arbiter (
        .clk(ACLK_i),
        .rst_n(ARESETn_i),
        .req_i(arb_req),          
        .req_weight_i(),
        .num_grant_req_i(1'b1),
        .grant_ready_i(arb_grant_ready),  
        .grant_valid_o(arb_grant_valid)
    );
    onehot_encoder #(
        .INPUT_W(MST_AMT),
        .OUTPUT_W(MST_ID_W)
    ) master_id_encoder (
        .i(arb_grant_valid),
        .o(granted_mst_id)
    );
    
    // Slave skid buffer (pipelined in/out)
    skid_buffer #(
        .SBUF_TYPE(3),
        .DATA_WIDTH(AX_INFO_W)
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
//    edgedet 
//    #(
//        .RISING_EDGE(1'b1)
//    )transaction_booter(
//        .clk(ACLK_i),
//        .i(AxVALID_o_nxt),
////        .en(1'b1),
//        .en(~AxVALID_o_r),
//        .o(tbr_trans_boot),
//        .rst_n(ARESETn_i)
//    );
    //////////////////////////////////////////
    assign tbr_trans_boot = AxVALID_o_nxt & ~AxVALID_o_r;
    //////////////////////////////////////////
    
    // Combinational logic
    generate
    for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : MST_LOGIC
        // Dispatcher interface
        assign dsp_AxREADY_o[mst_idx] = ~(dsp_dispatcher_full_i[mst_idx] | fifo_addr_info_full[mst_idx]);
        // FIFO
        assign ADDR_info[mst_idx] = {dsp_AxID_i[TRANS_MST_ID_W*(mst_idx+1)-1-:TRANS_MST_ID_W], dsp_AxADDR_i[ADDR_WIDTH*(mst_idx+1)-1-:ADDR_WIDTH], dsp_AxBURST_i[TRANS_BURST_W*(mst_idx+1)-1-:TRANS_BURST_W], dsp_AxLEN_i[TRANS_DATA_LEN_W*(mst_idx+1)-1-:TRANS_DATA_LEN_W], dsp_AxSIZE_i[TRANS_DATA_SIZE_W*(mst_idx+1)-1-:TRANS_DATA_SIZE_W]}; // ADDR_info[mst_0] = AxID[mst_0] | AxADDR[mst_0] | AxLEN[mst_0] | AxSIZE[mst_0]
        assign AxADDR_i[mst_idx] = dsp_AxADDR_i[ADDR_WIDTH*(mst_idx+1)-1-:ADDR_WIDTH];
        assign slv_addr_decoder[mst_idx] = AxADDR_i[mst_idx][SLV_ID_MSB_IDX:SLV_ID_LSB_IDX] == SLV_ID;
        assign dsp_AxVALID_dec[mst_idx] = slv_addr_decoder[mst_idx] & dsp_AxVALID_i[mst_idx];
        assign dsp_handshake_occur[mst_idx] = dsp_AxVALID_dec[mst_idx] & dsp_AxREADY_o[mst_idx];
        assign fifo_addr_info_wr_en[mst_idx] = dsp_handshake_occur[mst_idx];
        assign {AxID_valid[mst_idx], AxADDR_valid[mst_idx], AxBURST_valid[mst_idx], AxLEN_valid[mst_idx], AxSIZE_valid[mst_idx]} = ADDR_info_valid[mst_idx];
        // ADDR mask controller
        assign rd_addr_info[mst_idx] = arb_grant_valid[mst_idx] & xADDR_channel_shift_en & AxVALID_o_nxt;
        assign fifo_addr_info_rd_en[mst_idx] = rd_addr_info[mst_idx] & (~msk_addr_crossing_flag[mst_idx] | msk_split_addr_sel[mst_idx]);
        assign msk_split_addr_sel_nxt[mst_idx] = ~msk_split_addr_sel[mst_idx];
        assign msk_split_addr_sel_en[mst_idx] = rd_addr_info[mst_idx] & msk_addr_crossing_flag[mst_idx];
        assign msk_addr_crossing_valid[mst_idx] = (~msk_split_addr_sel[mst_idx]) & msk_addr_crossing_flag[mst_idx];
        // Arbiter        
        assign arb_req[mst_idx] = ~fifo_addr_info_empt[mst_idx];
    end
    endgenerate
    // Arbiter
    assign arb_req_remain = |arb_req;
    assign arb_grant_ready = xADDR_channel_shift_en;
    assign arb_num_grant_req = AxLEN_o_nxt + 1'b1;
    assign slv_handshake_occur = ssb_bwd_valid & ssb_bwd_ready;
    assign xADDR_channel_shift_en = slv_handshake_occur | tbr_trans_boot;
    assign x_channel_shift_en = xADDR_channel_shift_en & ~xDATA_stall_i;
    
    assign s_AxID_o = ssb_fwd_AxID;
    assign s_AxADDR_o = ssb_fwd_AxADDR;
    assign s_AxBURST_o = ssb_fwd_AxBURST;
    assign s_AxLEN_o = ssb_fwd_AxLEN;
    assign s_AxSIZE_o = ssb_fwd_AxSIZE;
    assign s_AxVALID_o = ssb_fwd_valid;
    assign AxID_o_nxt = {granted_mst_id, AxID_valid[granted_mst_id]};
    assign AxADDR_o_nxt = AxADDR_valid_split[granted_mst_id];
    assign AxBURST_o_nxt = AxBURST_valid[granted_mst_id];
    assign AxLEN_o_nxt = AxLEN_valid_split[granted_mst_id];
    assign AxSIZE_o_nxt = AxSIZE_valid[granted_mst_id];
    assign AxVALID_o_nxt = arb_req_remain & ~xDATA_stall_i;
    // -- 
    assign xDATA_AxID_o = AxID_o_nxt;
    assign xDATA_mst_id_o = AxID_o_nxt[TRANS_SLV_ID_W-1-:MST_ID_W];
    assign xDATA_crossing_flag_o = msk_addr_crossing_valid[granted_mst_id];
    assign xDATA_AxLEN_o = AxLEN_o_nxt;
    assign xDATA_fifo_order_wr_en_o = AxVALID_o_nxt & x_channel_shift_en;
    // -- Slave skid buffer 
    assign ssb_bwd_data     = {AxID_o_r, AxADDR_o_r, AxBURST_o_r, AxLEN_o_r, AxSIZE_o_r};
    assign ssb_bwd_valid    = AxVALID_o_r;
    assign ssb_fwd_ready    = s_AxREADY_i;
    assign {ssb_fwd_AxID, ssb_fwd_AxADDR, ssb_fwd_AxBURST, ssb_fwd_AxLEN, ssb_fwd_AxSIZE} = ssb_fwd_data;
    // Flip-flop logic
    generate
    // -- ADDR mask controller
    for(mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : MST_FLOP
        always @(posedge ACLK_i) begin
            if(~ARESETn_i) begin
                msk_split_addr_sel[mst_idx] <= 0;
            end
            else if (msk_split_addr_sel_en[mst_idx]) begin
                msk_split_addr_sel[mst_idx] <= msk_split_addr_sel_nxt[mst_idx];
            end
        end
    end 
    endgenerate
    // -- Output reg
    // -- -- AW info
    always @(posedge ACLK_i) begin
        if(~ARESETn_i) begin
            AxID_o_r <= 0;
            AxADDR_o_r <= 0;
            AxBURST_o_r <= 0;
            AxLEN_o_r <= 0;
            AxSIZE_o_r <= 0;
        end
        else if(x_channel_shift_en) begin
            AxID_o_r <= AxID_o_nxt;
            AxADDR_o_r <= AxADDR_o_nxt;
            AxBURST_o_r <= AxBURST_o_nxt;
            AxLEN_o_r <= AxLEN_o_nxt;
            AxSIZE_o_r <= AxSIZE_o_nxt;
        end
    end
    // -- -- AW control
    always @(posedge ACLK_i) begin
        if(~ARESETn_i) begin
            AxVALID_o_r <= 0;
        end
        else if(xADDR_channel_shift_en) begin
            AxVALID_o_r <= AxVALID_o_nxt;
        end
    end
endmodule