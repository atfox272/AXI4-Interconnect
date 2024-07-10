module dsp_WADDR_channel
#(
    // Dispatcher configuration
    parameter SLV_AMT           = 2,
    parameter OUTSTANDING_AMT   = 8,
    // Transaction configuration
    parameter DATA_WIDTH        = 32,
    parameter ADDR_WIDTH        = 32,
    parameter TRANS_MST_ID_W    = 5,    // Bus width of master transaction ID 
    parameter TRANS_BURST_W     = 2,    // Width of xBURST 
    parameter TRANS_DATA_LEN_W  = 3,    // Bus width of xLEN
    parameter TRANS_DATA_SIZE_W = 3,    // Bus width of xSIZE
    parameter TRANS_WR_RESP_W   = 2,
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
    // ---- Write address channel
    input   [TRANS_MST_ID_W-1:0]            m_AWID_i,
    input   [ADDR_WIDTH-1:0]                m_AWADDR_i,
    input   [TRANS_BURST_W-1:0]             m_AWBURST_i,
    input   [TRANS_DATA_LEN_W-1:0]          m_AWLEN_i,
    input   [TRANS_DATA_SIZE_W-1:0]         m_AWSIZE_i,
    input                                   m_AWVALID_i,
    // -- To WDATA channel Dispatcher
    input                                   m_WVALID_i,
    input                                   m_WREADY_i,
    // -- To Slave Arbitration
    // ---- Write address channel (master)
    input   [SLV_AMT-1:0]                   sa_AWREADY_i,
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Write address channel (master)
    output                                  m_AWREADY_o,
    // -- To Slave Arbitration
    // ---- Write address channel
    output  [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_AWID_o,
    output  [ADDR_WIDTH*SLV_AMT-1:0]        sa_AWADDR_o,
    output  [TRANS_BURST_W-1:0]             sa_AWBURST_o,
    output  [TRANS_DATA_LEN_W*SLV_AMT-1:0]  sa_AWLEN_o,
    output  [TRANS_DATA_SIZE_W*SLV_AMT-1:0] sa_AWSIZE_o,
    output  [SLV_AMT-1:0]                   sa_AWVALID_o,
    output  [SLV_AMT-1:0]                   sa_AW_outst_full_o, // The Dispatcher is full
    // -- To WDATA channel Dispatcher
    output  [SLV_ID_W-1:0]                  dsp_WDATA_slv_id_o,
    output                                  dsp_WDATA_disable_o,
    // -- To WRESP channel Dispatcher
    output  [SLV_ID_W-1:0]                  dsp_WRESP_slv_id_o,
    output                                  dsp_WRESP_shift_en_o
);
    // Local parameters initialization
    localparam ADDR_INFO_W  = SLV_ID_W + TRANS_DATA_LEN_W;
    
    // Internal variable declaration
    genvar slv_idx;
    
    // Internal signal declaration
    // -- WADDR order fifo
    wire    [ADDR_INFO_W-1:0]       addr_info;
    wire    [ADDR_INFO_W-1:0]       addr_info_valid;
    wire                            fifo_wa_order_wr_en;
    wire                            fifo_wa_order_rd_en;
    wire                            fifo_wa_order_empty;
    wire                            fifo_wa_order_full;
    // -- Handshake detector
    wire                            AW_handshake_occcur;
    wire                            WDATA_handshake_occur;
    // -- Misc
    wire    [SLV_ID_W-1:0]          slv_id;
    wire    [SLV_AMT-1:0]           slv_sel;
    wire    [SLV_ID_W-1:0]          addr_slv_mapping;
    wire    [TRANS_DATA_LEN_W-1:0]  AWLEN_valid;
    // -- Transfer counter
    wire    [TRANS_DATA_LEN_W-1:0]  transfer_ctn_nxt;
    wire    [TRANS_DATA_LEN_W-1:0]  transfer_ctn_incr;
    wire                            transfer_ctn_match;
    
    // Reg declaration
    reg     [TRANS_DATA_LEN_W-1:0]  transfer_ctn_r;
    
    // Module
    // -- WADDR order FIFO 
    fifo #(
        .DATA_WIDTH(ADDR_INFO_W),
        .FIFO_DEPTH(OUTSTANDING_AMT)
    ) fifo_waddr_order (
        .clk(ACLK_i),
        .data_i(addr_info),
        .data_o(addr_info_valid),
        .rd_valid_i(fifo_wa_order_rd_en),
        .wr_valid_i(fifo_wa_order_wr_en),
        .empty_o(fifo_wa_order_empty),
        .full_o(fifo_wa_order_full),
        .almost_empty_o(),
        .almost_full_o(),
        .rst_n(ARESETn_i)
    );
    
    // Combinational logic
    // -- WADDR order FIFO
    assign addr_slv_mapping = m_AWADDR_i[SLV_ID_MSB_IDX:SLV_ID_LSB_IDX];
    assign addr_info = {addr_slv_mapping, m_AWLEN_i};
    assign {slv_id, AWLEN_valid} = addr_info_valid;
    assign fifo_wa_order_wr_en = AW_handshake_occcur;
    assign fifo_wa_order_rd_en = transfer_ctn_match & WDATA_handshake_occur;
    // -- Handshake detector
    assign AW_handshake_occcur = m_AWVALID_i & m_AWREADY_o;
    assign WDATA_handshake_occur = m_WVALID_i & m_WREADY_i;
    // -- Transfer counter
    assign transfer_ctn_nxt = (transfer_ctn_match) ? {TRANS_DATA_LEN_W{1'b0}} : transfer_ctn_incr;
    assign transfer_ctn_incr = transfer_ctn_r + 1'b1;
    assign transfer_ctn_match = transfer_ctn_r == AWLEN_valid;
    // -- Output 
    // -- -- Output to Slave Arbitration
    generate 
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin
            assign sa_AWID_o[TRANS_MST_ID_W*(slv_idx+1)-1-:TRANS_MST_ID_W]          = m_AWID_i;
            assign sa_AWADDR_o[ADDR_WIDTH*(slv_idx+1)-1-:ADDR_WIDTH]                = m_AWADDR_i;
            assign sa_AWBURST_o[TRANS_BURST_W*(slv_idx+1)-1-:TRANS_BURST_W]         = m_AWBURST_i;
            assign sa_AWLEN_o[TRANS_DATA_LEN_W*(slv_idx+1)-1-:TRANS_DATA_LEN_W]     = m_AWLEN_i;
            assign sa_AWSIZE_o[TRANS_DATA_SIZE_W*(slv_idx+1)-1-:TRANS_DATA_SIZE_W]  = m_AWSIZE_i;
            assign sa_AWVALID_o[slv_idx]                                            = m_AWVALID_i;
            assign sa_AW_outst_full_o[slv_idx]                                      = fifo_wa_order_full;
        end
    endgenerate
    // -- -- Output to WDATA dispatcher
    assign dsp_WDATA_slv_id_o = slv_id;
    assign dsp_WDATA_disable_o = fifo_wa_order_empty;
    // -- -- Output to WRESP dispatcher
    assign dsp_WRESP_slv_id_o = slv_id;
    assign dsp_WRESP_shift_en_o = fifo_wa_order_rd_en;
    // -- -- Output to Slave Arbitration
    assign m_AWREADY_o = sa_AWREADY_i[addr_slv_mapping];
    
    // Flip-flop
    always @(posedge ACLK_i) begin
        if(~ARESETn_i) begin
            transfer_ctn_r <= {TRANS_DATA_LEN_W{1'b0}};
        end
        else if(WDATA_handshake_occur) begin
            transfer_ctn_r <= transfer_ctn_nxt;
        end
    end

endmodule
