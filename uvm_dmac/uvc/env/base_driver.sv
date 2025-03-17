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
  uvm_event dma_done;
  int count = 0;
  base_item item_temp;
  base_item item_temp_ar;
  base_item item_temp_aw;
  base_item item_temp_w;
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
    if (!uvm_config_db#(uvm_event)::get(this, "", "dma_done", dma_done))
      `uvm_fatal("NODMADONE", {"dma done must be set for: ", get_full_name()})
    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name()})
    if (!uvm_config_db#(base_mem)::get(this, "", "memory", memory))
      `uvm_fatal("NOMEM", {"memory must be set for: ", get_full_name()})
    
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
      $display("COME-HERE");
      if (b_item.type_act == READ && b_item.type_axi == SLV) begin
        $display("SLV READ");
        slv_ar_mbx.put(rsp);
      end
      else if (b_item.type_act == WRITE && b_item.type_axi == SLV) begin
        $display("SLV WRITE");
        slv_aw_mbx.put(rsp);
      end
      $display("FINISH");
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
      wait (vif.m_wlast_o && vif.m_wvalid_o                );
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
      count ++;
      $display("ENTER MASTER RESP");
      wait(vif.m_bready_o);
      @(posedge vif.clk)
      vif.m_bid_i <= item.m_awid_o;
      vif.m_bresp_i <= 0;
      vif.m_bvalid_i <= 1;
      @(posedge vif.clk)
      vif.m_bvalid_i <= 0;
      if (count == 2) dma_done.trigger();
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
      // @(posedge vif.clk);
      // vif.s_awvalid_i <= 0;
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
      slv_r_mbx.put(item);
      // @(posedge vif.clk);
      // vif.s_arvalid_i <= 0;
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
