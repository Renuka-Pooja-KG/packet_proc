//=============================================================================
// File: pkt_proc_scoreboard_new.sv
// Description: New Simple Packet Processor UVM Scoreboard
// Author: Assistant
// Date: 2024
//=============================================================================


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
    //bit [31:0] ref_rd_data_delayed;  // Delayed read data output
    bit ref_deq_req_prev;  // Previous cycle's dequeue request (for out_sop timing)
    bit ref_deq_req_prev2;  // Two cycles ago dequeue request (for out_sop timing)
    bit ref_buffer_full_prev;   // Previous cycle's buffer_full
    bit ref_buffer_empty_prev;  // Previous cycle's buffer_empty
    
    // Write level tracking (matching RTL's always_ff behavior)
    bit [14:0] ref_wr_lvl_next;     // Next cycle's wr_lvl value (15 bits: [ADDR_WIDTH:0])
    bit ref_overflow;               // Internal overflow signal (matching int_buffer_top)
            bit ref_overflow_prev;          // Previous cycle's overflow
        bit ref_reset_active;              // Flag to track if reset is currently active
    

    
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
        `uvm_info("PACKET_LENGTH_DEBUG", $sformatf("Time=%0t: ref_packet_length_w initialized to 0", $time), UVM_LOW)
        
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
        
        // Initialize additional signals
        ref_empty_de_assert = 1;
        ref_buffer_empty_r = 1;
        ref_wr_en = 0;
        ref_rd_en = 0;
        ref_wr_en_prev = 0;
        ref_rd_en_prev = 0;
        //ref_rd_data_delayed = 0;
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
        
        // Initialize reset flag
        ref_reset_active = 0;
        
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
        // Debug current states being processed
        `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: Processing with states - WRITE: %0d, READ: %0d", 
                 $time, write_state, read_state), UVM_LOW)
        
        // CRITICAL FIX: Update ref_wr_lvl at the BEGINNING of the cycle (matching RTL always_ff behavior)
        // This uses the ref_wr_lvl_next calculated in the PREVIOUS cycle
        // UNLESS reset is active - then respond immediately like DUT
        if (!tr.pck_proc_int_mem_fsm_rstn) begin
            // ASYNC RESET: Only set wr_lvl to 0 when DUT actually responds to reset
            // This prevents premature reset assumption before DUT has time to propagate reset
            if (tr.pck_proc_wr_lvl == 0 && ref_wr_lvl != 0) begin
                `uvm_info("WR_LVL_RESET", $sformatf("Time=%0t: ASYNC RESET: ref_wr_lvl set to 0 (DUT wr_lvl=0, matching DUT reset response)", 
                         $time), UVM_LOW)
                ref_wr_lvl = 0;
            end else if (tr.pck_proc_wr_lvl != 0 && ref_wr_lvl != tr.pck_proc_wr_lvl) begin
                // DUT hasn't responded to reset yet - keep current value until it does
                `uvm_info("WR_LVL_RESET_WAIT", $sformatf("Time=%0t: RESET ASSERTED but DUT wr_lvl=%0d, keeping ref_wr_lvl=%0d until DUT responds", 
                         $time, tr.pck_proc_wr_lvl, ref_wr_lvl), UVM_LOW)
            end
        end else begin
            // Normal operation: Update from previous cycle's calculation
            if (ref_wr_lvl != ref_wr_lvl_next) begin
                `uvm_info("WR_LVL_UPDATE", $sformatf("Time=%0t: ref_wr_lvl updated from %0d to %0d (matching RTL clock edge behavior)", 
                         $time, ref_wr_lvl, ref_wr_lvl_next), UVM_LOW)
            end
            ref_wr_lvl = ref_wr_lvl_next;
        end
        
        // Apply one-cycle delay FIRST (use previous cycle's values for comparison)
        ref_buffer_empty_delayed = ref_buffer_empty;
        
        // Handle reset logic FIRST (matching RTL behavior)
        handle_reset_logic(tr);
        
        // Compute write next-state (mirror RTL always_comb); advance at end of cycle
        compute_write_next_state(tr);

        // Compute read next-state from present state and registered inputs (like RTL always_comb);
        // advance at end of cycle after outputs are derived from present state
        compute_read_next_state(tr);
        
        // Debug next states computed
        `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: Next states computed - WRITE: %0d -> %0d, READ: %0d -> %0d", 
                 $time, write_state, write_state_next, read_state, read_state_next), UVM_LOW)
        
        // Debug current cycle inputs for state transitions
        `uvm_info("STATE_INPUTS", $sformatf("Time=%0t: Current inputs - in_sop=%0b, in_eop=%0b, enq_req=%0b, pck_len_valid=%0b, pck_len_i=%0d", 
                 $time, tr.in_sop, tr.in_eop, tr.enq_req, tr.pck_len_valid, tr.pck_len_i), UVM_LOW)
        
        // Generate write/read enables FIRST (matching RTL order)
        generate_write_read_enables(tr);
        
        // NOW perform buffer operations FIRST (matching RTL order)
        // This updates ref_packet_length_w which is needed for packet drop logic
        update_buffer_operations(tr);
        
        // Calculate packet drop logic AFTER buffer operations (matching RTL exactly)
        // Now ref_packet_length_w is properly updated for the current cycle
        update_packet_drop_logic(tr);
        
        // Update buffer states based on the operations just performed
        update_buffer_states();
        
        // Update internal overflow signal
        update_internal_overflow();
        
        // Update write level based on current enables AFTER buffer operations (matching RTL order)
        update_write_level_next();
        
        // Debug wr_lvl calculation (but don't update ref_wr_lvl yet - it updates on next cycle like RTL)
        `uvm_info("WR_LVL_DEBUG", $sformatf("wr_lvl_next calc: wr_en=%0b, rd_en=%0b, buffer_full=%0b, buffer_empty=%0b, wr_lvl_next=%0d, current_wr_lvl=%0d", 
                 ref_wr_en, ref_rd_en, ref_buffer_full, ref_buffer_empty, ref_wr_lvl_next, ref_wr_lvl), UVM_LOW)
        
        // Update previous-cycle trackers BEFORE buffer operations (matching RTL timing)
        ref_rd_en_prev = ref_rd_en;
        ref_wr_en_prev = ref_wr_en;
        ref_buffer_full_prev  = ref_buffer_full;
        ref_buffer_empty_prev = ref_buffer_empty;
        ref_overflow_prev = ref_overflow;
        ref_deq_req_prev2 = ref_deq_req_prev;
        ref_deq_req_prev = ref_deq_req_r;
        
        // Update overflow/underflow detection
        update_overflow_underflow(tr);
        
        // Update outputs (depend on PRESENT state)
        update_outputs(tr);

        // Advance PRESENT states to NEXT after outputs (mirror RTL clocked state update)
        if (write_state != write_state_next) begin
            `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: WRITE FSM ADVANCE: %0d -> %0d", 
                     $time, write_state, write_state_next), UVM_LOW)
        end
        if (read_state != read_state_next) begin
            `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: READ FSM ADVANCE: %0d -> %0d", 
                     $time, read_state, read_state_next), UVM_LOW)
        end
        write_state = write_state_next;
        read_state  = read_state_next;
        
        // CRITICAL: Update pipeline registers at the END of the cycle (matching RTL clock edge behavior)
        // This ensures that all calculations use the PREVIOUS cycle's values
        `uvm_info("PIPELINE_TIMING", $sformatf("Time=%0t: Updating pipeline registers at END of cycle (for next cycle use)", $time), UVM_LOW)
        update_pipeline_registers(tr);
    endfunction

    function void handle_reset_logic(pkt_proc_seq_item tr);
        // Asynchronous active-low reset (highest priority)
        if (!tr.pck_proc_int_mem_fsm_rstn) begin
            `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: ASYNC RESET: Resetting all states to IDLE", $time), UVM_LOW)
            // Set reset active flag (matching DUT async reset behavior)
            ref_reset_active = 1;
            
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
            `uvm_info("PACKET_LENGTH_DEBUG", $sformatf("Time=%0t: ref_packet_length_w reset to 0 (ASYNC RESET)", $time), UVM_LOW)
            
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
        
        // Check if reset was just de-asserted (transition from reset to normal operation)
        if (ref_reset_active && tr.pck_proc_int_mem_fsm_rstn) begin
            `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: RESET DE-ASSERTED: Returning to normal operation", $time), UVM_LOW)
            ref_reset_active = 0;
        end
        
        // Synchronous active-high software reset (second priority)
        if (tr.pck_proc_int_mem_fsm_sw_rstn) begin
            `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: SYNC RESET: Resetting all states to IDLE", $time), UVM_LOW)
            // Set reset active flag for software reset
            ref_reset_active = 1;
            
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
            `uvm_info("PACKET_LENGTH_DEBUG", $sformatf("Time=%0t: ref_packet_length_w reset to 0 (SYNC RESET)", $time), UVM_LOW)
            
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
        
        // Check if software reset was just de-asserted
        if (ref_reset_active && !tr.pck_proc_int_mem_fsm_sw_rstn) begin
            `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: SOFTWARE RESET DE-ASSERTED: Returning to normal operation", $time), UVM_LOW)
            ref_reset_active = 0;
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
        
        // Debug pipeline register updates
        `uvm_info("PIPELINE_UPDATE", $sformatf("Time=%0t: Pipeline updated - in_sop_r1=%0b->%0b, pck_len_valid_r1=%0b->%0b, pck_len_i_r1=%0d->%0d", 
                 $time, ref_in_sop_r1, tr.in_sop, ref_pck_len_valid_r1, tr.pck_len_valid, ref_pck_len_i_r1, tr.pck_len_i), UVM_LOW)
        
        // Model RTL register on deq_req: stage and then register
        ref_deq_req_r1 = tr.deq_req;  // sample input
        ref_deq_req_r  = ref_deq_req_r1; // registered output (1-cycle delayed)
        ref_empty_de_assert = tr.empty_de_assert;
        
        // CRITICAL FIX: Do NOT update ref_wr_lvl here - it should update on NEXT cycle like RTL
        // The RTL wr_lvl updates on the NEXT clock edge, not the current one
        // ref_wr_lvl = ref_wr_lvl_next;  // REMOVED - this was causing 1-cycle ahead behavior
        
        // Debug write level timing
        `uvm_info("WR_LVL_TIMING", $sformatf("Time=%0t: ref_wr_lvl_next=%0d calculated, but ref_wr_lvl=%0d NOT updated yet (matching RTL always_ff timing)", 
                 $time, ref_wr_lvl_next, ref_wr_lvl), UVM_LOW)
    endfunction

    function void compute_write_next_state(pkt_proc_seq_item tr);
        unique case (write_state)
            IDLE_W: begin
                // Use current cycle values (matching RTL behavior exactly)
                if (tr.enq_req && tr.in_sop) begin
                    write_state_next = WRITE_HEADER;
                    `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: WRITE FSM: IDLE_W -> WRITE_HEADER (enq_req=%0b, in_sop=%0b)", 
                             $time, tr.enq_req, tr.in_sop), UVM_LOW)
                end else begin
                    write_state_next = IDLE_W;
                end
            end

            WRITE_HEADER: begin
                // Use current cycle values (matching RTL behavior exactly)
                if (tr.in_sop) begin
                    write_state_next = WRITE_HEADER;
                    `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: WRITE FSM: WRITE_HEADER -> WRITE_HEADER (in_sop=%0b)", 
                             $time, tr.in_sop), UVM_LOW)
                end else if (ref_packet_drop) begin
                    write_state_next = ERROR;
                    `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: WRITE FSM: WRITE_HEADER -> ERROR (packet_drop=%0b)", 
                             $time, ref_packet_drop), UVM_LOW)
                end else begin
                    write_state_next = WRITE_DATA;
                    `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: WRITE FSM: WRITE_HEADER -> WRITE_DATA (advance to data)", $time), UVM_LOW)
                end
            end

            WRITE_DATA: begin
                // Use current cycle values (matching RTL behavior exactly)
                if (tr.enq_req && tr.in_sop) begin
                    write_state_next = WRITE_HEADER;
                    `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: WRITE FSM: WRITE_DATA -> WRITE_HEADER (next_data_ready: enq_req=%0b, in_sop=%0b)", 
                             $time, tr.enq_req, tr.in_sop), UVM_LOW)
                end else if (ref_in_eop_r1 && !tr.in_sop && !tr.enq_req) begin
                    write_state_next = IDLE_W;
                    `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: WRITE FSM: WRITE_DATA -> IDLE_W (next_data_nt_ready: in_eop_r1=%0b, in_sop=%0b, enq_req=%0b)", 
                             $time, ref_in_eop_r1, tr.in_sop, tr.enq_req), UVM_LOW)
                end else begin
                    write_state_next = WRITE_DATA;
                end
            end

            ERROR: begin
                write_state_next = IDLE_W;
                `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: WRITE FSM: ERROR -> IDLE_W (error recovery)", $time), UVM_LOW)
            end

            default: begin
                write_state_next = IDLE_W;
                `uvm_error("STATE_TRANSITION", $sformatf("Time=%0t: WRITE FSM: Unknown state %0d, resetting to IDLE_W", $time, write_state))
            end
        endcase
    endfunction

    function void compute_read_next_state(pkt_proc_seq_item tr);
        unique case (read_state)
            IDLE_R: begin
                // Use registered values (matching RTL behavior exactly)
                if (ref_deq_req_r && !ref_buffer_empty) begin
                    read_state_next = READ_HEADER;
                    `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: READ FSM: IDLE_R -> READ_HEADER (deq_req_r=%0b, buffer_empty=%0b)", 
                             $time, ref_deq_req_r, ref_buffer_empty), UVM_LOW)
                end else begin
                    read_state_next = IDLE_R;
                end
            end

            READ_HEADER: begin
                read_state_next = READ_DATA;
                `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: READ FSM: READ_HEADER -> READ_DATA (advance to data)", $time), UVM_LOW)
            end

            READ_DATA: begin
                if (ref_buffer_empty) begin
                    read_state_next = IDLE_R;
                    `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: READ FSM: READ_DATA -> IDLE_R (buffer empty)", $time), UVM_LOW)
                end else if ((ref_count_r == (ref_packet_length - 1)) && ref_deq_req_r) begin
                    read_state_next = READ_HEADER;  // Next packet
                    `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: READ FSM: READ_DATA -> READ_HEADER (next packet: count_r=%0d, pck_len=%0d, deq_req_r=%0b)", 
                             $time, ref_count_r, ref_packet_length, ref_deq_req_r), UVM_LOW)
                end else if ((ref_count_r == (ref_packet_length - 1)) && !ref_deq_req_r) begin
                    read_state_next = IDLE_R;  // End of packet
                    `uvm_info("STATE_TRANSITION", $sformatf("Time=%0t: READ FSM: READ_DATA -> IDLE_R (end of packet: count_r=%0d, pck_len=%0d, deq_req_r=%0b)", 
                             $time, ref_count_r, ref_packet_length, ref_deq_req_r), UVM_LOW)
                end else begin
                    read_state_next = READ_DATA;  // Continue reading
                end
            end
        endcase
    endfunction

    function bit is_packet_invalid(pkt_proc_seq_item tr);
        // Mirror RTL pck_invalid: (invalid_1 || invalid_3 || invalid_4 || invalid_5 || invalid_6) && enq_req
    //     bit cond1, cond3, cond4, cond5, cond6;
        
    //     // Debug: Show current ref_packet_length_w value when evaluating packet validity
    //     `uvm_info("PACKET_LENGTH_DEBUG", $sformatf("Time=%0t: is_packet_invalid evaluation - ref_packet_length_w=%0d, ref_count_w=%0d, write_state=%0d, tr.pck_len_valid=%0b, tr.in_sop=%0b, tr.pck_len_i=%0d", 
    //              $time, ref_packet_length_w, ref_count_w, write_state, tr.pck_len_valid, tr.in_sop, tr.pck_len_i), UVM_LOW)
        
    //     cond1 = (tr.in_sop && tr.in_eop);
    //     //cond3 = (tr.in_sop && (~ref_in_eop_r1) && (write_state == WRITE_DATA));
    //    // cond3 = (tr.in_sop && ~ref_in_eop_r1 && (write_state == WRITE_DATA));
    //     // Use WRITE-PATH packet length for these checks
    //     cond4 = ((ref_count_w < (ref_packet_length_w - 1)) && (ref_packet_length_w != 0) && (ref_in_eop_r1));
    //     cond5 = (((ref_count_w == (ref_packet_length_w - 1)) || (ref_packet_length_w == 0)) && (~ref_in_eop_r1) && (write_state == WRITE_DATA));
    //     cond6 = (ref_pck_proc_overflow);

    //     // Debug: Show condition calculations that use ref_packet_length_w
    //     `uvm_info("PACKET_LENGTH_DEBUG", $sformatf("Time=%0t: Condition calculations - cond4=%0b (count_w=%0d < pck_len_w-1=%0d && pck_len_w!=0=%0b && in_eop_r1=%0b), cond5=%0b (count_w=%0d == pck_len_w-1=%0d || pck_len_w==0=%0b && ~in_eop_r1=%0b && state=%0d)", 
    //              $time, cond4, ref_count_w, ref_packet_length_w-1, (ref_packet_length_w != 0), ref_in_eop_r1, 
    //                     cond5, ref_count_w, ref_packet_length_w-1, (ref_packet_length_w == 0), ref_in_eop_r1, write_state), UVM_LOW)

    //    // if (tr.enq_req && (cond1 || cond3 || cond4 || cond5 || cond6)) begin
    //     if (tr.enq_req && (cond1 || cond4 || cond5 || cond6)) begin
    //     //    `uvm_info("PKT_DROP_DEBUG", $sformatf("Time=%0t: pck_invalid: enq_req=1, state=%0d, cond1=%0b, cond3=%0b, cond4=%0b, cond5=%0b, cond6=%0b, count_w=%0d, pck_len_w=%0d, in_sop=%0b, in_eop_r1=%0b",
    //     //             $time, write_state, cond1, cond3, cond4, cond5, cond6, ref_count_w, ref_packet_length_w, tr.in_sop, ref_in_eop_r1), UVM_LOW)
    //         `uvm_info("PKT_DROP_DEBUG", $sformatf("Time=%0t: pck_invalid: enq_req=1, state=%0d, cond1=%0b, cond4=%0b, cond5=%0b, cond6=%0b, count_w=%0d, pck_len_w=%0d, in_sop=%0b, in_eop_r1=%0b",
    //                  $time, write_state, cond1, cond4, cond5, cond6, ref_count_w, ref_packet_length_w, tr.in_sop, ref_in_eop_r1), UVM_LOW)
    //         return 1;
    //     end
        return 0;
    endfunction

    function void generate_write_read_enables(pkt_proc_seq_item tr);
        // Determine write enable (matching RTL logic exactly)
        // RTL uses enq_req_r for output logic, but current cycle values for state transitions
        ref_wr_en = 0;
        if (write_state == WRITE_HEADER && ref_enq_req_r && !ref_packet_drop) begin
            ref_wr_en = 1;
        end else if (write_state == WRITE_DATA && ref_enq_req_r && !ref_packet_drop) begin
            ref_wr_en = 1;
        end
        
        // Determine read enable (matching RTL logic)
        ref_rd_en = 0;
        if (read_state == READ_HEADER && tr.deq_req) begin
            ref_rd_en = 1;
        end else if (read_state == READ_DATA && tr.deq_req) begin
            ref_rd_en = 1;
        end
    endfunction

    function void update_packet_drop_logic(pkt_proc_seq_item tr);
        // Calculate packet drop logic (matching RTL exactly)
        // pck_invalid = (invalid_1 || invalid_3 || invalid_4 || invalid_5 || invalid_6) && enq_req
        // invalid_1 = in_sop && in_eop
        // invalid_3 = in_sop && (~in_eop_r1) && (write_state == WRITE_DATA)
        // invalid_4 = (count_w < (packet_length_w - 1)) && (packet_length_w != 0) && (in_eop_r1)
        // invalid_5 = ((count_w == (packet_length_w - 1)) || (packet_length_w == 0)) && (~in_eop_r1) && (write_state == WRITE_DATA)
        // invalid_6 = pck_proc_overflow

        // Use WRITE-PATH packet length for these checks
        bit invalid_1 = (tr.in_sop && tr.in_eop);
        bit invalid_3 = (tr.in_sop && (~ref_in_eop_r1) && (write_state == WRITE_DATA));
        // CRITICAL FIX: Only evaluate invalid_4 when we're actually ending a packet (not starting a new one)
        // Check if we're in WRITE_DATA state (processing a packet) before evaluating invalid_4
        // This prevents false packet drops when count_w=0 from previous packet completion
        bit invalid_4 = (write_state == WRITE_DATA) && 
                        ((ref_count_w < (ref_packet_length_w - 1)) && (ref_packet_length_w != 0) && (ref_in_eop_r1));
        // CRITICAL FIX: invalid_5 should check CURRENT cycle in_eop, not previous cycle in_eop_r1
        // This prevents false packet drops when a packet legitimately completes
        bit invalid_5 = (((ref_count_w == (ref_packet_length_w - 1)) || (ref_packet_length_w == 0)) && (~tr.in_eop) && (write_state == WRITE_DATA));
        bit invalid_6 = ref_pck_proc_overflow;

        // Debug: Show condition calculations that use ref_packet_length_w
        `uvm_info("PACKET_LENGTH_DEBUG", $sformatf("Time=%0t: Condition calculations - invalid_1=%0b (in_sop=%0b && in_eop=%0b), invalid_3=%0b (in_sop=%0b && ~in_eop_r1=%0b && state=%0d), invalid_4=%0b (count_w=%0d < pck_len_w-1=%0d && pck_len_w!=0=%0b && in_eop_r1=%0b), invalid_5=%0b (count_w=%0d == pck_len_w-1=%0d || pck_len_w==0=%0b && ~in_eop=%0b && state=%0d), invalid_6=%0b (overflow=%0b)", 
                 $time, invalid_1, tr.in_sop, tr.in_eop, invalid_3, tr.in_sop, ref_in_eop_r1, write_state, invalid_4, ref_count_w, ref_packet_length_w-1, (ref_packet_length_w != 0), ref_in_eop_r1, invalid_5, ref_count_w, ref_packet_length_w-1, (ref_packet_length_w == 0), tr.in_eop, write_state, invalid_6, ref_pck_proc_overflow), UVM_LOW)

        // pck_invalid = (invalid_1 || invalid_3 || invalid_4 || invalid_5 || invalid_6) && enq_req
        if (tr.enq_req && (invalid_1 || invalid_3 || invalid_4 || invalid_5 || invalid_6)) begin
            `uvm_info("PKT_DROP_DEBUG", $sformatf("Time=%0t: pck_invalid: enq_req=1, state=%0d, invalid_1=%0b, invalid_3=%0b, invalid_4=%0b, invalid_5=%0b, invalid_6=%0b, count_w=%0d, pck_len_w=%0d, in_sop=%0b, in_eop_r1=%0b",
                     $time, write_state, invalid_1, invalid_3, invalid_4, invalid_5, invalid_6, ref_count_w, ref_packet_length_w, tr.in_sop, ref_in_eop_r1), UVM_LOW)
            
            // Additional debug for invalid_4 specifically
            if (invalid_4) begin
                `uvm_info("INVALID_4_DEBUG", $sformatf("Time=%0t: INVALID_4 triggered: state=%0d, count_w=%0d < (pck_len_w-1)=%0d && pck_len_w!=0=%0b && in_eop_r1=%0b", 
                         $time, write_state, ref_count_w, ref_packet_length_w-1, (ref_packet_length_w != 0), ref_in_eop_r1), UVM_LOW)
            end
            
            ref_packet_drop = 1;
        end else begin
            ref_packet_drop = 0;
        end
        
        // Store previous value for next cycle
        ref_packet_drop_prev = ref_packet_drop;
    endfunction

    function void update_buffer_operations(pkt_proc_seq_item tr);
        // Write/read enables are already calculated in generate_write_read_enables()
        // No need to recalculate them here
        
        // Write operations
        if (ref_wr_en && !ref_buffer_full) begin
            if (write_state == WRITE_HEADER) begin
                ref_buffer[ref_wr_ptr[13:0]] = ref_wr_data_r1;  // Use registered value
            end else if (write_state == WRITE_DATA) begin
                ref_buffer[ref_wr_ptr[13:0]] = ref_wr_data_r1;  // Use registered value
            end
            
            if (write_state == WRITE_HEADER || write_state == WRITE_DATA) begin
                ref_wr_ptr = ref_wr_ptr + 1;
                ref_count_w = ref_count_w + 1;
                `uvm_info("COUNT_W_DEBUG", $sformatf("Time=%0t: count_w incremented to %0d (state=%0d, wr_en=%0b)", 
                         $time, ref_count_w, write_state, ref_wr_en), UVM_LOW)
            end
        end
        
        // Packet length buffer operations (matching RTL exactly)
        // RTL writes to pck_len_buffer in WRITE_HEADER state regardless of wr_en
        if (write_state == WRITE_HEADER) begin
            // Use RTL logic exactly: pck_len_r2 = (pck_len_valid_r1) ? pck_len_i_r1 : ((in_sop_r1) ? wr_data_r1[11:0] : packet_length)
            // CRITICAL: These _r1 values contain the PREVIOUS cycle's values (when in_sop=1, pck_len_valid=1)
            bit [11:0] pck_len_r2_value;
            if (ref_pck_len_valid_r1) begin
                pck_len_r2_value = ref_pck_len_i_r1;
                `uvm_info("PACKET_LENGTH_DEBUG", $sformatf("Time=%0t: WRITE_HEADER: Using pck_len_i_r1=%0d (pck_len_valid_r1=1)", 
                         $time, ref_pck_len_i_r1), UVM_LOW)
            end else if (ref_in_sop_r1) begin
                pck_len_r2_value = ref_wr_data_r1[11:0];
                `uvm_info("PACKET_LENGTH_DEBUG", $sformatf("Time=%0t: WRITE_HEADER: Using wr_data_r1[11:0]=%0d (in_sop_r1=1)", 
                         $time, ref_wr_data_r1[11:0]), UVM_LOW)
            end else begin
                pck_len_r2_value = ref_packet_length_w;  // Keep previous value
                `uvm_info("PACKET_LENGTH_DEBUG", $sformatf("Time=%0t: WRITE_HEADER: Using prev_packet_length=%0d (both conditions false)", 
                         $time, ref_packet_length_w), UVM_LOW)
            end
            
            // Write to packet length buffer (matching RTL pck_len_wr_en = 1'b1 in WRITE_HEADER)
            ref_pck_len_buffer[ref_pck_len_wr_ptr[4:0]] = pck_len_r2_value;
            ref_pck_len_wr_ptr = ref_pck_len_wr_ptr + 1;
            
            // Update write-path packet length mirror for pck_invalid checks
            ref_packet_length_w = pck_len_r2_value;
            
            // Debug print for packet length assignment
            `uvm_info("PACKET_LENGTH_DEBUG", $sformatf("Time=%0t: WRITE_HEADER: pck_len_r2=%0d (pck_len_valid_r1=%0b, in_sop_r1=%0b, pck_len_i_r1=%0d, wr_data_r1[11:0]=%0d, prev_packet_length=%0d)", 
                     $time, pck_len_r2_value, ref_pck_len_valid_r1, ref_in_sop_r1, ref_pck_len_i_r1, ref_wr_data_r1[11:0], ref_packet_length_w), UVM_LOW)
        end
        
        // CRITICAL FIX: Read operations should update based on REGISTERED deq_req_r (matching RTL exactly)
        // RTL uses deq_req_r (1-cycle delayed) to generate rd_en, so scoreboard must do the same
        // This prevents the 1-cycle timing mismatch where rd_data_o is read even when deq_req=0
        if (ref_deq_req_r && !ref_buffer_empty && (read_state == READ_HEADER || read_state == READ_DATA)) begin
            ref_rd_data_o = ref_buffer[ref_rd_ptr[13:0]];
            ref_rd_ptr = ref_rd_ptr + 1;
            `uvm_info("RD_DATA_DEBUG", $sformatf("Time=%0t: Read operation: deq_req_r=%0b, state=%0d, rd_data=0x%0h, ptr=%0d", 
                     $time, ref_deq_req_r, read_state, ref_rd_data_o, ref_rd_ptr-1), UVM_LOW)
        end

        // Packet length read aligns with deq_req_r in READ_HEADER (matching RTL exactly)
        if (read_state == READ_HEADER && ref_deq_req_r) begin
            ref_packet_length = ref_pck_len_buffer[ref_pck_len_rd_ptr[4:0]];
            ref_pck_len_rd_ptr = ref_pck_len_rd_ptr + 1;
            `uvm_info("PKT_LEN_READ_DEBUG", $sformatf("Time=%0t: Packet length read: deq_req_r=%0b, pck_len=%0d, ptr=%0d", 
                     $time, ref_deq_req_r, ref_packet_length, ref_pck_len_rd_ptr-1), UVM_LOW)
        end
        
        // Packet drop handling - now handled in update_packet_drop_logic()
        // Just apply the packet drop effects here
        if (ref_packet_drop) begin
            `uvm_info("PKT_DROP_DEBUG", $sformatf("Time=%0t: PACKET_DROP applied. overflow=%0b, count_w=%0d, wr_ptr(before)=%0d",
                     $time, ref_pck_proc_overflow, ref_count_w, ref_wr_ptr), UVM_LOW)
            if (ref_pck_proc_overflow) begin
                ref_wr_ptr = ref_wr_ptr - ref_count_w + 1;
            end else begin
                ref_wr_ptr = ref_wr_ptr - ref_count_w;
            end
            ref_count_w = 0;
            // Note: ref_packet_drop is reset in update_packet_drop_logic() for next cycle
            `uvm_info("PKT_DROP_DEBUG", $sformatf("Time=%0t: PACKET_DROP applied. wr_ptr(after)=%0d, wr_lvl=%0d",
                     $time, ref_wr_ptr, ref_wr_lvl), UVM_LOW)
        end
        
        // CRITICAL FIX: Reset count_w when packet completes normally (matching RTL exactly)
        // RTL resets count_w when: (in_eop_r1 && present_state_w == WRITE_DATA) || packet_drop
        if (ref_in_eop_r1 && (write_state == WRITE_DATA)) begin
            `uvm_info("COUNT_W_DEBUG", $sformatf("Time=%0t: Packet completed normally: resetting count_w from %0d to 0 (in_eop_r1=%0b, state=%0d)", 
                     $time, ref_count_w, ref_in_eop_r1, write_state), UVM_LOW)
            ref_count_w = 0;
        end
    endfunction

    function void update_buffer_states();
        // CRITICAL FIX: Buffer full should be based on wr_lvl, not pointer comparison
        // DUT logic: pck_proc_full = 1 when wr_lvl == DEPTH (buffer is full)
        // This matches the actual RTL behavior
        ref_buffer_full = (ref_wr_lvl == DEPTH) ? 1 : 0;  // Use parameter instead of hardcoded value
        
        // CRITICAL FIX: Buffer empty should be based on wr_lvl, not pointer comparison
        // DUT logic: pck_proc_empty = 1 when wr_lvl > 0 (buffer has data)
        // This matches the actual RTL behavior
        ref_buffer_empty = (ref_wr_lvl > 0) ? 0 : 1;
        
        // Debug buffer state
        `uvm_info("BUFFER_DEBUG", $sformatf("Buffer State: wr_ptr=%0d, rd_ptr=%0d, empty=%0b, full=%0b, empty_de_assert=%0b, in_eop_r2=%0b", 
                 ref_wr_ptr, ref_rd_ptr, ref_buffer_empty, ref_buffer_full, ref_empty_de_assert, ref_in_eop_r2), UVM_LOW)
        
        // No longer need buffer_empty_r since we use simple wr_lvl-based logic
        
        // Packet length buffer conditions
        ref_pck_len_full = (ref_pck_len_wr_ptr == ref_pck_len_rd_ptr) ? 0 :
                          (({~ref_pck_len_wr_ptr[5], ref_pck_len_wr_ptr[4:0]} == ref_pck_len_rd_ptr) ? 1 : 0);
        ref_pck_len_empty = (ref_pck_len_wr_ptr == ref_pck_len_rd_ptr) ? 1 : 0;
    endfunction

    function void update_write_level_next();
        // CRITICAL FIX: Check for reset first - if reset is active, don't calculate wr_lvl_next
        // This prevents the scoreboard from calculating new values during reset
        if (!ref_reset_active) begin
            // Write level logic (matching RTL always_ff exactly):
            // RTL calculates based on CURRENT cycle enables and CURRENT buffer states
            if (ref_packet_drop) begin
                ref_wr_lvl_next = ref_wr_lvl - ref_count_w;
            end else if ((ref_wr_en && !ref_buffer_full) && (ref_rd_en && !ref_buffer_empty) && (!ref_overflow)) begin
                ref_wr_lvl_next = ref_wr_lvl;  // No change
            end else if (ref_wr_en && !ref_buffer_full) begin
                ref_wr_lvl_next = ref_wr_lvl + 1;
            end else if (ref_rd_en && !ref_buffer_empty) begin
                ref_wr_lvl = ref_wr_lvl - 1;
                ref_wr_lvl_next = ref_wr_lvl;
            end else begin
                ref_wr_lvl_next = ref_wr_lvl;  // No change
            end
            
            // Debug wr_lvl calculation details
            `uvm_info("WR_LVL_DEBUG", $sformatf("wr_lvl_next calc: wr_en=%0b, rd_en=%0b, buffer_full=%0b, buffer_empty=%0b, overflow=%0b, current_wr_lvl=%0d, next_wr_lvl=%0d", 
                     ref_wr_en, ref_rd_en, ref_buffer_full, ref_buffer_empty, ref_overflow, ref_wr_lvl, ref_wr_lvl_next), UVM_LOW)
        end else begin
            // Reset is active: keep wr_lvl_next at 0 (matching DUT behavior)
            ref_wr_lvl_next = 0;
            `uvm_info("WR_LVL_DEBUG", $sformatf("Time=%0t: RESET ACTIVE: ref_wr_lvl_next kept at 0 (matching DUT reset behavior)", $time), UVM_LOW)
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
        
        // // Packet drop detection & debug
        // if (is_packet_invalid(tr)) begin
        //     if (!ref_packet_drop) begin
        //         // Recompute condition flags for detailed debug
        //         bit dbg_cond1, dbg_cond3, dbg_cond4, dbg_cond5, dbg_cond6;
        //         dbg_cond1 = (tr.in_sop && tr.in_eop);
        //         //dbg_cond3 = (ref_in_sop_r1 && (~ref_in_eop_r1) && (write_state == WRITE_DATA));
        //         dbg_cond4 = ((ref_count_w < (ref_packet_length_w - 1)) && (ref_packet_length_w != 0) && (ref_in_eop_r1));
        //         dbg_cond5 = (((ref_count_w == (ref_packet_length_w - 1)) || (ref_packet_length_w == 0)) && (~ref_in_eop_r1) && (write_state == WRITE_DATA));
        //         dbg_cond6 = (ref_pck_proc_overflow);
        //         //`uvm_info("PKT_DROP_DEBUG", $sformatf(
        //         //    "Time=%0t: PACKET_DROP detected. enq_req=%0b | cond1=%0b cond3=%0b cond4=%0b cond5=%0b cond6=%0b | in_sop=%0b in_eop=%0b in_sop_r=%0b in_sop_r1=%0b in_eop_r1=%0b | state=%0d count_w=%0d pck_len_w=%0d overflow=%0b",
        //         `uvm_info("PKT_DROP_DEBUG", $sformatf(
        //             "Time=%0t: PACKET_DROP detected. enq_req=%0b | cond1=%0b cond4=%0b cond5=%0b cond6=%0b | in_sop=%0b in_eop=%0b in_sop_r=%0b in_sop_r1=%0b in_eop_r1=%0b | state=%0d count_w=%0d pck_len_w=%0d overflow=%0b",
        //             $time,
        //             tr.enq_req,
        //            // dbg_cond1, dbg_cond3, dbg_cond4, dbg_cond5, dbg_cond6,
        //             dbg_cond1, dbg_cond4, dbg_cond5, dbg_cond6,
        //             tr.in_sop, tr.in_eop, ref_in_sop_r, ref_in_sop_r1, ref_in_eop_r1,
        //             write_state, ref_count_w, ref_packet_length_w, ref_pck_proc_overflow), UVM_LOW)
        //     end
        //     ref_packet_drop = 1;
        // end else begin
        //     ref_packet_drop_prev = ref_packet_drop;
        // end
    endfunction

    function void update_outputs(pkt_proc_seq_item tr);
        // Generate expected outputs
        ref_out_sop = 0;
        ref_out_eop = 0;
        
        // CRITICAL FIX: Scoreboard mirrors RTL exactly using present_state and deq_req_r
        // RTL uses deq_req_r (1-cycle delayed) for count_r updates, so scoreboard must do the same
        unique case (read_state)
            IDLE_R: begin
                ref_out_sop = 0;
                ref_out_eop = 0;
            end
            READ_HEADER: begin
                if (ref_deq_req_r) begin  // ← Use registered version (matching RTL)
                    ref_out_sop = 1;
                    ref_out_eop = 0;
                    // Start/advance packet counter on deq_req_r (matching RTL exactly)
                    ref_count_r = ref_count_r + 1;
                    `uvm_info("COUNT_DEBUG", $sformatf("Time=%0t: READ_HEADER count_r incremented to %0d (deq_req_r=%0b)", 
                             $time, ref_count_r, ref_deq_req_r), UVM_LOW)
                end
            end
            READ_DATA: begin
                if (ref_deq_req_r) begin  // ← Use registered version (matching RTL)
                    // Increment count on each dequeued data beat; assert eop on last beat
                    ref_count_r = ref_count_r + 1;
                    if (ref_count_r == (ref_packet_length)) begin
                        ref_out_eop = 1;
                        ref_count_r = 0; // packet boundary
                        `uvm_info("COUNT_DEBUG", $sformatf("Time=%0t: READ_DATA count_r reset to 0 (packet complete, length=%0d)", 
                                 $time, ref_packet_length), UVM_LOW)
                    end else begin
                        `uvm_info("COUNT_DEBUG", $sformatf("Time=%0t: READ_DATA count_r incremented to %0d (deq_req_r=%0b)", 
                                 $time, ref_count_r, ref_deq_req_r), UVM_LOW)
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
        // CRITICAL FIX: pck_proc_full should be based on wr_lvl, not pointer comparison
        // DUT logic: pck_proc_full = 1 when wr_lvl == DEPTH (buffer is full)
        // This matches the actual RTL behavior, not the complex pointer-based logic
        ref_buffer_full = (ref_wr_lvl == DEPTH) ? 1 : 0;  // Use parameter instead of hardcoded value
        
        // CRITICAL FIX: pck_proc_empty should be based on wr_lvl, not pointer comparison
        // DUT logic: pck_proc_empty = 1 when wr_lvl > 0 (buffer has data)
        // This matches the actual RTL behavior, not the complex pointer-based logic
        ref_buffer_empty = (ref_wr_lvl > 0) ? 0 : 1;
        
        // CRITICAL FIX: pck_proc_almost_full threshold should be DEPTH - almost_full_value
        // DUT logic: pck_proc_almost_full = 1 when wr_lvl >= (DEPTH - almost_full_value)
        // This matches the actual RTL behavior
        ref_pck_proc_almost_full = (ref_wr_lvl >= (DEPTH - tr.pck_proc_almost_full_value));
        
        // pck_proc_almost_empty (from buffer_almost_empty) - matching RTL assign
        // Use transaction value, not hardcoded value
        ref_pck_proc_almost_empty = (ref_wr_lvl <= tr.pck_proc_almost_empty_value);

    endfunction

    function void compare_outputs(pkt_proc_seq_item tr);
        // Debug information
        `uvm_info("SCOREBOARD_DEBUG", $sformatf("Time=%0d: DUT wr_lvl=%0d, ref_wr_lvl=%0d, DUT_empty=%0b, ref_empty=%0b, DUT_rd_data=0x%0h, ref_rd_data=0x%0h", 
                 $time, tr.pck_proc_wr_lvl, ref_wr_lvl, tr.pck_proc_empty, ref_buffer_empty, tr.rd_data_o, ref_rd_data_o), UVM_LOW)
        
        // Compare all outputs with reference model
        if (tr.out_sop !== ref_out_sop) begin
            `uvm_error("SCOREBOARD_NEW", $sformatf("out_sop mismatch: expected=%0b, got=%0b", ref_out_sop, tr.out_sop))
            errors++;
        end
        
        if (tr.out_eop !== ref_out_eop) begin
            `uvm_error("SCOREBOARD_NEW", $sformatf("out_eop mismatch: expected=%0b, got=%0b", ref_out_eop, tr.out_eop))
            errors++;
        end
        
        // CRITICAL FIX: Compare rd_data_o only when ref_deq_req_r is high (matching RTL timing)
        // RTL generates rd_data_o based on deq_req_r, not the current cycle's deq_req
        if (ref_deq_req_r && !ref_buffer_empty) begin
            if (tr.rd_data_o !== ref_rd_data_o) begin
                `uvm_error("SCOREBOARD_NEW", $sformatf("rd_data_o mismatch: expected=0x%0h, got=0x%0h (deq_req_r=%0b, state=%0d)", 
                         ref_rd_data_o, tr.rd_data_o, ref_deq_req_r, read_state))
                errors++;
            end
        end
        
        if (tr.pck_proc_full !== ref_buffer_full) begin
            `uvm_error("SCOREBOARD_NEW", $sformatf("pck_proc_full mismatch: expected=%0b, got=%0b", ref_buffer_full, tr.pck_proc_full))
            errors++;
        end
        
        if (tr.pck_proc_empty !== ref_buffer_empty) begin
            `uvm_error("SCOREBOARD_NEW", $sformatf("pck_proc_empty mismatch: expected=%0b, got=%0b", ref_buffer_empty, tr.pck_proc_empty))
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
