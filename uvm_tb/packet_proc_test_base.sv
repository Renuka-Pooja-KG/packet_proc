class packet_proc_test_base extends uvm_test;
  packet_proc_env env;

  `uvm_component_utils(packet_proc_test_base)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = packet_proc_env::type_id::create("env", this);
  endfunction
endclass 