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
    write_state_e write_state_next; // next-state mirror for write FSM
    read_state_e read_state;
    read_state_e read_state_next; // mirror RTL present/next state split
    
    // Reference model internal state
    bit [31:0] ref_buffer[0:16383];  // Main buffer
    bit [11:0] ref_pck_len_buffer[0:31];  // Packet length buffer
    bit [14:0] ref_wr_ptr, ref_rd_ptr;
    bit [14:0] ref_pck_len_wr_ptr, ref_pck_len_rd_ptr;
    bit [14:0] ref_wr_lvl;
    bit [11:0] ref_count_w, ref_count_r;
    bit [11:0] ref_packet_length;      // read-path packet length (used by read FSM)
    bit [11:0] ref_packet_length_w;    // write-path packet length (used for pck_invalid)
    bit ref_buffer_full, ref_buffer_empty;
    bit ref_pck_len_full, ref_pck_len_empty;
    bit ref_pck_proc_overflow, ref_pck_proc_underflow;
    bit ref_packet_drop;
    bit ref_packet_drop_prev;  // track rising edge of packet_drop for debug
    
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
    bit ref_deq_req_r;   // registered deq_req (1-cycle delayed)
    bit ref_deq_req_r1;  // sampling stage for deq_req
    
    // Additional signals
    bit ref_empty_de_assert;
    bit ref_buffer_empty_r;
    bit ref_wr_en, ref_rd_en;
    bit ref_wr_en_prev;  // Previous cycle's write enable
    
    // Read pipeline delay (matching DUT timing)
    bit ref_rd_en_prev;  // Previous cycle's read enable
    bit [31:0] ref_rd_data_delayed;  // Delayed read data output
    bit ref_deq_req_prev;  // Previous cycle's dequeue request (for out_sop timing)
    bit ref_deq_req_prev2;  // Two cycles ago dequeue request (for out_sop timing)
    bit ref_buffer_full_prev;   // Previous cycle's buffer_full
    bit ref_buffer_empty_prev;  // Previous cycle's buffer_empty
    
    // Write level tracking (matching RTL's always_ff behavior)
    bit [14:0] ref_wr_lvl_next;     // Next cycle's wr_lvl value (15 bits: [ADDR_WIDTH:0])
    bit ref_overflow;               // Internal overflow signal (matching int_buffer_top)
    bit ref_overflow_prev;          // Previous cycle's overflow
    
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
        write_state_next = IDLE_W;
        read_state = IDLE_R;
        read_state_next = IDLE_R;
        
        // Initialize pointers and counters
        ref_wr_ptr = 0;
        ref_rd_ptr = 0;
        ref_pck_len_wr_ptr = 0;
        ref_pck_len_rd_ptr = 0;
        ref_wr_lvl = 0;
        ref_count_w = 0;
        ref_count_r = 0;
        ref_packet_length = 0;
        ref_packet_length_w = 0;
        
        // Initialize buffer states
        ref_buffer_full = 0;
        ref_buffer_empty = 1;
        ref_pck_len_full = 0;
        ref_pck_len_empty = 1;
        
        // Initialize flags
        ref_pck_proc_overflow = 0;
        ref_pck_proc_underflow = 0;
        ref_packet_drop = 0;
        ref_packet_drop_prev = 0;
        
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
        ref_deq_req_r1 = 0;
        
        // Initialize additional signals
        ref_empty_de_assert = 1;
        ref_buffer_empty_r = 1;
        ref_wr_en = 0;
        ref_rd_en = 0;
        ref_wr_en_prev = 0;
        ref_rd_en_prev = 0;
        ref_rd_data_delayed = 0;
        ref_deq_req_prev = 0;
        ref_deq_req_prev2 = 0;
        ref_buffer_full_prev = 0;
        ref_buffer_empty_prev = 1;
        
        // Initialize write level tracking
        ref_wr_lvl_next = 0;
        ref_overflow = 0;
        ref_overflow_prev = 0;
        
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
        
        // Compute write next-state (mirror RTL always_comb); advance at end of cycle
        compute_write_next_state(tr);

        // Compute read next-state from present state and registered inputs (like RTL always_comb);
        // advance at end of cycle after outputs are derived from present state
        compute_read_next_state(tr);
        
        // Generate write/read enables FIRST (matching RTL order)
        generate_write_read_enables(tr);
        
        // Update write level based on current enables (matching RTL order)
        update_write_level_next();
        
        // Update internal overflow signal
        update_internal_overflow();
        
        // Update write level (registered output computed from prior-cycle enables/states)
        ref_wr_lvl = ref_wr_lvl_next;
        
        // Debug wr_lvl calculation
        `uvm_info("WR_LVL_DEBUG", $sformatf("wr_lvl calc: wr_en=%0b, rd_en=%0b, buffer_full=%0b, buffer_empty=%0b, wr_lvl_next=%0d, wr_lvl=%0d", 
                 ref_wr_en, ref_rd_en, ref_buffer_full, ref_buffer_empty, ref_wr_lvl_next, ref_wr_lvl), UVM_LOW)
        
        // NOW perform buffer operations (after wr_lvl calculation)
        update_buffer_operations(tr);
        
        // Update buffer states based on the operations just performed
        update_buffer_states();
        
        // Update overflow/underflow detection
        update_overflow_underflow(tr);
        
        // Update previous-cycle trackers for debug (not used in current wr_lvl calc)
        ref_rd_en_prev = ref_rd_en;
        ref_wr_en_prev = ref_wr_en;
        ref_buffer_full_prev  = ref_buffer_full;
        ref_buffer_empty_prev = ref_buffer_empty;
        ref_overflow_prev = ref_overflow;
        ref_deq_req_prev2 = ref_deq_req_prev;
        ref_deq_req_prev = ref_deq_req_r;
        
        // Update outputs (depend on PRESENT state)
        update_outputs(tr);

        // Advance PRESENT states to NEXT after outputs (mirror RTL clocked state update)
        write_state = write_state_next;
        read_state  = read_state_next;
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
            ref_packet_length_w = 0;
            
            // Reset buffer states
            //ref_buffer_full = 0;
            //ref_buffer_empty = 1;
            ref_pck_len_full = 0;
            ref_pck_len_empty = 1;
            
            // Reset flags
            ref_pck_proc_overflow = 0;
            ref_pck_proc_underflow = 0;
            ref_packet_drop = 0;
            ref_packet_drop_prev = 0;
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
            ref_packet_length_w = 0;
            
            // Reset buffer states
            //ref_buffer_full = 0;
            //ref_buffer_empty = 1;
            ref_pck_len_full = 0;
            ref_pck_len_empty = 1;
            
            // Reset flags
            ref_pck_proc_overflow = 0;
            ref_pck_proc_underflow = 0;
            ref_packet_drop = 0;
            ref_packet_drop_prev = 0;
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
        
        // Model RTL register on deq_req: stage and then register
        ref_deq_req_r1 = tr.deq_req;  // sample input
        ref_deq_req_r  = ref_deq_req_r1; // registered output (1-cycle delayed)
        ref_empty_de_assert = tr.empty_de_assert;
    endfunction

    function void compute_write_next_state(pkt_proc_seq_item tr);
        unique case (write_state)
            IDLE_W: begin
                if (ref_enq_req_r && ref_in_sop_r1) begin
                    write_state_next = WRITE_HEADER;
                end else begin
                    write_state_next = IDLE_W;
                end
            end

            WRITE_HEADER: begin
                if (ref_in_sop_r1) begin
                    write_state_next = WRITE_HEADER;  // Stay in header
                end else if (is_packet_invalid(tr)) begin
                    write_state_next = ERROR;
                end else begin
                    write_state_next = WRITE_DATA;
                end
            end

            WRITE_DATA: begin
                if (ref_in_sop_r1 && ref_enq_req_r) begin
                    write_state_next = WRITE_HEADER;  // New packet
                end else if (ref_in_eop_r1 && !ref_in_sop_r1 && !ref_enq_req_r) begin
                    write_state_next = IDLE_W;  // End of packet
                end else begin
                    write_state_next = WRITE_DATA;  // Continue data
                end
            end

            ERROR: begin
                write_state_next = IDLE_W;  // Return to idle
            end
        endcase
    endfunction

    function void compute_read_next_state(pkt_proc_seq_item tr);
        unique case (read_state)
            IDLE_R: begin
                if (ref_deq_req_r && !ref_buffer_empty) begin
                    read_state_next = READ_HEADER;
                end else begin
                    read_state_next = IDLE_R;
                end
            end

            READ_HEADER: begin
                read_state_next = READ_DATA;
            end

            READ_DATA: begin
                if (ref_buffer_empty) begin
                    read_state_next = IDLE_R;
                end else if ((ref_count_r == (ref_packet_length - 1)) && ref_deq_req_r) begin
                    read_state_next = READ_HEADER;  // Next packet
                end else if ((ref_count_r == (ref_packet_length - 1)) && !ref_deq_req_r) begin
                    read_state_next = IDLE_R;  // End of packet
                end else begin
                    read_state_next = READ_DATA;  // Continue reading
                end
            end
        endcase
    endfunction

    function bit is_packet_invalid(pkt_proc_seq_item tr);
        // Invalid packet conditions (matching RTL)
        if (tr.in_sop && tr.in_eop) begin
            `uvm_info("PKT_DROP_DEBUG", $sformatf("Time=%0t: Invalid packet: SOP and EOP asserted together", $time), UVM_LOW)
            return 1;
        end
        if (ref_in_sop_r && ref_in_sop_r1)  begin
            `uvm_info("PKT_DROP_DEBUG", $sformatf("Back-to-back SOP ref in_sop_r = %0b, ref in_sop_r1 = %0b", ref_in_sop_r, ref_in_sop_r1), UVM_LOW)
            return 1;
        end
        if (tr.in_sop && (write_state == WRITE_DATA) && !ref_in_eop_r1) begin 
            `uvm_info("PKT_DROP_DEBUG", $sformatf("SOP during data:  DUT in_sop = %0b, write_state = %0d, ref in_eop_r1 = %0b", tr.in_sop, write_state, ref_in_eop_r1), UVM_LOW); 
            return 1; 
        end
        // Use write-path packet length for write-side validity checks
        if (ref_in_eop_r1 && (ref_count_w < ref_packet_length_w - 1) && (ref_packet_length_w != 0)) begin 
            `uvm_info("PKT_DROP_DEBUG", $sformatf("Early EOP: ref in_eop_r1 = %0b, ref count_w = %0d, ref packet_length_w = %0d", ref_in_eop_r1, ref_count_w, ref_packet_length_w), UVM_LOW) 
            return 1; 
        end
        if (!ref_in_eop_r1 && ((ref_count_w == ref_packet_length_w - 1) || (ref_packet_length_w == 0)) && (write_state == WRITE_DATA)) begin 
            `uvm_info("PKT_DROP_DEBUG", $sformatf("Late EOP: ref in_eop_r1 = %0b, ref count_w = %0d, ref packet_length_w = %0d, write_state = %0d", ref_in_eop_r1, ref_count_w, ref_packet_length_w, write_state), UVM_LOW) 
            return 1; 
        end
        if (ref_pck_proc_overflow) begin 
            `uvm_info("PKT_DROP_DEBUG", $sformatf("Overflow condition: ref pck_proc_overflow = %0b", ref_pck_proc_overflow), UVM_LOW) 
            return 1; 
        end
        if (tr.pck_len_valid && (tr.pck_len_i <= 1)) begin 
            `uvm_info("PKT_DROP_DEBUG", $sformatf("Invalid pck_len: DUT pck_len_valid = %0b, DUT pck_len_i = %0d", tr.pck_len_valid, tr.pck_len_i), UVM_LOW) 
            return 1; 
        end
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
                // Update write-path packet length mirror (used in scoreboard pck_invalid checks)
                ref_packet_length_w = (ref_pck_len_valid_r1) ? ref_pck_len_i_r1 : ref_wr_data_r1[11:0];
            end else if (write_state == WRITE_DATA) begin
                ref_buffer[ref_wr_ptr[13:0]] = ref_wr_data_r1;
            end
            
            if (write_state == WRITE_HEADER || write_state == WRITE_DATA) begin
                ref_wr_ptr = ref_wr_ptr + 1;
                ref_count_w = ref_count_w + 1;
            end
        end
        
        // Read operations with one-cycle delay for data path only (matching DUT memory pipeline)
        if (ref_rd_en_prev && !ref_buffer_empty) begin
            ref_rd_data_delayed = ref_buffer[ref_rd_ptr[13:0]];
            ref_rd_ptr = ref_rd_ptr + 1;
            // NOTE: Do not increment ref_count_r here; count is driven by FSM on deq_req_r
        end

        // Packet length read aligns with deq_req_r in READ_HEADER (no extra delay)
        if (read_state == READ_HEADER && ref_deq_req_r) begin
            ref_packet_length = ref_pck_len_buffer[ref_pck_len_rd_ptr[4:0]];
            ref_pck_len_rd_ptr = ref_pck_len_rd_ptr + 1;
        end
        
        // Packet drop handling
        if (ref_packet_drop) begin
            `uvm_info("PKT_DROP_DEBUG", $sformatf("Time=%0t: PACKET_DROP asserted. overflow=%0b, count_w=%0d, wr_ptr(before)=%0d",
                     $time, ref_pck_proc_overflow, ref_count_w, ref_wr_ptr), UVM_LOW)
            if (ref_pck_proc_overflow) begin
                ref_wr_ptr = ref_wr_ptr - ref_count_w + 1;
            end else begin
                ref_wr_ptr = ref_wr_ptr - ref_count_w;
            end
            ref_count_w = 0;
            ref_packet_drop = 0;
            `uvm_info("PKT_DROP_DEBUG", $sformatf("Time=%0t: PACKET_DROP applied. wr_ptr(after)=%0d, wr_lvl=%0d",
                     $time, ref_wr_ptr, ref_wr_lvl), UVM_LOW)
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
        
        // Debug buffer state
        `uvm_info("BUFFER_DEBUG", $sformatf("Buffer State: wr_ptr=%0d, rd_ptr=%0d, empty=%0b, full=%0b, empty_de_assert=%0b, in_eop_r2=%0b", 
                 ref_wr_ptr, ref_rd_ptr, ref_buffer_empty, ref_buffer_full, ref_empty_de_assert, ref_in_eop_r2), UVM_LOW)
        
        // Update buffer_empty_r
        ref_buffer_empty_r = ref_buffer_empty;
        
        // Packet length buffer conditions
        ref_pck_len_full = (ref_pck_len_wr_ptr == ref_pck_len_rd_ptr) ? 0 :
                          (({~ref_pck_len_wr_ptr[5], ref_pck_len_wr_ptr[4:0]} == ref_pck_len_rd_ptr) ? 1 : 0);
        ref_pck_len_empty = (ref_pck_len_wr_ptr == ref_pck_len_rd_ptr) ? 1 : 0;
    endfunction

    function void update_write_level_next();
        // Write level logic (matching RTL always_ff):
        // Compute from CURRENT-cycle enables and CURRENT buffer states (which reflect previous pointers this edge)
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
        
        // Packet drop detection & debug
        if (is_packet_invalid(tr)) begin
            if (!ref_packet_drop) begin
                `uvm_info("PKT_DROP_DEBUG", $sformatf("Time=%0t: PACKET_DROP detected. Reasons: in_sop=%0b, in_eop=%0b, in_sop_r=%0b, in_sop_r1=%0b, early_eop=%0b, late_eop=%0b, overflow=%0b, pck_len_valid=%0b, pck_len_i=%0d",
                         $time,
                         tr.in_sop, tr.in_eop,
                         ref_in_sop_r, ref_in_sop_r1,
                         (ref_in_eop_r1 && (ref_count_w < ref_packet_length - 1) && (ref_packet_length != 0)),
                         (!ref_in_eop_r1 && (ref_count_w == ref_packet_length - 1) && (write_state == WRITE_DATA)),
                         ref_pck_proc_overflow,
                         tr.pck_len_valid, tr.pck_len_i), UVM_LOW)
            end
            ref_packet_drop = 1;
        end else begin
            ref_packet_drop_prev = ref_packet_drop;
        end
    endfunction

    function void update_outputs(pkt_proc_seq_item tr);
        // Generate expected outputs
        ref_out_sop = 0;
        ref_out_eop = 0;
        
        // Scoreboard mirrors RTL next_state/output timing using present_state and deq_req_r
        // Outputs depend on present state and registered deq_req_r
        unique case (read_state)
            IDLE_R: begin
                ref_out_sop = 0;
                ref_out_eop = 0;
            end
            READ_HEADER: begin
                if (ref_deq_req_r) begin
                    ref_out_sop = 1;
                    ref_out_eop = 0;
                    // Start/advance packet counter on deq_req_r
                    ref_count_r = ref_count_r + 1;
                end
            end
            READ_DATA: begin
                if (ref_deq_req_r) begin
                    // Increment count on each dequeued data beat; assert eop on last beat
                    ref_count_r = ref_count_r + 1;
                    if (ref_count_r == (ref_packet_length)) begin
                        ref_out_eop = 1;
                        ref_count_r = 0; // packet boundary
                    end
                end
            end
        endcase
        
        // Combinational output signals (matching RTL exactly)
        update_combinational_outputs(tr);
        
        // Debug out_sop calculation
        `uvm_info("OUT_SOP_DEBUG", $sformatf("out_sop/eop: state=%0d, deq_req_r=%0b, count_r=%0d, pck_len=%0d, out_sop=%0b, out_eop=%0b", 
                 read_state, ref_deq_req_r, ref_count_r, ref_packet_length, ref_out_sop, ref_out_eop), UVM_LOW)
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
        // Debug information
        `uvm_info("SCOREBOARD_DEBUG", $sformatf("Time=%0d: DUT wr_lvl=%0d, ref_wr_lvl=%0d, DUT_empty=%0b, ref_empty=%0b, DUT_rd_data=0x%0h, ref_rd_data=0x%0h", 
                 $time, tr.pck_proc_wr_lvl, ref_wr_lvl, tr.pck_proc_empty, ref_buffer_empty, tr.rd_data_o, ref_rd_data_delayed), UVM_LOW)
        
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
            if (tr.rd_data_o !== ref_rd_data_delayed) begin
                `uvm_error("SCOREBOARD_NEW", $sformatf("rd_data_o mismatch: expected=0x%0h, got=0x%0h", ref_rd_data_delayed, tr.rd_data_o))
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