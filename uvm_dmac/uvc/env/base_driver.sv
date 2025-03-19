// `include "base_item.sv"
class base_driver extends uvm_driver #(base_item);
  typedef enum {READ, WRITE} type_rd_wr; 
  typedef enum {SLV, MST} axi_side; 
  uvm_analysis_port #(base_item) item_collected_port;
  `uvm_component_utils(base_driver)
  virtual dut_if vif;
  base_mem memory;
  base_item b_item;
  int cnt;
  int cnt_2 = 1;
  int start_addr;
  int size;
  int length;
  uvm_event dma_chn_1_done;
  uvm_event dma_chn_2_done;
  int count_1 = 0;
  int count_2 = 0;
  base_item item_temp;
  base_item item_temp_ar;
  base_item item_temp_aw;
  base_item item_temp_w;
  int wd_per_burst_1 = -1;
  int x_len_1 = -1;
  int y_len_1;
  int num_trans_row_1 = 0;
  int chn_id;

  int wd_per_burst_2 = -1;
  int x_len_2 = -1;
  int y_len_2;
  int num_trans_row_2 = 0;
  int total_cyclic;
  

  parameter BASE_ADDR = 32'h8000_0000;
  parameter SRC_ADDR = 'h0009 + BASE_ADDR;
  parameter DST_ADDR = 'h000A + BASE_ADDR;
  parameter TRANSFER_X_LEN_ADDR = 'h000B + BASE_ADDR;
  parameter CHN_FLAGS_ADDR = 'h0002 + BASE_ADDR;
  parameter ATX_SRC_BURST_ADDR = 'h0006 + BASE_ADDR;
  parameter ATX_DST_BURST_ADDR = 'h0007 + BASE_ADDR; 
  parameter ATX_WD_PER_BURST_ADDR  = 'h0008 + BASE_ADDR; 
  parameter TRANSFER_Y_LEN_ADDR = 'h000C + BASE_ADDR; 
  parameter SRC_STRIDE_ADDR = 'h000D + BASE_ADDR; 
  parameter DST_STRIDE_ADDR = 'h000E + BASE_ADDR; 

  mailbox #(base_item)  slv_aw_mbx = new(0);
  mailbox #(base_item)  slv_w_mbx = new(0);
  mailbox #(base_item)  slv_b_mbx = new(0);
  mailbox #(base_item)  slv_ar_mbx = new(0);
  mailbox #(base_item)  slv_r_mbx = new(0);

  mailbox #(base_item)  mst_aw_mbx = new(0);
  mailbox #(base_item)  mst_w_mbx = new(0);
  mailbox #(base_item)  mst_b_mbx = new(0);
  mailbox #(base_item)  mst_ar_mbx = new(0);
  mailbox #(base_item)  mst_r_mbx = new(0);

  function new(string name, uvm_component parent);
    super.new(name, parent);
    b_item = new();
    item_collected_port = new("item_collected_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(uvm_event)::get(this, "", "dma_chn_1_done", dma_chn_1_done))
      `uvm_fatal("NODMADONECHN1", {"dma done must be set for: ", get_full_name()})
    if (!uvm_config_db#(uvm_event)::get(this, "", "dma_chn_2_done", dma_chn_2_done))
      `uvm_fatal("NODMADONECHN2", {"dma done must be set for: ", get_full_name()})
    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name()})
    if (!uvm_config_db#(base_mem)::get(this, "", "memory", memory))
      `uvm_fatal("NOMEM", {"memory must be set for: ", get_full_name()})
    if (!uvm_config_db#(int)::get(this, "", "total_cyclic", total_cyclic))
      `uvm_fatal("NOTOTALCYCLIC1", {"total_cyclic must be set for: ", get_full_name()})
  endfunction

  task run_phase(uvm_phase phase);
    wait_reset();
    fork
        master_ar_channel();
        master_aw_channel();
        master_w_channel();
        master_r_channel();
        master_resp_channel();    
        slave_ar_channel();
        slave_aw_channel();
        slave_w_channel();
        slave_r_channel();
        slave_resp_channel();
    join_none

    forever begin
      seq_item_port.get(b_item);
      `uvm_info("run_phase", $sformatf("Start driver: %s", b_item.sprint()), UVM_LOW)
      $cast(rsp, b_item.clone());
      rsp.set_id_info(b_item);
      if (b_item.type_act == READ && b_item.type_axi == SLV) begin
        slv_ar_mbx.put(rsp);
      end
      else if (b_item.type_act == WRITE && b_item.type_axi == SLV) begin
        // CHANNEL 1
        chn_id = b_item.chn_id;
        if (b_item.s_awaddr_i == SRC_ADDR + chn_id * (2**4)) begin
          item_collected_port.write(rsp);
        end
        if (b_item.s_awaddr_i == DST_ADDR + chn_id * (2**4)) begin
          item_collected_port.write(rsp);
        end
        if (b_item.s_awaddr_i == TRANSFER_X_LEN_ADDR + chn_id * (2**4)) begin
          if (chn_id == 0) begin
            x_len_1 = b_item.s_wdata_i;
            if (wd_per_burst_1 != -1)  begin
              num_trans_row_1 += $ceil(1.0 * (x_len_1 + 1) / (wd_per_burst_1 + 1));
              $display("num_trans_row_1: %0d", num_trans_row_1);
            end
          end
          else if (chn_id == 1) begin
            x_len_2 = b_item.s_wdata_i;
            if (wd_per_burst_2 != -1)  begin
              num_trans_row_2 += $ceil(1.0 * (x_len_1 + 1) / (wd_per_burst_1 + 1));
              $display("num_trans_row_2: %0d", num_trans_row_2);
            end
          end
          item_collected_port.write(rsp);
        end
        if (b_item.s_awaddr_i == CHN_FLAGS_ADDR + chn_id * (2**4)) begin
          item_collected_port.write(rsp);
        end
        if (b_item.s_awaddr_i == ATX_SRC_BURST_ADDR + chn_id * (2**4)) begin
          item_collected_port.write(rsp);
        end
        if (b_item.s_awaddr_i == ATX_DST_BURST_ADDR + chn_id * (2**4)) begin
          item_collected_port.write(rsp);
        end
        if (b_item.s_awaddr_i == ATX_WD_PER_BURST_ADDR + chn_id * (2**4)) begin
          if (chn_id == 0) begin
            wd_per_burst_1 = b_item.s_wdata_i;
            if (x_len_1 != -1)  begin
              num_trans_row_1 += $ceil(1.0 * (x_len_1 + 1) / (wd_per_burst_1 + 1));
              $display("num_trans_row_1: %0d", num_trans_row_1);
            end
          end
          else if (chn_id == 1) begin
            wd_per_burst_2 = b_item.s_wdata_i;
            if (x_len_2 != -1)  begin
              num_trans_row_2 += $ceil(1.0 * (x_len_2 + 1) / (wd_per_burst_2 + 1));
              $display("num_trans_row_2: %0d", num_trans_row_2);
            end
          end
          item_collected_port.write(rsp);
        end
        if (b_item.s_awaddr_i == TRANSFER_Y_LEN_ADDR + chn_id * (2**4)) begin
          if (chn_id == 0) begin
            y_len_1 = b_item.s_wdata_i;
            $display("Y_LEN_1", y_len_1);
          end
          else if (chn_id == 1) begin
            y_len_2 = b_item.s_wdata_i;
            $display("Y_LEN_2", y_len_2);
          end
          item_collected_port.write(rsp);
        end
        if (b_item.s_awaddr_i == SRC_STRIDE_ADDR + chn_id * (2**4)) begin
          item_collected_port.write(rsp);
        end
        if (b_item.s_awaddr_i == DST_STRIDE_ADDR + chn_id * (2**4)) begin
          item_collected_port.write(rsp);
        end

        slv_aw_mbx.put(rsp);
      end
      // else if (b_item.type_act == "READ" && b_item.type_axi == "MST") begin
      //   mst_w_mbx.put(rsp);
      // end
      // else if (b_item.type_act == "WRITE" && b_item.type_axi == "MST") begin
      //   mst_mbx.put(rsp);
      // end
    end
  endtask

  task wait_reset();
    vif.s_awvalid_i <= 0;
    vif.s_arvalid_i <= 0;
    vif.s_wvalid_i <= 0;
    @(posedge vif.rst);
  endtask

  task master_ar_channel();
    base_item item = new();
    forever begin
      @ (posedge vif.clk);
      wait (vif.m_arvalid_o);
      @ (posedge vif.clk);
      vif.m_arready_i <= 1;
      item.m_arid_o = vif.m_arid_o;
      item.m_araddr_o = vif.m_araddr_o;
      item.m_arlen_o = vif.m_arlen_o;
      item.m_arburst_o = vif.m_arburst_o;
      $cast(item_temp_ar, item.clone());
      mst_r_mbx.put(item_temp_ar);
      $display("len master ar: %0d", item.m_arlen_o);
    end
  endtask

  task master_r_channel();
    base_item item = null;
    forever begin
      mst_r_mbx.get(item);
      $display("ENTER MASTER R");
      $display("get master ar: %0d", item.m_arlen_o);
      for (int i = 0; i < item.m_arlen_o + 1; i++) begin
        @(posedge vif.clk);
        $display ("i: %0d, rdata: %0d", i, item.m_araddr_o + i);
        $display ("len: %0d", item.m_arlen_o);
        vif.m_rid_i <= item.m_arid_o;
        vif.m_rdata_i <= memory.read(item.m_araddr_o + i);
        vif.m_rresp_i <= 0;
        if (i == item.m_arlen_o) begin
          $display("LAST OCCUR");
        end
        vif.m_rlast_i <= (i == item.m_arlen_o) ? 1 : 0;
        vif.m_rvalid_i <= 1;
        wait(vif.m_rready_o);
      end
      @(posedge vif.clk);
      vif.m_rlast_i <= 0;
      vif.m_rvalid_i <= 0;
    end
  endtask


  task master_aw_channel();
    base_item item = new();
    forever begin
      @ (posedge vif.clk);
      wait (vif.m_awvalid_o);
      @ (posedge vif.clk);
      vif.m_awready_i <= 1;
      item.m_awid_o = vif.m_awid_o;
      item.m_awaddr_o = vif.m_awaddr_o;
      item.m_awlen_o = vif.m_awlen_o;
      item.m_awburst_o = vif.m_awburst_o;
      $cast(item_temp_aw, item.clone());
      mst_w_mbx.put(item_temp_aw);
      // @(posedge vif.clk);
      // vif.m_awready_i <= 0;
    end
  endtask

  task master_w_channel();
    base_item item = null;
    forever begin
      mst_w_mbx.get(item);
      // wait (vif.m_wvalid_o);
      // @(posedge vif.clk);
      // vif.m_wready_i <= 1;
      // @(posedge vif.clk);
      // vif.m_wready_i <= 0;
      @ (posedge vif.clk);
      vif.m_wready_i <= 1;
      wait (vif.m_wlast_o && vif.m_wvalid_o);
      @ (posedge vif.clk);
      vif.m_wready_i <= 0;
      $cast(item_temp_w, item.clone());
      mst_b_mbx.put(item_temp_w);

    end
  endtask
  
  task master_resp_channel();
    base_item item = null;
    forever begin
      mst_b_mbx.get(item);
      if (item.m_awid_o == 1) count_1 ++;
      else count_2 ++;
      $display ("TOTAL WAIT 1: %0d", num_trans_row_1 * (y_len_1 + 1) * 2);
      $display ("TOTAL WAIT 2: %0d", num_trans_row_2 * (y_len_2 + 1) * 2);
      $display ("count_1: %0d", count_1); 
      $display ("count_2: %0d", count_2);
      $display("ENTER MASTER RESP");
      wait(vif.m_bready_o);
      @(posedge vif.clk)
      vif.m_bid_i <= item.m_awid_o;
      vif.m_bresp_i <= 0;
      vif.m_bvalid_i <= 1;
      @(posedge vif.clk)
      vif.m_bvalid_i <= 0;
      if (count_1 == num_trans_row_1 * (y_len_1 + 1) * (total_cyclic - 1)) begin
        $display("DONE DMA 1 TRIGGER");
        dma_chn_1_done.trigger();
      end
      if (count_2 == num_trans_row_2 * (y_len_2 + 1) * (total_cyclic - 1)) begin
        $display("DONE DMA 2 TRIGGER");
        dma_chn_2_done.trigger();
      end
    end
  endtask

  task slave_aw_channel();
    base_item item = null;
    forever begin
      slv_aw_mbx.get(item);
      @(posedge vif.clk);
      vif.s_awid_i <= item.s_awid_i;
      vif.s_awaddr_i <= item.s_awaddr_i;
      vif.s_awburst_i <= item.s_awburst_i;
      vif.s_awlen_i <= item.s_awlen_i;
      vif.s_awvalid_i <= 1;
      @(posedge vif.clk);  
      wait(vif.s_awready_o);
      // #1;
      @(posedge vif.clk);
      vif.s_awvalid_i <= 0;
      slv_w_mbx.put(item);
      `uvm_info("Handshake successfully slave", $sformatf("time: %0t", $realtime), UVM_LOW)
    end
  endtask

  task slave_w_channel();
    base_item item = null;
    forever begin
      slv_w_mbx.get(item);
      @(posedge vif.clk);
      vif.s_wdata_i <= item.s_wdata_i; 
      vif.s_wlast_i <= 1;
      vif.s_wvalid_i <= 1;
      vif.s_bready_i <= 1;
      wait(vif.s_wready_o);
      slv_b_mbx.put(item);
      @(posedge vif.clk);
      vif.s_wlast_i <= 0;
      vif.s_wvalid_i <= 0;
    end
  endtask

  task slave_ar_channel();
    base_item item = null;
    forever begin
      slv_ar_mbx.get(item);
      @(posedge vif.clk);
      vif.s_arid_i <= item.s_arid_i;
      vif.s_araddr_i <= item.s_araddr_i;
      vif.s_arburst_i <= item.s_arburst_i;
      vif.s_arlen_i <= item.s_arlen_i;
      vif.s_arvalid_i <= 1;
      @(posedge vif.clk);
      wait(vif.s_arready_o);
      @(posedge vif.clk);
      vif.s_arvalid_i <= 0;
      slv_r_mbx.put(item);
    end
  endtask

  task slave_r_channel();
    base_item item = null;
    forever begin
      slv_r_mbx.get(item);
      @(posedge vif.clk);
      vif.s_rready_i <= 1;
      wait(vif.s_rvalid_o);
      item.s_rid_o = vif.s_rid_o;
      item.s_rdata_o = vif.s_rdata_o;
      item.s_rresp_o = vif.s_rresp_o;
      @(posedge vif.clk);
      vif.s_rready_i <= 0;
      seq_item_port.put(item);
    end
  endtask

  task slave_resp_channel();
    base_item item = null;
    forever begin
      slv_b_mbx.get(item);
      wait(vif.s_bvalid_o);
      seq_item_port.put(item);
    end
  endtask
endclass : base_driver
