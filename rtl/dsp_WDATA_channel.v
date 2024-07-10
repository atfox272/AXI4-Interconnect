module dsp_WDATA_channel
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
    output  [SLV_AMT-1:0]                   sa_WDATA_sel_o    // Slave Arbitration selection
);
    // Local parameters
    localparam SLV_ID_VALID_W = SLV_ID_W + 1;   // SLV_ID_W + 1bit (~valid)
    
    // Internal variable declaration
    genvar slv_idx;
    
    // Internal signal declaration
    // -- Slave ID decoder
    wire    [SLV_ID_VALID_W-1:0]    slv_id_valid;
    wire    [SLV_AMT-1:0]           slv_sel;
    
    // Combinational logic
    // -- Slave ID decoder
    assign slv_id_valid = {dsp_AW_disable_i, dsp_AW_slv_id_i};
    // -- Output
    // -- -- Output to Master
    assign m_WREADY_o = (dsp_AW_disable_i) ? 1'b0 : sa_WREADY_i[dsp_AW_slv_id_i];
    // -- -- Output to Slave arbitration
    generate
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin
            assign sa_WDATA_o[DATA_WIDTH*(slv_idx+1)-1-:DATA_WIDTH] = m_WDATA_i;
            assign sa_WLAST_o[slv_idx] = m_WLAST_i;
            assign sa_WVALID_o[slv_idx] = m_WVALID_i;
            assign sa_WDATA_sel_o[slv_idx] = slv_sel[slv_idx];
        end
    endgenerate
    
    // Module 
    onehot_decoder #(
        .INPUT_W(SLV_ID_VALID_W),
        .OUTPUT_W(SLV_AMT)
    ) slave_id_decoder (
        .i(slv_id_valid),
        .o(slv_sel)
    );

endmodule