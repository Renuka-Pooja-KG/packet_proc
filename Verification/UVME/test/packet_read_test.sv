// Packet Read Test for Packet Processor
// Tests packet read operations and continuous read scenarios

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
    
    // Test 1: Write some packets first
    `uvm_info(get_type_name(), "Test 1: Write packets for reading", UVM_LOW)
    seq.scenario = 5;  // Packet write scenario
    seq.num_transactions = 40;
    seq.start(m_env.pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 2: Read-only operations
    `uvm_info(get_type_name(), "Test 2: Read-only operations", UVM_LOW)
    seq.scenario = 3;  // Read-only scenario
    seq.num_transactions = 50;
    seq.start(m_env.pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 3: Continuous read operations
    `uvm_info(get_type_name(), "Test 3: Continuous read operations", UVM_LOW)
    seq.scenario = 6;  // Continuous read scenario
    seq.num_transactions = 60;
    seq.start(m_env.pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 4: Mixed read/write operations
    `uvm_info(get_type_name(), "Test 4: Mixed read/write operations", UVM_LOW)
    seq.scenario = 4;  // Concurrent R/W scenario
    seq.num_transactions = 70;
    seq.start(m_env.pkt_proc_agent.m_pkt_proc_sequencer);
    
    // Test 5: Underflow scenario (read when empty)
    `uvm_info(get_type_name(), "Test 5: Underflow scenario", UVM_LOW)
    seq.scenario = 9;  // Underflow scenario
    seq.num_transactions = 80;
    seq.start(m_env.pkt_proc_agent.m_pkt_proc_sequencer);
    
    `uvm_info(get_type_name(), "Packet read test suite completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass