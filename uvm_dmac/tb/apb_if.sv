interface dut_if #(
    // DMA
  parameter DMA_BASE_ADDR     = 32'h8000_0000,
  parameter DMA_CHN_NUM       = 2,    // Number of DMA channels
  parameter DMA_LENGTH_W      = 16,   // Maximum size of 1 transfer is (2^16 * 256) 
  parameter DMA_DESC_DEPTH    = 4,    // The maximum number of descriptors in each channel
  parameter DMA_CHN_ARB_W     = 3,    // Channel arbitration weight's width
  parameter ROB_EN            = 0,    // Reorder multiple AXI outstanding transactions enable
  parameter DESC_QUEUE_TYPE   = (DMA_DESC_DEPTH >= 16) ? "RAM-BASED" : "FLIPFLOP-BASED",
  // SOURCE 
  parameter SRC_IF_TYPE       = "AXI4", // "AXI4" || "AXIS"
  parameter SRC_ADDR_W        = 32,
  parameter SRC_TDEST_W       = 2,
  parameter ATX_SRC_DATA_W    = 256,
  // DESITNATION 
  parameter DST_IF_TYPE       = "AXI4", // "AXI4" || "AXIS"
  parameter DST_ADDR_W        = 32,
  parameter DST_TDEST_W       = 2,
  parameter ATX_DST_DATA_W    = 256,
  // AXI Slave
  parameter S_DATA_W          = 32,
  parameter S_ADDR_W          = 32,
  // AXI BUS 
  parameter MST_ID_W          = 5,
  parameter ATX_LEN_W         = 8,
  parameter ATX_SIZE_W        = 3,
  parameter ATX_RESP_W        = 2,
  parameter ATX_SRC_BYTE_AMT  = ATX_SRC_DATA_W/8,
  parameter ATX_DST_BYTE_AMT  = ATX_DST_DATA_W/8,
  parameter ATX_NUM_OSTD      = (DMA_CHN_NUM > 1) ? DMA_CHN_NUM : 2,  // Number of outstanding transactions in AXI bus (recmd: equal to the number of channel - min: equal to 2)
  parameter ATX_INTL_DEPTH    = 16 // Interleaving depth on the AXI data channel 
) (
    input bit clk,
    input bit rst
);


    // AXI4 Slave Interface            
    // -- AW channel         
  logic   [MST_ID_W-1:0]         s_awid_i;
  logic   [S_ADDR_W-1:0]         s_awaddr_i;
  logic   [1:0]                  s_awburst_i;
  logic   [ATX_LEN_W-1:0]        s_awlen_i;
  logic                          s_awvalid_i = 0;
  logic                          s_awready_o;
  // -- W channel          
  logic   [S_DATA_W-1:0]         s_wdata_i;
  logic                          s_wlast_i;
  logic                          s_wvalid_i = 0;
  logic                          s_wready_o;
  // -- B channel          
  logic  [MST_ID_W-1:0]          s_bid_o;
  logic  [ATX_RESP_W-1:0]        s_bresp_o;
  logic                          s_bvalid_o;
  logic                          s_bready_i = 0;
  // -- AR channel         
  logic   [MST_ID_W-1:0]         s_arid_i;
  logic   [S_ADDR_W-1:0]         s_araddr_i;
  logic   [1:0]                  s_arburst_i;
  logic   [ATX_LEN_W-1:0]        s_arlen_i;
  logic                          s_arvalid_i = 0;
  logic                          s_arready_o;
  // -- R channel          
  logic  [MST_ID_W-1:0]          s_rid_o;
  logic  [S_DATA_W-1:0]          s_rdata_o;
  logic  [ATX_RESP_W-1:0]        s_rresp_o;
  logic                          s_rlast_o;
  logic                          s_rvalid_o;
  logic                          s_rready_i = 0;

  // Source Interface
  // -- AXI4 
  // -- -- AR channel         
  logic  [MST_ID_W-1:0]          m_arid_o;
  logic  [SRC_ADDR_W-1:0]        m_araddr_o;
  logic  [ATX_LEN_W-1:0]         m_arlen_o;
  logic  [1:0]                   m_arburst_o;
  logic                          m_arvalid_o;
  logic                          m_arready_i = 0;
  // -- -- R channel          
  logic   [MST_ID_W-1:0]         m_rid_i;
  logic   [ATX_SRC_DATA_W-1:0]   m_rdata_i;
  logic   [ATX_RESP_W-1:0]       m_rresp_i;
  logic                          m_rlast_i = 0;
  logic                          m_rvalid_i = 0;
  logic                          m_rready_o;
  // -- AXI-Stream Slave
  logic   [MST_ID_W-1:0]         s_tid_i;    
  logic   [SRC_TDEST_W-1:0]      s_tdest_i;  // Not-use
  logic   [ATX_SRC_DATA_W-1:0]   s_tdata_i;
  logic   [ATX_SRC_BYTE_AMT-1:0] s_tkeep_i;
  logic   [ATX_SRC_BYTE_AMT-1:0] s_tstrb_i;
  logic                          s_tlast_i;
  logic                          s_tvalid_i;
  logic                          s_tready_o;

  // Destination Interface
  // -- AXI4
  // -- -- AW channel         
  logic  [MST_ID_W-1:0]          m_awid_o;
  logic  [DST_ADDR_W-1:0]        m_awaddr_o;
  logic  [ATX_LEN_W-1:0]         m_awlen_o;
  logic  [1:0]                   m_awburst_o;
  logic                          m_awvalid_o;
  logic                          m_awready_i = 0;
  // -- -- W channel          
  logic  [ATX_DST_DATA_W-1:0]    m_wdata_o;
  logic                          m_wlast_o;
  logic                          m_wvalid_o;
  logic                          m_wready_i = 0;
  // -- -- B channel
  logic   [MST_ID_W-1:0]         m_bid_i;
  logic   [ATX_RESP_W-1:0]       m_bresp_i;
  logic                          m_bvalid_i = 0;
  logic                          m_bready_o;
  // -- AXI-Stream
  logic  [MST_ID_W-1:0]          m_tid_o;    
  logic  [DST_TDEST_W-1:0]       m_tdest_o;
  logic  [ATX_DST_DATA_W-1:0]    m_tdata_o;
  logic  [ATX_DST_BYTE_AMT-1:0]  m_tkeep_o;
  logic  [ATX_DST_BYTE_AMT-1:0]  m_tstrb_o;
  logic                          m_tlast_o;
  logic                          m_tvalid_o;
  logic                          m_tready_i;
  // Interrupt
  logic  [0:DMA_CHN_NUM-1]       irq;  // Caused by TX Queueing; TX Completion
  logic  [0:DMA_CHN_NUM-1]       trap;   // Caused by Wrong address mapping


  clocking cb @(posedge clk);
    default input #1ps output #1ps;
    output s_awid_i, s_awaddr_i, s_awburst_i, s_awlen_i, s_awvalid_i,
           s_wdata_i, s_wlast_i, s_wvalid_i,
           s_bready_i, 
           s_arid_i, s_araddr_i, s_arburst_i, s_arlen_i, s_arvalid_i,
           s_rready_i,
           m_arready_i,
           m_rid_i, m_rdata_i, m_rresp_i, m_rlast_i, m_rvalid_i,
           s_tid_i, s_tdest_i, s_tdata_i, s_tkeep_i, s_tstrb_i, s_tlast_i, s_tvalid_i,
           m_awready_i,
           m_wready_i,
           m_bid_i, m_bresp_i, m_bvalid_i,
           m_tready_i;

    input s_awready_o,
          s_wready_o,
          s_bid_o, s_bresp_o, s_bvalid_o,
          s_arready_o,
          s_rid_o, s_rdata_o, s_rresp_o, s_rlast_o, s_rvalid_o,
          m_arid_o, m_araddr_o, m_arlen_o, m_arburst_o, m_arvalid_o,
          m_rready_o, 
          s_tready_o,
          m_awid_o, m_awaddr_o, m_awlen_o, m_awburst_o, m_awvalid_o,
          m_wdata_o, m_wlast_o, m_wvalid_o,
          m_bready_o,
          m_tid_o, m_tdest_o, m_tdata_o, m_tkeep_o, m_tstrb_o, m_tlast_o, m_tvalid_o,
          irq, trap;
  endclocking
endinterface
