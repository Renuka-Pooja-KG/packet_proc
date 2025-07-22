class packet_proc_agent extends uvm_agent;
  packet_proc_driver driver;
  packet_proc_sequencer sequencer;
  packet_proc_monitor monitor;
  uvm_analysis_port #(packet_proc_transaction) ap;

  `uvm_component_utils(packet_proc_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
     ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
        driver = packet_proc_driver::type_id::create("driver", this);
        sequencer = packet_proc_sequencer::type_id::create("sequencer", this);
    end
    monitor = packet_proc_monitor::type_id::create("monitor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
        driver.seq_item_port.connect(sequencer.seq_item_export);
    end
    monitor.ap.connect(ap);
  endfunction
endclass 