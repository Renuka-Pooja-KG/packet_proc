// Basic test for Packet Processor
// Tests basic write and read operations with proper reset initialization

class base_test extends uvm_test;
  `uvm_component_utils(base_test)

  pkt_proc_env m_env;
  pkt_proc_base_sequence seq;

  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = pkt_proc_env::type_id::create("m_env", this);
    seq = pkt_proc_base_sequence::type_id::create("seq");
    `uvm_info(get_type_name(), "Base test build_phase completed", UVM_LOW)
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
    `uvm_info(get_type_name(), "Base test end_of_elaboration_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Configure sequence for random scenario (scenario = 0)
    seq.scenario = 0;  // Random scenario
    seq.num_transactions = 20;
    
    `uvm_info(get_type_name(), $sformatf("Starting base test with scenario %0d", seq.scenario), UVM_LOW)
    
    // Start the sequence
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    `uvm_info(get_type_name(), "Base test run_phase completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass