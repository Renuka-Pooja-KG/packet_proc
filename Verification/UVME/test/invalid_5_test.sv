//=============================================================================
// File: invalid_5_test.sv
// Description: Test for invalid_5 condition ((count_w == (packet_length_w - 1)) || (packet_length_w == 0)) && (~in_eop) && (write_state == WRITE_DATA)
// Author: Assistant
// Date: 2024
//=============================================================================

`ifndef INVALID_5_TEST_SV
`define INVALID_5_TEST_SV

class invalid_5_test extends uvm_test;
  `uvm_component_utils(invalid_5_test)

  pkt_proc_env m_env;
  pkt_proc_base_sequence seq;

  function new(string name = "invalid_5_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = pkt_proc_env::type_id::create("m_env", this);
    seq = pkt_proc_base_sequence::type_id::create("seq");
    `uvm_info(get_type_name(), "Invalid 5 test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Configure sequence for invalid 1 scenario (scenario = 15)
    seq.invalid_5_scenario();  // Invalid 5 scenario    
    `uvm_info(get_type_name(), $sformatf("Starting invalid 5 test with scenario %0d", seq.scenario), UVM_LOW)
    
    // Start the sequence
    seq.start(m_env.m_pkt_proc_agent.m_pkt_proc_sequencer);
    
    `uvm_info(get_type_name(), "Invalid 5 test run_phase completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // INVALID_5_TEST_SV 