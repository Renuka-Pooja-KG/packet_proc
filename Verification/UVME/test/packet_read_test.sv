// Packet Read Test for Packet Processor
// Tests packet read operations with proper write-then-read sequence
// No garbage enq_req signals - clean read operations after writes

class packet_read_test extends uvm_test;
  `uvm_component_utils(packet_read_test)

  pkt_proc_env m_env;
  pkt_proc_base_sequence seq;

  function new(string name = "packet_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = pkt_proc_env::type_id::create("m_env", this);
    seq = pkt_proc_base_sequence::type_id::create("seq");
    `uvm_info(get_type_name(), "Packet read test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting packet read test suite", UVM_LOW)
    
    // Test 1: Write packets first (clean write operations)
    `uvm_info(get_type_name(), "Test 1: Write packets for reading", UVM_LOW)
    seq.scenario = 5;  // Packet write scenario
    seq.num_transactions = 20;  // Reduced from 40 to avoid buffer overflow
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Add idle cycles to ensure writes complete
    seq.send_idle_transaction(5);
    
    // Test 2: Clean read operations (no random enq_req)
    `uvm_info(get_type_name(), "Test 2: Clean read operations", UVM_LOW)
    seq.scenario = 3;  // Read-only scenario
    seq.num_transactions = 20;  // Reduced from 50
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 3: Write more packets for additional read testing
    `uvm_info(get_type_name(), "Test 3: Write more packets for extended read testing", UVM_LOW)
    seq.scenario = 5;  // Packet write scenario
    seq.num_transactions = 15;  // Smaller batch
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Add idle cycles to ensure writes complete
    seq.send_idle_transaction(5);
    
    // Test 4: Extended read operations
    `uvm_info(get_type_name(), "Test 4: Extended read operations", UVM_LOW)
    seq.scenario = 3;  // Read-only scenario
    seq.num_transactions = 20;
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);

    `uvm_info(get_type_name(), "Test 5: Almost full toggle scenario", UVM_LOW)
    seq.scenario = 19;  // Almost full toggle scenario
    // seq.num_transactions = 10;
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);

    `uvm_info(get_type_name(), "Test 6: Almost empty toggle scenario", UVM_LOW)
    seq.scenario = 20;  // Almost empty toggle scenario
    // seq.num_transactions = 10;
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);

    `uvm_info(get_type_name(), "Starting pck_len_coverage_scenario", UVM_LOW)
    seq.scenario = 21;
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);

  
    
    // // Test 5: Underflow scenario (read when buffer is empty)
    // `uvm_info(get_type_name(), "Test 5: Underflow scenario (read from empty buffer)", UVM_LOW)
    // seq.scenario = 3;  // Read-only scenario - will cause underflow
    // seq.num_transactions = 10;  // Small number to test underflow
    // seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // // Test 6: Final write-then-read cycle
    // `uvm_info(get_type_name(), "Test 6: Final write-then-read cycle", UVM_LOW)
    // // Write one packet
    // seq.scenario = 5;  // Packet write scenario
    // seq.num_transactions = 1;  // Just one packet
    // seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // // Add idle cycles
    // send_idle_cycles(3);
    
    // // Read the packet
    // seq.scenario = 3;  // Read-only scenario
    // seq.num_transactions = 1;  // Just one read
    // seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Final idle cycles to clean up
    //seq.send_idle_transaction(5);
    
    `uvm_info(get_type_name(), "Packet read test suite completed", UVM_LOW)
    phase.drop_objection(this);
  endtask



endclass
