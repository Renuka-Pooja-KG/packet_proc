// Reset Test for Packet Processor
// Tests various reset scenarios with write/read operations

class reset_test extends uvm_test;
  `uvm_component_utils(reset_test)

  pkt_proc_env m_env;
  pkt_proc_base_sequence seq;

  function new(string name = "reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = pkt_proc_env::type_id::create("m_env", this);
    seq = pkt_proc_base_sequence::type_id::create("seq");
    `uvm_info(get_type_name(), "Reset test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting reset test suite", UVM_LOW)
    
    // Test 1: Basic reset scenario
    `uvm_info(get_type_name(), "Test 1: Basic reset scenario", UVM_LOW)
    seq.scenario = 1;  // Reset scenario
    seq.num_transactions = 20;
    seq.start(m_env.pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 2: Async reset scenario
    `uvm_info(get_type_name(), "Test 2: Async reset scenario", UVM_LOW)
    seq.scenario = 10;  // Async reset scenario
    seq.num_transactions = 25;
    seq.start(m_env.pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 3: Sync reset scenario
    `uvm_info(get_type_name(), "Test 3: Sync reset scenario", UVM_LOW)
    seq.scenario = 11;  // Sync reset scenario
    seq.num_transactions = 25;
    seq.start(m_env.pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 4: Dual reset scenario
    `uvm_info(get_type_name(), "Test 4: Dual reset scenario", UVM_LOW)
    seq.scenario = 12;  // Dual reset scenario
    seq.num_transactions = 30;
    seq.start(m_env.pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 5: Reset during packet scenario
    `uvm_info(get_type_name(), "Test 5: Reset during packet scenario", UVM_LOW)
    seq.scenario = 13;  // Reset during packet scenario
    seq.num_transactions = 35;
    seq.start(m_env.pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 6: Reset during read scenario
    `uvm_info(get_type_name(), "Test 6: Reset during read scenario", UVM_LOW)
    seq.scenario = 14;  // Reset during read scenario
    seq.num_transactions = 30;
    seq.start(m_env.pkt_proc_agent.m_pkt_proc_sequencer);
    
    `uvm_info(get_type_name(), "Reset test suite completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass