// Reset Test for Packet Processor
// Simple test: Write packets, read them, then apply reset

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
    
    `uvm_info(get_type_name(), "Starting simple reset test", UVM_LOW)
    
    // Test 1: Write packets first (build up write level)
    `uvm_info(get_type_name(), "Test 1: Write packets to build write level", UVM_LOW)
    seq.scenario = 5;  // Packet write scenario
    seq.num_transactions = 15;  // Write 15 packets
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Add idle cycles to ensure writes complete
    seq.send_idle_transaction(5);
    
    // Test 2: Read packets (verify normal operation)
    `uvm_info(get_type_name(), "Test 2: Read packets to verify normal operation", UVM_LOW)
    seq.scenario = 3;  // Read-only scenario
    seq.num_transactions = 10;  // Read 10 packets
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Add idle cycles to ensure reads complete
    seq.send_idle_transaction(5);
    
    // Test 3: Apply async reset (verify reset behavior)
    `uvm_info(get_type_name(), "Test 3: Apply async reset", UVM_LOW)
    // seq.scenario = 10;  // Async reset scenario
    // seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    send_reset_transaction(1'b1, 1'b1, 5);  // async_rst=1, sync_rst=1 for clean start
    send_reset_transaction(1'b1, 1'b1, 3);  // Release sync reset
    
    // Add idle cycles after reset
    seq.send_idle_transaction(5);
    
    // Test 4: Write more packets after reset (verify reset recovery)
    `uvm_info(get_type_name(), "Test 4: Write packets after reset to verify recovery", UVM_LOW)
    seq.scenario = 5;  // Packet write scenario
    seq.num_transactions = 8;  // Write 8 packets
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Add idle cycles to ensure writes complete
    seq.send_idle_transaction(5);
    
    // Test 5: Read packets after reset (verify reset recovery)
    `uvm_info(get_type_name(), "Test 5: Read packets after reset to verify recovery", UVM_LOW)
    seq.scenario = 3;  // Read-only scenario
    seq.num_transactions = 8;  // Read 8 packets
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Final idle cycles to clean up
    seq.send_idle_transaction(5);
    
    `uvm_info(get_type_name(), "Simple reset test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass