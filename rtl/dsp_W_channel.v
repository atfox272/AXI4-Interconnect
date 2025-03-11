module dsp_W_channel
#(
    // Dispatcher configuration
    parameter SLV_AMT           = 2,
    // Transaction configuration
    parameter DATA_WIDTH        = 32,
    // Slave configuration
    parameter SLV_ID_W          = $clog2(SLV_AMT),
    parameter SLV_ID_MSB_IDX    = 30,
    parameter SLV_ID_LSB_IDX    = 30
)
(
    // Input declaration
    input                                   ACLK_i,
    input                                   ARESETn_i,
    // -- To Master (slave interface of the interconnect)
    // ---- Write data channel
    input   [DATA_WIDTH-1:0]                m_WDATA_i,
    input                                   m_WLAST_i,
    input                                   m_WVALID_i,
    // -- To Slave Arbitration
    // ---- Write data channel (master)
    input   [SLV_AMT-1:0]                   sa_WREADY_i,
    // -- To AW channel Dispatcher
    input   [SLV_ID_W-1:0]                  dsp_AW_slv_id_i,
    input                                   dsp_AW_disable_i,
    // Output declaration
    // -- To Master (slave interface of interconnect)
    // ---- Write data channel (master)
    output                                  m_WREADY_o,
    // -- To Slave Arbitration
    // ---- Write data channel
    output  [DATA_WIDTH*SLV_AMT-1:0]        sa_WDATA_o,
    output  [SLV_AMT-1:0]                   sa_WLAST_o,
    output  [SLV_AMT-1:0]                   sa_WVALID_o,
    // -- To DSP AW channel
    output                                  dsp_AW_WVALID_o,
    output                                  dsp_AW_WREADY_o
);
    // Local parameters
    localparam SLV_ID_VALID_W   = SLV_ID_W + 1;   // SLV_ID_W + 1bit (~valid)
    localparam W_INFO_W         = DATA_WIDTH + 1;
    
    // Internal variable declaration
    genvar slv_idx;
    
    // Internal signal declaration
    // -- Slave ID decoder
    wire    [SLV_ID_VALID_W-1:0]    slv_id_valid;
    wire    [SLV_AMT-1:0]           slv_sel;
    // -- Master skid buffer
    wire    [W_INFO_W-1:0]          msb_bwd_data;
    wire                            msb_bwd_valid;
    wire                            msb_bwd_ready;
    wire    [W_INFO_W-1:0]          msb_fwd_data;
    wire                            msb_fwd_valid;
    wire                            msb_fwd_ready;
    wire    [DATA_WIDTH-1:0]        msb_fwd_WDATA;
    wire                            msb_fwd_WLAST;
    
    // Internal module
    onehot_decoder #(
        .INPUT_W(SLV_ID_VALID_W),
        .OUTPUT_W(SLV_AMT)
    ) slave_id_decoder (
        .i(slv_id_valid),
        .o(slv_sel)
    );
    // -- Master skid buffer
    skid_buffer #(
        .SBUF_TYPE(1),
        .DATA_WIDTH(W_INFO_W)
    ) mst_skid_buffer (
        .clk        (ACLK_i),
        .rst_n      (ARESETn_i),
        .bwd_data_i (msb_bwd_data),
        .bwd_valid_i(msb_bwd_valid),
        .fwd_ready_i(msb_fwd_ready),
        .fwd_data_o (msb_fwd_data),
        .bwd_ready_o(msb_bwd_ready),
        .fwd_valid_o(msb_fwd_valid)
    );
    
    // Combinational logic
    // -- Slave ID decoder
    assign slv_id_valid = {dsp_AW_disable_i, dsp_AW_slv_id_i};
    // -- Output
    // -- -- Output to Master
    assign m_WREADY_o = msb_bwd_ready;
    // -- -- Output to Slave arbitration
    generate
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_LOGIC
            assign sa_WDATA_o[DATA_WIDTH*(slv_idx+1)-1-:DATA_WIDTH] = msb_fwd_WDATA;
            assign sa_WLAST_o[slv_idx] = msb_fwd_WLAST;
            assign sa_WVALID_o[slv_idx] = msb_fwd_valid & slv_sel[slv_idx];
        end
    endgenerate
    // -- To DSP AW channel 
    assign dsp_AW_WVALID_o  = msb_fwd_valid;
    assign dsp_AW_WREADY_o  = msb_fwd_ready;
    // -- Master skid buffer 
    assign msb_bwd_data     = {m_WDATA_i, m_WLAST_i};
    assign msb_bwd_valid    = m_WVALID_i;
    assign msb_fwd_ready    = (~dsp_AW_disable_i) & sa_WREADY_i[dsp_AW_slv_id_i];
    assign {msb_fwd_WDATA, msb_fwd_WLAST} = msb_fwd_data;
endmodule
