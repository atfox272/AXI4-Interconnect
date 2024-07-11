module dsp_RADDR_channel
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
    parameter TRANS_DATA_SIZE_W = 3,     // Bus width of xSIZE
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
    // ---- Read address channel
    input   [TRANS_MST_ID_W-1:0]            m_ARID_i,
    input   [ADDR_WIDTH-1:0]                m_ARADDR_i,
    input   [TRANS_BURST_W-1:0]             m_ARBURST_i,
    input   [TRANS_DATA_LEN_W-1:0]          m_ARLEN_i,
    input   [TRANS_DATA_SIZE_W-1:0]         m_ARSIZE_i,
    input                                   m_ARVALID_i,
    // -- To Slave Arbitration
    // ---- Read address channel (master)
    input   [SLV_AMT-1:0]                   sa_ARREADY_i,
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Read address channel (master)
    output                                  m_ARREADY_o,
    // -- To Slave Arbitration
    // ---- Read address channel            
    output  [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_ARID_o,
    output  [ADDR_WIDTH*SLV_AMT-1:0]        sa_ARADDR_o,
    output  [TRANS_BURST_W-1:0]             sa_ARBURST_o,
    output  [TRANS_DATA_LEN_W*SLV_AMT-1:0]  sa_ARLEN_o,
    output  [TRANS_DATA_SIZE_W*SLV_AMT-1:0] sa_ARSIZE_o,
    output  [SLV_AMT-1:0]                   sa_ARVALID_o,
    output  [SLV_AMT-1:0]                   sa_AR_outst_full_o  // The Dispatcher is full
);
    // Local parameter
    localparam ADDR_INFO_W  = SLV_ID_W + TRANS_DATA_LEN_W;

    // Internal signal declaration
    // -- RADDR order fifo
    wire    [ADDR_INFO_W-1:0]       addr_info;
    wire    [ADDR_INFO_W-1:0]       addr_info_valid;
    wire                            fifo_ra_order_wr_en;
    wire                            fifo_ra_order_rd_en;
    wire                            fifo_ra_order_empty;
    wire                            fifo_ra_order_full;
    // -- Handshake detector
    wire                            m_handshake_occur;
    // -- Transfer counter
    wire    [TRANS_DATA_LEN_W-1:0]  transfer_ctn_nxt;
    wire    [TRANS_DATA_LEN_W-1:0]  transfer_ctn_incr;
    wire                            transfer_ctn_match;

    // Module
    fifo 
        #(
        .DATA_WIDTH(ADDR_INFO_W),
        .FIFO_DEPTH(OUTSTANDING_AMT)
    ) fifo_raddr_order (
        .clk(ACLK_i),
        .data_i(addr_info),
        .data_o(addr_info_valid),
        .rd_valid_i(fifo_ra_order_rd_en),
        .wr_valid_i(fifo_ra_order_wr_en),
        .empty_o(fifo_ra_order_empty),
        .full_o(fifo_ra_order_full),
        .almost_empty_o(),
        .almost_full_o(),
        .rst_n(ARESETn_i)
    );
    
endmodule
