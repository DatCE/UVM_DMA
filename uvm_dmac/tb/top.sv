`timescale 1ns / 1ps

`include "apb_if.sv"
`include "uvm_macros.svh"
import uvm_pkg::*;
import base_uvm_pkg::*;
`include "base_test.sv"
// `include "base_mem.sv"
`include "adma_as_atx_arb.sv"
`include "adma_as_atx_fetch.sv"
`include "adma_as_atx_req.sv"
`include "adma_as_tx_stat.sv"
`include "adma_atx_sched.sv"
`include "adma_chn_man.sv"
`include "adma_cm_chn_unit.sv"
`include "adma_cm_tf_split.sv"
`include "adma_cm_tx_fetch.sv"
`include "adma_cm_xfer_stat.sv"
`include "adma_data_mover.sv"
`include "adma_desc_queue.sv"
`include "adma_dm_axi_ax.sv"
`include "adma_dm_axi_b.sv"
`include "adma_dm_axi_r.sv"
`include "adma_dm_axi_w.sv"
`include "adma_dm_data_buf.sv"
`include "adma_dm_dst_axis.sv"
`include "adma_dm_rd_host.sv"
`include "adma_dm_src_axis.sv"
`include "adma_dm_wr_host.sv"
`include "adma_reg_map.sv"
`include "axi_dma.sv"
`include "axi4_ctrl.v"
`include "arb_prior_granter.v"
`include "arb_round_comp_detector.v"
`include "arbiter_iwrr_1cycle.v"
`include "bin2gray_converter.v"
`include "gray2bin_converter.v"
`include "onehot_decoder.v"
`include "edgedet.v"
`include "onehot_encoder.v"
`include "asyn_fifo.v"
`include "fifo.v"
`include "sync_fifo.v"
`include "mem.v"
`include "reorder_buffer.v"
`include "sb_fifo.v"
`include "skid_buffer.v"
`include "splitter.v"

