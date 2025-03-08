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

  function new(string name = "init_read_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    // repeat (10) begin
      // CONFIG ENABLE DMA
    `uvm_do_with(req,
                {
                  type_act == WRITE;
                  type_axi == SLV;
                  chn_id == 0;
                  s_awid_i == 1;
                  s_awaddr_i == BASE_ADDR + DMA_CONTROL_ADDR;
                  s_awburst_i == 0; // FIXED
                  s_awlen_i == 2; 
                  s_wdata_i == 'h1;
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
                  s_wdata_i == 'h1;

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
                  s_wdata_i == 'h2;

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
                  s_wdata_i == 'h0;

                });  
    // end

    repeat (4) begin
      get_response(rsp);
    end
  endtask

endclass
