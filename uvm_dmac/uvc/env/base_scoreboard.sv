`uvm_analysis_imp_decl(_mon)
`uvm_analysis_imp_decl(_drv)

class base_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp_drv #(base_item, base_scoreboard) drv_item_collected_export;
  uvm_analysis_imp_mon #(base_item, base_scoreboard) mon_item_collected_export;
  `uvm_component_utils(base_scoreboard)
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

  parameter TOTAL_PIXEL = 320 * 240;

  int count_config;
  int count_process;
  int src_addr;
  int dst_addr;
  int x_len;
  int y_len;
  int chn_flag;
  int src_burst_addr;
  int dst_burst_addr;
  int wd_per_burst_addr;
  int src_stride;
  int dst_stride;
  int total_cyclic = 3;
  bit  [31:0] mem_expected [TOTAL_PIXEL] [$];
  bit  [31:0] mem_actual   [TOTAL_PIXEL] [$];
  bit  [31:0] temp_mem_expected [TOTAL_PIXEL] [$];
  bit  [31:0] temp_mem_actual   [TOTAL_PIXEL] [$];
  base_mem memory;

  function new(string name = "base_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    drv_item_collected_export = new("drv_item_collected_export", this);
    mon_item_collected_export = new("mon_item_collected_export", this);
    if (!uvm_config_db#(base_mem)::get(this, "", "memory", memory))
      `uvm_fatal("NOMEM", {"memory must be set for: ", get_full_name()})

    // $display("IN SCOREBOARD");
    // memory.mem_print();
    for (int i = 0; i < 1024; i++) begin
      mem_expected[i].delete();
      mem_actual[i].delete();
    end
  endfunction


  virtual function void write_drv(base_item item);
    `uvm_info(get_type_name(), $sformatf("Captured packet from drv %s", item.sprint()), UVM_LOW)
    if (item.s_awaddr_i == CHN_FLAGS_ADDR) begin
      if (item.s_wdata_i == 2) begin
        count_process = 7;
        $display("Mode: Cyclic");
      end
      if (item.s_wdata_i == 1) begin
        count_process = 10;
        $display("Mode: 2D transfer");
      end
      if (item.s_wdata_i == 3) begin
        count_process = 10;
        $display("Mode: 2D transfer & Cyclic");
      end
    end
    if (item.s_awaddr_i == SRC_ADDR) begin
      src_addr = item.s_wdata_i;
      count_config++;
    end
    if (item.s_awaddr_i == DST_ADDR) begin
      dst_addr = item.s_wdata_i;
      count_config++;
    end
    if (item.s_awaddr_i == TRANSFER_X_LEN_ADDR) begin
      x_len = item.s_wdata_i;
      count_config++;
    end
    if (item.s_awaddr_i == TRANSFER_Y_LEN_ADDR) begin
      y_len = item.s_wdata_i;
      count_config++;
    end
    if (item.s_awaddr_i == SRC_STRIDE_ADDR) begin
      src_stride = item.s_wdata_i;
      count_config++;
    end
    if (item.s_awaddr_i == DST_STRIDE_ADDR) begin
      dst_stride = item.s_wdata_i;
      count_config++;
    end
    if (item.s_awaddr_i == CHN_FLAGS_ADDR) begin
      chn_flag = item.s_wdata_i;
      count_config++;
    end
    if (item.s_awaddr_i == ATX_SRC_BURST_ADDR) begin
      src_burst_addr = item.s_wdata_i;
      count_config++;
    end
    if (item.s_awaddr_i == ATX_DST_BURST_ADDR) begin
      dst_burst_addr = item.s_wdata_i;
      count_config++;
    end
    if (item.s_awaddr_i == ATX_WD_PER_BURST_ADDR) begin
      wd_per_burst_addr = item.s_wdata_i;
      count_config++;
    end
    $display ("count config: %0d", count_config);
    if (count_config == count_process) begin
      if (count_process == 7) begin // MODE CYCLIC
        // MODE AXI FIXED
        if (src_burst_addr == 0 && dst_burst_addr == 0) begin
          $display("ENTER MODE 1");
          for (int i = 0; i < x_len + 1; i++) begin
            mem_expected[dst_addr].push_back(memory.read(src_addr));
          end
        end
        else if (src_burst_addr == 1 && dst_burst_addr == 0) begin
          $display("ENTER MODE 2");
          for (int i = 0; i < x_len + 1; i++) begin
            mem_expected[dst_addr].push_back(memory.read(src_addr + i));
          end
        end
        else if (src_burst_addr == 0 && dst_burst_addr == 1) begin
          $display("ENTER MODE 3");
          for (int i = 0; i < x_len + 1; i++) begin
            mem_expected[dst_addr + i].push_back(memory.read((src_addr + i) % (wd_per_burst_addr + 1)));
          end
        end
        else if (src_burst_addr == 1 && dst_burst_addr == 1) begin
          $display("ENTER MODE 4");
          for (int i = 0; i < x_len + 1; i++) begin
            mem_expected[dst_addr + i].push_back(memory.read(src_addr + i));
          end
        end
      end

      else if (count_process == 10) begin
        $display("ENTER MODE 2D");
        for (int k = 0; k < total_cyclic; k++) begin
          for (int i = 0; i < y_len + 1; i++) begin
            for (int j = 0; j < x_len + 1; j++) begin
              mem_expected[dst_addr + i * dst_stride + j].push_back(memory.read(src_addr + i * src_stride + j));
            end
          end
        end
      end
    end

  endfunction

  virtual function void write_mon(base_item item);
    `uvm_info(get_type_name(), $sformatf("Captured packet from mon %s", item.sprint()), UVM_LOW)
    if (item.m_awburst_o == 0) begin
      for (int i = 0; i < item.m_awlen_o + 1; i++) begin
        mem_actual[item.m_awaddr_o].push_back(item.buffer_wdata[0]);
        item.buffer_wdata.pop_front();
      end
    end
    else if (item.m_awburst_o == 1) begin
      for (int i = 0; i < item.m_awlen_o + 1; i++) begin
        mem_actual[item.m_awaddr_o + i].push_back(item.buffer_wdata[0]);
        item.buffer_wdata.pop_front();
      end
    end
    
  endfunction

  virtual function void extract_phase(uvm_phase phase);
    temp_mem_actual = mem_actual;
    temp_mem_expected = mem_expected;

    for (int i = 0; i < TOTAL_PIXEL; i++) begin
      if (temp_mem_expected[i].size() != 0) begin
        `uvm_info("MEM EXPECTED EXTRACT_PHASE", $sformatf("mem_expected[%0d]: %p", i, temp_mem_expected[i]), UVM_LOW)
      end
      // temp_mem_expected.pop_front();
    end


    for (int i = 0; i < TOTAL_PIXEL; i++) begin
      if (temp_mem_actual[i].size() != 0) begin
        `uvm_info("MEM ACTUAL EXTRACT_PHASE", $sformatf("mem_actual[%0d]: %p", i, temp_mem_actual[i]), UVM_LOW)
      end
      // temp_mem_actual.pop_front();
    end
    // for (int i = 0; i < 1024; i++) begin

    //   if (mem_expected[i].size() != mem_actual[i].size()) begin
    //     `uvm_error("MEM SIZE ERROR", $sformatf("Error at index i: %0d", i))
    //   end
    //   else begin
    //     for (int j = 0; j < mem_expected[i].size(); j++) begin
    //       if (mem_expected[i][0] != mem_actual[i][0]) begin
    //         `uvm_error("MEM DATA ERROR", $sformatf("Error at index i: %0d, j: %0d", i, j))
    //         $display ("Expected: %0d, Actual: %0d", mem_expected[i][0], mem_actual[i][0]);
    //         mem_expected[i].pop_front();
    //       end
    //       else begin
    //         $display("PASS");
    //       end
    //     end
    //   end

    // end 
  endfunction

endclass