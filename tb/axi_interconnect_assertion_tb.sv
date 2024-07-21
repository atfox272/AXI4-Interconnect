typedef struct {
    bit                           trans_wr_rd; // Write(1) / read(0) transaction
    // -- Ax channel
    bit [TRANS_MST_ID_W-1:0]      AxID;
    bit [TRANS_BURST_W-1:0]       AxBURST;
    bit [SLV_ID_W-1:0]            AxADDR_slv_id;
    bit [ADDR_WIDTH-SLV_ID_W-2:0] AxADDR_addr;
    bit [TRANS_DATA_LEN_W-1:0]    AxLEN;
    bit [TRANS_DATA_SIZE_W-1:0]   AxSIZE;
    // -- W channel
    bit [DATA_WIDTH-1:0]          WDATA  [`MAX_LENGTH];    // Maximum: 8-beat transaction
} trans_info;

typedef struct {
    bit                             trans_wr_rd; // Write(1) / read(0) transaction
    bit [TRANS_MST_ID_W-1:0]        AxID;
    bit [TRANS_BURST_W-1:0]         AxBURST;
    bit [SLV_ID_W-1:0]              AxADDR_slv_id;
    bit [ADDR_WIDTH-SLV_ID_W-2:0]   AxADDR_addr;
    bit [TRANS_DATA_LEN_W-1:0]      AxLEN;
    bit [TRANS_DATA_SIZE_W-1:0]     AxSIZE;
} Ax_info;
typedef struct {
    bit [DATA_WIDTH-1:0]            WDATA [`MAX_LENGTH];
} W_info;

typedef struct {
    bit [TRANS_SLV_ID_W-1:0]        BID;
    bit [TRANS_WR_RESP_W-1:0]       BRESP;
} B_info;

typedef struct {
    bit [TRANS_SLV_ID_W-1:0]        RID;
    bit [DATA_WIDTH-1:0]            RDATA   [`MAX_LENGTH];
    bit [TRANS_WR_RESP_W-1:0]       RRESP;
} R_info;
    
class m_trans_random #(int mode = `BURST_MODE, int trans_rate = 50);
    // Transaction rate
    rand    bit                             m_trans_avail;
    // Write(1) / read(0) transaction
    rand    bit                             m_trans_wr_rd;
    // Ax channel
    rand    bit [TRANS_MST_ID_W-1:0]        m_AxID;
    rand    bit [TRANS_BURST_W-1:0]         m_AxBURST;
    rand    bit [SLV_ID_W-1:0]              m_AxADDR_slv_id;
    rand    bit [ADDR_WIDTH-SLV_ID_W-2:0]   m_AxADDR_addr;
    rand    bit [TRANS_DATA_LEN_W-1:0]      m_AxLEN;
    rand    bit [TRANS_DATA_SIZE_W-1:0]     m_AxSIZE;
    // W channel
    rand    bit [DATA_WIDTH-1:0]            m_WDATA [`MAX_LENGTH];    // Maximum: 8 beats
    
    constraint m_trans{
        if(mode == `BURST_MODE) {
            m_trans_avail               == 1;
            m_trans_wr_rd               dist{0 :/ 1, 1:/ 1};
            m_AxBURST                   == 1;                 
            m_AxADDR_slv_id             dist{0 :/ 1, 1:/ 1};
            m_AxADDR_addr%(1<<m_AxSIZE) == 0;   // All transfers must be aligned
        }
        else if(mode == `ARBITRATION_MODE) {
        
            m_trans_avail   dist{0 :/ 100, 1:/ trans_rate};  // rate = trans_rate % 
            m_AxADDR_slv_id == 0;                            // Map to only 1 slave (slv_id == 0)                       
            m_trans_wr_rd   == 0;                            // Only read transaction
            m_AxSIZE        == 0;                            // Align transaciton
        }
    }
endclass : m_trans_random