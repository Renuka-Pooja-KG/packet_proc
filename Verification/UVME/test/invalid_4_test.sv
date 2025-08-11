//=============================================================================
// File: invalid_4_test.sv
// Description: Test for invalid_4 condition (count_w < (packet_length_w - 1)) && (packet_length_w != 0) && (in_eop)
// Author: Assistant
// Date: 2024
//=============================================================================

class invalid_4_test extends uvm_test;
  `uvm_component_utils(invalid_4_test)

  pkt_proc_env m_env;
  pkt_proc_base_sequence seq;

  function new(string name = "invalid_4_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = pkt_proc_env::type_id::create("m_env", this);
    seq = pkt_proc_base_sequence::type_id::create("seq");
    `uvm_info(get_type_name(), "Invalid 4 test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Configure sequence for invalid 1 scenario (scenario = 15)
    seq.scenario = 17;  // Invalid 4 scenario    
    `uvm_info(get_type_name(), $sformatf("Starting invalid 4 test with scenario %0d", seq.scenario), UVM_LOW)
    
    // Start the sequence
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    `uvm_info(get_type_name(), "Invalid 4 test run_phase completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass