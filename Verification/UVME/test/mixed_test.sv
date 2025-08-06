// Mixed Test for Packet Processor
// Tests mixed operations scenarios

class mixed_test extends uvm_test;
  `uvm_component_utils(mixed_test)

  pkt_proc_env m_env;
  pkt_proc_base_sequence seq;

  function new(string name = "mixed_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = pkt_proc_env::type_id::create("m_env", this);
    seq = pkt_proc_base_sequence::type_id::create("seq");
    `uvm_info(get_type_name(), "Mixed test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting mixed operations test suite", UVM_LOW)
    
    // Test 1: Mixed operations scenario
    `uvm_info(get_type_name(), "Test 1: Mixed operations scenario", UVM_LOW)
    seq.scenario = 7;  // Mixed ops scenario
    seq.num_transactions = 60;
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 2: Concurrent R/W scenario
    `uvm_info(get_type_name(), "Test 2: Concurrent R/W scenario", UVM_LOW)
    seq.scenario = 4;  // Concurrent R/W scenario
    seq.num_transactions = 50;
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 3: Random scenario
    `uvm_info(get_type_name(), "Test 3: Random scenario", UVM_LOW)
    seq.scenario = 0;  // Random scenario
    seq.num_transactions = 40;
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 4: Overflow scenario
    `uvm_info(get_type_name(), "Test 4: Overflow scenario", UVM_LOW)
    seq.scenario = 8;  // Overflow scenario
    seq.num_transactions = 80;
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 5: Underflow scenario
    `uvm_info(get_type_name(), "Test 5: Underflow scenario", UVM_LOW)
    seq.scenario = 9;  // Underflow scenario
    seq.num_transactions = 80;
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    `uvm_info(get_type_name(), "Mixed operations test suite completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass