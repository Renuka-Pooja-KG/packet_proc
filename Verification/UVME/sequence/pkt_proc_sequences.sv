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

  bit [11:0] remaining_beats = 0;
  bit [7:0] packet_id = 0;
  
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
      15: invalid_1_scenario();
      16: invalid_3_scenario();
      17: invalid_4_scenario();
      18: invalid_5_scenario();
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
      tr.pck_proc_almost_full_value = 5'd28;
      tr.pck_proc_almost_empty_value = 5'd4;
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

    // Helper task to write and read a complete packet
  // This version ensures in_eop is set only on the last word (i == pkt_length-1)
  // and handles the single-word packet case correctly.
  task write_and_read_packet(int pkt_length, bit [31:0] base_data = 32'hA000);
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
      tr.deq_req = 1'b1;
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

  // Concurrent read/write scenario - Technically correct implementation
  task concurrent_rw_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting technically correct concurrent R/W scenario"), UVM_LOW)
    
    // Phase 1: Write initial packets to build up buffer level
    `uvm_info(get_type_name(), "Phase 1: Writing initial packets to build buffer level", UVM_LOW)
    for (int pkt = 0; pkt < 5; pkt++) begin
      current_packet_length = $urandom_range(4, 8);
      write_packet(current_packet_length, 32'hB000 + (pkt << 8));
    end
    
    // Add idle cycles to ensure writes complete
    send_idle_transaction(3);
    
    // Phase 2: Controlled concurrent operations with proper packet boundaries
    `uvm_info(get_type_name(), "Phase 2: Controlled concurrent R/W operations", UVM_LOW)
    
    write_and_read_packet(8, 32'hC000);
    
    // Phase 4: Clean up with idle cycles
    `uvm_info(get_type_name(), "Phase 4: Cleanup with idle cycles", UVM_LOW)
    send_idle_transaction(5);
    
    `uvm_info(get_type_name(), $sformatf("Concurrent R/W scenario completed with %0d packets", packet_id), UVM_LOW)
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

  // Overflow scenario - stop after first overflow occurs
  task overflow_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting overflow scenario - Buffer depth: 16384"), UVM_LOW)
    
    // Phase 1: Fill buffer to near capacity with large packets
    `uvm_info(get_type_name(), "Phase 1: Filling buffer to near capacity", UVM_LOW)
    for (int pkt = 0; pkt < 16; pkt++) begin
      // Each packet: 1 header + 1000 data beats = 1001 beats × 32 bits = 32,032 bits = 4,004 bytes
      // 16 packets × 4,004 bytes = 64,064 bytes (just under buffer capacity of 65,536 bytes)
      // Remaining capacity: 1,472 bytes
      write_packet(1000, 32'hE000 + pkt);
      send_idle_transaction(1);  // Small gap to prevent backpressure issues
    end
    
    // Phase 2: Write one more packet to trigger overflow
    `uvm_info(get_type_name(), "Phase 2: Writing one packet to trigger overflow", UVM_LOW)
    // This packet (4,004 bytes) will overflow the remaining 1,472 bytes by 2,532 bytes
    write_packet(1000, 32'hF000);
    
    // Phase 3: Wait for overflow to be detected and packet drop to occur
    `uvm_info(get_type_name(), "Phase 3: Waiting for overflow detection and packet drop", UVM_LOW)
    send_idle_transaction(5);  // Wait for overflow processing
    
    `uvm_info(get_type_name(), "Overflow scenario completed - First overflow occurred", UVM_LOW)
  endtask

  // Underflow scenario - try to read from empty buffer
  task underflow_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting underflow scenario"), UVM_LOW)
    // Write some packets to fill the buffer
      write_packet(10, 32'hC000);
      send_idle_transaction(10);
    
    // Try to read more than the buffer can hold
    // Try to read from empty buffer
    read_data(12);
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
      write_packet(8, 32'hD000 + (pkt << 8));
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
    send_reset_transaction(1'b1, 1'b0, 5);  // async_rst=1, sync_rst=0
    
    // Phase 6: Write more packets to verify DUT is functional
    `uvm_info(get_type_name(), "Phase 6: Writing packets after sync reset", UVM_LOW)
    for (int pkt = 0; pkt < 3; pkt++) begin
      write_packet(8, 32'hE000 + (pkt << 8));
      send_idle_transaction(1);
    end
    
    // Phase 7: Read data to verify read functionality
    `uvm_info(get_type_name(), "Phase 7: Reading data after sync reset", UVM_LOW)
    read_data(10);
    
    // Phase 8: Apply another sync reset
    `uvm_info(get_type_name(), "Phase 8: Applying second sync reset", UVM_LOW)
    send_reset_transaction(1'b1, 1'b1, 4);  // async_rst=1, sync_rst=1
    send_reset_transaction(1'b1, 1'b0, 2);  // Release sync reset
    
    // Phase 9: Final write/read sequence
    `uvm_info(get_type_name(), "Phase 9: Final write/read sequence", UVM_LOW)
    write_packet(6, 32'hF000);
    read_data(10);
    
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
    tr.pck_proc_almost_full_value = 5'd28;
    tr.pck_proc_almost_empty_value = 5'd4;
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
      tr.pck_proc_almost_full_value = 5'd28;
      tr.pck_proc_almost_empty_value = 5'd4;
      finish_item(tr);
    end
    
    // Apply reset during packet transmission
    send_reset_transaction(1'b0, 1'b1, 3);
    send_reset_transaction(1'b1, 1'b1, 2);
    
    // Try to complete the packet (should be dropped)
    write_packet(6, 32'hF700);
  endtask

  // Reset during read scenario
  task reset_during_read_scenario();
    `uvm_info(get_type_name(), "Starting reset during read scenario", UVM_LOW)
    
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
    tr.wr_data_i = 32'h0005;
    tr.pck_len_valid = 1'b1;
    tr.pck_len_i = 12'h5;
    tr.pck_proc_almost_full_value = 5'd28;
    tr.pck_proc_almost_empty_value = 5'd4;
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
      tr.wr_data_i = 32'h0005 + i;
      tr.pck_len_valid = 1'b0;
      tr.pck_len_i = 12'h5;
      tr.pck_proc_almost_full_value = 5'd28;
      tr.pck_proc_almost_empty_value = 5'd4;
      finish_item(tr);
    end

    // Write EOP
    tr = pkt_proc_seq_item::type_id::create("tr_sop");
    start_item(tr);
    tr.pck_proc_int_mem_fsm_rstn = 1'b1;
    tr.pck_proc_int_mem_fsm_sw_rstn = 1'b0;
    tr.empty_de_assert = 1'b0;
    tr.enq_req = 1'b1;
    tr.deq_req = 1'b0;
    tr.in_sop = 1'b0;
    tr.in_eop = 1'b1;
    tr.wr_data_i = 32'h0005;
    tr.pck_len_valid = 1'b1;
    tr.pck_len_i = 12'h5;
    tr.pck_proc_almost_full_value = 5'd28;
    tr.pck_proc_almost_empty_value = 5'd4;
    finish_item(tr);
    
    send_idle_transaction(5);

    // Read data
    repeat(4) begin
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
          tr.pck_proc_almost_full_value = 5'd28;
          tr.pck_proc_almost_empty_value = 5'd4;
          finish_item(tr);
        end

        // Apply reset during packet transmission
        send_reset_transaction(1'b1, 1'b1, 3);
        send_reset_transaction(1'b1, 1'b0, 2);

        write_packet(6, 32'hF800);
  endtask

  // ============================================================================
  // INVALID CONDITION TEST SEQUENCES
  // ============================================================================

  // Test invalid_1: in_sop && in_eop (start and end of packet simultaneously)
  task invalid_1_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), "Starting invalid_1 scenario - in_sop && in_eop", UVM_LOW)
    
    // Phase 1: Write a normal packet first
    `uvm_info(get_type_name(), "Phase 1: Writing normal packet", UVM_LOW)
    write_packet(5, 32'hA000);
    send_idle_transaction(3);
    
    // Phase 2: Trigger invalid_1 condition
    `uvm_info(get_type_name(), "Phase 2: Triggering invalid_1 (in_sop=1 && in_eop=1)", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_invalid_1");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1'b1;
      pck_proc_int_mem_fsm_sw_rstn == 1'b0;
      empty_de_assert == 1'b0;
      pck_proc_almost_full_value == local::almost_full_value;
      pck_proc_almost_empty_value == local::almost_empty_value;
      enq_req == 1'b1;
      deq_req == 1'b0;
      in_sop == 1'b1;        // Start of packet
      in_eop == 1'b1;        // End of packet (INVALID!)
      wr_data_i == 32'hB001;
      pck_len_valid == 1'b1;
      pck_len_i == 12'h0001; // Single beat packet
    });
    finish_item(tr);
    
    // Phase 3: Wait for packet drop processing
    `uvm_info(get_type_name(), "Phase 3: Waiting for packet drop processing", UVM_LOW)
    send_idle_transaction(5);
    
    `uvm_info(get_type_name(), "Invalid_1 scenario completed - Packet drop expected", UVM_LOW)
  endtask

  // Test invalid_3: in_sop && (~in_eop_r1) && (write_state == WRITE_DATA)
  task invalid_3_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), "Starting invalid_3 scenario - in_sop && (~in_eop_r1) && (write_state == WRITE_DATA)", UVM_LOW)
    
    // Phase 1: Write packet header to get into WRITE_DATA state
    `uvm_info(get_type_name(), "Phase 1: Writing packet header to enter WRITE_DATA state", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_invalid_3_header");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1'b1;
      pck_proc_int_mem_fsm_sw_rstn == 1'b0;
      empty_de_assert == 1'b0;
      pck_proc_almost_full_value == local::almost_full_value;
      pck_proc_almost_empty_value == local::almost_empty_value;
      enq_req == 1'b1;
      deq_req == 1'b0;
      in_sop == 1'b1;        // Start of packet
      in_eop == 1'b0;        // Not end of packet
      wr_data_i == 32'hB000;
      pck_len_valid == 1'b1;
      pck_len_i == 12'h000A; // Packet length = 10 beats
    });
    finish_item(tr);
    
    // Phase 2: Write several data beats to stay in WRITE_DATA state
    `uvm_info(get_type_name(), "Phase 2: Writing data beats to stay in WRITE_DATA state", UVM_LOW)
    for (int i = 0; i < 5; i++) begin
      tr = pkt_proc_seq_item::type_id::create("tr_invalid_3_data");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1'b1;
        pck_proc_int_mem_fsm_sw_rstn == 1'b0;
        empty_de_assert == 1'b0;
        pck_proc_almost_full_value == local::almost_full_value;
        pck_proc_almost_empty_value == local::almost_empty_value;
        enq_req == 1'b1;
        deq_req == 1'b0;
        in_sop == 1'b0;        // Not start of packet
        in_eop == 1'b0;        // Not end of packet
        wr_data_i == 32'hB001 + i;
        pck_len_valid == 1'b0;
        pck_len_i == 12'h0000;
      });
      finish_item(tr);
      send_idle_transaction(1);
    end
    
    // Phase 3: Trigger invalid_3 condition - assert in_sop while in WRITE_DATA state
    `uvm_info(get_type_name(), "Phase 3: Triggering invalid_3 (in_sop=1 while in WRITE_DATA state)", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_invalid_3_trigger");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1'b1;
      pck_proc_int_mem_fsm_sw_rstn == 1'b0;
      empty_de_assert == 1'b0;
      pck_proc_almost_full_value == local::almost_full_value;
      pck_proc_almost_empty_value == local::almost_empty_value;
      enq_req == 1'b1;
      deq_req == 1'b0;
      in_sop == 1'b1;        // Start of packet (INVALID - already processing a packet!)
      in_eop == 1'b0;        // Not end of packet
      wr_data_i == 32'hB006;
      pck_len_valid == 1'b1;
      pck_len_i == 12'h0005; // New packet length
    });
    finish_item(tr);
    
    // Phase 4: Wait for packet drop processing
    `uvm_info(get_type_name(), "Phase 4: Waiting for packet drop processing", UVM_LOW)
    send_idle_transaction(5);
    
    `uvm_info(get_type_name(), "Invalid_3 scenario completed - Packet drop expected", UVM_LOW)
  endtask

  // Test invalid_4: (count_w < (packet_length_w - 1)) && (packet_length_w != 0) && (in_eop)
  task invalid_4_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), "Starting invalid_4 scenario - count_w < (packet_length_w - 1) && in_eop", UVM_LOW)
    
    // Phase 1: Write partial packet (not enough beats)
    `uvm_info(get_type_name(), "Phase 1: Writing partial packet (insufficient beats)", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_invalid_4_partial");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1'b1;
      pck_proc_int_mem_fsm_sw_rstn == 1'b0;
      empty_de_assert == 1'b0;
      pck_proc_almost_full_value == local::almost_full_value;
      pck_proc_almost_empty_value == local::almost_empty_value;
      enq_req == 1'b1;
      deq_req == 1'b0;
      in_sop == 1'b1;        // Start of packet
      in_eop == 1'b0;        // Not end of packet
      wr_data_i == 32'hC000;
      pck_len_valid == 1'b1;
      pck_len_i == 12'h0005; // Packet length = 5 beats
    });
    finish_item(tr);
    
    // Phase 2: Write only 2 more beats (should have 3 beats total, need 5)
    `uvm_info(get_type_name(), "Phase 2: Writing only 2 more beats (total=3, need=5)", UVM_LOW)
    for (int i = 0; i < 2; i++) begin
      tr = pkt_proc_seq_item::type_id::create("tr_invalid_4_data");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1'b1;
        pck_proc_int_mem_fsm_sw_rstn == 1'b0;
        empty_de_assert == 1'b0;
        pck_proc_almost_full_value == local::almost_full_value;
        pck_proc_almost_empty_value == local::almost_empty_value;
        enq_req == 1'b1;
        deq_req == 1'b0;
        in_sop == 1'b0;        // Not start of packet
        in_eop == 1'b0;        // Not end of packet
        wr_data_i == 32'hC001 + i;
        pck_len_valid == 1'b0;
        pck_len_i == 12'h0000;
      });
      finish_item(tr);
      send_idle_transaction(1);
    end
    
    // Phase 3: Trigger invalid_4 with premature end of packet
    `uvm_info(get_type_name(), "Phase 3: Triggering invalid_4 (premature end with count_w=3 < 4)", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_invalid_4_eop");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1'b1;
      pck_proc_int_mem_fsm_sw_rstn == 1'b0;
      empty_de_assert == 1'b0;
      pck_proc_almost_full_value == local::almost_full_value;
      pck_proc_almost_empty_value == local::almost_empty_value;
      enq_req == 1'b1;
      deq_req == 1'b0;
      in_sop == 1'b0;        // Not start of packet
      in_eop == 1'b1;        // End of packet (INVALID - only 3 beats written, need 5)
      wr_data_i == 32'hC003;
      pck_len_valid == 1'b0;
      pck_len_i == 12'h0000;
    });
    finish_item(tr);
    
    // Phase 4: Wait for packet drop processing
    `uvm_info(get_type_name(), "Phase 4: Waiting for packet drop processing", UVM_LOW)
    send_idle_transaction(5);
    
    `uvm_info(get_type_name(), "Invalid_4 scenario completed - Packet drop expected", UVM_LOW)
  endtask

  // Test invalid_5: ((count_w == (packet_length_w - 1)) || (packet_length_w == 0)) && (~in_eop) && (write_state == WRITE_DATA)
  task invalid_5_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), "Starting invalid_5 scenario - count_w == (packet_length_w - 1) && (~in_eop) && (write_state == WRITE_DATA)", UVM_LOW)
    
    // Phase 1: Write packet header to get into WRITE_DATA state
    `uvm_info(get_type_name(), "Phase 1: Writing packet header to enter WRITE_DATA state", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_invalid_5_header");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1'b1;
      pck_proc_int_mem_fsm_sw_rstn == 1'b0;
      empty_de_assert == 1'b0;
      pck_proc_almost_full_value == local::almost_full_value;
      pck_proc_almost_empty_value == local::almost_empty_value;
      enq_req == 1'b1;
      deq_req == 1'b0;
      in_sop == 1'b1;        // Start of packet
      in_eop == 1'b0;        // Not end of packet
      wr_data_i == 32'hD000;
      pck_len_valid == 1'b1;
      pck_len_i == 12'h0005; // Packet length = 5 beats
    });
    finish_item(tr);
    
    // Phase 2: Write data beats to reach count_w = 4 (packet_length_w - 1)
    `uvm_info(get_type_name(), "Phase 2: Writing data beats to reach count_w = 4 (packet_length_w - 1)", UVM_LOW)
    for (int i = 0; i < 3; i++) begin
      tr = pkt_proc_seq_item::type_id::create("tr_invalid_5_data");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1'b1;
        pck_proc_int_mem_fsm_sw_rstn == 1'b0;
        empty_de_assert == 1'b0;
        pck_proc_almost_full_value == local::almost_full_value;
        pck_proc_almost_empty_value == local::almost_empty_value;
        enq_req == 1'b1;
        deq_req == 1'b0;
        in_sop == 1'b0;        // Not start of packet
        in_eop == 1'b0;        // Not end of packet
        wr_data_i == 32'hD001 + i;
        pck_len_valid == 1'b0;
        pck_len_i == 12'h0000;
      });
      finish_item(tr);
      send_idle_transaction(1);
    end
    
    // Phase 3: Trigger invalid_5 condition - count_w = 4 (packet_length_w - 1) but in_eop = 0
    `uvm_info(get_type_name(), "Phase 3: Triggering invalid_5 (count_w=4 == packet_length_w-1=4, but in_eop=0)", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_invalid_5_trigger");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1'b1;
      pck_proc_int_mem_fsm_sw_rstn == 1'b0;
      empty_de_assert == 1'b0;
      pck_proc_almost_full_value == local::almost_full_value;
      pck_proc_almost_empty_value == local::almost_empty_value;
      enq_req == 1'b1;
      deq_req == 1'b0;
      in_sop == 1'b0;        // Not start of packet
      in_eop == 1'b0;        // Not end of packet (INVALID - should be 1 when count_w reaches limit!)
      wr_data_i == 32'hD004;
      pck_len_valid == 1'b0;
      pck_len_i == 12'h0000;
    });
    finish_item(tr);
    
    // Phase 4: Wait for packet drop processing
    `uvm_info(get_type_name(), "Phase 4: Waiting for packet drop processing", UVM_LOW)
    send_idle_transaction(5);
    
    `uvm_info(get_type_name(), "Invalid_5 scenario completed - Packet drop expected", UVM_LOW)
  endtask


endclass

`endif // PKT_PROC_SEQUENCES_SV