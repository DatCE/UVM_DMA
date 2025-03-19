class base_test extends uvm_test;

  `uvm_component_utils(base_test)
  base_env bus_env;
  init_read_seq seq0;
  stop_cyclic_0 seq_1;
  stop_cyclic_1 seq_2;
  bit test_pass;
  base_mem memory;
  uvm_event dma_chn_1_done;
  uvm_event dma_chn_2_done;
  int total_cyclic = 3;
  int total_cyclic_chn_1 = 0;
  int total_cyclic_chn_2 = 0;
  // The test's constructor
  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Update this component's properties and create the base_tb component.
  virtual function void build_phase(uvm_phase phase); // Create the testbench.
    super.build_phase(phase);
    memory = base_mem::type_id::create("memory", this);
    memory.mem_init();
    // memory.mem_print();
    dma_chn_1_done = new("dma_chn_1_done");
    dma_chn_2_done = new("dma_chn_2_done");
    uvm_config_db#(uvm_event)::set(this, "*", "dma_chn_1_done", dma_chn_1_done);
    uvm_config_db#(uvm_event)::set(this, "*", "dma_chn_2_done", dma_chn_2_done);
    uvm_config_db#(base_mem)::set(this, "*", "memory", memory);
    uvm_config_db#(int)::set(this, "*", "test_phase", 1);
    bus_env = base_env::type_id::create("bus_env", this);
    uvm_config_db#(int)::set(this,"bus_env.master", "is_active", UVM_ACTIVE);
    uvm_config_db#(int)::set(this, "*", "total_cyclic", total_cyclic);
    uvm_config_db#(int)::set(this, "*", "total_cyclic_chn_1", total_cyclic_chn_1);
    uvm_config_db#(int)::set(this, "*", "total_cyclic_chn_2", total_cyclic_chn_2);
  endfunction

  virtual function void end_of_elaboration();
    uvm_top.print_topology();
  endfunction : end_of_elaboration
  task done_dma_chn_1();
    dma_chn_1_done.wait_trigger();
    $display("start seq stop dma_chn_1");
    seq_1.start(bus_env.master.sequencer);
  endtask
  task done_dma_chn_2();
    dma_chn_2_done.wait_trigger();
    $display("start seq stop dma_chn_2");
    seq_2.start(bus_env.master.sequencer);
  endtask

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq0 = init_read_seq::type_id::create("sequence0");
    seq_1 = stop_cyclic_0::type_id::create("sequence1");
    seq_2 = stop_cyclic_1::type_id::create("sequence2");
    seq0.start(bus_env.master.sequencer);
    // #50000ns; // 26ns
    // dma_chn_1_done.wait_trigger();
    fork
      done_dma_chn_1();
      done_dma_chn_2();
    join
    #100000ns;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    int error_cnt;
    uvm_report_server server;

    server = get_report_server();
    error_cnt = server.get_severity_count(UVM_FATAL) +
                server.get_severity_count(UVM_ERROR);

    if(error_cnt == 0) begin
      test_pass = 1;
    end
    
    //`uvm_info(get_type_name(), $sformatf("Coverage percentage: %f%%", bus_env.master.monitor.cov_trans.get_coverage()), UVM_LOW)

    if(test_pass) begin
      `uvm_info(get_type_name(), "** TEST PASSED **", UVM_NONE)
    end
    else begin
      `uvm_error(get_type_name(), "** TEST FAIL **")
    end
  endfunction
endclass