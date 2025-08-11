//=============================================================================
// File: invalid_1_test.sv
// Description: Test for invalid_1 condition (in_sop && in_eop)
// Author: Assistant
// Date: 2024
//=============================================================================

`ifndef INVALID_1_TEST_SV
`define INVALID_1_TEST_SV

class invalid_1_test extends base_test;
    `uvm_component_utils(invalid_1_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Starting invalid_1 test - Testing in_sop && in_eop condition", UVM_LOW)
        
        // Run the invalid_1 scenario
        seq.invalid_1_scenario();
        
        // Wait for all transactions to complete
        phase.drop_objection(this);
        
        `uvm_info(get_type_name(), "Invalid_1 test completed", UVM_LOW)
    endtask

endclass

`endif // INVALID_1_TEST_SV 