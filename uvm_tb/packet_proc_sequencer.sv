class packet_proc_sequencer extends uvm_sequencer #(packet_proc_transaction);
  `uvm_component_utils(packet_proc_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass 