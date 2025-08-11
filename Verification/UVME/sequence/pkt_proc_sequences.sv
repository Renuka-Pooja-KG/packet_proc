//=============================================================================
// File: pkt_proc_sequences.sv
// Description: Packet Processor UVM Sequences with Proper Protocol Handling
// Author: [Your Name]
// Date: [Date]
//=============================================================================

`ifndef PKT_PROC_SEQUENCES_SV
`define PKT_PROC_SEQUENCES_SV

// Base sequence for Packet Processor with scenario-based testing
class pkt_proc_base_sequence extends uvm_sequence #(pkt_proc_seq_item);
  `uvm_object_utils(pkt_proc_base_sequence)

  // Configuration parameters
  int num_transactions = 10;
  int scenario = 0; // 0: random, 1: reset, 2: write_only, 3: read_only, 4: concurrent_rw
                    // 5: packet_write, 6: continuous_read, 7: mixed_ops, 8: overflow, 9: underflow
                    // 10: async_reset, 11: sync_reset, 12: dual_reset, 13: reset_during_packet, 14: reset_during_read
  
  // Reset configuration
  int reset_cycles = 5;    // Number of clock cycles to hold reset
  int idle_cycles = 3;     // Number of idle cycles after reset
  bit enable_reset = 1;    // Enable/disable reset initialization
  
  // Fixed configuration values (not randomized per transaction)
  bit [4:0] almost_full_value = 5'd28;   // Fixed almost full threshold
  bit [4:0] almost_empty_value = 5'd4;   // Fixed almost empty threshold
  
  // Packet configuration
  int packet_count = 5;
  int min_packet_length = 4;
  int max_packet_length = 16;
  int current_packet_length;
  int current_packet_word_count;
  
  // Transaction handle
  pkt_proc_seq_item tr;
  
  function new(string name = "pkt_proc_base_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), $sformatf("Starting pkt_proc_base_sequence with %0d transactions, scenario=%0d", num_transactions, scenario), UVM_LOW)
    case (scenario)
      0: random_scenario();
      1: reset_scenario();
      2: write_only_scenario();
      3: read_only_scenario();
      4: concurrent_rw_scenario();
      5: packet_write_scenario();
      6: continuous_read_scenario();
      7: mixed_ops_scenario();
      8: overflow_scenario();
      9: underflow_scenario();
      10: async_reset_scenario();
      11: sync_reset_scenario();
      12: dual_reset_scenario();
      13: reset_during_packet_scenario();
      14: reset_during_read_scenario();
      default: random_scenario();
    endcase
    `uvm_info(get_type_name(), "pkt_proc_base_sequence completed", UVM_LOW)
  endtask

  // Initialize DUT with proper reset sequence
  virtual task initialize_dut();
    if (!enable_reset) return;
    
    `uvm_info("SEQUENCE_BASE", $sformatf("Initializing DUT with %0d reset cycles", reset_cycles), UVM_LOW)
    
    // Phase 1: Apply both resets
    send_reset_transaction(1'b0, 1'b1, reset_cycles);
    
    // Phase 2: De-assert resets
    send_reset_transaction(1'b1, 1'b0, 1);
    
    // Phase 3: Idle cycles after reset
    send_idle_transaction(idle_cycles);
    
    `uvm_info("SEQUENCE_BASE", "DUT initialization completed", UVM_LOW)
  endtask

  // Helper task to send reset transactions
  task send_reset_transaction(bit async_rstn, bit sync_rstn, int cycles);
    repeat(cycles) begin
      tr = pkt_proc_seq_item::type_id::create("tr_reset");
      start_item(tr);
      tr.pck_proc_int_mem_fsm_rstn = async_rstn;
      tr.pck_proc_int_mem_fsm_sw_rstn = sync_rstn;
      // All other fields can take any value (left unassigned)
      finish_item(tr);
    end
  endtask

  // Helper task to send idle transactions
  task send_idle_transaction(int cycles);
    repeat(cycles) begin
          tr = pkt_proc_seq_item::type_id::create("tr_idle");
    start_item(tr);
    tr.pck_proc_int_mem_fsm_rstn = 1'b1;
    tr.pck_proc_int_mem_fsm_sw_rstn = 1'b0;
    tr.empty_de_assert = 1'b0;  // Always disabled
      tr.enq_req = 1'b0;
      tr.deq_req = 1'b0;
      tr.in_sop = 1'b0;
      tr.in_eop = 1'b0;
      tr.wr_data_i = 32'h0;
      tr.pck_len_valid = 1'b0;
      tr.pck_len_i = 12'h0;
      tr.pck_proc_almost_full_value = almost_full_value;
      tr.pck_proc_almost_empty_value = almost_empty_value;
      finish_item(tr);
    end
  endtask

  // Helper task to write a complete packet
  // This version ensures in_eop is set only on the last word (i == pkt_length-1)
  // and handles the single-word packet case correctly.
  task write_packet(int pkt_length, bit [31:0] base_data = 32'hA000);
    `uvm_info(get_type_name(), $sformatf("Writing packet with length %0d", pkt_length), UVM_MEDIUM)

    if (pkt_length <= 0) begin
      `uvm_error(get_type_name(), "Packet length must be >= 1")
      return;
    end

    for (int i = 0; i < pkt_length; i++) begin
      // Calculate packet control signals before transaction creation
      bit is_sop = (i == 0);
      bit is_eop = (i == pkt_length-1);
      string tr_name = is_sop ? "tr_sop" : (is_eop ? "tr_eop" : $sformatf("tr_data_%0d", i));

      tr = pkt_proc_seq_item::type_id::create(tr_name);
      start_item(tr);
      tr.pck_proc_int_mem_fsm_rstn = 1'b1;
      tr.pck_proc_int_mem_fsm_sw_rstn = 1'b0;
      tr.empty_de_assert = 1'b0;
      tr.enq_req = 1'b1;
      tr.deq_req = 1'b0;
      tr.in_sop = is_sop;
      tr.in_eop = is_eop;
      tr.wr_data_i = base_data + i;
      tr.pck_len_valid = is_sop;
      tr.pck_len_i = pkt_length[11:0];
      tr.pck_proc_almost_full_value = almost_full_value;
      tr.pck_proc_almost_empty_value = almost_empty_value;
      finish_item(tr);
    end
  endtask

  // Helper task to perform read operations
  task read_data(int read_count);
    repeat(read_count) begin
      tr = pkt_proc_seq_item::type_id::create("tr_read");
      start_item(tr);
      tr.pck_proc_int_mem_fsm_rstn = 1'b1;
      tr.pck_proc_int_mem_fsm_sw_rstn = 1'b0;
      tr.empty_de_assert = 1'b0;
      tr.enq_req = 1'b0;
      tr.deq_req = 1'b1;
      tr.in_sop = 1'b0;
      tr.in_eop = 1'b0;
      tr.wr_data_i = 32'h0;
      tr.pck_len_valid = 1'b0;
      tr.pck_len_i = 12'h0;
      tr.pck_proc_almost_full_value = almost_full_value;
      tr.pck_proc_almost_empty_value = almost_empty_value;
      finish_item(tr);
    end
  endtask

  // Random scenario with proper constraints
  task random_scenario();
    initialize_dut();
    
    repeat (num_transactions) begin
      tr = pkt_proc_seq_item::type_id::create("tr_random");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1'b1;
        pck_proc_int_mem_fsm_sw_rstn == 1'b0;
        empty_de_assert == 1'b0;  // Always disabled
        pck_proc_almost_full_value == local::almost_full_value;
        pck_proc_almost_empty_value == local::almost_empty_value;
        // Randomize operations but keep protocol valid
        enq_req dist {1 := 60, 0 := 40};
        deq_req dist {1 := 40, 0 := 60};
      });
      finish_item(tr);
      `uvm_info(get_type_name(), $sformatf("Random: enq=%0b deq=%0b sop=%0b eop=%0b", 
                tr.enq_req, tr.deq_req, tr.in_sop, tr.in_eop), UVM_HIGH)
    end
  endtask

  // Reset scenario
  task reset_scenario();
    `uvm_info(get_type_name(), "Starting reset scenario", UVM_LOW)
    
    // Test different reset combinations
    send_reset_transaction(1'b0, 1'b1, 3);  // Both resets
    send_reset_transaction(1'b1, 1'b0, 2);  // Release both
    send_idle_transaction(5);
  endtask

  // Write-only scenario with proper packet structure
  task write_only_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting write-only scenario with %0d packets", packet_count), UVM_LOW)
    
    for (int pkt = 0; pkt < packet_count; pkt++) begin
      current_packet_length = $urandom_range(min_packet_length, max_packet_length);
      write_packet(current_packet_length, 32'hA000 + (pkt << 8));
      
      // Add some idle cycles between packets
      send_idle_transaction(2);
    end
  endtask

  // Read-only scenario
  task read_only_scenario();
    //initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting read-only scenario with %0d reads", num_transactions), UVM_LOW)
    
    read_data(num_transactions);
  endtask

  // Concurrent read/write scenario
  task concurrent_rw_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting concurrent R/W scenario"), UVM_LOW)
    
    // Write some packets first
    for (int pkt = 0; pkt < 3; pkt++) begin
      current_packet_length = $urandom_range(4, 8);
      write_packet(current_packet_length, 32'hB000 + (pkt << 8));
    end
    
    // Then do concurrent operations
    repeat (num_transactions) begin
      tr = pkt_proc_seq_item::type_id::create("tr_concurrent");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1'b1;
        pck_proc_int_mem_fsm_sw_rstn == 1'b0;
        empty_de_assert == 1'b0;
        pck_proc_almost_full_value == local::almost_full_value;
        pck_proc_almost_empty_value == local::almost_empty_value;
        enq_req dist {1 := 30, 0 := 70};
        deq_req dist {1 := 50, 0 := 50};
      });
      finish_item(tr);
    end
  endtask

  // Packet write scenario with structured packets
  task packet_write_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting packet write scenario: %0d packets", packet_count), UVM_LOW)
    
    for (int pkt = 0; pkt < packet_count; pkt++) begin
      current_packet_length = $urandom_range(min_packet_length, max_packet_length);
      `uvm_info(get_type_name(), $sformatf("Writing packet %0d with length %0d", pkt, current_packet_length), UVM_LOW)
      
      write_packet(current_packet_length, 32'hC000 + (pkt << 8));
      
      // Add idle cycles between packets
      send_idle_transaction($urandom_range(1, 3));
    end
  endtask

  // Continuous read scenario
  task continuous_read_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting continuous read scenario: %0d reads", num_transactions), UVM_LOW)
    
    read_data(num_transactions);
  endtask

  // Mixed operations scenario
  task mixed_ops_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting mixed operations scenario"), UVM_LOW)
    
    // Write some packets
    for (int pkt = 0; pkt < 2; pkt++) begin
      write_packet($urandom_range(4, 8), 32'hD000 + (pkt << 8));
    end
    
    // Mixed read/write operations
    repeat (num_transactions) begin
      tr = pkt_proc_seq_item::type_id::create("tr_mixed");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1'b1;
        pck_proc_int_mem_fsm_sw_rstn == 1'b0;
        empty_de_assert == 1'b0;
        pck_proc_almost_full_value == local::almost_full_value;
        pck_proc_almost_empty_value == local::almost_empty_value;
        enq_req dist {1 := 40, 0 := 60};
        deq_req dist {1 := 40, 0 := 60};
      });
      finish_item(tr);
    end
  endtask

  // Overflow scenario - try to fill the buffer
  task overflow_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting overflow scenario"), UVM_LOW)
    
    // Write many packets to cause overflow
    for (int pkt = 0; pkt < 50; pkt++) begin
      write_packet(4, 32'hE000 + pkt);  // Small packets to write many
    end
  endtask

  // Underflow scenario - try to read from empty buffer
  task underflow_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting underflow scenario"), UVM_LOW)
    
    // Try to read from empty buffer
    read_data(num_transactions);
  endtask

  // Async reset scenario with write/read level verification
  task async_reset_scenario();
    `uvm_info(get_type_name(), "Starting async reset scenario with level verification", UVM_LOW)
    
    // Phase 1: Clean start - Assert async reset
    `uvm_info(get_type_name(), "Phase 1: Clean start - Asserting async reset", UVM_LOW)
    send_reset_transaction(1'b0, 1'b0, 5);  // async_rst=0, sync_rst=1 for clean start
    send_reset_transaction(1'b1, 1'b0, 3);  // Release async reset
    
    // Phase 2: Write packets to increment write level
    `uvm_info(get_type_name(), "Phase 2: Writing packets to increment write level", UVM_LOW)
    for (int pkt = 0; pkt < 5; pkt++) begin
      write_packet($urandom_range(4, 8), 32'hA000 + (pkt << 8));
      send_idle_transaction(1);  // Small gap between packets
    end
    
    // Phase 3: Read some data to increment read level
    `uvm_info(get_type_name(), "Phase 3: Reading data to increment read level", UVM_LOW)
    read_data(10);
    
    // Phase 4: Assert async reset while keeping sync reset deasserted
    `uvm_info(get_type_name(), "Phase 4: Asserting async reset (sync reset deasserted)", UVM_LOW)
    send_reset_transaction(1'b0, 1'b0, 5);  // async_rst=0, sync_rst=0 for 5 cycles
    
    // Phase 5: Deassert async reset
    `uvm_info(get_type_name(), "Phase 5: Deasserting async reset", UVM_LOW)
    send_reset_transaction(1'b1, 1'b0, 3);  // async_rst=1, sync_rst=0
    
    // Phase 6: Write more packets to verify DUT is functional
    `uvm_info(get_type_name(), "Phase 6: Writing packets after async reset", UVM_LOW)
    for (int pkt = 0; pkt < 3; pkt++) begin
      write_packet($urandom_range(4, 6), 32'hB000 + (pkt << 8));
      send_idle_transaction(1);
    end
    
    // Phase 7: Read data to verify read functionality
    `uvm_info(get_type_name(), "Phase 7: Reading data after async reset", UVM_LOW)
    read_data(8);
    
    // Phase 8: Apply another async reset
    `uvm_info(get_type_name(), "Phase 8: Applying second async reset", UVM_LOW)
    send_reset_transaction(1'b0, 1'b0, 4);  // async_rst=0, sync_rst=0
    send_reset_transaction(1'b1, 1'b0, 2);  // Release async reset
    
    // Phase 9: Final write/read sequence
    `uvm_info(get_type_name(), "Phase 9: Final write/read sequence", UVM_LOW)
    write_packet(6, 32'hC000);
    read_data(5);
    
    `uvm_info(get_type_name(), "Async reset scenario completed", UVM_LOW)
  endtask

  // Sync reset scenario with write/read level verification
  task sync_reset_scenario();
    `uvm_info(get_type_name(), "Starting sync reset scenario with level verification", UVM_LOW)
    
    // Phase 1: Clean start - Assert async reset
    `uvm_info(get_type_name(), "Phase 1: Clean start - Asserting async reset", UVM_LOW)
    send_reset_transaction(1'b0, 1'b0, 5);  // async_rst=0, sync_rst=0 for clean start
    send_reset_transaction(1'b1, 1'b0, 3);  // Release async reset
    
    // Phase 2: Write packets to increment write level
    `uvm_info(get_type_name(), "Phase 2: Writing packets to increment write level", UVM_LOW)
    for (int pkt = 0; pkt < 5; pkt++) begin
      write_packet($urandom_range(4, 8), 32'hD000 + (pkt << 8));
      send_idle_transaction(1);  // Small gap between packets
    end
    
    // Phase 3: Read some data to increment read level
    `uvm_info(get_type_name(), "Phase 3: Reading data to increment read level", UVM_LOW)
    read_data(10);
    
    // Phase 4: Assert sync reset while keeping async reset deasserted
    `uvm_info(get_type_name(), "Phase 4: Asserting sync reset (async reset deasserted)", UVM_LOW)
    send_reset_transaction(1'b1, 1'b1, 5);  // async_rst=1, sync_rst=1 for 5 cycles
    
    // Phase 5: Deassert sync reset
    `uvm_info(get_type_name(), "Phase 5: Deasserting sync reset", UVM_LOW)
    send_reset_transaction(1'b1, 1'b0, 3);  // async_rst=1, sync_rst=0
    
    // Phase 6: Write more packets to verify DUT is functional
    `uvm_info(get_type_name(), "Phase 6: Writing packets after sync reset", UVM_LOW)
    for (int pkt = 0; pkt < 3; pkt++) begin
      write_packet($urandom_range(4, 6), 32'hE000 + (pkt << 8));
      send_idle_transaction(1);
    end
    
    // Phase 7: Read data to verify read functionality
    `uvm_info(get_type_name(), "Phase 7: Reading data after sync reset", UVM_LOW)
    read_data(8);
    
    // Phase 8: Apply another sync reset
    `uvm_info(get_type_name(), "Phase 8: Applying second sync reset", UVM_LOW)
    send_reset_transaction(1'b1, 1'b1, 4);  // async_rst=1, sync_rst=1
    send_reset_transaction(1'b1, 1'b0, 2);  // Release sync reset
    
    // Phase 9: Final write/read sequence
    `uvm_info(get_type_name(), "Phase 9: Final write/read sequence", UVM_LOW)
    write_packet(6, 32'hF000);
    read_data(5);
    
    `uvm_info(get_type_name(), "Sync reset scenario completed", UVM_LOW)
  endtask

  // Dual reset scenario
  task dual_reset_scenario();
    `uvm_info(get_type_name(), "Starting dual reset scenario", UVM_LOW)
    
    // Normal operations
    initialize_dut();
    write_packet(8, 32'hF400);
    
    // Assert both resets
    send_reset_transaction(1'b0, 1'b1, 5);
    send_reset_transaction(1'b1, 1'b0, 2);
    
    // Continue operations
    write_packet(6, 32'hF500);
  endtask

  // Reset during packet scenario
  task reset_during_packet_scenario();
    `uvm_info(get_type_name(), "Starting reset during packet scenario", UVM_LOW)
    
    initialize_dut();
    
    // Start writing a packet
    current_packet_length = 8;
    
    // Write SOP
    tr = pkt_proc_seq_item::type_id::create("tr_sop");
    start_item(tr);
    tr.pck_proc_int_mem_fsm_rstn = 1'b1;
    tr.pck_proc_int_mem_fsm_sw_rstn = 1'b0;
    tr.empty_de_assert = 1'b0;
    tr.enq_req = 1'b1;
    tr.deq_req = 1'b0;
    tr.in_sop = 1'b1;
    tr.in_eop = 1'b0;
    tr.wr_data_i = 32'hF600;
    tr.pck_len_valid = 1'b1;
    tr.pck_len_i = current_packet_length[11:0];
    tr.pck_proc_almost_full_value = almost_full_value;
    tr.pck_proc_almost_empty_value = almost_empty_value;
    finish_item(tr);
    
    // Write a few data words
    for (int i = 1; i < 4; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_data_%0d", i));
      start_item(tr);
      tr.pck_proc_int_mem_fsm_rstn = 1'b1;
      tr.pck_proc_int_mem_fsm_sw_rstn = 1'b0;
      tr.empty_de_assert = 1'b0;
      tr.enq_req = 1'b1;
      tr.deq_req = 1'b0;
      tr.in_sop = 1'b0;
      tr.in_eop = 1'b0;
      tr.wr_data_i = 32'hF600 + i;
      tr.pck_len_valid = 1'b0;
      tr.pck_len_i = current_packet_length[11:0];
      tr.pck_proc_almost_full_value = almost_full_value;
      tr.pck_proc_almost_empty_value = almost_empty_value;
      finish_item(tr);
    end
    
    // Apply reset during packet transmission
    send_reset_transaction(1'b0, 1'b1, 3);
    send_reset_transaction(1'b1, 1'b0, 2);
    
    // Try to complete the packet (should be dropped)
    write_packet(6, 32'hF700);
  endtask

  // Reset during read scenario
  task reset_during_read_scenario();
    `uvm_info(get_type_name(), "Starting reset during read scenario", UVM_LOW)
    
    initialize_dut();
    
    // Write some data first
    write_packet(8, 32'hF800);
    write_packet(6, 32'hF900);
    
    // Start reading
    read_data(3);
    
    // Apply reset during read
    send_reset_transaction(1'b0, 1'b1, 3);
    send_reset_transaction(1'b1, 1'b0, 2);
    
    // Continue reading (should be empty now)
    read_data(5);
  endtask

endclass

`endif // PKT_PROC_SEQUENCES_SV