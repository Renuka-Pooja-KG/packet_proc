//=============================================================================
// File: invalid_1_test.sv
// Description: Test for invalid_1 condition (in_sop && in_eop)
// Author: Assistant
// Date: 2024
//=============================================================================

// Packet Write Test for Packet Processor
// Tests packet writing operations with proper reset initialization

class invalid_1_test extends uvm_test;
  `uvm_component_utils(invalid_1_test)

  pkt_proc_env m_env;
  pkt_proc_base_sequence seq;

  function new(string name = "invalid_1_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = pkt_proc_env::type_id::create("m_env", this);
    seq = pkt_proc_base_sequence::type_id::create("seq");
    `uvm_info(get_type_name(), "Invalid 1 test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Configure sequence for invalid 1 scenario (scenario = 15)
    seq.scenario = 15;  // Invalid 1 scenario    
    `uvm_info(get_type_name(), $sformatf("Starting invalid 1 test with scenario %0d", seq.scenario), UVM_LOW)
    
    // Start the sequence
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    `uvm_info(get_type_name(), "Invalid 1 test run_phase completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass
