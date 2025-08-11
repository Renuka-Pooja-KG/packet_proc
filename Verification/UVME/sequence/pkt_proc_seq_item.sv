//=============================================================================
// File: pkt_proc_seq_item.sv
// Description: Packet Processor UVM Sequence Item
// Author: [Your Name]
// Date: [Date]
//=============================================================================

`ifndef PKT_PROC_SEQ_ITEM_SV
`define PKT_PROC_SEQ_ITEM_SV

class pkt_proc_seq_item extends uvm_sequence_item;

  // Reset signals (shared)
  rand bit pck_proc_int_mem_fsm_rstn;
  rand bit pck_proc_int_mem_fsm_sw_rstn;
  rand bit empty_de_assert;

  // Write operation signals
  rand bit enq_req;
  rand bit in_sop;
  rand bit in_eop;
  rand bit [31:0] wr_data_i;
  rand bit pck_len_valid;
  rand bit [11:0] pck_len_i;

  // Read operation signals
  rand bit deq_req;

  // Configuration signals (shared)
  rand bit [4:0] pck_proc_almost_full_value;
  rand bit [4:0] pck_proc_almost_empty_value;

  // Output signals (from DUT)
  bit out_sop;
  bit [31:0] rd_data_o;
  bit out_eop;
  bit pck_proc_full;
  bit pck_proc_empty;
  bit pck_proc_almost_full;
  bit pck_proc_almost_empty;
  bit pck_proc_overflow;
  bit pck_proc_underflow;
  bit packet_drop;
  bit [14:0] pck_proc_wr_lvl;

//   // Operation type control
//   typedef enum {WRITE_OP, READ_OP, BOTH_OP} operation_type_e;
//   rand operation_type_e op_type;

  // // Write-specific constraints
  // constraint write_protocol_constraints {
  //   // No enq_req when overflow or full
  //   (pck_proc_overflow || pck_proc_full) -> enq_req == 0;
    
  //   // No in_sop and in_eop high at same time
  //   !(in_sop && in_eop);
    
  //   // Packet length must be greater than 1 when valid
  //   (in_sop && pck_len_valid) -> pck_len_i > 1;
    
  //   // When pck_len_valid is high, pck_len_i should be reasonable
  //   pck_len_valid -> pck_len_i inside {[2:4095]};
    
  //   // When in_sop is high, pck_len_valid should typically be high
  //   in_sop -> pck_len_valid dist {1 := 80, 0 := 20};
    
  //   // Ensure empty_de_assert is always disabled
  //   empty_de_assert == 1'b0;
  // }

  // Read-specific constraints
  constraint read_protocol_constraints {
    // No deq_req when underflow or empty
    (pck_proc_underflow || pck_proc_empty) -> deq_req == 0;
  }

  // Operation type constraints
  constraint operation_type_constraints {
    // Almost full/empty values should be reasonable
    pck_proc_almost_full_value inside {[1:31]};
    pck_proc_almost_empty_value inside {[1:31]};
    pck_proc_almost_full_value > pck_proc_almost_empty_value;
  }

//   // Operation-specific signal constraints
//   constraint operation_signals {
//     if (op_type == WRITE_OP) {
//       deq_req == 0;  // No read operation
//     }
//     if (op_type == READ_OP) {
//       enq_req == 0;  // No write operation
//       in_sop == 0;
//       in_eop == 0;
//       wr_data_i == 32'h0;
//       pck_len_valid == 0;
//       pck_len_i == 12'h0;
//     }
//     if (op_type == BOTH_OP) {
//       // Both operations allowed - use protocol constraints
//     }
//   }

  `uvm_object_utils_begin(pkt_proc_seq_item)
    `uvm_field_int(pck_proc_int_mem_fsm_rstn, UVM_ALL_ON)
    `uvm_field_int(pck_proc_int_mem_fsm_sw_rstn, UVM_ALL_ON)
    `uvm_field_int(empty_de_assert, UVM_ALL_ON)
    `uvm_field_int(enq_req, UVM_ALL_ON)
    `uvm_field_int(in_sop, UVM_ALL_ON)
    `uvm_field_int(in_eop, UVM_ALL_ON)
    `uvm_field_int(wr_data_i, UVM_ALL_ON)
    `uvm_field_int(pck_len_valid, UVM_ALL_ON)
    `uvm_field_int(pck_len_i, UVM_ALL_ON)
    `uvm_field_int(deq_req, UVM_ALL_ON)
    `uvm_field_int(pck_proc_almost_full_value, UVM_ALL_ON)
    `uvm_field_int(pck_proc_almost_empty_value, UVM_ALL_ON)
    `uvm_field_int(out_sop, UVM_ALL_ON)
    `uvm_field_int(rd_data_o, UVM_ALL_ON)
    `uvm_field_int(out_eop, UVM_ALL_ON)
    `uvm_field_int(pck_proc_full, UVM_ALL_ON)
    `uvm_field_int(pck_proc_empty, UVM_ALL_ON)
    `uvm_field_int(pck_proc_almost_full, UVM_ALL_ON)
    `uvm_field_int(pck_proc_almost_empty, UVM_ALL_ON)
    `uvm_field_int(pck_proc_overflow, UVM_ALL_ON)
    `uvm_field_int(pck_proc_underflow, UVM_ALL_ON)
    `uvm_field_int(packet_drop, UVM_ALL_ON)
    `uvm_field_int(pck_proc_wr_lvl, UVM_ALL_ON)
    //`uvm_field_enum(operation_type_e, op_type, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "enhanced_pkt_proc_seq_item");
    super.new(name);
  endfunction

//   function string convert2string();
//     string op_str;
//     case (op_type)
//       WRITE_OP: op_str = "WRITE";
//       READ_OP: op_str = "READ";
//       BOTH_OP: op_str = "BOTH";
//     endcase
    
//     return $sformatf("Enhanced_Item[%s]: enq_req=%0b, deq_req=%0b, in_sop=%0b, in_eop=%0b, out_sop=%0b, out_eop=%0b, wr_data=0x%0h, rd_data=0x%0h, full=%0b, empty=%0b", 
//                      op_str, enq_req, deq_req, in_sop, in_eop, out_sop, out_eop, wr_data_i, rd_data_o, pck_proc_full, pck_proc_empty);
//   endfunction

//   // Helper functions for specific operations
//   function void set_write_operation();
//     op_type = WRITE_OP;
//   endfunction

//   function void set_read_operation();
//     op_type = READ_OP;
//   endfunction

//   function void set_both_operation();
//     op_type = BOTH_OP;
//   endfunction

endclass 

`endif // PKT_PROC_SEQ_ITEM_SV 