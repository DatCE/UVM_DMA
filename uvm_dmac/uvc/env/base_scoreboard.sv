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

  int src_addr_1;
  int dst_addr_1;
  int x_len_1;
  int y_len_1;
  int chn_flag_1;
  int src_burst_addr_1;
  int dst_burst_addr_1;
  int wd_per_burst_addr_1;
  int src_stride_1;
  int dst_stride_1;

  int src_addr_2;
  int dst_addr_2;
  int x_len_2;
  int y_len_2;
  int chn_flag_2;
  int src_burst_addr_2;
  int dst_burst_addr_2;
  int wd_per_burst_addr_2;
  int src_stride_2;
  int dst_stride_2;

  int chn_id;

  int total_cyclic;
  bit  [31:0] mem_expected_chn_1 [TOTAL_PIXEL] [$];
  bit  [31:0] mem_expected_chn_2 [TOTAL_PIXEL] [$];
  bit  [31:0] mem_actual_chn_1   [TOTAL_PIXEL] [$];
  bit  [31:0] mem_actual_chn_2   [TOTAL_PIXEL] [$];
  base_mem memory;

  function new(string name = "base_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    drv_item_collected_export = new("drv_item_collected_export", this);
    mon_item_collected_export = new("mon_item_collected_export", this);
    if (!uvm_config_db#(base_mem)::get(this, "", "memory", memory))
      `uvm_fatal("NOMEM", {"memory must be set for: ", get_full_name()})
    if (!uvm_config_db#(int)::get(this, "", "total_cyclic", total_cyclic))
      `uvm_fatal("NOTOTALCYCLIC", {"total_cyclic must be set for: ", get_full_name()})

    // $display("IN SCOREBOARD");
    // memory.mem_print();
    for (int i = 0; i < TOTAL_PIXEL; i++) begin
      mem_expected_chn_1[i].delete();
      mem_expected_chn_2[i].delete();
      mem_actual_chn_1[i].delete();
      mem_actual_chn_2[i].delete();
    end
  endfunction


  virtual function void write_drv(base_item item);
    `uvm_info(get_type_name(), $sformatf("Captured packet from drv %s", item.sprint()), UVM_LOW)
    chn_id = item.chn_id;

    if (item.s_awaddr_i == CHN_FLAGS_ADDR + chn_id * (2**4)) begin
      if (item.s_wdata_i == 2) begin
        count_process += 7;
        $display("Mode: Cyclic");
      end
      if (item.s_wdata_i == 1) begin
        count_process += 10;
        $display("Mode: 2D transfer");
      end
      if (item.s_wdata_i == 3) begin
        count_process += 10;
        $display("Mode: 2D transfer & Cyclic");
      end
    end
    if (item.s_awaddr_i == SRC_ADDR + chn_id * (2**4)) begin
      if (chn_id == 0) begin
        src_addr_1 = item.s_wdata_i;
      end
      else if (chn_id == 1) begin
        src_addr_2 = item.s_wdata_i;
      end
      count_config++;
    end
    if (item.s_awaddr_i == DST_ADDR + chn_id * (2**4)) begin
      if (chn_id == 0) begin
        dst_addr_1 = item.s_wdata_i;
      end
      else if (chn_id == 1) begin
        dst_addr_2 = item.s_wdata_i;
      end
      count_config++;
    end
    if (item.s_awaddr_i == TRANSFER_X_LEN_ADDR + chn_id * (2**4)) begin
      if (chn_id == 0) begin
        x_len_1 = item.s_wdata_i;
      end
      else if (chn_id == 1) begin
        x_len_2 = item.s_wdata_i;
      end
      count_config++;
    end
    if (item.s_awaddr_i == TRANSFER_Y_LEN_ADDR + chn_id * (2**4)) begin
      if (chn_id == 0) begin
        y_len_1 = item.s_wdata_i;
      end
      else if (chn_id == 1) begin
        y_len_2 = item.s_wdata_i;
      end
      count_config++;
    end
    if (item.s_awaddr_i == SRC_STRIDE_ADDR + chn_id * (2**4)) begin
      if (chn_id == 0) begin
        src_stride_1 = item.s_wdata_i;
      end
      else if (chn_id == 1) begin
        src_stride_2 = item.s_wdata_i;
      end
      count_config++;
    end
    if (item.s_awaddr_i == DST_STRIDE_ADDR + chn_id * (2**4)) begin
      if (chn_id == 0) begin
        dst_stride_1 = item.s_wdata_i;
      end
      else if (chn_id == 1) begin
        dst_stride_2 = item.s_wdata_i;
      end
      count_config++;
    end
    if (item.s_awaddr_i == CHN_FLAGS_ADDR + chn_id * (2**4)) begin
      if (chn_id == 0) begin
        chn_flag_1 = item.s_wdata_i;
      end
      else if (chn_id == 1) begin
        chn_flag_2 = item.s_wdata_i;
      end
      count_config++;
    end
    if (item.s_awaddr_i == ATX_SRC_BURST_ADDR + chn_id * (2**4)) begin
      if (chn_id == 0) begin
        src_burst_addr_1 = item.s_wdata_i;
      end
      else if (chn_id == 1) begin
        src_burst_addr_2 = item.s_wdata_i;
      end
      count_config++;
    end
    if (item.s_awaddr_i == ATX_DST_BURST_ADDR + chn_id * (2**4)) begin
      if (chn_id == 0) begin
        dst_burst_addr_1 = item.s_wdata_i;
      end
      else if (chn_id == 1) begin
        dst_burst_addr_2 = item.s_wdata_i;
      end
      count_config++;
    end
    if (item.s_awaddr_i == ATX_WD_PER_BURST_ADDR + chn_id * (2**4)) begin
      if (chn_id == 0) begin
        wd_per_burst_addr_1 = item.s_wdata_i;
      end
      else if (chn_id == 1) begin
        wd_per_burst_addr_2 = item.s_wdata_i;
      end
      count_config++;
    end
    $display ("count process: %0d", count_process);
    $display ("count config: %0d", count_config);
    if (count_config == count_process) begin
      // if (count_process == 7) begin // MODE CYCLIC
      //   // MODE AXI FIXED
      //   if (src_burst_addr == 0 && dst_burst_addr == 0) begin
      //     $display("ENTER MODE 1");
      //     for (int i = 0; i < x_len + 1; i++) begin
      //       mem_expected[dst_addr].push_back(memory.read(src_addr));
      //     end
      //   end
      //   else if (src_burst_addr == 1 && dst_burst_addr == 0) begin
      //     $display("ENTER MODE 2");
      //     for (int i = 0; i < x_len + 1; i++) begin
      //       mem_expected[dst_addr].push_back(memory.read(src_addr + i));
      //     end
      //   end
      //   else if (src_burst_addr == 0 && dst_burst_addr == 1) begin
      //     $display("ENTER MODE 3");
      //     for (int i = 0; i < x_len + 1; i++) begin
      //       mem_expected[dst_addr + i].push_back(memory.read((src_addr + i) % (wd_per_burst_addr + 1)));
      //     end
      //   end
      //   else if (src_burst_addr == 1 && dst_burst_addr == 1) begin
      //     $display("ENTER MODE 4");
      //     for (int i = 0; i < x_len + 1; i++) begin
      //       mem_expected[dst_addr + i].push_back(memory.read(src_addr + i));
      //     end
      //   end
      // end

      // else if (count_process == 10) begin
      //   $display("ENTER MODE 2D");
      //   for (int k = 0; k < total_cyclic; k++) begin
      //     for (int i = 0; i < y_len + 1; i++) begin
      //       for (int j = 0; j < x_len + 1; j++) begin
      //         mem_expected[dst_addr + i * dst_stride + j].push_back(memory.read(src_addr + i * src_stride + j));
      //       end
      //     end
      //   end
      // end

      if (count_process == 20) begin
        $display ("ENTER MODE 2D - 2 DMA CHANNEL");
        for (int k = 0; k < total_cyclic; k++) begin
          for (int i = 0; i < y_len_1 + 1; i++) begin
            for (int j = 0; j < x_len_1 + 1; j++) begin
              mem_expected_chn_1[dst_addr_1 + i * dst_stride_1 + j].push_back(memory.read(src_addr_1 + i * src_stride_1 + j));
            end
          end
        end
        for (int k = 0; k < total_cyclic; k++) begin
          for (int i = 0; i < y_len_2 + 1; i++) begin
            for (int j = 0; j < x_len_2 + 1; j++) begin
              mem_expected_chn_2[dst_addr_2 + i * dst_stride_2 + j].push_back(memory.read(src_addr_2 + i * src_stride_2 + j));
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
        mem_actual_chn_1[item.m_awaddr_o].push_back(item.buffer_wdata[0]);
        item.buffer_wdata.pop_front();
      end
    end
    else if (item.m_awburst_o == 1) begin
      if (item.m_awid_o == 1) begin // Channel 1
        for (int i = 0; i < item.m_awlen_o + 1; i++) begin
          mem_actual_chn_1[item.m_awaddr_o + i].push_back(item.buffer_wdata[0]);
          item.buffer_wdata.pop_front();
        end
      end
      if (item.m_awid_o == 2) begin // Channel 2
        for (int i = 0; i < item.m_awlen_o + 1; i++) begin
          mem_actual_chn_2[item.m_awaddr_o + i].push_back(item.buffer_wdata[0]);
          item.buffer_wdata.pop_front();
        end
    end

    end
    
  endfunction

  virtual function void extract_phase(uvm_phase phase);
    /* DEBUG */

    $display("src_addr_1: %0d", src_addr_1);
    $display("dst_addr_1: %0d", dst_addr_1);
    $display("x_len_1: %0d", x_len_1);
    $display("y_len_1: %0d", y_len_1);
    $display("chn_flag_1: %0d", chn_flag_1);
    $display("src_burst_addr_1: %0d", src_burst_addr_1);
    $display("dst_burst_addr_1: %0d", dst_burst_addr_1);
    $display("wd_per_burst_addr_1: %0d", wd_per_burst_addr_1);
    $display("src_stride_1: %0d", src_stride_1);
    $display("dst_stride_1: %0d", dst_stride_1);

    $display("src_addr_2: %0d", src_addr_2);
    $display("dst_addr_2: %0d", dst_addr_2);
    $display("x_len_2: %0d", x_len_2);
    $display("y_len_2: %0d", y_len_2);
    $display("chn_flag_2: %0d", chn_flag_2);
    $display("src_burst_addr_2: %0d", src_burst_addr_2);
    $display("dst_burst_addr_2: %0d", dst_burst_addr_2);
    $display("wd_per_burst_addr_2: %0d", wd_per_burst_addr_2);
    $display("src_stride_2: %0d", src_stride_2);
    $display("dst_stride_2: %0d", dst_stride_2);


    for (int i = 0; i < TOTAL_PIXEL; i++) begin
      if (mem_expected_chn_1[i].size() != 0) begin
        `uvm_info("MEM EXPECTED CHANNEL 1 EXTRACT_PHASE", $sformatf("mem_expected_chn_1[%0d]: %p", i, mem_expected_chn_1[i]), UVM_LOW)
      end
    end

    for (int i = 0; i < TOTAL_PIXEL; i++) begin
      if (mem_expected_chn_2[i].size() != 0) begin
        `uvm_info("MEM EXPECTED CHANNEL 2 EXTRACT_PHASE", $sformatf("mem_expected_chn_2[%0d]: %p", i, mem_expected_chn_2[i]), UVM_LOW)
      end
    end

    for (int i = 0; i < TOTAL_PIXEL; i++) begin
      if (mem_actual_chn_1[i].size() != 0) begin
        `uvm_info("MEM ACTUAL CHANNEL 1 EXTRACT_PHASE", $sformatf("mem_actual_chn_1[%0d]: %p", i, mem_actual_chn_1[i]), UVM_LOW)
      end
    end

    for (int i = 0; i < TOTAL_PIXEL; i++) begin
      if (mem_actual_chn_2[i].size() != 0) begin
        `uvm_info("MEM ACTUAL CHANNEL 2 EXTRACT_PHASE", $sformatf("mem_actual_chn_2[%0d]: %p", i, mem_actual_chn_2[i]), UVM_LOW)
      end
    end
    /* DEBUG */

    $display("---------------------------------START CHANNEL 1---------------------------------");
    for (int i = 0; i < TOTAL_PIXEL; i++) begin
      if (mem_expected_chn_1[i].size() != mem_actual_chn_1[i].size()) begin
        `uvm_error("MEM SIZE ERROR CHANNEL 1", $sformatf("Error at index i: %0d", i))
        $display ("Expected: %p, Actual: %p", mem_expected_chn_1[i], mem_actual_chn_1[i]);
      end
      else begin
        for (int j = 0; j < mem_expected_chn_1[i].size(); j++) begin
          if (mem_expected_chn_1[i][0] != mem_actual_chn_1[i][0]) begin
            `uvm_error("MEM DATA ERROR", $sformatf("Error at index i: %0d, j: %0d", i, j))
            $display ("Expected: %0d, Actual: %0d", mem_expected_chn_1[i][0], mem_actual_chn_1[i][0]);
            mem_expected_chn_1[i].pop_front();
          end
          else begin
            $display("PASS");
          end
        end
      end
    end 
    $display("---------------------------------START CHANNEL 2---------------------------------");
    for (int i = 0; i < TOTAL_PIXEL; i++) begin
      if (mem_expected_chn_2[i].size() != mem_actual_chn_2[i].size()) begin
        `uvm_error("MEM SIZE ERROR CHANNEL 2", $sformatf("Error at index i: %0d", i))
        $display ("Expected: %p, Actual: %p", mem_expected_chn_2[i], mem_actual_chn_2[i]);
      end
      else begin
        for (int j = 0; j < mem_expected_chn_2[i].size(); j++) begin
          if (mem_expected_chn_2[i][0] != mem_actual_chn_2[i][0]) begin
            `uvm_error("MEM DATA ERROR", $sformatf("Error at index i: %0d, j: %0d", i, j))
            $display ("Expected: %0d, Actual: %0d", mem_expected_chn_2[i][0], mem_actual_chn_2[i][0]);
            mem_expected_chn_2[i].pop_front();
          end
          else begin
            $display("PASS");
          end
        end
      end
    end 

  endfunction

endclass