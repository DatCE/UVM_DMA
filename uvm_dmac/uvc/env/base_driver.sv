// `include "base_item.sv"
class base_driver extends uvm_driver #(base_item);
  typedef enum {READ, WRITE} type_rd_wr; 
  typedef enum {SLV, MST} axi_side; 
  uvm_analysis_port #(base_item) item_collected_port;
  `uvm_component_utils(base_driver)
  virtual dut_if vif;
  base_item b_item;
  int cnt;
  int cnt_2 = 1;

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
    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name()})
  endfunction

  task run_phase(uvm_phase phase);
    wait_reset();
    fork
        hs_slave_ar_channel();
        hs_slave_aw_channel();
        hs_slave_w_channel();
        hs_slave_r_channel();
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

  task drive_slave_aw_to_0();
    vif.s_awid_i <= 0;
    vif.s_awaddr_i <= 0;
    vif.s_awburst_i <= 0;
    vif.s_awlen_i <= 0;
    vif.s_awvalid_i <= 0;
  endtask

  task drive_slave_w_to_0();
    vif.s_wdata_i <= 0;
    vif.s_wlast_i <= 0;
    vif.s_wvalid_i <= 0;
  endtask

  task drive_slave_b_to_0();
    vif.s_bready_i <= 0;
  endtask
  
  task drive_slave_ar_to_0();
    vif.s_arid_i <= 0;
    vif.s_araddr_i <= 0;
    vif.s_arburst_i <= 0;
    vif.s_arlen_i <= 0;
    vif.s_arvalid_i <= 0;
  endtask

  task drive_slave_r_to_0();
    vif.s_rready_i <= 0;
  endtask

  task hs_slave_aw_channel();
    base_item item = null;
    forever begin
      // @(posedge vif.clk);
      slv_aw_mbx.get(item);
      $display({"Enter aw channel"});
      @(posedge vif.clk);
      vif.s_awid_i <= item.s_awid_i;
      vif.s_awaddr_i <= item.s_awaddr_i;
      vif.s_awburst_i <= item.s_awburst_i;
      vif.s_awlen_i <= item.s_awlen_i;
      vif.s_awvalid_i <= 1;
      wait(vif.s_awready_o);
      slv_w_mbx.put(item);
      @(posedge vif.clk);
      drive_slave_aw_to_0();
      $display("Exit aw channel");
    end
  endtask

  task hs_slave_w_channel();
    base_item item = null;
    forever begin
      // @(posedge vif.clk);
      slv_w_mbx.get(item);
      $display("Enter w channel");
      @(posedge vif.clk);
      vif.s_wdata_i <= item.s_wdata_i; 
      vif.s_wlast_i <= 1;
      vif.s_wvalid_i <= 1;
      vif.s_bready_i <= 1;
      wait(vif.s_wready_o);
      slv_b_mbx.put(item);
      @(posedge vif.clk);
      drive_slave_w_to_0();
      $display("Exit w channel");
    end
  endtask

  task hs_slave_ar_channel();
    base_item item = null;
    forever begin
      // @(posedge vif.clk);
      slv_ar_mbx.get(item);
      @(posedge vif.clk);
      vif.s_arid_i <= item.s_arid_i;
      vif.s_araddr_i <= item.s_araddr_i;
      vif.s_arburst_i <= item.s_arburst_i;
      vif.s_arlen_i <= item.s_arlen_i;
      vif.s_arvalid_i <= 1;
      wait(vif.s_arready_o);
      slv_r_mbx.put(item);
      @(posedge vif.clk);
      drive_slave_ar_to_0();
    end
  endtask

  task hs_slave_r_channel();
    base_item item = null;
    forever begin
      // @(posedge vif.clk);
      slv_ar_mbx.get(item);
      @(posedge vif.clk);
      vif.s_rready_i <= 1;
      wait(vif.s_rvalid_o);
      item.s_rdata_o = vif.s_rdata_o;
      @(posedge vif.clk);
      drive_slave_r_to_0();
      seq_item_port.put(item);
    end
  endtask

  task slave_resp_channel();
    base_item item = null;
    forever begin
      slv_b_mbx.get(item);
      // $display("-----------------BUG-----------------");
      wait(vif.s_bvalid_o);
      // @(posedge vif.clk);
      seq_item_port.put(item);
    end
  endtask
endclass : base_driver
