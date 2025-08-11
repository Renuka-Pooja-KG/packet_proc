//=============================================================================
// File: invalid_3_test.sv
// Description: Test for invalid_3 condition (in_sop && (~in_eop_r1) && (write_state == WRITE_DATA))
// Author: Assistant
// Date: 2024
//=============================================================================

`ifndef INVALID_3_TEST_SV
`define INVALID_3_TEST_SV

class invalid_3_test extends base_test;
    `uvm_component_utils(invalid_3_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Starting invalid_3 test - Testing in_sop && (~in_eop_r1) && (write_state == WRITE_DATA) condition", UVM_LOW)
        `uvm_info(get_type_name(), "This tests starting a new packet while already processing another packet", UVM_LOW)
        
        // Run the invalid_3 scenario
        seq.invalid_3_scenario();
        
        // Wait for all transactions to complete
        phase.drop_objection(this);
        
        `uvm_info(get_type_name(), "Invalid_3 test completed", UVM_LOW)
    endtask

endclass

`endif // INVALID_3_TEST_SV 