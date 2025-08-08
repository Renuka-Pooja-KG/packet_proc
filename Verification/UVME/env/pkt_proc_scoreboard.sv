//=============================================================================
// File: pkt_proc_scoreboard_new.sv
// Description: New Simple Packet Processor UVM Scoreboard
// Author: Assistant
// Date: 2024
//=============================================================================

`ifndef PKT_PROC_SCOREBOARD_NEW_SV
`define PKT_PROC_SCOREBOARD_NEW_SV

class pkt_proc_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(pkt_proc_scoreboard)

    uvm_analysis_imp #(pkt_proc_seq_item, pkt_proc_scoreboard) analysis_export;

    // Configuration parameters (matching RTL)
    parameter int DEPTH = 16384;
    parameter int PCK_LEN_DEPTH = 32;
    parameter int DATA_WIDTH = 32;
    parameter int ADDR_WIDTH = 14;
    parameter int PCK_LEN = 12;

    // Reference model state machines (matching RTL)
    typedef enum {IDLE_W, WRITE_HEADER, WRITE_DATA, ERROR} write_state_e;
    typedef enum {IDLE_R, READ_HEADER, READ_DATA} read_state_e;
    
    write_state_e write_state;
    read_state_e read_state;
    
    // Reference model internal state
    bit [31:0] ref_buffer[0:16383];  // Main buffer
    bit [11:0] ref_pck_len_buffer[0:31];  // Packet length buffer
    bit [14:0] ref_wr_ptr, ref_rd_ptr;
    bit [14:0] ref_pck_len_wr_ptr, ref_pck_len_rd_ptr;
    bit [14:0] ref_wr_lvl;
    bit [11:0] ref_count_w, ref_count_r;
    bit [11:0] ref_packet_length;
    bit ref_buffer_full, ref_buffer_empty;
    bit ref_pck_len_full, ref_pck_len_empty;
    bit ref_pck_proc_overflow, ref_pck_proc_underflow;
    bit ref_packet_drop;
    
    // Expected outputs
    bit ref_out_sop, ref_out_eop;
    bit [31:0] ref_rd_data_o;
    bit ref_pck_proc_almost_full, ref_pck_proc_almost_empty;
    
    // Pipeline registers (matching RTL exactly)
    bit ref_in_sop_r, ref_in_sop_r1, ref_in_sop_r2;
    bit ref_in_eop_r, ref_in_eop_r1, ref_in_eop_r2;
    bit ref_enq_req_r, ref_enq_req_r1;
    bit [31:0] ref_wr_data_r, ref_wr_data_r1;
    bit ref_pck_len_valid_r, ref_pck_len_valid_r1;
    bit [11:0] ref_pck_len_i_r, ref_pck_len_i_r1;
    bit ref_deq_req_r;
    
    // Additional signals
    bit ref_empty_de_assert;
    bit ref_buffer_empty_r;
    bit ref_wr_en, ref_rd_en;
    
    // Write level tracking (matching RTL's always_ff behavior)
    bit [14:0] ref_wr_lvl_next;     // Next cycle's wr_lvl value
    bit ref_overflow;               // Internal overflow signal (matching int_buffer_top)
    
    // One-cycle delayed signals (matching RTL's always_ff outputs)
    bit ref_buffer_empty_delayed;   // One-cycle delayed buffer_empty
    
    // Temporary variables for combinational calculations
    bit temp_full, temp_empty;
    
    // Statistics
    int total_transactions = 0;
    int errors = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        initialize_reference_model();
    endfunction

    function void initialize_reference_model();
        // Initialize state machines
        write_state = IDLE_W;
        read_state = IDLE_R;
        
        // Initialize pointers and counters
        ref_wr_ptr = 0;
        ref_rd_ptr = 0;
        ref_pck_len_wr_ptr = 0;
        ref_pck_len_rd_ptr = 0;
        ref_wr_lvl = 0;
        ref_count_w = 0;
        ref_count_r = 0;
        ref_packet_length = 0;
        
        // Initialize buffer states
        ref_buffer_full = 0;
        ref_buffer_empty = 1;
        ref_pck_len_full = 0;
        ref_pck_len_empty = 1;
        
        // Initialize flags
        ref_pck_proc_overflow = 0;
        ref_pck_proc_underflow = 0;
        ref_packet_drop = 0;
        
        // Initialize outputs
        ref_out_sop = 0;
        ref_out_eop = 0;
        ref_rd_data_o = 0;
        ref_pck_proc_almost_full = 0;
        ref_pck_proc_almost_empty = 0;
        
        // Initialize pipeline registers
        ref_in_sop_r = 0; ref_in_sop_r1 = 0; ref_in_sop_r2 = 0;
        ref_in_eop_r = 0; ref_in_eop_r1 = 0; ref_in_eop_r2 = 0;
        ref_enq_req_r = 0; ref_enq_req_r1 = 0;
        ref_wr_data_r = 0; ref_wr_data_r1 = 0;
        ref_pck_len_valid_r = 0; ref_pck_len_valid_r1 = 0;
        ref_pck_len_i_r = 0; ref_pck_len_i_r1 = 0;
        ref_deq_req_r = 0;
        
        // Initialize additional signals
        ref_empty_de_assert = 1;
        ref_buffer_empty_r = 1;
        ref_wr_en = 0;
        ref_rd_en = 0;
        
        // Initialize write level tracking
        ref_wr_lvl_next = 0;
        ref_overflow = 0;
        
        // Initialize delayed signals
        ref_buffer_empty_delayed = 1;
        
        // Initialize temporary variables
        temp_full = 0;
        temp_empty = 0;
    endfunction

    function void write(pkt_proc_seq_item tr);
        total_transactions++;
        
        `uvm_info("SCOREBOARD_NEW", $sformatf("Processing transaction #%0d", total_transactions), UVM_LOW)
        
        // Update reference model
        update_reference_model(tr);
        
        // Compare outputs
        compare_outputs(tr);
    endfunction

    function void update_reference_model(pkt_proc_seq_item tr);
        // Apply one-cycle delay FIRST (use previous cycle's values for comparison)
        ref_buffer_empty_delayed = ref_buffer_empty;
        
        // Handle reset logic FIRST (matching RTL behavior)
        handle_reset_logic(tr);
        
        // Update pipeline registers (matching RTL exactly)
        update_pipeline_registers(tr);
        
        // Update write FSM
        update_write_fsm(tr);
        
        // Update read FSM
        update_read_fsm(tr);
        
        // Generate write/read enables FIRST (matching RTL order)
        generate_write_read_enables(tr);
        
        // Update write level based on current enables (matching RTL order)
        update_write_level_next();
        
        // Update internal overflow signal
        update_internal_overflow();
        
        // Update write level (current cycle becomes next cycle)
        ref_wr_lvl = ref_wr_lvl_next;
        
        // NOW perform buffer operations (after wr_lvl calculation)
        update_buffer_operations(tr);
        
        // Update buffer states based on the operations just performed
        update_buffer_states();
        
        // Update overflow/underflow detection
        update_overflow_underflow(tr);
        
        // Update outputs
        update_outputs(tr);
    endfunction

    function void handle_reset_logic(pkt_proc_seq_item tr);
        // Asynchronous active-low reset (highest priority)
        if (!tr.pck_proc_int_mem_fsm_rstn) begin
            // Reset all state machines and registers
            write_state = IDLE_W;
            read_state = IDLE_R;
            
            // Reset pointers and counters
            ref_wr_ptr = 0;
            ref_rd_ptr = 0;
            ref_pck_len_wr_ptr = 0;
            ref_pck_len_rd_ptr = 0;
            ref_wr_lvl = 0;
            ref_count_w = 0;
            ref_count_r = 0;
            ref_packet_length = 0;
            
            // Reset buffer states
            //ref_buffer_full = 0;
            //ref_buffer_empty = 1;
            ref_pck_len_full = 0;
            ref_pck_len_empty = 1;
            
            // Reset flags
            ref_pck_proc_overflow = 0;
            ref_pck_proc_underflow = 0;
            ref_packet_drop = 0;
            ref_overflow = 0;
            
            // Reset outputs
            ref_out_sop = 0;
            ref_out_eop = 0;
            ref_rd_data_o = 0;
            //ref_pck_proc_almost_full = 0;
            //ref_pck_proc_almost_empty = 0;
            
            // Reset pipeline registers
            ref_in_sop_r = 0; ref_in_sop_r1 = 0; ref_in_sop_r2 = 0;
            ref_in_eop_r = 0; ref_in_eop_r1 = 0; ref_in_eop_r2 = 0;
            ref_enq_req_r = 0; ref_enq_req_r1 = 0;
            ref_wr_data_r = 0; ref_wr_data_r1 = 0;
            ref_pck_len_valid_r = 0; ref_pck_len_valid_r1 = 0;
            ref_pck_len_i_r = 0; ref_pck_len_i_r1 = 0;
            ref_deq_req_r = 0;
            
            // Reset additional signals
            ref_empty_de_assert = 0;
            ref_buffer_empty_r = 1;
            ref_wr_en = 0;
            ref_rd_en = 0;
            ref_wr_lvl_next = 0;
            
            return; // Exit early - no further processing during reset
        end
        
        // Synchronous active-high software reset (second priority)
        if (tr.pck_proc_int_mem_fsm_sw_rstn) begin
            // Reset all state machines and registers
            write_state = IDLE_W;
            read_state = IDLE_R;
            
            // Reset pointers and counters
            ref_wr_ptr = 0;
            ref_rd_ptr = 0;
            ref_pck_len_wr_ptr = 0;
            ref_pck_len_rd_ptr = 0;
            ref_wr_lvl = 0;
            ref_count_w = 0;
            ref_count_r = 0;
            ref_packet_length = 0;
            
            // Reset buffer states
            //ref_buffer_full = 0;
            //ref_buffer_empty = 1;
            ref_pck_len_full = 0;
            ref_pck_len_empty = 1;
            
            // Reset flags
            ref_pck_proc_overflow = 0;
            ref_pck_proc_underflow = 0;
            ref_packet_drop = 0;
            ref_overflow = 0;
            
            // Reset outputs
            ref_out_sop = 0;
            ref_out_eop = 0;
            ref_rd_data_o = 0;
            //ref_pck_proc_almost_full = 0;
            //ref_pck_proc_almost_empty = 0;
            
            // Reset pipeline registers
            ref_in_sop_r = 0; ref_in_sop_r1 = 0; ref_in_sop_r2 = 0;
            ref_in_eop_r = 0; ref_in_eop_r1 = 0; ref_in_eop_r2 = 0;
            ref_enq_req_r = 0; ref_enq_req_r1 = 0;
            ref_wr_data_r = 0; ref_wr_data_r1 = 0;
            ref_pck_len_valid_r = 0; ref_pck_len_valid_r1 = 0;
            ref_pck_len_i_r = 0; ref_pck_len_i_r1 = 0;
            ref_deq_req_r = 0;
            
            // Reset additional signals
            ref_empty_de_assert = 0;
            ref_buffer_empty_r = 1;
            ref_wr_en = 0;
            ref_rd_en = 0;
            ref_wr_lvl_next = 0;
            
            return; // Exit early - no further processing during reset
        end
    endfunction

    function void update_pipeline_registers(pkt_proc_seq_item tr);
        // Pipeline registers (matching RTL exactly)
        ref_in_sop_r2 = ref_in_sop_r;
        ref_in_sop_r = ref_in_sop_r1;
        ref_in_sop_r1 = tr.in_sop;
        
        ref_in_eop_r2 = ref_in_eop_r;
        ref_in_eop_r = ref_in_eop_r1;
        ref_in_eop_r1 = tr.in_eop;
        
        ref_enq_req_r1 = ref_enq_req_r;
        ref_enq_req_r = tr.enq_req;
        
        ref_wr_data_r = ref_wr_data_r1;
        ref_wr_data_r1 = tr.wr_data_i;
        
        ref_pck_len_valid_r = ref_pck_len_valid_r1;
        ref_pck_len_valid_r1 = tr.pck_len_valid;
        
        ref_pck_len_i_r = ref_pck_len_i_r1;
        ref_pck_len_i_r1 = tr.pck_len_i;
        
        ref_deq_req_r = tr.deq_req;
        ref_empty_de_assert = tr.empty_de_assert;
    endfunction

    function void update_write_fsm(pkt_proc_seq_item tr);
        case (write_state)
            IDLE_W: begin
                if (ref_enq_req_r && ref_in_sop_r1) begin
                    write_state = WRITE_HEADER;
                end
            end
            
            WRITE_HEADER: begin
                if (ref_in_sop_r1) begin
                    write_state = WRITE_HEADER;  // Stay in header
                end else if (is_packet_invalid(tr)) begin
                    write_state = ERROR;
                end else begin
                    write_state = WRITE_DATA;
                end
            end
            
            WRITE_DATA: begin
                if (ref_in_sop_r1 && ref_enq_req_r) begin
                    write_state = WRITE_HEADER;  // New packet
                end else if (ref_in_eop_r1 && !ref_in_sop_r1 && !ref_enq_req_r) begin
                    write_state = IDLE_W;  // End of packet
                end else begin
                    write_state = WRITE_DATA;  // Continue data
                end
            end
            
            ERROR: begin
                write_state = IDLE_W;  // Return to idle
            end
        endcase
    endfunction

    function void update_read_fsm(pkt_proc_seq_item tr);
        case (read_state)
            IDLE_R: begin
                if (ref_deq_req_r && !ref_buffer_empty) begin
                    read_state = READ_HEADER;
                end
            end
            
            READ_HEADER: begin
                read_state = READ_DATA;
            end
            
            READ_DATA: begin
                if (ref_buffer_empty) begin
                    read_state = IDLE_R;
                end else if ((ref_count_r == (ref_packet_length - 1)) && ref_deq_req_r) begin
                    read_state = READ_HEADER;  // Next packet
                end else if ((ref_count_r == (ref_packet_length - 1)) && !ref_deq_req_r) begin
                    read_state = IDLE_R;  // End of packet
                end else begin
                    read_state = READ_DATA;  // Continue reading
                end
            end
        endcase
    endfunction

    function bit is_packet_invalid(pkt_proc_seq_item tr);
        // Invalid packet conditions (matching RTL)
        if (tr.in_sop && tr.in_eop) return 1;  // SOP and EOP together
        if (ref_in_sop_r && ref_in_sop_r1) return 1;  // Back-to-back SOP
        if (tr.in_sop && (write_state == WRITE_DATA) && !ref_in_eop_r1) return 1;  // SOP during data
        if (ref_in_eop_r1 && (ref_count_w < ref_packet_length - 1) && (ref_packet_length != 0)) return 1;  // Early EOP
        if (!ref_in_eop_r1 && (ref_count_w == ref_packet_length - 1) && (write_state == WRITE_DATA)) return 1;  // Late EOP
        if (ref_pck_proc_overflow) return 1;  // Overflow condition
        if (tr.pck_len_valid && (tr.pck_len_i <= 1)) return 1;  // Invalid packet length
        return 0;
    endfunction

    function void generate_write_read_enables(pkt_proc_seq_item tr);
        // Determine write enable (matching RTL logic)
        ref_wr_en = 0;
        if (write_state == WRITE_HEADER && ref_enq_req_r && !ref_packet_drop) begin
            ref_wr_en = 1;
        end else if (write_state == WRITE_DATA && ref_enq_req_r && !ref_packet_drop) begin
            ref_wr_en = 1;
        end
        
        // Determine read enable (matching RTL logic)
        ref_rd_en = 0;
        if (read_state == READ_HEADER && ref_deq_req_r) begin
            ref_rd_en = 1;
        end else if (read_state == READ_DATA && ref_deq_req_r) begin
            ref_rd_en = 1;
        end
    endfunction

    function void update_buffer_operations(pkt_proc_seq_item tr);
        // Write/read enables are already calculated in generate_write_read_enables()
        // No need to recalculate them here
        
        // Write operations
        if (ref_wr_en && !ref_buffer_full) begin
            if (write_state == WRITE_HEADER) begin
                ref_buffer[ref_wr_ptr[13:0]] = ref_wr_data_r1;
                ref_pck_len_buffer[ref_pck_len_wr_ptr[4:0]] = 
                    (ref_pck_len_valid_r1) ? ref_pck_len_i_r1 : ref_wr_data_r1[11:0];
                ref_pck_len_wr_ptr = ref_pck_len_wr_ptr + 1;
            end else if (write_state == WRITE_DATA) begin
                ref_buffer[ref_wr_ptr[13:0]] = ref_wr_data_r1;
            end
            
            if (write_state == WRITE_HEADER || write_state == WRITE_DATA) begin
                ref_wr_ptr = ref_wr_ptr + 1;
                ref_count_w = ref_count_w + 1;
            end
        end
        
        // Read operations
        if (ref_rd_en && !ref_buffer_empty) begin
            ref_rd_data_o = ref_buffer[ref_rd_ptr[13:0]];
            ref_rd_ptr = ref_rd_ptr + 1;
            ref_count_r = ref_count_r + 1;
            
            if (read_state == READ_HEADER) begin
                ref_packet_length = ref_pck_len_buffer[ref_pck_len_rd_ptr[4:0]];
                ref_pck_len_rd_ptr = ref_pck_len_rd_ptr + 1;
                // DON'T reset counter here - it should be reset when out_eop is generated
            end
        end
        
        // Packet drop handling
        if (ref_packet_drop) begin
            if (ref_pck_proc_overflow) begin
                ref_wr_ptr = ref_wr_ptr - ref_count_w + 1;
            end else begin
                ref_wr_ptr = ref_wr_ptr - ref_count_w;
            end
            ref_count_w = 0;
            ref_packet_drop = 0;
        end
    endfunction

    function void update_buffer_states();
        // Buffer full condition (matching RTL)
        ref_buffer_full = (({~ref_wr_ptr[14], ref_wr_ptr[13:0]} == ref_rd_ptr));
        
        // Buffer empty condition (matching RTL)
        if ((ref_empty_de_assert == 0) && (ref_wr_ptr != ref_rd_ptr)) begin
            ref_buffer_empty = 0;
        end else if ((ref_in_eop_r2 && (ref_wr_ptr != ref_rd_ptr) && (ref_empty_de_assert == 1))) begin
            ref_buffer_empty = 0;
        end else if (ref_wr_ptr == ref_rd_ptr) begin
            ref_buffer_empty = 1;
        end else begin
            ref_buffer_empty = ref_buffer_empty_r;
        end
        
        // Update buffer_empty_r
        ref_buffer_empty_r = ref_buffer_empty;
        
        // Packet length buffer conditions
        ref_pck_len_full = (ref_pck_len_wr_ptr == ref_pck_len_rd_ptr) ? 0 :
                          (({~ref_pck_len_wr_ptr[5], ref_pck_len_wr_ptr[4:0]} == ref_pck_len_rd_ptr) ? 1 : 0);
        ref_pck_len_empty = (ref_pck_len_wr_ptr == ref_pck_len_rd_ptr) ? 1 : 0;
    endfunction

    function void update_write_level_next();
        // Write level logic (matching RTL's always_ff exactly)
        // Use current cycle's write/read enables (matching RTL order)
        if (ref_packet_drop) begin
            ref_wr_lvl_next = ref_wr_lvl - ref_count_w;
        end else if ((ref_wr_en && !ref_buffer_full) && (ref_rd_en && !ref_buffer_empty) && (!ref_overflow)) begin
            ref_wr_lvl_next = ref_wr_lvl;  // No change
        end else if (ref_wr_en && !ref_buffer_full) begin
            ref_wr_lvl_next = ref_wr_lvl + 1;
        end else if (ref_rd_en && !ref_buffer_empty) begin
            ref_wr_lvl_next = ref_wr_lvl - 1;
        end else begin
            ref_wr_lvl_next = ref_wr_lvl;  // No change
        end
    endfunction

    function void update_internal_overflow();
        // Internal overflow logic (matching int_buffer_top's always_ff)
        // Use previous cycle's buffer states for calculation
        if (ref_buffer_full && ref_wr_en) begin
            ref_overflow = 1;
        end else begin
            ref_overflow = 0;
        end
    endfunction

    function void update_overflow_underflow(pkt_proc_seq_item tr);
        // Overflow detection
        if (tr.enq_req && ref_buffer_full) begin
            ref_pck_proc_overflow = 1;
        end else begin
            ref_pck_proc_overflow = 0;
        end
        
        // Underflow detection
        if (tr.deq_req && ref_buffer_empty) begin
            ref_pck_proc_underflow = 1;
        end else begin
            ref_pck_proc_underflow = 0;
        end
        
        // Packet drop detection
        if (is_packet_invalid(tr)) begin
            ref_packet_drop = 1;
        end
    endfunction

    function void update_outputs(pkt_proc_seq_item tr);
        // Generate expected outputs
        ref_out_sop = 0;
        ref_out_eop = 0;
        
        if (read_state == READ_HEADER && ref_deq_req_r) begin
            ref_out_sop = 1;
        end else if (read_state == READ_DATA && ref_deq_req_r) begin
            if (ref_count_r == (ref_packet_length - 1)) begin
                ref_out_eop = 1;
                // Reset read counter when out_eop is generated (matching RTL)
                ref_count_r = 0;
            end
        end
        
        // Combinational output signals (matching RTL exactly)
        update_combinational_outputs(tr);
    endfunction

    function void update_combinational_outputs(pkt_proc_seq_item tr);
        // pck_proc_full (from buffer_full) - matching RTL assign
        ref_buffer_full = (({~ref_wr_ptr[14], ref_wr_ptr[13:0]} == ref_rd_ptr));
        
        // pck_proc_empty (from buffer_empty) - matching RTL assign
        if ((ref_empty_de_assert == 0) && (ref_wr_ptr != ref_rd_ptr)) begin
            ref_buffer_empty = 0;
        end else if ((ref_in_eop_r2 && (ref_wr_ptr != ref_rd_ptr) && (ref_empty_de_assert == 1))) begin
            ref_buffer_empty = 0;
        end else if (ref_wr_ptr == ref_rd_ptr) begin
            ref_buffer_empty = 1;
        end else begin
            ref_buffer_empty = ref_buffer_empty_r;
        end
        
        // pck_proc_almost_full (from almost_full) - matching RTL always_comb
        temp_full = (ref_wr_lvl >= DEPTH - tr.pck_proc_almost_full_value);
        if (temp_full) begin
            ref_pck_proc_almost_full = 1;
        end else begin
            ref_pck_proc_almost_full = 0;
        end
        
        // pck_proc_almost_empty (from almost_empty) - matching RTL always_comb
        temp_empty = (ref_wr_lvl <= tr.pck_proc_almost_empty_value);
        if (temp_empty) begin
            ref_pck_proc_almost_empty = 1;
        end else begin
            ref_pck_proc_almost_empty = 0;
        end
    endfunction

    function void compare_outputs(pkt_proc_seq_item tr);
        // Compare all outputs with reference model
        if (tr.out_sop !== ref_out_sop) begin
            `uvm_error("SCOREBOARD_NEW", $sformatf("out_sop mismatch: expected=%0b, got=%0b", ref_out_sop, tr.out_sop))
            errors++;
        end
        
        if (tr.out_eop !== ref_out_eop) begin
            `uvm_error("SCOREBOARD_NEW", $sformatf("out_eop mismatch: expected=%0b, got=%0b", ref_out_eop, tr.out_eop))
            errors++;
        end
        
        if (tr.deq_req && !ref_buffer_empty) begin
            if (tr.rd_data_o !== ref_rd_data_o) begin
                `uvm_error("SCOREBOARD_NEW", $sformatf("rd_data_o mismatch: expected=0x%0h, got=0x%0h", ref_rd_data_o, tr.rd_data_o))
                errors++;
            end
        end
        
        if (tr.pck_proc_full !== ref_buffer_full) begin
            `uvm_error("SCOREBOARD_NEW", $sformatf("pck_proc_full mismatch: expected=%0b, got=%0b", ref_buffer_full, tr.pck_proc_full))
            errors++;
        end
        
        if (tr.pck_proc_empty !== ref_buffer_empty_delayed) begin
            `uvm_error("SCOREBOARD_NEW", $sformatf("pck_proc_empty mismatch: expected=%0b, got=%0b", ref_buffer_empty_delayed, tr.pck_proc_empty))
            errors++;
        end
        
        if (tr.pck_proc_almost_full !== ref_pck_proc_almost_full) begin
            `uvm_error("SCOREBOARD_NEW", $sformatf("pck_proc_almost_full mismatch: expected=%0b, got=%0b", ref_pck_proc_almost_full, tr.pck_proc_almost_full))
            errors++;
        end
        
        if (tr.pck_proc_almost_empty !== ref_pck_proc_almost_empty) begin
            `uvm_error("SCOREBOARD_NEW", $sformatf("pck_proc_almost_empty mismatch: expected=%0b, got=%0b", ref_pck_proc_almost_empty, tr.pck_proc_almost_empty))
            errors++;
        end
        
        if (tr.pck_proc_overflow !== ref_pck_proc_overflow) begin
            `uvm_error("SCOREBOARD_NEW", $sformatf("pck_proc_overflow mismatch: expected=%0b, got=%0b", ref_pck_proc_overflow, tr.pck_proc_overflow))
            errors++;
        end
        
        if (tr.pck_proc_underflow !== ref_pck_proc_underflow) begin
            `uvm_error("SCOREBOARD_NEW", $sformatf("pck_proc_underflow mismatch: expected=%0b, got=%0b", ref_pck_proc_underflow, tr.pck_proc_underflow))
            errors++;
        end
        
        if (tr.packet_drop !== ref_packet_drop) begin
            `uvm_error("SCOREBOARD_NEW", $sformatf("packet_drop mismatch: expected=%0b, got=%0b", ref_packet_drop, tr.packet_drop))
            errors++;
        end
        
        // if (tr.pck_proc_wr_lvl !== ref_wr_lvl) begin
        //     `uvm_error("SCOREBOARD_NEW", $sformatf("pck_proc_wr_lvl mismatch: expected=%0d, got=%0d (wr_en=%0b, rd_en=%0b, buffer_full=%0b, buffer_empty=%0b, overflow=%0b)", ref_wr_lvl, tr.pck_proc_wr_lvl, ref_wr_en, ref_rd_en, ref_buffer_full, ref_buffer_empty, ref_overflow))
        //     errors++;
        // end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCOREBOARD_NEW", $sformatf("New Scoreboard Report: Total=%0d, Errors=%0d", total_transactions, errors), UVM_LOW)
    endfunction

endclass

`endif 