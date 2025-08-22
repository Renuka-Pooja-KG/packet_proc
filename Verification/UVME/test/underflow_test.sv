// Packet Write Test for Packet Processor
// Tests packet writing operations with proper reset initialization

class underflow_test extends uvm_test;
  `uvm_component_utils(underflow_test)

  pkt_proc_env m_env;
  pkt_proc_base_sequence seq;

  function new(string name = "underflow_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = pkt_proc_env::type_id::create("m_env", this);
    seq = pkt_proc_base_sequence::type_id::create("seq");
    `uvm_info(get_type_name(), "Underflow test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Configure sequence for underflow scenario (scenario = 9)
    seq.scenario = 9;  // Underflow scenario
    
    `uvm_info(get_type_name(), $sformatf("Starting underflow test with scenario %0d", seq.scenario), UVM_LOW)
    
    // Start the sequence
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);

    // `uvm_info(get_type_name(), "Starting pck_len_coverage_scenario", UVM_LOW)
    // seq.scenario = 21;
    // seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);

    `uvm_info(get_type_name(), "Underflow test run_phase completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass