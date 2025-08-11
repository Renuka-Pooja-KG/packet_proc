//=============================================================================
// File: invalid_5_test.sv
// Description: Test for invalid_5 condition ((count_w == (packet_length_w - 1)) || (packet_length_w == 0)) && (~in_eop) && (write_state == WRITE_DATA)
// Author: Assistant
// Date: 2024
//=============================================================================

`ifndef INVALID_5_TEST_SV
`define INVALID_5_TEST_SV

class invalid_5_test extends base_test;
    `uvm_component_utils(invalid_5_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Starting invalid_5 test - Testing count_w == (packet_length_w - 1) && (~in_eop) && (write_state == WRITE_DATA) condition", UVM_LOW)
        `uvm_info(get_type_name(), "This tests when count_w reaches packet length limit but in_eop is not asserted", UVM_LOW)
        
        // Run the invalid_5 scenario
        seq.invalid_5_scenario();
        
        // Wait for all transactions to complete
        phase.drop_objection(this);
        
        `uvm_info(get_type_name(), "Invalid_5 test completed", UVM_LOW)
    endtask

endclass

`endif // INVALID_5_TEST_SV 