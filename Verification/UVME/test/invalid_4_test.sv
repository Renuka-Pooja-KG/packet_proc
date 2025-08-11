//=============================================================================
// File: invalid_4_test.sv
// Description: Test for invalid_4 condition (count_w < (packet_length_w - 1)) && (packet_length_w != 0) && (in_eop)
// Author: Assistant
// Date: 2024
//=============================================================================

`ifndef INVALID_4_TEST_SV
`define INVALID_4_TEST_SV

class invalid_4_test extends base_test;
    `uvm_component_utils(invalid_4_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Starting invalid_4 test - Testing count_w < (packet_length_w - 1) && (packet_length_w != 0) && (in_eop) condition", UVM_LOW)
        
        // Run the invalid_4 scenario
        seq.invalid_4_scenario();
        
        // Wait for all transactions to complete
        phase.drop_objection(this);
        
        `uvm_info(get_type_name(), "Invalid_4 test completed", UVM_LOW)
    endtask

endclass

`endif // INVALID_4_TEST_SV 