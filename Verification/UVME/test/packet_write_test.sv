// Packet Write Test for Packet Processor
// Tests packet writing operations with proper reset initialization

class packet_write_test extends uvm_test;
  `uvm_component_utils(packet_write_test)

  pkt_proc_env m_env;
  pkt_proc_base_sequence seq;

  function new(string name = "packet_write_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = pkt_proc_env::type_id::create("m_env", this);
    seq = pkt_proc_base_sequence::type_id::create("seq");
    `uvm_info(get_type_name(), "Packet write test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Configure sequence for packet write scenario (scenario = 5)
    seq.scenario = 5;  // Packet write scenario
    seq.num_transactions = 50;  // More transactions for packet testing
    
    `uvm_info(get_type_name(), $sformatf("Starting packet write test with scenario %0d", seq.scenario), UVM_LOW)
    
    // Start the sequence
    seq.start(m_env.pkt_proc_agent.m_pkt_proc_sequencer);
    
    `uvm_info(get_type_name(), "Packet write test run_phase completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass