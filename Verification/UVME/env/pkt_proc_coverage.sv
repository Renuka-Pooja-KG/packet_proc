//=============================================================================
// Simple Packet Processor Coverage Class
//=============================================================================
// This file contains essential coverage for the packet processor design
// covering basic operations, buffer states, and error conditions
//=============================================================================


class pkt_proc_coverage extends uvm_component;
    `uvm_component_utils(pkt_proc_coverage)

    // Analysis port to receive transactions
    uvm_analysis_imp #(pkt_proc_seq_item, pkt_proc_coverage) cov_export;

    // Main coverage group
    covergroup pkt_proc_cg with function sample(
        bit enq_req, bit deq_req, bit in_sop, bit in_eop,
        bit pck_proc_full, bit pck_proc_empty,
        bit pck_proc_overflow, bit pck_proc_underflow, bit packet_drop,
        bit pck_proc_int_mem_fsm_rstn, bit pck_proc_int_mem_fsm_sw_rstn,
        bit [11:0] pck_len_i
    );

        // Basic operation coverage
        basic_ops: coverpoint {enq_req, deq_req} {
            bins idle = {2'b00};
            bins write_only = {2'b10};
            bins read_only = {2'b01};
            bins concurrent = {2'b11};
        }

        // Packet protocol coverage
        packet_protocol: coverpoint {in_sop, in_eop} {
            bins no_packet = {2'b00};
            bins start_packet = {2'b10};
            bins end_packet = {2'b01};
            bins single_word_packet = {2'b11};
        }

        // Buffer status coverage
        buffer_status: coverpoint {pck_proc_full, pck_proc_empty} {
            bins empty = {2'b01};
            bins normal = {2'b00};
            bins full = {2'b10};
            bins full_and_empty = {2'b11};  // Should not occur
        }

        // Error condition coverage
        error_conditions: coverpoint {pck_proc_overflow, pck_proc_underflow, packet_drop} {
            bins no_error = {3'b000};
            bins overflow = {3'b100};
            bins underflow = {3'b010};
            bins packet_drop = {3'b001};
            bins overflow_and_drop = {3'b101};
        }

        // Reset coverage
        reset_conditions: coverpoint {pck_proc_int_mem_fsm_rstn, pck_proc_int_mem_fsm_sw_rstn} {
            bins no_reset = {2'b11};
            bins async_reset = {2'b01};
            bins sync_reset = {2'b10};
            bins both_reset = {2'b00};
        }

        // Packet length coverage
        packet_length: coverpoint pck_len_i {
            bins small_packets = {[1:10]};
            bins medium_packets = {[11:100]};
            bins large_packets = {[101:1000]};
            bins very_large_packets = {[1001:4095]};
        }

        // Cross coverage for critical scenarios
        write_during_full: cross basic_ops, buffer_status {
            bins write_to_full = binsof(basic_ops.write_only) && binsof(buffer_status.full);
        }

        read_during_empty: cross basic_ops, buffer_status {
            bins read_from_empty = binsof(basic_ops.read_only) && binsof(buffer_status.empty);
        }

        concurrent_ops: cross basic_ops, buffer_status {
            bins concurrent_normal = binsof(basic_ops.concurrent) && binsof(buffer_status.normal);
        }

        reset_during_ops: cross basic_ops, reset_conditions {
            bins reset_during_write = binsof(basic_ops.write_only) && binsof(reset_conditions.async_reset);
            bins reset_during_read = binsof(basic_ops.read_only) && binsof(reset_conditions.sync_reset);
        }

    endgroup

    // Constructor
    function new(string name = "pkt_proc_coverage", uvm_component parent = null);
        super.new(name, parent);
        cov_export = new("cov_export", this);
        pkt_proc_cg = new();
    endfunction

    // Write function for analysis port
    function void write(pkt_proc_seq_item tr);
        // Sample coverage
        pkt_proc_cg.sample(
            tr.enq_req, tr.deq_req, tr.in_sop, tr.in_eop,
            tr.pck_proc_full, tr.pck_proc_empty,
            tr.pck_proc_overflow, tr.pck_proc_underflow, tr.packet_drop,
            tr.pck_proc_int_mem_fsm_rstn, tr.pck_proc_int_mem_fsm_sw_rstn,
            tr.pck_len_i
        );
    endfunction

    // Report coverage
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("COVERAGE", "Coverage Report:", UVM_LOW)
        `uvm_info("COVERAGE", $sformatf("Coverage: %0.2f%%", pkt_proc_cg.get_coverage()), UVM_LOW)
        
        // Check coverage goal
        if (pkt_proc_cg.get_coverage() < 85.0) begin
            `uvm_warning("COVERAGE", $sformatf("Coverage goal not met: %0.2f%% < 85%%", pkt_proc_cg.get_coverage()))
        end else begin
            `uvm_info("COVERAGE", "Coverage goal met!", UVM_LOW)
        end
    endfunction

endclass

