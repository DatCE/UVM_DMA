class base_mem extends uvm_component;
    `uvm_component_utils(base_mem)
    parameter MEM_SIZE = 320 * 240;
    static bit [31:0] mem [MEM_SIZE];

    function new(string name = "base_mem", uvm_component parent = null);
      super.new(name, parent);
      foreach(mem[i]) begin
        mem[i] = i;
      end
    endfunction

    function void mem_init();
        foreach(mem[i]) begin
          mem[i] = i;
        end
    endfunction

    function void mem_print();
      foreach(mem[i]) begin
        `uvm_info(get_type_name(), $sformatf("mem %h:%h, ", i, mem[i]), UVM_LOW)
      end
    endfunction

    function int read(bit [31:0] addr);
      return mem[addr];
    endfunction
  endclass