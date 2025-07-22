class packet_proc_sequence_base extends uvm_sequence #(packet_proc_transaction);
  `uvm_object_utils(packet_proc_sequence_base)
  function new(string name = "packet_proc_sequence_base");
    super.new(name);
  endfunction
endclass 