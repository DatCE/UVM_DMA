class base_item extends uvm_sequence_item;

    // DMA
  parameter DMA_BASE_ADDR = 32'h8000_0000;
  parameter DMA_CHN_NUM = 1;  // Number of DMA channels
  parameter DMA_LENGTH_W = 16;  // Maximum size of 1 transfer is (2^16 * 256) 
  parameter DMA_DESC_DEPTH = 4;  // The maximum number of descriptors in each channel
  parameter DMA_CHN_ARB_W = 3;  // Channel arbitration weight's width
  parameter ROB_EN = 0;  // Reorder multiple AXI outstanding transactions enable
  parameter DESC_QUEUE_TYPE = (DMA_DESC_DEPTH >= 16) ? "RAM-BASED" : "FLIPFLOP-BASED";
  // SOURCE 
  parameter SRC_IF_TYPE = "AXIS";  // "AXI4" || "AXIS"
  parameter SRC_ADDR_W = 32;
  parameter SRC_TDEST_W = 2;
  parameter ATX_SRC_DATA_W = 256;
  // DESITNATION 
  parameter DST_IF_TYPE = "AXIS";  // "AXI4" || "AXIS"
  parameter DST_ADDR_W = 32;
  parameter DST_TDEST_W = 2;
  parameter ATX_DST_DATA_W = 256;
  // AXI Slave
  parameter S_DATA_W = 32;
  parameter S_ADDR_W = 32;
  // AXI BUS 
  parameter MST_ID_W = 5;
  parameter ATX_LEN_W = 8;
  parameter ATX_SIZE_W = 3;
  parameter ATX_RESP_W = 2;
  parameter ATX_SRC_BYTE_AMT = ATX_SRC_DATA_W / 8;
  parameter ATX_DST_BYTE_AMT = ATX_DST_DATA_W / 8;
  parameter ATX_NUM_OSTD      = (DMA_CHN_NUM > 1) ? DMA_CHN_NUM : 2;  // Number of outstanding transactions in AXI bus (recmd: equal to the number of channel - min: equal to 2)
  parameter ATX_INTL_DEPTH = 16;  // Interleaving depth on the AXI data channel 


    // AXI4 Slave Interface            
    // -- AW channel       
  
  
  logic  [ATX_DST_DATA_W-1:0]    buffer_wdata [$];
  logic  [9:0]                   src_addr;
  logic  [9:0]                   dest_addr;
  logic  [S_DATA_W-1:0]          x_len;


  typedef enum {READ, WRITE} type_rd_wr; 
  typedef enum {SLV, MST} axi_side; 

  rand type_rd_wr                     type_act;
  rand axi_side                       type_axi; 
  rand bit                          chn_id;

  rand bit   [MST_ID_W-1:0]      s_awid_i;
  rand bit   [S_ADDR_W-1:0]      s_awaddr_i;
  rand bit   [1:0]               s_awburst_i;
  rand bit   [ATX_LEN_W-1:0]     s_awlen_i;
  logic                          s_awvalid_i;
  logic                          s_awready_o;
  // -- W channel          
  rand bit   [S_DATA_W-1:0]         s_wdata_i;
  logic                          s_wlast_i;
  logic                          s_wvalid_i;
  logic                          s_wready_o;
  // -- B channel          
  logic  [MST_ID_W-1:0]          s_bid_o;
  logic  [ATX_RESP_W-1:0]        s_bresp_o;
  logic                          s_bvalid_o;
  logic                          s_bready_i;
  // -- AR channel         
  rand bit   [MST_ID_W-1:0]         s_arid_i;
  rand bit   [S_ADDR_W-1:0]         s_araddr_i;
  rand bit   [1:0]                  s_arburst_i;
  rand bit   [ATX_LEN_W-1:0]        s_arlen_i;
  logic                          s_arvalid_i;
  logic                          s_arready_o;
  // -- R channel          
  logic  [MST_ID_W-1:0]          s_rid_o;
  logic  [S_DATA_W-1:0]          s_rdata_o;
  logic  [ATX_RESP_W-1:0]        s_rresp_o;
  logic                          s_rlast_o;
  logic                          s_rvalid_o;
  logic                          s_rready_i;

  // Source Interface
  // -- AXI4 
  // -- -- AR channel         
  logic  [MST_ID_W-1:0]          m_arid_o;
  logic  [SRC_ADDR_W-1:0]        m_araddr_o;
  logic  [ATX_LEN_W-1:0]         m_arlen_o;
  logic  [1:0]                   m_arburst_o;
  logic                          m_arvalid_o;
  logic                          m_arready_i;
  // -- -- R channel          
  logic   [MST_ID_W-1:0]         m_rid_i;
  logic   [ATX_SRC_DATA_W-1:0]   m_rdata_i;
  logic   [ATX_RESP_W-1:0]       m_rresp_i;
  logic                          m_rlast_i;
  logic                          m_rvalid_i;
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
  logic                          m_awready_i;
  // -- -- W channel          
  logic  [ATX_DST_DATA_W-1:0]    m_wdata_o;
  logic                          m_wlast_o;
  logic                          m_wvalid_o;
  logic                          m_wready_i;
  // -- -- B channel
  logic   [MST_ID_W-1:0]         m_bid_i;
  logic   [ATX_RESP_W-1:0]       m_bresp_i;
  logic                          m_bvalid_i;
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
  logic                          irq         [0:DMA_CHN_NUM-1];  // Caused by TX Queueing; TX Completion
  logic                          trap        [0:DMA_CHN_NUM-1];   // Caused by Wrong address mapping

  constraint type_act_cstr { type_act inside {READ, WRITE}; }
  constraint type_axi_cstr { type_axi inside {SLV, MST}; }
  `uvm_object_utils_begin(base_item)

    `uvm_field_sarray_int(buffer_wdata, UVM_ALL_ON);
    `uvm_field_int (src_addr, UVM_ALL_ON);
    `uvm_field_int (dest_addr, UVM_ALL_ON);
    `uvm_field_int (x_len, UVM_ALL_ON);
    `uvm_field_enum(type_rd_wr, type_act, UVM_ALL_ON);
    `uvm_field_enum(axi_side, type_axi, UVM_ALL_ON);
    `uvm_field_int(chn_id, UVM_ALL_ON);

    `uvm_field_int(s_awid_i, UVM_ALL_ON);
    `uvm_field_int(s_awaddr_i, UVM_ALL_ON);
    `uvm_field_int(s_awburst_i, UVM_ALL_ON);
    `uvm_field_int(s_awlen_i, UVM_ALL_ON);
    `uvm_field_int(s_awvalid_i, UVM_ALL_ON);
    `uvm_field_int(s_awready_o, UVM_ALL_ON);

    `uvm_field_int(s_wdata_i, UVM_ALL_ON);
    `uvm_field_int(s_wlast_i, UVM_ALL_ON);
    `uvm_field_int(s_wvalid_i, UVM_ALL_ON);
    `uvm_field_int(s_wready_o, UVM_ALL_ON);

    `uvm_field_int(s_bid_o, UVM_ALL_ON);
    `uvm_field_int(s_bresp_o, UVM_ALL_ON);
    `uvm_field_int(s_bvalid_o, UVM_ALL_ON);
    `uvm_field_int(s_bready_i, UVM_ALL_ON);

    `uvm_field_int(s_arid_i, UVM_ALL_ON);
    `uvm_field_int(s_araddr_i, UVM_ALL_ON);
    `uvm_field_int(s_arburst_i, UVM_ALL_ON);
    `uvm_field_int(s_arlen_i, UVM_ALL_ON);
    `uvm_field_int(s_arvalid_i, UVM_ALL_ON);
    `uvm_field_int(s_arready_o, UVM_ALL_ON);

    `uvm_field_int(s_rid_o, UVM_ALL_ON);
    `uvm_field_int(s_rdata_o, UVM_ALL_ON);
    `uvm_field_int(s_rresp_o, UVM_ALL_ON);
    `uvm_field_int(s_rlast_o, UVM_ALL_ON);
    `uvm_field_int(s_rvalid_o, UVM_ALL_ON);
    `uvm_field_int(s_rready_i, UVM_ALL_ON);

    `uvm_field_int(m_arid_o, UVM_ALL_ON);
    `uvm_field_int(m_araddr_o, UVM_ALL_ON);
    `uvm_field_int(m_arlen_o, UVM_ALL_ON);
    `uvm_field_int(m_arburst_o, UVM_ALL_ON);
    `uvm_field_int(m_arvalid_o, UVM_ALL_ON);
    `uvm_field_int(m_arready_i, UVM_ALL_ON);

    `uvm_field_int(m_rid_i, UVM_ALL_ON);
    `uvm_field_int(m_rdata_i, UVM_ALL_ON);
    `uvm_field_int(m_rresp_i, UVM_ALL_ON);
    `uvm_field_int(m_rlast_i, UVM_ALL_ON);
    `uvm_field_int(m_rvalid_i, UVM_ALL_ON);
    `uvm_field_int(m_rready_o, UVM_ALL_ON);

    `uvm_field_int(s_tid_i, UVM_ALL_ON);
    `uvm_field_int(s_tdest_i, UVM_ALL_ON);
    `uvm_field_int(s_tdata_i, UVM_ALL_ON);
    `uvm_field_int(s_tkeep_i, UVM_ALL_ON);
    `uvm_field_int(s_tstrb_i, UVM_ALL_ON);
    `uvm_field_int(s_tlast_i, UVM_ALL_ON);
    `uvm_field_int(s_tvalid_i, UVM_ALL_ON);
    `uvm_field_int(s_tready_o, UVM_ALL_ON);

    `uvm_field_int(m_awid_o, UVM_ALL_ON);
    `uvm_field_int(m_awaddr_o, UVM_ALL_ON);
    `uvm_field_int(m_awlen_o, UVM_ALL_ON);
    `uvm_field_int(m_awburst_o, UVM_ALL_ON);
    `uvm_field_int(m_awvalid_o, UVM_ALL_ON);
    `uvm_field_int(m_awready_i, UVM_ALL_ON);

    `uvm_field_int(m_wdata_o, UVM_ALL_ON);
    `uvm_field_int(m_wlast_o, UVM_ALL_ON);
    `uvm_field_int(m_wvalid_o, UVM_ALL_ON);
    `uvm_field_int(m_wready_i, UVM_ALL_ON);

    `uvm_field_int(m_bid_i, UVM_ALL_ON);
    `uvm_field_int(m_bresp_i, UVM_ALL_ON);
    `uvm_field_int(m_bvalid_i, UVM_ALL_ON);
    `uvm_field_int(m_bready_o, UVM_ALL_ON);

    `uvm_field_int(m_tid_o, UVM_ALL_ON);
    `uvm_field_int(m_tdest_o, UVM_ALL_ON);
    `uvm_field_int(m_tdata_o, UVM_ALL_ON);
    `uvm_field_int(m_tkeep_o, UVM_ALL_ON);
    `uvm_field_int(m_tstrb_o, UVM_ALL_ON);
    `uvm_field_int(m_tlast_o, UVM_ALL_ON);
    `uvm_field_int(m_tvalid_o, UVM_ALL_ON);
    `uvm_field_int(m_tready_i, UVM_ALL_ON);

    `uvm_field_sarray_int(irq, UVM_ALL_ON);
    `uvm_field_sarray_int(trap, UVM_ALL_ON);

  `uvm_object_utils_end

  function new(string name = "base_item");
    super.new(name);
  endfunction
  
  function void post_randomize();
    // Process addr for exact channel
    s_awaddr_i = s_awaddr_i + chn_id * (2**4);
  endfunction
endclass : base_item
