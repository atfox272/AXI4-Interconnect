module dsp_xADDR_channel
#(
    // Dispatcher configuration
    parameter SLV_AMT           = 2,
    parameter OUTSTANDING_AMT   = 8,
    parameter OUTST_CTN_W       = $clog2(OUTSTANDING_AMT) + 1,
    // Transaction configuration
    parameter DATA_WIDTH        = 32,
    parameter ADDR_WIDTH        = 32,
    parameter TRANS_MST_ID_W    = 5,    // Bus width of master transaction ID 
    parameter TRANS_BURST_W     = 2,    // Width of xBURST 
    parameter TRANS_DATA_LEN_W  = 3,    // Bus width of xLEN
    parameter TRANS_DATA_SIZE_W = 3,    // Bus width of xSIZE
    // Slave configuration
    parameter SLV_ID_W          = $clog2(SLV_AMT),
    parameter SLV_ID_MSB_IDX    = 30,
    parameter SLV_ID_LSB_IDX    = 30
)
(
    // Input declaration
    // -- Global signals
    input                                   ACLK_i,
    input                                   ARESETn_i,
    // -- To Master (slave interface of the interconnect)
    // ---- Write/Read address channel
    input   [TRANS_MST_ID_W-1:0]            m_AxID_i,
    input   [ADDR_WIDTH-1:0]                m_AxADDR_i,
    input   [TRANS_BURST_W-1:0]             m_AxBURST_i,
    input   [TRANS_DATA_LEN_W-1:0]          m_AxLEN_i,
    input   [TRANS_DATA_SIZE_W-1:0]         m_AxSIZE_i,
    input                                   m_AxVALID_i,
    // -- To xDATA channel Dispatcher
    input                                   m_xVALID_i,
    input                                   m_xREADY_i,
    // -- To Slave Arbitration
    // ---- Write/Read address channel (master)
    input   [SLV_AMT-1:0]                   sa_AxREADY_i,
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Write/Read address channel (master)
    output                                  m_AxREADY_o,
    // -- To Slave Arbitration
    // ---- Write/Read address channel
    output  [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_AxID_o,
    output  [ADDR_WIDTH*SLV_AMT-1:0]        sa_AxADDR_o,
    output  [TRANS_BURST_W*SLV_AMT-1:0]     sa_AxBURST_o,
    output  [TRANS_DATA_LEN_W*SLV_AMT-1:0]  sa_AxLEN_o,
    output  [TRANS_DATA_SIZE_W*SLV_AMT-1:0] sa_AxSIZE_o,
    output  [SLV_AMT-1:0]                   sa_AxVALID_o,
    output  [OUTST_CTN_W-1:0]               sa_Ax_outst_ctn_o,
    // -- To xDATA channel Dispatcher
    output  [SLV_ID_W-1:0]                  dsp_xDATA_slv_id_o,
    output                                  dsp_xDATA_disable_o,
    // -- To WRESP channel Dispatcher
    output  [SLV_ID_W-1:0]                  dsp_WRESP_slv_id_o,
    output                                  dsp_WRESP_shift_en_o
);
    // Local parameters initialization
    localparam ADDR_INFO_W  = SLV_ID_W + TRANS_DATA_LEN_W;
    
    // Internal variable declaration
    genvar slv_idx;
    
    // Internal signal declaration
    // -- xADDR order fifo
    wire    [ADDR_INFO_W-1:0]       addr_info;
    wire    [ADDR_INFO_W-1:0]       addr_info_valid;
    wire                            fifo_xa_order_wr_en;
    wire                            fifo_xa_order_rd_en;
    wire                            fifo_xa_order_empty;
    // -- Handshake detector
    wire                            Ax_handshake_occcur;
    wire                            xDATA_handshake_occur;
    // -- Misc
    wire    [SLV_ID_W-1:0]          slv_id;
    wire    [SLV_AMT-1:0]           slv_sel;
    wire    [SLV_ID_W-1:0]          addr_slv_mapping;
    wire    [TRANS_DATA_LEN_W-1:0]  AxLEN_valid;
    // -- Transfer counter
    wire    [TRANS_DATA_LEN_W-1:0]  transfer_ctn_nxt;
    wire    [TRANS_DATA_LEN_W-1:0]  transfer_ctn_incr;
    wire                            transfer_ctn_match;
    
    // Reg declaration
    reg     [TRANS_DATA_LEN_W-1:0]  transfer_ctn_r;
    
    // Module
    // -- xADDR order FIFO 
    fifo #(
        .DATA_WIDTH(ADDR_INFO_W),
        .FIFO_DEPTH(OUTSTANDING_AMT)
    ) fifo_xaddr_order (
        .clk(ACLK_i),
        .data_i(addr_info),
        .data_o(addr_info_valid),
        .rd_valid_i(fifo_xa_order_rd_en),
        .wr_valid_i(fifo_xa_order_wr_en),
        .empty_o(fifo_xa_order_empty),
        .full_o(),
        .almost_empty_o(),
        .almost_full_o(),
        .counter(sa_Ax_outst_ctn_o),
        .rst_n(ARESETn_i)
    );
    
    // Combinational logic
    // -- xADDR order FIFO
    assign addr_slv_mapping = m_AxADDR_i[SLV_ID_MSB_IDX:SLV_ID_LSB_IDX];
    assign addr_info = {addr_slv_mapping, m_AxLEN_i};
    assign {slv_id, AxLEN_valid} = addr_info_valid;
    assign fifo_xa_order_wr_en = Ax_handshake_occcur;
    assign fifo_xa_order_rd_en = transfer_ctn_match & xDATA_handshake_occur;
    // -- Handshake detector
    assign Ax_handshake_occcur = m_AxVALID_i & m_AxREADY_o;
    assign xDATA_handshake_occur = m_xVALID_i & m_xREADY_i;
    // -- Transfer counter
    assign transfer_ctn_nxt = (transfer_ctn_match) ? {TRANS_DATA_LEN_W{1'b0}} : transfer_ctn_incr;
    assign transfer_ctn_incr = transfer_ctn_r + 1'b1;
    assign transfer_ctn_match = transfer_ctn_r == AxLEN_valid;
    // -- Output 
    // -- -- Output to Slave Arbitration
    generate 
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin
            assign sa_AxID_o[TRANS_MST_ID_W*(slv_idx+1)-1-:TRANS_MST_ID_W]          = m_AxID_i;
            assign sa_AxADDR_o[ADDR_WIDTH*(slv_idx+1)-1-:ADDR_WIDTH]                = m_AxADDR_i;
            assign sa_AxBURST_o[TRANS_BURST_W*(slv_idx+1)-1-:TRANS_BURST_W]         = m_AxBURST_i;
            assign sa_AxLEN_o[TRANS_DATA_LEN_W*(slv_idx+1)-1-:TRANS_DATA_LEN_W]     = m_AxLEN_i;
            assign sa_AxSIZE_o[TRANS_DATA_SIZE_W*(slv_idx+1)-1-:TRANS_DATA_SIZE_W]  = m_AxSIZE_i;
            assign sa_AxVALID_o[slv_idx]                                            = m_AxVALID_i;
        end
    endgenerate
    // -- -- Output to xDATA dispatcher
    assign dsp_xDATA_slv_id_o = slv_id;
    assign dsp_xDATA_disable_o = fifo_xa_order_empty;
    // -- -- Output to WRESP dispatcher
    assign dsp_WRESP_slv_id_o = slv_id;
    assign dsp_WRESP_shift_en_o = fifo_xa_order_rd_en;
    // -- -- Output to Slave Arbitration
    assign m_AxREADY_o = sa_AxREADY_i[addr_slv_mapping];
    
    // Flip-flop
    always @(posedge ACLK_i) begin
        if(~ARESETn_i) begin
            transfer_ctn_r <= {TRANS_DATA_LEN_W{1'b0}};
        end
        else if(xDATA_handshake_occur) begin
            transfer_ctn_r <= transfer_ctn_nxt;
        end
    end

endmodule