`define CLK_GEN(clk, cycle)\
    initial begin\
        clk = 0;\
        forever clk = #(cycle/2.0)  ~clk;\
    end

module top;

  parameter DMA_BASE_ADDR = 32'h8000_0000;
  parameter DMA_CHN_NUM = 2;  // Number of DMA channels
  parameter DMA_LENGTH_W = 16;  // Maximum size of 1 transfer is (2^16 * 256) 
  parameter DMA_DESC_DEPTH = 4;  // The maximum number of descriptors in each channel
  parameter DMA_CHN_ARB_W = 3;  // Channel arbitration weight's width
  parameter ROB_EN = 0;  // Reorder multiple AXI outstanding transactions enable
  parameter DESC_QUEUE_TYPE = (DMA_DESC_DEPTH >= 16) ? "RAM-BASED" : "FLIPFLOP-BASED";
  // SOURCE 
  parameter SRC_IF_TYPE = "AXI4";  // "AXI4" || "AXIS"
  parameter SRC_ADDR_W = 32;
  parameter SRC_TDEST_W = 2;
  parameter ATX_SRC_DATA_W = 256;
  // DESITNATION 
  parameter DST_IF_TYPE = "AXI4";  // "AXI4" || "AXIS"
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

  bit clk = 0;
  bit rst = 0;
  // base_mem memory; 
  // memory.mem_init();
  // memory.mem_print();

  parameter cycle = 2;
  `CLK_GEN(clk, cycle);

  dut_if #(
      .DMA_BASE_ADDR   (DMA_BASE_ADDR),
      .DMA_CHN_NUM     (DMA_CHN_NUM),
      .DMA_LENGTH_W    (DMA_LENGTH_W),
      .DMA_DESC_DEPTH  (DMA_DESC_DEPTH),
      .DMA_CHN_ARB_W   (DMA_CHN_ARB_W),
      .ROB_EN          (ROB_EN),
      .DESC_QUEUE_TYPE (DESC_QUEUE_TYPE),
      .SRC_IF_TYPE     (SRC_IF_TYPE),
      .SRC_ADDR_W      (SRC_ADDR_W),
      .SRC_TDEST_W     (SRC_TDEST_W),
      .ATX_SRC_DATA_W  (ATX_SRC_DATA_W),
      .DST_IF_TYPE     (DST_IF_TYPE),
      .DST_ADDR_W      (DST_ADDR_W),
      .DST_TDEST_W     (DST_TDEST_W),
      .ATX_DST_DATA_W  (ATX_DST_DATA_W),
      .S_DATA_W        (S_DATA_W),
      .S_ADDR_W        (S_ADDR_W),
      .MST_ID_W        (MST_ID_W),
      .ATX_LEN_W       (ATX_LEN_W),
      .ATX_SIZE_W      (ATX_SIZE_W),
      .ATX_RESP_W      (ATX_RESP_W),
      .ATX_SRC_BYTE_AMT(ATX_SRC_BYTE_AMT),
      .ATX_DST_BYTE_AMT(ATX_DST_BYTE_AMT),
      .ATX_NUM_OSTD    (ATX_NUM_OSTD),
      .ATX_INTL_DEPTH  (ATX_INTL_DEPTH)
  ) vif (
      .clk(clk),
      .rst(rst)
  );

  axi_dma #(
      // DMA
      .DMA_BASE_ADDR   (DMA_BASE_ADDR),
      .DMA_CHN_NUM     (DMA_CHN_NUM),
      // Number of DMA channels
      .DMA_LENGTH_W    (DMA_LENGTH_W),
      // Maximum size of 1 transfer is (2^16 * 256) 
      .DMA_DESC_DEPTH  (DMA_DESC_DEPTH),
      // The maximum number of descriptors in each channel
      .DMA_CHN_ARB_W   (DMA_CHN_ARB_W),
      // Channel arbitration weight's width
      .ROB_EN          (ROB_EN),
      // Reorder multiple AXI outstanding transactions enable
      .DESC_QUEUE_TYPE (DESC_QUEUE_TYPE),
      // SOURCE 
      .SRC_IF_TYPE     (SRC_IF_TYPE),
      // "AXI4" || "AXIS"
      .SRC_ADDR_W      (SRC_ADDR_W),
      .SRC_TDEST_W     (SRC_TDEST_W),
      .ATX_SRC_DATA_W  (ATX_SRC_DATA_W),
      // DESITNATION 
      .DST_IF_TYPE     (DST_IF_TYPE),
      // "AXI4" || "AXIS"
      .DST_ADDR_W      (DST_ADDR_W),
      .DST_TDEST_W     (DST_TDEST_W),
      .ATX_DST_DATA_W  (ATX_DST_DATA_W),
      // AXI Slave
      .S_DATA_W        (S_DATA_W),
      .S_ADDR_W        (S_ADDR_W),
      // AXI BUS 
      .MST_ID_W        (MST_ID_W),
      .ATX_LEN_W       (ATX_LEN_W),
      .ATX_SIZE_W      (ATX_SIZE_W),
      .ATX_RESP_W      (ATX_RESP_W),
      .ATX_SRC_BYTE_AMT(ATX_SRC_BYTE_AMT),
      .ATX_DST_BYTE_AMT(ATX_DST_BYTE_AMT),
      .ATX_NUM_OSTD    (ATX_NUM_OSTD),
      // Number of outstanding transactions in AXI bus (recmd: equal to the number of channel - min: equal to 2)
      // Interleaving depth on the AXI data channel 
      .ATX_INTL_DEPTH  (ATX_INTL_DEPTH)
  ) u_axi_dma (
      .aclk       (clk),
      .aresetn    (rst),
      // AXI4 Slave Interface            
      // -- AW channel         
      .s_awid_i   (vif.s_awid_i),
      .s_awaddr_i (vif.s_awaddr_i),
      .s_awburst_i(vif.s_awburst_i),
      .s_awlen_i  (vif.s_awlen_i),
      .s_awvalid_i(vif.s_awvalid_i),
      .s_awready_o(vif.s_awready_o),
      // -- W channel          
      .s_wdata_i  (vif.s_wdata_i),
      .s_wlast_i  (vif.s_wlast_i),
      .s_wvalid_i (vif.s_wvalid_i),
      .s_wready_o (vif.s_wready_o),
      // -- B channel          
      .s_bid_o    (vif.s_bid_o),
      .s_bresp_o  (vif.s_bresp_o),
      .s_bvalid_o (vif.s_bvalid_o),
      .s_bready_i (vif.s_bready_i),
      // -- AR channel         
      .s_arid_i   (vif.s_arid_i),
      .s_araddr_i (vif.s_araddr_i),
      .s_arburst_i(vif.s_arburst_i),
      .s_arlen_i  (vif.s_arlen_i),
      .s_arvalid_i(vif.s_arvalid_i),
      .s_arready_o(vif.s_arready_o),
      // -- R channel          
      .s_rid_o    (vif.s_rid_o),
      .s_rdata_o  (vif.s_rdata_o),
      .s_rresp_o  (vif.s_rresp_o),
      .s_rlast_o  (vif.s_rlast_o),
      .s_rvalid_o (vif.s_rvalid_o),
      .s_rready_i (vif.s_rready_i),
      // Source Interface
      // -- AXI4 
      // -- -- AR channel         
      .m_arid_o   (vif.m_arid_o),
      .m_araddr_o (vif.m_araddr_o),
      .m_arlen_o  (vif.m_arlen_o),
      .m_arburst_o(vif.m_arburst_o),
      .m_arvalid_o(vif.m_arvalid_o),
      .m_arready_i(vif.m_arready_i),
      // -- -- R channel          
      .m_rid_i    (vif.m_rid_i),
      .m_rdata_i  (vif.m_rdata_i),
      .m_rresp_i  (vif.m_rresp_i),
      .m_rlast_i  (vif.m_rlast_i),
      .m_rvalid_i (vif.m_rvalid_i),
      .m_rready_o (vif.m_rready_o),
      // -- AXI-Stream Slave
      .s_tid_i    (vif.s_tid_i),
      .s_tdest_i  (vif.s_tdest_i),
      // Not-use
      .s_tdata_i  (vif.s_tdata_i),
      .s_tkeep_i  (vif.s_tkeep_i),
      .s_tstrb_i  (vif.s_tstrb_i),
      .s_tlast_i  (vif.s_tlast_i),
      .s_tvalid_i (vif.s_tvalid_i),
      .s_tready_o (vif.s_tready_o),
      // Destination Interface
      // -- AXI4
      // -- -- AW channel         
      .m_awid_o   (vif.m_awid_o),
      .m_awaddr_o (vif.m_awaddr_o),
      .m_awlen_o  (vif.m_awlen_o),
      .m_awburst_o(vif.m_awburst_o),
      .m_awvalid_o(vif.m_awvalid_o),
      .m_awready_i(vif.m_awready_i),
      // -- -- W channel          
      .m_wdata_o  (vif.m_wdata_o),
      .m_wlast_o  (vif.m_wlast_o),
      .m_wvalid_o (vif.m_wvalid_o),
      .m_wready_i (vif.m_wready_i),
      // -- -- B channel
      .m_bid_i    (vif.m_bid_i),
      .m_bresp_i  (vif.m_bresp_i),
      .m_bvalid_i (vif.m_bvalid_i),
      .m_bready_o (vif.m_bready_o),
      // -- AXI-Stream
      .m_tid_o    (vif.m_tid_o),
      .m_tdest_o  (vif.m_tdest_o),
      .m_tdata_o  (vif.m_tdata_o),
      .m_tkeep_o  (vif.m_tkeep_o),
      .m_tstrb_o  (vif.m_tstrb_o),
      .m_tlast_o  (vif.m_tlast_o),
      .m_tvalid_o (vif.m_tvalid_o),
      .m_tready_i (vif.m_tready_i),
      // Interrupt
      .irq        (vif.irq),
      // Caused by TX Queueing, TX Completion
      // Caused by Wrong address mapping
      .trap       (vif.trap)
  );
  initial begin
    // memory.mem_init();
    // $display("Memory hihi", memory.mem);
    // memory.mem_print();
    uvm_config_db#(virtual dut_if)::set(null, "*", "vif", vif);
    run_test();
  end

  initial begin
    rst = 0;
    repeat (5) @(posedge vif.clk);
    rst = 1;
  end
endmodule
