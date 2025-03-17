class base_monitor extends uvm_monitor;
  virtual dut_if vif;
  bit checks_enable = 1;
  bit coverage_enable = 1;
  uvm_analysis_port #(base_item) item_collected_port;
  `uvm_component_utils_begin(base_monitor)
    `uvm_field_int(checks_enable, UVM_ALL_ON)
    `uvm_field_int(coverage_enable, UVM_ALL_ON)
  `uvm_component_utils_end
  protected base_item trans_collected;
  protected base_item temp_trans;
  protected base_item write_info;
  protected base_item temp_write_info;
  protected base_item q_write [$];
  protected base_item temp_write;
  event cov_transaction;
  int test_phase;
  int i;
  covergroup cov_trans @cov_transaction;
  // coverpoint
  endgroup : cov_trans


  function new(string name = "base_monitor", uvm_component parent);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
    trans_collected = new();
    write_info = new();
    cov_trans = new();
    cov_trans.set_inst_name({get_full_name(), ".cov_trans"});
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name()})
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if (vif.m_awvalid_o && vif.m_awready_i) begin
        write_info.m_awid_o = vif.m_awid_o;
        write_info.m_awaddr_o = vif.m_awaddr_o;
        write_info.m_awlen_o = vif.m_awlen_o;
        write_info.m_awburst_o = vif.m_awburst_o;
        temp_write_info = base_item::type_id::create("temp_write_info", this);
        temp_write_info.copy(write_info);
        q_write.push_back(temp_write_info);
      end

      if (vif.m_wvalid_o && vif.m_wready_i) begin
        trans_collected.buffer_wdata.push_back(vif.m_wdata_o);
        if (vif.m_wlast_o) begin
          temp_write = q_write.pop_front();
          trans_collected.m_awid_o = temp_write.m_awid_o;
          trans_collected.m_awaddr_o = temp_write.m_awaddr_o;
          trans_collected.m_awlen_o = temp_write.m_awlen_o;
          trans_collected.m_awburst_o = temp_write.m_awburst_o;
          $cast(temp_trans, trans_collected.clone());
          temp_trans.set_id_info(trans_collected);
          item_collected_port.write(temp_trans);
          trans_collected.buffer_wdata.delete();
        end
      end
    end
  endtask



  virtual protected function void perform_transfer_coverage();
    // -> cov_transaction;
  endfunction

  virtual protected function void perform_transfer_checks();


  endfunction

endclass
