module dsp_WRESP_channel
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
    // -- -- Write response channel
    input                                   m_BREADY_i,
    // -- To Slave Arbitration
    // -- -- Write response channel (master)
    input   [TRANS_MST_ID_W*SLV_AMT-1:0]    sa_BID_i,
    input   [TRANS_WR_RESP_W*SLV_AMT-1:0]   sa_BRESP_i,
    input   [SLV_AMT-1:0]                   sa_BVALID_i,
    // -- To AW channel Dispatcher
    input   [SLV_ID_W-1:0]                  dsp_AW_slv_id_i,
    input                                   dsp_AW_shift_en_i,
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // -- -- Write response channel (master)
    output  [TRANS_MST_ID_W-1:0]            m_BID_o,
    output  [TRANS_WR_RESP_W-1:0]           m_BRESP_o,
    output                                  m_BVALID_o,
    // -- To Slave Arbitration
    // -- -- Write response channel
    output  [SLV_AMT-1:0]                   sa_BREADY_o
);
    // Local parameter
    localparam SLV_INFO_W = SLV_ID_W;
    localparam RESP_INFO_W = TRANS_MST_ID_W + TRANS_WR_RESP_W;
    
    // Internal variable declaration
    genvar slv_idx;
    
    // Internal signal declaration
    // -- Slave order FIFO
    wire    [SLV_INFO_W-1:0]    slv_info;
    wire    [SLV_INFO_W-1:0]    slv_info_valid;
    wire                        fifo_slv_ord_wr_en;
    wire                        fifo_slv_ord_rd_en;
    wire                        fifo_slv_ord_empty;
    wire                        fifo_slv_ord_full;
    // -- WRESP FIFO
    wire    [RESP_INFO_W-1:0]   resp_info           [SLV_AMT-1:0];
    wire    [RESP_INFO_W-1:0]   resp_info_valid     [SLV_AMT-1:0];
    wire                        fifo_wresp_wr_en    [SLV_AMT-1:0];
    wire                        fifo_wresp_rd_en    [SLV_AMT-1:0];
    wire                        fifo_wresp_empty    [SLV_AMT-1:0];
    wire                        fifo_wresp_full     [SLV_AMT-1:0];
    // -- Handshake detector
    wire                        sa_handshake_occur  [SLV_AMT-1:0];
    wire                        m_handshake_occur;
    // Module
    // -- Slave order FIFO
    fifo #(
        .DATA_WIDTH(SLV_INFO_W),
        .FIFO_WIDTH(OUTSTANDING_AMT)
    ) fifo_slv_order (
        .clk(ACLK_i),
        .data_i(slv_info),
        .data_o(slv_info_valid),
        .rd_valid_i(fifo_slv_ord_rd_en),
        .wr_valid_i(fifo_slv_ord_wr_en),
        .empty_o(fifo_slv_ord_empty),
        .full_o(fifo_slv_ord_full),
        .almost_empty_o(),
        .almost_full_o(),
        .rst_n(ARESETn_i) 
    );
    // -- Slave Response FIFO
    generate 
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin
            fifo #(
                .DATA_WIDTH(RESP_INFO_W),
                .FIFO_WIDTH(OUTSTANDING_AMT)
            ) fifo_WRESP_slv (
                .clk(ACLK_i),
                .data_i(resp_info[slv_idx]),
                .data_o(resp_info_valid[slv_idx]),
                .rd_valid_i(fifo_wresp_rd_en[slv_idx]),
                .wr_valid_i(fifo_wresp_wr_en[slv_idx]),
                .empty_o(fifo_wresp_empty[slv_idx]),
                .full_o(fifo_wresp_full[slv_idx]),
                .almost_empty_o(),
                .almost_full_o(),
                .rst_n(ARESETn_i) 
            );
        end
    endgenerate
    
    // Combinational logic
    // -- Slave order FIFO
    assign fifo_slv_ord_wr_en = dsp_AW_shift_en_i;
    
endmodule
