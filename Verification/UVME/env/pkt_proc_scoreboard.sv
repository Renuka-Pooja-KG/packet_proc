class pkt_proc_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(pkt_proc_scoreboard)

    uvm_analysis_imp #(pkt_proc_seq_item, pkt_proc_scoreboard) analysis_export;

    // Reference model state machines (matching RTL)
    typedef enum {IDLE_W, WRITE_HEADER, WRITE_DATA, ERROR} write_state_e;
    typedef enum {IDLE_R, READ_HEADER, READ_DATA} read_state_e;
    
    write_state_e write_state;
    read_state_e read_state;
    
    // Reference model internal signals (matching RTL)
    bit [31:0] ref_buffer[0:16383];  // 16384 deep buffer
    bit [11:0] ref_pck_len_buffer[0:31];  // 32 deep packet length buffer
    bit [14:0] ref_wr_ptr, ref_rd_ptr;
    bit [14:0] ref_pck_len_wr_ptr, ref_pck_len_rd_ptr;
    bit [14:0] ref_wr_lvl;
    bit [11:0] ref_count_w, ref_count_r;
    bit [11:0] ref_packet_length;
    bit ref_buffer_full, ref_buffer_empty;
    bit ref_pck_len_full, ref_pck_len_empty;
    bit ref_pck_proc_overflow, ref_pck_proc_underflow;
    bit ref_packet_drop;
    
    // Packet tracking
    bit ref_in_packet;
    bit [11:0] ref_curr_packet_length;
    bit [31:0] ref_expected_data[$];
    int ref_data_count;
    
    // Expected outputs
    bit ref_out_sop, ref_out_eop;
    bit [31:0] ref_rd_data_o;
    bit ref_pck_proc_almost_full, ref_pck_proc_almost_empty;
    
    // Registered signals (matching RTL pipeline)
    bit ref_in_sop_r, ref_in_sop_r1, ref_in_sop_r2;
    bit ref_in_eop_r, ref_in_eop_r1, ref_in_eop_r2;
    bit ref_enq_req_r, ref_enq_req_r1;
    bit [31:0] ref_wr_data_r, ref_wr_data_r1;
    bit ref_pck_len_valid_r, ref_pck_len_valid_r1;
    bit [11:0] ref_pck_len_i_r, ref_pck_len_i_r1;
    bit ref_deq_req_r;
    
    // Configuration
    parameter int DEPTH = 16384;
    parameter int PCK_LEN_DEPTH = 32;
    parameter int DATA_WIDTH = 32;
    parameter int ADDR_WIDTH = 14;
    parameter int PCK_LEN = 12;

    // Statistics - based on actual operations
    int total_transaction_count = 0;
    int write_operation_count = 0;
    int read_operation_count = 0;
    int concurrent_operation_count = 0;
    int error_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        initialize_reference_model();
    endfunction

    function void initialize_reference_model();
        write_state = IDLE_W;
        read_state = IDLE_R;
        ref_in_packet = 0;
        ref_wr_ptr = 0;
        ref_rd_ptr = 0;
        ref_pck_len_wr_ptr = 0;
        ref_pck_len_rd_ptr = 0;
        ref_wr_lvl = 0;
        ref_count_w = 0;
        ref_count_r = 0;
        ref_packet_length = 0;
        ref_buffer_full = 0;
        ref_buffer_empty = 1;
        ref_pck_len_full = 0;
        ref_pck_len_empty = 1;
        ref_pck_proc_overflow = 0;
        ref_pck_proc_underflow = 0;
        ref_packet_drop = 0;
        ref_curr_packet_length = 0;
        ref_data_count = 0;
        ref_expected_data.delete();
        
        // Initialize registered signals
        ref_in_sop_r = 0; ref_in_sop_r1 = 0; ref_in_sop_r2 = 0;
        ref_in_eop_r = 0; ref_in_eop_r1 = 0; ref_in_eop_r2 = 0;
        ref_enq_req_r = 0; ref_enq_req_r1 = 0;
        ref_wr_data_r = 0; ref_wr_data_r1 = 0;
        ref_pck_len_valid_r = 0; ref_pck_len_valid_r1 = 0;
        ref_pck_len_i_r = 0; ref_pck_len_i_r1 = 0;
        ref_deq_req_r = 0;
    endfunction

    // Simplified transaction handler - no op_type needed!
    function void write(pkt_proc_seq_item tr);
        total_transaction_count++;
        
        // Update statistics based on actual signals (much simpler!)
        if (tr.enq_req && tr.deq_req) begin
            concurrent_operation_count++;
        end else if (tr.enq_req) begin
            write_operation_count++;
        end else if (tr.deq_req) begin
            read_operation_count++;
        end
        
        `uvm_info("SCOREBOARD", $sformatf("Processing transaction #%0d: %s", total_transaction_count, tr.sprint()), UVM_LOW)
        
        // Update reference model based on actual signals
        update_reference_model(tr);
        
        // Compare outputs
        compare_outputs(tr);
    endfunction

    function void update_reference_model(pkt_proc_seq_item tr);
        // Always update registered signals (matching RTL pipeline)
        ref_in_sop_r1 = tr.in_sop;
        ref_in_sop_r = ref_in_sop_r1;
        ref_in_sop_r2 = ref_in_sop_r;
        
        ref_in_eop_r1 = tr.in_eop;
        ref_in_eop_r = ref_in_eop_r1;
        ref_in_eop_r2 = ref_in_eop_r;
        
        ref_enq_req_r = tr.enq_req;
        ref_enq_req_r1 = ref_enq_req_r;
        
        ref_wr_data_r1 = tr.wr_data_i;
        ref_wr_data_r = ref_wr_data_r1;
        
        ref_pck_len_valid_r1 = tr.pck_len_valid;
        ref_pck_len_valid_r = ref_pck_len_valid_r1;
        
        ref_pck_len_i_r1 = tr.pck_len_i;
        ref_pck_len_i_r = ref_pck_len_i_r1;
        
        ref_deq_req_r = tr.deq_req;
        
        // Update write FSM if write operation is happening (much simpler!)
        if (tr.enq_req) begin
            update_write_fsm(tr);
            
            // Check for invalid packets
            if (is_packet_invalid(tr)) begin
                ref_packet_drop = 1;
            end
            
            // Update write buffer operations
            update_write_buffer_operations(tr);
        end
        
        // Update read FSM if read operation is happening (much simpler!)
        if (tr.deq_req) begin
            update_read_fsm(tr);
            
            // Update read buffer operations
            update_read_buffer_operations(tr);
            
            // Update read outputs
            update_read_outputs(tr);
        end
        
        // CRITICAL: Update buffer full/empty conditions BEFORE overflow/underflow detection
        update_buffer_full_empty();
        
        // Now update overflow/underflow detection with correct buffer states
        if (tr.enq_req) begin
            update_overflow_detection(tr);
        end
        
        if (tr.deq_req) begin
            update_underflow_detection(tr);
        end
    endfunction

    function void update_write_fsm(pkt_proc_seq_item tr);
        // Write FSM state transitions (matching RTL)
        case (write_state)
            IDLE_W: begin
                if (ref_enq_req_r && ref_in_sop_r1) begin
                    write_state = WRITE_HEADER;
                end
            end
            
            WRITE_HEADER: begin
                if (ref_in_sop_r1) begin
                    write_state = WRITE_HEADER;  // Stay in header state
                end else if (is_packet_invalid(tr)) begin
                    write_state = ERROR;
                end else begin
                    write_state = WRITE_DATA;
                end
            end
            
            WRITE_DATA: begin
                if (ref_in_sop_r1 && ref_enq_req_r) begin
                    write_state = WRITE_HEADER;  // New packet starts
                end else if (ref_in_eop_r1 && !ref_in_sop_r1 && !ref_enq_req_r) begin
                    write_state = IDLE_W;  // Packet ends
                end else begin
                    write_state = WRITE_DATA;  // Continue data
                end
            end
            
            ERROR: begin
                write_state = IDLE_W;  // Return to idle after error
            end
        endcase
    endfunction

    function void update_read_fsm(pkt_proc_seq_item tr);
        // Read FSM state transitions (matching RTL)
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
                    read_state = IDLE_R;  // End of packet, no more deq
                end else begin
                    read_state = READ_DATA;  // Continue reading
                end
            end
        endcase
    endfunction

    function bit is_packet_invalid(pkt_proc_seq_item tr);
        // Invalid packet conditions (matching RTL logic)
        bit invalid = 0;
        
        // Condition 1: in_sop and in_eop high at same time
        if (tr.in_sop && tr.in_eop) invalid = 1;
        
        // Condition 2: Back-to-back in_sop without in_eop
        if (ref_in_sop_r && ref_in_sop_r1) invalid = 1;
        
        // Condition 3: in_sop during WRITE_DATA state
        if (tr.in_sop && (write_state == WRITE_DATA) && !ref_in_eop_r1) invalid = 1;
        
        // Condition 4: Early in_eop (count < packet_length - 1)
        if (ref_in_eop_r1 && (ref_count_w < ref_packet_length - 1) && (ref_packet_length != 0)) invalid = 1;
        
        // Condition 5: Late in_eop (count == packet_length - 1 but no in_eop)
        if (!ref_in_eop_r1 && (ref_count_w == ref_packet_length - 1) && (write_state == WRITE_DATA)) invalid = 1;
        
        // Condition 6: Overflow condition
        if (ref_pck_proc_overflow) invalid = 1;
        
        // Condition 7: Invalid packet length (0 or 1)
        if (tr.pck_len_valid && (tr.pck_len_i <= 1)) invalid = 1;
        
        return invalid;
    endfunction

    function void update_write_buffer_operations(pkt_proc_seq_item tr);
        // Write operations
        if (ref_enq_req_r && !ref_buffer_full && write_state != ERROR) begin
            if (write_state == WRITE_HEADER) begin
                // Write header data
                ref_buffer[ref_wr_ptr[13:0]] = ref_wr_data_r1;
                ref_pck_len_buffer[ref_pck_len_wr_ptr[4:0]] = 
                    (ref_pck_len_valid_r1) ? ref_pck_len_i_r1 : ref_wr_data_r1[11:0];
                ref_pck_len_wr_ptr = ref_pck_len_wr_ptr + 1;
            end else if (write_state == WRITE_DATA) begin
                // Write data
                ref_buffer[ref_wr_ptr[13:0]] = ref_wr_data_r1;
            end
            
            if (write_state == WRITE_HEADER || write_state == WRITE_DATA) begin
                ref_wr_ptr = ref_wr_ptr + 1;
                ref_wr_lvl = ref_wr_lvl + 1;
                ref_count_w = ref_count_w + 1;
            end
        end
        
        // Packet drop handling
        if (ref_packet_drop) begin
            // Rollback write pointer and level
            ref_wr_ptr = ref_wr_ptr - ref_count_w;
            ref_wr_lvl = ref_wr_lvl - ref_count_w;
            ref_count_w = 0;
            ref_packet_drop = 0;
        end
    endfunction

    function void update_read_buffer_operations(pkt_proc_seq_item tr);
        // Read operations
        if (ref_deq_req_r && !ref_buffer_empty && (read_state == READ_HEADER || read_state == READ_DATA)) begin
            ref_rd_data_o = ref_buffer[ref_rd_ptr[13:0]];
            ref_rd_ptr = ref_rd_ptr + 1;
            ref_wr_lvl = ref_wr_lvl - 1;
            ref_count_r = ref_count_r + 1;
            
            if (read_state == READ_HEADER) begin
                ref_packet_length = ref_pck_len_buffer[ref_pck_len_rd_ptr[4:0]];
                ref_pck_len_rd_ptr = ref_pck_len_rd_ptr + 1;
                ref_count_r = 0;  // Reset read counter for new packet
            end
        end
    endfunction

    function void update_read_outputs(pkt_proc_seq_item tr);
        // Generate expected outputs based on read FSM state
        ref_out_sop = 0;
        ref_out_eop = 0;
        
        if (read_state == READ_HEADER && ref_deq_req_r) begin
            ref_out_sop = 1;
        end else if (read_state == READ_DATA && ref_deq_req_r) begin
            if (ref_count_r == (ref_packet_length - 1)) begin
                ref_out_eop = 1;
            end
        end
        
        // Update almost full/empty
        ref_pck_proc_almost_full = (ref_wr_lvl >= DEPTH - tr.pck_proc_almost_full_value);
        ref_pck_proc_almost_empty = (ref_wr_lvl <= tr.pck_proc_almost_empty_value);
    endfunction

    function void update_buffer_full_empty();
        // Buffer full condition (matching RTL logic)
        ref_buffer_full = (ref_wr_ptr == ref_rd_ptr) ? 0 : 
                         (({~ref_wr_ptr[14], ref_wr_ptr[13:0]} == ref_rd_ptr) ? 1 : 0);
        
        // Buffer empty condition (matching RTL logic)
        ref_buffer_empty = (ref_wr_ptr == ref_rd_ptr) ? 1 : 0;
        
        // Packet length buffer conditions
        ref_pck_len_full = (ref_pck_len_wr_ptr == ref_pck_len_rd_ptr) ? 0 :
                          (({~ref_pck_len_wr_ptr[5], ref_pck_len_wr_ptr[4:0]} == ref_pck_len_rd_ptr) ? 1 : 0);
        ref_pck_len_empty = (ref_pck_len_wr_ptr == ref_pck_len_rd_ptr) ? 1 : 0;
    endfunction
    
    function void update_overflow_detection(pkt_proc_seq_item tr);
        // Overflow detection
        if (ref_enq_req_r && ref_buffer_full) begin
            ref_pck_proc_overflow = 1;
        end else begin
            ref_pck_proc_overflow = 0;
        end
    endfunction

    function void update_underflow_detection(pkt_proc_seq_item tr);
        // Underflow detection
        if (ref_deq_req_r && ref_buffer_empty) begin
            ref_pck_proc_underflow = 1;
        end else begin
            ref_pck_proc_underflow = 0;
        end
    endfunction

    

    function void compare_outputs(pkt_proc_seq_item tr);
        // Compare all outputs with reference model
        if (tr.out_sop !== ref_out_sop) begin
            `uvm_error("SIMPLIFIED_SCOREBOARD", $sformatf("out_sop mismatch: expected=%0b, got=%0b", ref_out_sop, tr.out_sop))
            error_count++;
        end
        
        if (tr.out_eop !== ref_out_eop) begin
            `uvm_error("SIMPLIFIED_SCOREBOARD", $sformatf("out_eop mismatch: expected=%0b, got=%0b", ref_out_eop, tr.out_eop))
            error_count++;
        end
        
        if (tr.deq_req && !ref_buffer_empty) begin
            if (tr.rd_data_o !== ref_rd_data_o) begin
                `uvm_error("SIMPLIFIED_SCOREBOARD", $sformatf("rd_data_o mismatch: expected=0x%0h, got=0x%0h", ref_rd_data_o, tr.rd_data_o))
                error_count++;
            end
        end
        
        if (tr.pck_proc_full !== ref_buffer_full) begin
            `uvm_error("SIMPLIFIED_SCOREBOARD", $sformatf("pck_proc_full mismatch: expected=%0b, got=%0b", ref_buffer_full, tr.pck_proc_full))
            error_count++;
        end
        
        if (tr.pck_proc_empty !== ref_buffer_empty) begin
            `uvm_error("SIMPLIFIED_SCOREBOARD", $sformatf("pck_proc_empty mismatch: expected=%0b, got=%0b", ref_buffer_empty, tr.pck_proc_empty))
            error_count++;
        end
        
        if (tr.pck_proc_almost_full !== ref_pck_proc_almost_full) begin
            `uvm_error("SIMPLIFIED_SCOREBOARD", $sformatf("pck_proc_almost_full mismatch: expected=%0b, got=%0b", ref_pck_proc_almost_full, tr.pck_proc_almost_full))
            error_count++;
        end
        
        if (tr.pck_proc_almost_empty !== ref_pck_proc_almost_empty) begin
            `uvm_error("SIMPLIFIED_SCOREBOARD", $sformatf("pck_proc_almost_empty mismatch: expected=%0b, got=%0b", ref_pck_proc_almost_empty, tr.pck_proc_almost_empty))
            error_count++;
        end
        
        if (tr.pck_proc_overflow !== ref_pck_proc_overflow) begin
            `uvm_error("SIMPLIFIED_SCOREBOARD", $sformatf("pck_proc_overflow mismatch: expected=%0b, got=%0b", ref_pck_proc_overflow, tr.pck_proc_overflow))
            error_count++;
        end
        
        if (tr.pck_proc_underflow !== ref_pck_proc_underflow) begin
            `uvm_error("SIMPLIFIED_SCOREBOARD", $sformatf("pck_proc_underflow mismatch: expected=%0b, got=%0b", ref_pck_proc_underflow, tr.pck_proc_underflow))
            error_count++;
        end
        
        if (tr.packet_drop !== ref_packet_drop) begin
            `uvm_error("SIMPLIFIED_SCOREBOARD", $sformatf("packet_drop mismatch: expected=%0b, got=%0b", ref_packet_drop, tr.packet_drop))
            error_count++;
        end
        
        if (tr.pck_proc_wr_lvl !== ref_wr_lvl) begin
            `uvm_error("SIMPLIFIED_SCOREBOARD", $sformatf("pck_proc_wr_lvl mismatch: expected=%0d, got=%0d", ref_wr_lvl, tr.pck_proc_wr_lvl))
            error_count++;
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SIMPLIFIED_SCOREBOARD", $sformatf("Simplified Scoreboard Report: Total=%0d, Write=%0d, Read=%0d, Concurrent=%0d, Errors=%0d", 
                  total_transaction_count, write_operation_count, read_operation_count, concurrent_operation_count, error_count), UVM_LOW)
    endfunction

endclass 