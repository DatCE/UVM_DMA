class init_read_seq extends uvm_sequence #(base_item);
  base_item req;
  `uvm_object_utils_begin(init_read_seq)
    `uvm_field_object(req, UVM_ALL_ON)
  `uvm_object_utils_end

  parameter BASE_ADDR = 32'h8000_0000;
  parameter DMA_CONTROL_ADDR = 'h0000;
  parameter ATX_ID_ADDR = 'h0005;
  parameter ATX_SRC_BURST_ADDR = 'h0006; 
  parameter ATX_DST_BURST_ADDR = 'h0007; 
  parameter ATX_WD_PER_BURST_ADDR  = 'h0008; 
  parameter SRC_ADDR = 'h0009;
  parameter DST_ADDR = 'h000A;
  parameter TRANSFER_SUBMIT_ADDR = 'h1000;
  parameter TRANSFER_X_LEN_ADDR = 'h000B;
  parameter TRANSFER_Y_LEN_ADDR = 'h000C;
  parameter SRC_STRIDE_ADDR = 'h000D;
  parameter DST_STRIDE_ADDR = 'h000E;
  parameter TRANSFER_ID_ADDR = 'h2001;
  parameter TRANSFER_DONE_ADDR = 'h2002;
  parameter ACTIVE_TRANSFER_ID_ADDR = 'h2003;
  parameter ACTIVE_TRANSFER_LEN_ADDR = 'h2004;
  parameter CHN_CONTROL_ADDR = 'h0001;
  parameter CHN_FLAGS_ADDR = 'h0002;
  parameter CHN_IRQ_MASK_ADDR = 'h0003;
  parameter CHN_IRQ_SOURCE_ADDR = 'h2000;
  parameter CHN_ARBIT_RATE_ADDR = 'h0004;

  int wait_response = 0;
  int cnt = 0;

  function new(string name = "init_read_seq");
    super.new(name);
  endfunction : new

  virtual task body();
  //------------------------------ START CHANNEL 1 ------------------------------ 
    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 1;
                  s_awaddr_i == BASE_ADDR + DMA_CONTROL_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 1;
                }
    );
    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 2;
                  s_awaddr_i == BASE_ADDR + CHN_CONTROL_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 1;

                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 3;
                  s_awaddr_i == BASE_ADDR + CHN_FLAGS_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 3;

                });  

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 4;
                  s_awaddr_i == BASE_ADDR + CHN_IRQ_MASK_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 3;

                });  

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 5;
                  s_awaddr_i == BASE_ADDR + CHN_ARBIT_RATE_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 1;

                });
  //------------------------------ END CHANNEL 1 ------------------------------

  //------------------------------ START CHANNEL 2 ------------------------------
    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 6;
                  s_awaddr_i == BASE_ADDR + CHN_CONTROL_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 1;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 7;
                  s_awaddr_i == BASE_ADDR + CHN_FLAGS_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 3;

                });  
  
    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 8;
                  s_awaddr_i == BASE_ADDR + CHN_IRQ_MASK_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 3;

                });  

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 9;
                  s_awaddr_i == BASE_ADDR + CHN_ARBIT_RATE_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 1;

                });   

  //------------------------------ END CHANNEL 2 ------------------------------
    repeat (9) begin
      get_response(rsp);
    end


  //------------------------------ TEST READ AFTER WRITE ------------------------------
    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_arid_i == 1;
    //               s_araddr_i == BASE_ADDR + DMA_CONTROL_ADDR;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });
    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_arid_i == 2;
    //               s_araddr_i == BASE_ADDR + CHN_CONTROL_ADDR;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });
    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_arid_i == 3;
    //               s_araddr_i == BASE_ADDR + CHN_FLAGS_ADDR;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });
    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_arid_i == 4;
    //               s_araddr_i == BASE_ADDR + CHN_IRQ_MASK_ADDR;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });
    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 1;
    //               s_arid_i == 5;
    //               s_araddr_i == BASE_ADDR + CHN_CONTROL_ADDR;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });
    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 1;
    //               s_arid_i == 6;
    //               s_araddr_i == BASE_ADDR + CHN_FLAGS_ADDR;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });
    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 1;
    //               s_arid_i == 7;
    //               s_araddr_i == BASE_ADDR + CHN_IRQ_MASK_ADDR;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });

    // repeat (7) begin
    //   get_response(rsp);
    // end
  //------------------------------ END TEST READ AFTER WRITE ------------------------------

    



  //------------------------------ START WRITE TO DESCRIPTOR ------------------------------
  //------------------------------ START CONFIG CHANNEL 1 ------------------------------
    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 1;
                  s_awaddr_i == BASE_ADDR + SRC_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 0;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 2;
                  s_awaddr_i == BASE_ADDR + DST_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 0;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 3;
                  s_awaddr_i == BASE_ADDR + TRANSFER_X_LEN_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  // s_wdata_i inside {[0:319]};
                  s_wdata_i == 10;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 4;
                  s_awaddr_i == BASE_ADDR + TRANSFER_Y_LEN_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  // s_wdata_i inside {[0:239]};
                  s_wdata_i == 5;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 5;
                  s_awaddr_i == BASE_ADDR + SRC_STRIDE_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 200;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 6;
                  s_awaddr_i == BASE_ADDR + DST_STRIDE_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 300;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 7;
                  s_awaddr_i == BASE_ADDR + ATX_ID_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 1;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 8;
                  s_awaddr_i == BASE_ADDR + ATX_SRC_BURST_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 1;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 9;
                  s_awaddr_i == BASE_ADDR + ATX_DST_BURST_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 1;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 10;
                  s_awaddr_i == BASE_ADDR + ATX_WD_PER_BURST_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  // s_wdata_i inside {[0:50]};   // SO LUONG DATA TRONG MOI BURST
                  s_wdata_i == 5;
                });

  //------------------------------ END CONFIG CHANNEL 1 ------------------------------
  //------------------------------ START CONFIG CHANNEL 2 ------------------------------
    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 11;
                  s_awaddr_i == BASE_ADDR + SRC_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 20;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 12;
                  s_awaddr_i == BASE_ADDR + DST_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 30;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 13;
                  s_awaddr_i == BASE_ADDR + TRANSFER_X_LEN_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i inside {[0:319]};
                  s_wdata_i == 10;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 14;
                  s_awaddr_i == BASE_ADDR + TRANSFER_Y_LEN_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i inside {[0:239]};
                  s_wdata_i == 2;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 15;
                  s_awaddr_i == BASE_ADDR + SRC_STRIDE_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 400;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 16;
                  s_awaddr_i == BASE_ADDR + DST_STRIDE_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 500;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 17;
                  s_awaddr_i == BASE_ADDR + ATX_ID_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 2;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 18;
                  s_awaddr_i == BASE_ADDR + ATX_SRC_BURST_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 1;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 19;
                  s_awaddr_i == BASE_ADDR + ATX_DST_BURST_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 1;
                });

    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 20;
                  s_awaddr_i == BASE_ADDR + ATX_WD_PER_BURST_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i inside {[0:50]};   // SO LUONG DATA TRONG MOI BURST
                  // s_wdata_i == 5;
                });
  //------------------------------ END CONFIG CHANNEL 2 ------------------------------
    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 21;
                  s_awaddr_i == BASE_ADDR + TRANSFER_SUBMIT_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 1;
                });
    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 22;
                  s_awaddr_i == BASE_ADDR + TRANSFER_SUBMIT_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 1;
                });
    // wait_response = 3;
    repeat (22) begin
      get_response(rsp);
      // cnt ++;
      // $display("Received response: %0d", cnt);
    end


  //------------------------------ END WRITE TO DESCRIPTOR ------------------------------



  //------------------------------ START WRITE TO TRANSACTION ------------------------------  
    // `uvm_do_with(req,
    //             {
    //               type_act == WRITE;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_awid_i == 5;
    //               s_awaddr_i == BASE_ADDR + ATX_ID_ADDR;
    //               s_awburst_i == 0; // FIXED
    //               s_awlen_i == 0; 
    //               s_wdata_i == 'h1;
    //             });

    // `uvm_do_with(req,
    //             {
    //               type_act == WRITE;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_awid_i == 6;
    //               s_awaddr_i == BASE_ADDR + ATX_SRC_BURST_ADDR;
    //               s_awburst_i == 0; // FIXED
    //               s_awlen_i == 0; 
    //               s_wdata_i == '0;
    //             });

    // `uvm_do_with(req,
    //             {
    //               type_act == WRITE;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_awid_i == 7;
    //               s_awaddr_i == BASE_ADDR + ATX_DST_BURST_ADDR;
    //               s_awburst_i == 0; // FIXED
    //               s_awlen_i == 'h0; 
    //               s_wdata_i == 'h0;
    //             });

    // `uvm_do_with(req,
    //             {
    //               type_act == WRITE;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_awid_i == 8;
    //               s_awaddr_i == BASE_ADDR + ATX_WD_PER_BURST_ADDR;
    //               s_awburst_i == 0; // FIXED
    //               s_awlen_i == 0; 
    //               s_wdata_i == 'h1;
    //             });

    // repeat (4) begin
    //   get_response(rsp);
    // end 


  //------------------------------ END WRITE TO AXI TRANSACTION ------------------------------




    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_arid_i == 1;
    //               s_araddr_i == BASE_ADDR + TRANSFER_ID_ADDR ;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });

    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_arid_i == 2;
    //               s_araddr_i == BASE_ADDR + ACTIVE_TRANSFER_ID_ADDR ;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });

    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_arid_i == 3;
    //               s_araddr_i == BASE_ADDR + ACTIVE_TRANSFER_LEN_ADDR ;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });

    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_arid_i == 4;
    //               s_araddr_i == BASE_ADDR + TRANSFER_DONE_ADDR ;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });

    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_arid_i == 10;
    //               s_araddr_i == BASE_ADDR + TRANSFER_SUBMIT_ADDR  ;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });
    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_arid_i == 11;
    //               s_araddr_i == BASE_ADDR + TRANSFER_DONE_ADDR ;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });

    // repeat (6) begin
    //   get_response(rsp);
    // end

    // `uvm_do_with(req,
    //             {
    //               type_act == WRITE;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_awid_i == 30;
    //               s_awaddr_i == BASE_ADDR + CHN_FLAGS_ADDR;
    //               s_awburst_i == 0; // FIXED
    //               s_awlen_i == 0; 
    //               s_wdata_i == 'h0;

    //             });  

    // get_response(rsp);
    // #100ns;
    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_arid_i == 31;
    //               s_araddr_i == BASE_ADDR + TRANSFER_DONE_ADDR ;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });
    // get_response(rsp);
    // `uvm_do_with(req,
    //             {
    //               type_act == READ;
    //               type_axi == SLV;
    //               chn_id == 0;
    //               s_arid_i == 25;
    //               s_araddr_i == BASE_ADDR + CHN_IRQ_SOURCE_ADDR ;
    //               s_arburst_i == 0; // FIXED
    //               s_arlen_i == 0; 
    //             });
    // get_response(rsp);


  endtask
	// virtual task post_body();
  //   wait_response = 2;
  //   repeat (2) begin
  //     get_response(rsp);
  //     cnt ++;
  //     $display("Received response: %0d", cnt);
  //   end
	// endtask
// virtual task post_body()
  // wait_response = 2;
  // repeat (2) begin
  //   get_response(rsp);
  //   cnt ++;
  //   $display("Received response: %0d", cnt);
  // end
// endtask

endclass






class stop_cyclic_0 extends uvm_sequence #(base_item);
  base_item req;
  `uvm_object_utils_begin(stop_cyclic_0)
    `uvm_field_object(req, UVM_ALL_ON)
  `uvm_object_utils_end

  parameter BASE_ADDR = 32'h8000_0000;
  parameter DMA_CONTROL_ADDR = 'h0000;
  parameter ATX_ID_ADDR = 'h0005;
  parameter ATX_SRC_BURST_ADDR = 'h0006; 
  parameter ATX_DST_BURST_ADDR = 'h0007; 
  parameter ATX_WD_PER_BURST_ADDR  = 'h0008; 
  parameter SRC_ADDR = 'h0009;
  parameter DST_ADDR = 'h000A;
  parameter TRANSFER_SUBMIT_ADDR = 'h1000;
  parameter TRANSFER_X_LEN_ADDR = 'h000B;
  parameter TRANSFER_Y_LEN_ADDR = 'h000C;
  parameter SRC_STRIDE_ADDR = 'h000D;
  parameter DST_STRIDE_ADDR = 'h000E;
  parameter TRANSFER_ID_ADDR = 'h2001;
  parameter TRANSFER_DONE_ADDR = 'h2002;
  parameter ACTIVE_TRANSFER_ID_ADDR = 'h2003;
  parameter ACTIVE_TRANSFER_LEN_ADDR = 'h2004;
  parameter CHN_CONTROL_ADDR = 'h0001;
  parameter CHN_FLAGS_ADDR = 'h0002;
  parameter CHN_IRQ_MASK_ADDR = 'h0003;
  parameter CHN_IRQ_SOURCE_ADDR = 'h2000;
  parameter CHN_ARBIT_RATE_ADDR = 'h0004;

  int wait_response = 0;
  int cnt = 0;

  function new(string name = "stop_cyclic_0");
    super.new(name);
  endfunction : new

  virtual task body();
    
    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 1;
                  s_awaddr_i == BASE_ADDR + CHN_FLAGS_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 0;

                });  
    get_response(rsp);
  endtask
endclass


class stop_cyclic_1 extends uvm_sequence #(base_item);
  base_item req;
  `uvm_object_utils_begin(stop_cyclic_1)
    `uvm_field_object(req, UVM_ALL_ON)
  `uvm_object_utils_end

  parameter BASE_ADDR = 32'h8000_0000;
  parameter DMA_CONTROL_ADDR = 'h0000;
  parameter ATX_ID_ADDR = 'h0005;
  parameter ATX_SRC_BURST_ADDR = 'h0006; 
  parameter ATX_DST_BURST_ADDR = 'h0007; 
  parameter ATX_WD_PER_BURST_ADDR  = 'h0008; 
  parameter SRC_ADDR = 'h0009;
  parameter DST_ADDR = 'h000A;
  parameter TRANSFER_SUBMIT_ADDR = 'h1000;
  parameter TRANSFER_X_LEN_ADDR = 'h000B;
  parameter TRANSFER_Y_LEN_ADDR = 'h000C;
  parameter SRC_STRIDE_ADDR = 'h000D;
  parameter DST_STRIDE_ADDR = 'h000E;
  parameter TRANSFER_ID_ADDR = 'h2001;
  parameter TRANSFER_DONE_ADDR = 'h2002;
  parameter ACTIVE_TRANSFER_ID_ADDR = 'h2003;
  parameter ACTIVE_TRANSFER_LEN_ADDR = 'h2004;
  parameter CHN_CONTROL_ADDR = 'h0001;
  parameter CHN_FLAGS_ADDR = 'h0002;
  parameter CHN_IRQ_MASK_ADDR = 'h0003;
  parameter CHN_IRQ_SOURCE_ADDR = 'h2000;
  parameter CHN_ARBIT_RATE_ADDR = 'h0004;

  int wait_response = 0;
  int cnt = 0;

  function new(string name = "stop_cyclic_1");
    super.new(name);
  endfunction : new

  virtual task body();
    
    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 1;
                  s_awid_i == 2;
                  s_awaddr_i == BASE_ADDR + CHN_FLAGS_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 0; 
                  s_wdata_i == 0;

                });  
    get_response(rsp);  
  endtask
endclass