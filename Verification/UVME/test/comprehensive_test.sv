// Comprehensive Test for Packet Processor
// Tests all major functionality with proper reset initialization

class comprehensive_test extends uvm_test;
  `uvm_component_utils(comprehensive_test)

  env m_env;
  pkt_proc_base_sequence seq;

  function new(string name = "comprehensive_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = env::type_id::create("m_env", this);
    seq = pkt_proc_base_sequence::type_id::create("seq");
    `uvm_info(get_type_name(), "Comprehensive test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting comprehensive test suite", UVM_LOW)
    
    // Test 1: Random scenario
    `uvm_info(get_type_name(), "Test 1: Random scenario", UVM_LOW)
    seq.scenario = 0;  // Random scenario
    seq.num_transactions = 30;
    seq.start(m_env.m_agent.m_sequencer);
    
    // Test 2: Write-only scenario
    `uvm_info(get_type_name(), "Test 2: Write-only scenario", UVM_LOW)
    seq.scenario = 2;  // Write-only scenario
    seq.num_transactions = 25;
    seq.start(m_env.m_agent.m_sequencer);
    
    // Test 3: Read-only scenario
    `uvm_info(get_type_name(), "Test 3: Read-only scenario", UVM_LOW)
    seq.scenario = 3;  // Read-only scenario
    seq.num_transactions = 25;
    seq.start(m_env.m_agent.m_sequencer);
    
    // Test 4: Concurrent R/W scenario
    `uvm_info(get_type_name(), "Test 4: Concurrent R/W scenario", UVM_LOW)
    seq.scenario = 4;  // Concurrent R/W scenario
    seq.num_transactions = 40;
    seq.start(m_env.m_agent.m_sequencer);
    
    // Test 5: Packet write scenario
    `uvm_info(get_type_name(), "Test 5: Packet write scenario", UVM_LOW)
    seq.scenario = 5;  // Packet write scenario
    seq.num_transactions = 50;
    seq.start(m_env.m_agent.m_sequencer);
    
    // Test 6: Overflow scenario
    `uvm_info(get_type_name(), "Test 6: Overflow scenario", UVM_LOW)
    seq.scenario = 8;  // Overflow scenario
    seq.num_transactions = 100;
    seq.start(m_env.m_agent.m_sequencer);
    
    // Test 7: Async reset scenario
    `uvm_info(get_type_name(), "Test 7: Async reset scenario", UVM_LOW)
    seq.scenario = 10;  // Async reset scenario
    seq.num_transactions = 20;
    seq.start(m_env.m_agent.m_sequencer);
    
    // Test 8: Reset during packet scenario
    `uvm_info(get_type_name(), "Test 8: Reset during packet scenario", UVM_LOW)
    seq.scenario = 13;  // Reset during packet scenario
    seq.num_transactions = 30;
    seq.start(m_env.m_agent.m_sequencer);
    
    `uvm_info(get_type_name(), "Comprehensive test suite completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass