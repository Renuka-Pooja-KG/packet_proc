// Concurrent Test for Packet Processor
// Tests concurrent read/write operations

class concurrent_test extends uvm_test;
  `uvm_component_utils(concurrent_test)

  env m_env;
  pkt_proc_base_sequence seq;

  function new(string name = "concurrent_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = env::type_id::create("m_env", this);
    seq = pkt_proc_base_sequence::type_id::create("seq");
    `uvm_info(get_type_name(), "Concurrent test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting concurrent operations test suite", UVM_LOW)
    
    // Test 1: Concurrent R/W scenario - Light load
    `uvm_info(get_type_name(), "Test 1: Concurrent R/W - Light load", UVM_LOW)
    seq.scenario = 4;  // Concurrent R/W scenario
    seq.num_transactions = 30;
    seq.start(m_env.m_agent.m_sequencer);
    
    // Test 2: Concurrent R/W scenario - Medium load
    `uvm_info(get_type_name(), "Test 2: Concurrent R/W - Medium load", UVM_LOW)
    seq.scenario = 4;  // Concurrent R/W scenario
    seq.num_transactions = 60;
    seq.start(m_env.m_agent.m_sequencer);
    
    // Test 3: Concurrent R/W scenario - Heavy load
    `uvm_info(get_type_name(), "Test 3: Concurrent R/W - Heavy load", UVM_LOW)
    seq.scenario = 4;  // Concurrent R/W scenario
    seq.num_transactions = 100;
    seq.start(m_env.m_agent.m_sequencer);
    
    // Test 4: Mixed operations with concurrent access
    `uvm_info(get_type_name(), "Test 4: Mixed operations", UVM_LOW)
    seq.scenario = 7;  // Mixed ops scenario
    seq.num_transactions = 80;
    seq.start(m_env.m_agent.m_sequencer);
    
    // Test 5: Continuous read with concurrent write
    `uvm_info(get_type_name(), "Test 5: Continuous read scenario", UVM_LOW)
    seq.scenario = 6;  // Continuous read scenario
    seq.num_transactions = 70;
    seq.start(m_env.m_agent.m_sequencer);
    
    `uvm_info(get_type_name(), "Concurrent operations test suite completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass