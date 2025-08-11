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
    `uvm_info(get_type_name(), "Test 2: Reset during packet scenario", UVM_LOW)
    seq.scenario = 13;  // Reset during packet scenario
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);

    // Test 2: Reset during read scenario
    `uvm_info(get_type_name(), "Test 2: Reset during read scenario", UVM_LOW)
    seq.scenario = 14;  // Reset during read scenario
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    
    
    `uvm_info(get_type_name(), "Simple reset test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass