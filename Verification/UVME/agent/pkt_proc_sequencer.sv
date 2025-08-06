class pkt_proc_sequencer extends uvm_sequencer #(pkt_proc_seq_item);
  `uvm_component_utils(pkt_proc_sequencer)

  function new(string name = "pkt_proc_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass 