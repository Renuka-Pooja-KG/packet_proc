//=============================================================================
// File: pkt_proc_sequences.sv
// Description: Packet Processor UVM Sequences
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
    tr = pkt_proc_seq_item::type_id::create("tr_reset_init");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 0;  // Assert async reset
      pck_proc_int_mem_fsm_sw_rstn == 0;  // Assert sync reset
      enq_req == 0;  // No operations during reset
      deq_req == 0;
    });
    finish_item(tr);
    
    // Phase 2: Hold reset for specified cycles
    repeat(reset_cycles - 1) begin
      tr = pkt_proc_seq_item::type_id::create("tr_reset_hold");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 0;  // Keep async reset asserted
        pck_proc_int_mem_fsm_sw_rstn == 0;  // Keep sync reset asserted
        enq_req == 0;  // No operations during reset
        deq_req == 0;
      });
      finish_item(tr);
    end
    
    // Phase 3: De-assert resets
    tr = pkt_proc_seq_item::type_id::create("tr_reset_deassert");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1;  // De-assert async reset
      pck_proc_int_mem_fsm_sw_rstn == 1;  // De-assert sync reset
      enq_req == 0;  // No operations immediately after reset
      deq_req == 0;
    });
    finish_item(tr);
    
    // Phase 4: Idle cycles after reset
    repeat(idle_cycles) begin
      tr = pkt_proc_seq_item::type_id::create("tr_idle_after_reset");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req == 0;  // Idle cycles
        deq_req == 0;
      });
      finish_item(tr);
    end
    
    `uvm_info("SEQUENCE_BASE", "DUT initialization completed", UVM_LOW)
  endtask

  // Random scenario
  task random_scenario();
    initialize_dut();
    
    repeat (num_transactions) begin
      tr = pkt_proc_seq_item::type_id::create("tr_random");
      if (!tr.randomize()) begin
        `uvm_fatal(get_type_name(), "Failed to randomize transaction")
      end
      start_item(tr);
      finish_item(tr);
      `uvm_info(get_type_name(), $sformatf("Random: %s", tr.sprint()), UVM_HIGH)
    end
  endtask

  // Reset scenario
  task reset_scenario();
    `uvm_info(get_type_name(), "Starting reset scenario", UVM_LOW)
    
    // Hardware reset for specified cycles
    repeat (reset_cycles) begin
      tr = pkt_proc_seq_item::type_id::create("tr_reset");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 0;  // Assert async reset
        pck_proc_int_mem_fsm_sw_rstn == 0;  // Assert sync reset
        enq_req == 0;  // No operations during reset
        deq_req == 0;
      });
      finish_item(tr);
      `uvm_info(get_type_name(), $sformatf("Reset: %s", tr.sprint()), UVM_HIGH)
    end
    
    // De-assert reset
    tr = pkt_proc_seq_item::type_id::create("tr_deassert_reset");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1;  // De-assert async reset
      pck_proc_int_mem_fsm_sw_rstn == 1;  // De-assert sync reset
      enq_req == 0;  // No operations immediately after reset
      deq_req == 0;
    });
    finish_item(tr);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", tr.sprint()), UVM_HIGH)
  endtask

  // Write-only scenario
  task write_only_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting write-only scenario with %0d writes", num_transactions), UVM_LOW)
    
    repeat (num_transactions) begin
      tr = pkt_proc_seq_item::type_id::create("tr_write");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req == 1;  // Write operation
        deq_req == 0;  // No read operation
      });
      finish_item(tr);
      `uvm_info(get_type_name(), $sformatf("Write: %s", tr.sprint()), UVM_HIGH)
    end
  endtask

  // Read-only scenario
  task read_only_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting read-only scenario with %0d reads", num_transactions), UVM_LOW)
    
    repeat (num_transactions) begin
      tr = pkt_proc_seq_item::type_id::create("tr_read");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        deq_req == 1;  // Read operation
        enq_req == 0;  // No write operation
      });
      finish_item(tr);
      `uvm_info(get_type_name(), $sformatf("Read: %s", tr.sprint()), UVM_HIGH)
    end
  endtask

  // Concurrent read/write scenario
  task concurrent_rw_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting concurrent R/W scenario with %0d transactions", num_transactions), UVM_LOW)
    
    repeat (num_transactions) begin
      tr = pkt_proc_seq_item::type_id::create("tr_concurrent");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        // Allow both read and write operations naturally
        enq_req dist {1 := 50, 0 := 50};  // 50% write operations
        deq_req dist {1 := 50, 0 := 50};  // 50% read operations
        enq_req || deq_req;  // At least one operation
      });
      finish_item(tr);
      `uvm_info(get_type_name(), $sformatf("Concurrent: %s", tr.sprint()), UVM_HIGH)
    end
  endtask

  // Packet write scenario
  task packet_write_scenario();
    initialize_dut();
    
    int packet_count = 5;
    int min_packet_length = 4;
    int max_packet_length = 16;
    int packet_length;
    
    `uvm_info(get_type_name(), $sformatf("Starting packet write scenario: %0d packets", packet_count), UVM_LOW)
    
    for (int pkt = 0; pkt < packet_count; pkt++) begin
      // Randomize packet length
      packet_length = $urandom_range(min_packet_length, max_packet_length);
      
      `uvm_info(get_type_name(), $sformatf("Writing packet %0d with length %0d", pkt, packet_length), UVM_LOW)
      
      // Write packet header (SOP)
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_sop_%0d", pkt));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req == 1;
        deq_req == 0;  // No read operation
        in_sop == 1;
        in_eop == 0;
        pck_len_valid == 1;
        pck_len_i == packet_length;
      });
      finish_item(tr);
      
      // Write packet data
      for (int i = 1; i < packet_length - 1; i++) begin
        tr = pkt_proc_seq_item::type_id::create($sformatf("tr_data_%0d_%0d", pkt, i));
        start_item(tr);
        assert(tr.randomize() with {
          pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
          pck_proc_int_mem_fsm_sw_rstn == 1;
          enq_req == 1;
          deq_req == 0;  // No read operation
          in_sop == 0;
          in_eop == 0;
        });
        finish_item(tr);
      end
      
      // Write packet trailer (EOP)
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_eop_%0d", pkt));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req == 1;
        deq_req == 0;  // No read operation
        in_sop == 0;
        in_eop == 1;
      });
      finish_item(tr);
    end
  endtask

  // Continuous read scenario
  task continuous_read_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting continuous read scenario: %0d reads", num_transactions), UVM_LOW)
    
    repeat (num_transactions) begin
      tr = pkt_proc_seq_item::type_id::create("tr_cont_read");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        deq_req == 1;  // Read operation
        enq_req == 0;  // No write operation
      });
      finish_item(tr);
      `uvm_info(get_type_name(), $sformatf("Continuous Read: %s", tr.sprint()), UVM_HIGH)
    end
  endtask

  // Mixed operations scenario
  task mixed_ops_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting mixed operations scenario: %0d transactions", num_transactions), UVM_LOW)
    
    repeat (num_transactions) begin
      tr = pkt_proc_seq_item::type_id::create("tr_mixed");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        // Allow both read and write operations naturally
        enq_req dist {1 := 40, 0 := 60};  // 40% write operations
        deq_req dist {1 := 40, 0 := 60};  // 40% read operations
      });
      finish_item(tr);
      `uvm_info(get_type_name(), $sformatf("Mixed: %s", tr.sprint()), UVM_HIGH)
    end
  endtask

  // Overflow scenario
  task overflow_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting overflow scenario: %0d writes", num_transactions), UVM_LOW)
    
    // Try to write continuously to cause overflow
    repeat (num_transactions) begin
      tr = pkt_proc_seq_item::type_id::create("tr_overflow");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req == 1;  // Write operation
        deq_req == 0;  // No read operation
        in_sop dist {1 := 20, 0 := 80};  // 20% SOP, 80% data
        in_eop dist {1 := 20, 0 := 80};  // 20% EOP, 80% data
      });
      finish_item(tr);
      `uvm_info(get_type_name(), $sformatf("Overflow: %s", tr.sprint()), UVM_HIGH)
    end
  endtask

  // Underflow scenario
  task underflow_scenario();
    initialize_dut();
    
    `uvm_info(get_type_name(), $sformatf("Starting underflow scenario: %0d reads", num_transactions), UVM_LOW)
    
    // Try to read continuously to cause underflow
    repeat (num_transactions) begin
      tr = pkt_proc_seq_item::type_id::create("tr_underflow");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        deq_req == 1;  // Read operation
        enq_req == 0;  // No write operation
      });
      finish_item(tr);
      `uvm_info(get_type_name(), $sformatf("Underflow: %s", tr.sprint()), UVM_HIGH)
    end
  endtask

  // Async reset scenario
  task async_reset_scenario();
    `uvm_info(get_type_name(), "Starting async reset scenario", UVM_LOW)
    
    // Phase 1: Normal operations
    repeat (10) begin
      tr = pkt_proc_seq_item::type_id::create("tr_normal");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // No async reset
        pck_proc_int_mem_fsm_sw_rstn == 1;  // No sync reset
        enq_req == 1;
        deq_req == 0;
      });
      finish_item(tr);
    end
    
    // Phase 2: Assert async reset
    tr = pkt_proc_seq_item::type_id::create("tr_async_reset");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 0;  // Assert async reset
      enq_req == 1;  // Continue operations during reset
      deq_req == 1;
    });
    finish_item(tr);
    
    // Phase 3: Continue operations during reset
    repeat (5) begin
      tr = pkt_proc_seq_item::type_id::create("tr_during_reset");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 0;  // Keep reset asserted
        enq_req dist {1 := 60, 0 := 40};
        deq_req dist {1 := 60, 0 := 40};
      });
      finish_item(tr);
    end
    
    // Phase 4: De-assert reset
    tr = pkt_proc_seq_item::type_id::create("tr_deassert_reset");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1;  // De-assert async reset
      enq_req == 1;
      deq_req == 0;
    });
    finish_item(tr);
    
    // Phase 5: Post-reset operations
    repeat (15) begin
      tr = pkt_proc_seq_item::type_id::create("tr_post_reset");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep reset de-asserted
        enq_req dist {1 := 50, 0 := 50};
        deq_req dist {1 := 50, 0 := 50};
        enq_req || deq_req;  // At least one operation
      });
      finish_item(tr);
    end
  endtask

  // Sync reset scenario
  task sync_reset_scenario();
    `uvm_info(get_type_name(), "Starting sync reset scenario", UVM_LOW)
    
    // Phase 1: Normal operations
    repeat (8) begin
      tr = pkt_proc_seq_item::type_id::create("tr_normal");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_sw_rstn == 1;  // No sync reset
        enq_req == 1;
        deq_req == 0;
      });
      finish_item(tr);
    end
    
    // Phase 2: Assert sync reset
    tr = pkt_proc_seq_item::type_id::create("tr_sync_reset");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_sw_rstn == 0;  // Assert sync reset
      enq_req == 1;  // Continue operations during reset
      deq_req == 1;
    });
    finish_item(tr);
    
    // Phase 3: Operations during sync reset
    repeat (6) begin
      tr = pkt_proc_seq_item::type_id::create("tr_during_sync_reset");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_sw_rstn == 0;  // Keep sync reset asserted
        enq_req dist {1 := 70, 0 := 30};
        deq_req dist {1 := 70, 0 := 30};
      });
      finish_item(tr);
    end
    
    // Phase 4: De-assert sync reset
    tr = pkt_proc_seq_item::type_id::create("tr_deassert_sync_reset");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_sw_rstn == 1;  // De-assert sync reset
      enq_req == 1;
      deq_req == 0;
    });
    finish_item(tr);
    
    // Phase 5: Post-sync-reset operations
    repeat (12) begin
      tr = pkt_proc_seq_item::type_id::create("tr_post_sync_reset");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_sw_rstn == 1;  // Keep sync reset de-asserted
        enq_req dist {1 := 50, 0 := 50};
        deq_req dist {1 := 50, 0 := 50};
        enq_req || deq_req;  // At least one operation
      });
      finish_item(tr);
    end
  endtask

  // Dual reset scenario
  task dual_reset_scenario();
    `uvm_info(get_type_name(), "Starting dual reset scenario", UVM_LOW)
    
    // Phase 1: Normal operations
    repeat (6) begin
      tr = pkt_proc_seq_item::type_id::create("tr_normal");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // No async reset
        pck_proc_int_mem_fsm_sw_rstn == 1;  // No sync reset
        enq_req == 1;
        deq_req == 0;
      });
      finish_item(tr);
    end
    
    // Phase 2: Assert both resets
    tr = pkt_proc_seq_item::type_id::create("tr_dual_reset");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 0;  // Assert async reset
      pck_proc_int_mem_fsm_sw_rstn == 0;  // Assert sync reset
      enq_req == 1;  // Continue operations during reset
      deq_req == 1;
    });
    finish_item(tr);
    
    // Phase 3: Operations during dual reset
    repeat (8) begin
      tr = pkt_proc_seq_item::type_id::create("tr_during_dual_reset");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 0;  // Keep async reset asserted
        pck_proc_int_mem_fsm_sw_rstn == 0;  // Keep sync reset asserted
        enq_req dist {1 := 50, 0 := 50};
        deq_req dist {1 := 50, 0 := 50};
      });
      finish_item(tr);
    end
    
    // Phase 4: De-assert both resets
    tr = pkt_proc_seq_item::type_id::create("tr_deassert_dual_reset");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1;  // De-assert async reset
      pck_proc_int_mem_fsm_sw_rstn == 1;  // De-assert sync reset
      enq_req == 1;
      deq_req == 0;
    });
    finish_item(tr);
    
    // Phase 5: Post-dual-reset operations
    repeat (10) begin
      tr = pkt_proc_seq_item::type_id::create("tr_post_dual_reset");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req dist {1 := 50, 0 := 50};
        deq_req dist {1 := 50, 0 := 50};
        enq_req || deq_req;  // At least one operation
      });
      finish_item(tr);
    end
  endtask

  // Reset during packet scenario
  task reset_during_packet_scenario();
    `uvm_info(get_type_name(), "Starting reset during packet scenario", UVM_LOW)
    
    // Phase 1: Start packet transmission
    // Packet header
    tr = pkt_proc_seq_item::type_id::create("tr_packet_header");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1;
      pck_proc_int_mem_fsm_sw_rstn == 1;
      enq_req == 1;
      deq_req == 0;
      in_sop == 1;
      in_eop == 0;
      pck_len_valid == 1;
      pck_len_i == 8;  // 8-word packet
    });
    finish_item(tr);
    
    // Packet data (first few words)
    for (int i = 1; i < 4; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_packet_data_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req == 1;
        deq_req == 0;
        in_sop == 0;
        in_eop == 0;
        wr_data_i == 32'hA000 + i;  // Unique data pattern
      });
      finish_item(tr);
    end
    
    // Phase 2: Assert reset during packet transmission
    tr = pkt_proc_seq_item::type_id::create("tr_reset_during_packet");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 0;  // Assert async reset
      pck_proc_int_mem_fsm_sw_rstn == 0;  // Assert sync reset
      enq_req == 1;  // Continue packet transmission
      deq_req == 0;
      in_sop == 0;
      in_eop == 0;
      wr_data_i == 32'hB000;  // Data during reset
    });
    finish_item(tr);
    
    // Phase 3: Continue packet during reset
    for (int i = 4; i < 7; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_packet_during_reset_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 0;
        pck_proc_int_mem_fsm_sw_rstn == 0;
        enq_req == 1;
        deq_req == 0;
        in_sop == 0;
        in_eop == 0;
        wr_data_i == 32'hC000 + i;
      });
      finish_item(tr);
    end
    
    // Phase 4: De-assert reset and complete packet
    tr = pkt_proc_seq_item::type_id::create("tr_complete_packet");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1;  // De-assert async reset
      pck_proc_int_mem_fsm_sw_rstn == 1;  // De-assert sync reset
      enq_req == 1;
      deq_req == 0;
      in_sop == 0;
      in_eop == 1;  // End of packet
    });
    finish_item(tr);
  endtask

  // Reset during read scenario
  task reset_during_read_scenario();
    `uvm_info(get_type_name(), "Starting reset during read scenario", UVM_LOW)
    
    // Phase 1: Write some data first
    repeat (5) begin
      tr = pkt_proc_seq_item::type_id::create("tr_write");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req == 1;
        deq_req == 0;
      });
      finish_item(tr);
    end
    
    // Phase 2: Start read operations
    repeat (3) begin
      tr = pkt_proc_seq_item::type_id::create("tr_read_start");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req == 0;
        deq_req == 1;  // Read operations
      });
      finish_item(tr);
    end
    
    // Phase 3: Assert reset during read
    tr = pkt_proc_seq_item::type_id::create("tr_reset_during_read");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 0;  // Assert async reset
      pck_proc_int_mem_fsm_sw_rstn == 0;  // Assert sync reset
      enq_req == 0;
      deq_req == 1;  // Continue read during reset
    });
    finish_item(tr);
    
    // Phase 4: Continue read during reset
    repeat (4) begin
      tr = pkt_proc_seq_item::type_id::create("tr_read_during_reset");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 0;
        pck_proc_int_mem_fsm_sw_rstn == 0;
        enq_req == 0;
        deq_req == 1;  // Read operations during reset
      });
      finish_item(tr);
    end
    
    // Phase 5: De-assert reset
    tr = pkt_proc_seq_item::type_id::create("tr_deassert_reset_read");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1;  // De-assert async reset
      pck_proc_int_mem_fsm_sw_rstn == 1;  // De-assert sync reset
      enq_req == 0;
      deq_req == 1;  // Continue read after reset
    });
    finish_item(tr);
    
    // Phase 6: Mixed operations after reset
    repeat (8) begin
      tr = pkt_proc_seq_item::type_id::create("tr_mixed_after_reset");
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req dist {1 := 50, 0 := 50};
        deq_req dist {1 := 50, 0 := 50};
        enq_req || deq_req;  // At least one operation
      });
      finish_item(tr);
    end
  endtask

endclass

`endif // PKT_PROC_SEQUENCES_SV 