// Reset test sequences for Packet Processor
// These sequences test various reset scenarios with write/read operations

// Base reset initialization sequence
class reset_initialization_sequence extends uvm_sequence #(pkt_proc_seq_item);
  `uvm_object_utils(reset_initialization_sequence)

  int reset_cycles = 5;
  int idle_cycles = 3;
  
  function new(string name = "reset_initialization_sequence");
    super.new(name);
  endfunction

  task automatic body();
    pkt_proc_seq_item tr;
    
    `uvm_info("RESET_INIT_SEQ", $sformatf("Initializing DUT with %0d reset cycles", reset_cycles), UVM_LOW)
    
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
    
    `uvm_info("RESET_INIT_SEQ", "DUT initialization completed", UVM_LOW)
  endtask
endclass

// Base reset test sequence
class reset_test_sequence_base extends uvm_sequence #(pkt_proc_seq_item);
  `uvm_object_utils(reset_test_sequence_base)

  int operation_count = 20;
  int reset_duration = 10;  // Clock cycles
  
  function new(string name = "reset_test_sequence_base");
    super.new(name);
  endfunction

  task automatic body();
    pkt_proc_seq_item tr;
    
    for (int i = 0; i < operation_count; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        // Mix of write and read operations
        enq_req dist {1 := 50, 0 := 50};
        deq_req dist {1 := 50, 0 := 50};
        // Ensure at least one operation per transaction
        enq_req || deq_req;
      });
      finish_item(tr);
    end
  endtask
endclass

// Test asynchronous reset during operations
class async_reset_test_sequence extends reset_test_sequence_base;
  `uvm_object_utils(async_reset_test_sequence)

  function new(string name = "async_reset_test_sequence");
    super.new(name);
  endfunction

  task automatic body();
    pkt_proc_seq_item tr;
    
    `uvm_info("ASYNC_RESET_SEQ", "Starting async reset test sequence", UVM_LOW)
    
    // Phase 1: Normal operations
    `uvm_info("ASYNC_RESET_SEQ", "Phase 1: Normal operations", UVM_LOW)
    for (int i = 0; i < 10; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_normal_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        enq_req == 1;
        deq_req == 0;
        in_sop dist {1 := 30, 0 := 70};
        in_eop dist {1 := 20, 0 := 80};
      });
      finish_item(tr);
    end
    
    // Phase 2: Assert async reset
    `uvm_info("ASYNC_RESET_SEQ", "Phase 2: Asserting async reset", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_async_reset");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 0;  // Assert async reset
      enq_req == 1;  // Continue operations during reset
      deq_req == 1;
    });
    finish_item(tr);
    
    // Phase 3: Continue operations during reset
    `uvm_info("ASYNC_RESET_SEQ", "Phase 3: Operations during reset", UVM_LOW)
    for (int i = 0; i < 5; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_during_reset_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 0;  // Keep reset asserted
        enq_req dist {1 := 60, 0 := 40};
        deq_req dist {1 := 60, 0 := 40};
      });
      finish_item(tr);
    end
    
    // Phase 4: De-assert reset
    `uvm_info("ASYNC_RESET_SEQ", "Phase 4: De-asserting async reset", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_deassert_reset");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1;  // De-assert async reset
      enq_req == 1;
      deq_req == 0;
    });
    finish_item(tr);
    
    // Phase 5: Post-reset operations
    `uvm_info("ASYNC_RESET_SEQ", "Phase 5: Post-reset operations", UVM_LOW)
    for (int i = 0; i < 15; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_post_reset_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep reset de-asserted
        enq_req dist {1 := 50, 0 := 50};
        deq_req dist {1 := 50, 0 := 50};
        enq_req || deq_req;  // At least one operation
      });
      finish_item(tr);
    end
    
    `uvm_info("ASYNC_RESET_SEQ", "Async reset test sequence completed", UVM_LOW)
  endtask
endclass

// Test synchronous reset during operations
class sync_reset_test_sequence extends reset_test_sequence_base;
  `uvm_object_utils(sync_reset_test_sequence)

  function new(string name = "sync_reset_test_sequence");
    super.new(name);
  endfunction

  task automatic body();
    pkt_proc_seq_item tr;
    
    `uvm_info("SYNC_RESET_SEQ", "Starting sync reset test sequence", UVM_LOW)
    
    // Phase 1: Normal operations
    `uvm_info("SYNC_RESET_SEQ", "Phase 1: Normal operations", UVM_LOW)
    for (int i = 0; i < 8; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_normal_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_sw_rstn == 1;  // No sync reset
        enq_req == 1;
        deq_req == 0;
        in_sop dist {1 := 25, 0 := 75};
        in_eop dist {1 := 25, 0 := 75};
      });
      finish_item(tr);
    end
    
    // Phase 2: Assert sync reset
    `uvm_info("SYNC_RESET_SEQ", "Phase 2: Asserting sync reset", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_sync_reset");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_sw_rstn == 0;  // Assert sync reset
      enq_req == 1;  // Continue operations during reset
      deq_req == 1;
    });
    finish_item(tr);
    
    // Phase 3: Operations during sync reset
    `uvm_info("SYNC_RESET_SEQ", "Phase 3: Operations during sync reset", UVM_LOW)
    for (int i = 0; i < 6; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_during_sync_reset_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_sw_rstn == 0;  // Keep sync reset asserted
        enq_req dist {1 := 70, 0 := 30};
        deq_req dist {1 := 70, 0 := 30};
      });
      finish_item(tr);
    end
    
    // Phase 4: De-assert sync reset
    `uvm_info("SYNC_RESET_SEQ", "Phase 4: De-asserting sync reset", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_deassert_sync_reset");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_sw_rstn == 1;  // De-assert sync reset
      enq_req == 1;
      deq_req == 0;
    });
    finish_item(tr);
    
    // Phase 5: Post-sync-reset operations
    `uvm_info("SYNC_RESET_SEQ", "Phase 5: Post-sync-reset operations", UVM_LOW)
    for (int i = 0; i < 12; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_post_sync_reset_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_sw_rstn == 1;  // Keep sync reset de-asserted
        enq_req dist {1 := 50, 0 := 50};
        deq_req dist {1 := 50, 0 := 50};
        enq_req || deq_req;  // At least one operation
      });
      finish_item(tr);
    end
    
    `uvm_info("SYNC_RESET_SEQ", "Sync reset test sequence completed", UVM_LOW)
  endtask
endclass

// Test both resets simultaneously
class dual_reset_test_sequence extends reset_test_sequence_base;
  `uvm_object_utils(dual_reset_test_sequence)

  function new(string name = "dual_reset_test_sequence");
    super.new(name);
  endfunction

  task automatic body();
    pkt_proc_seq_item tr;
    
    `uvm_info("DUAL_RESET_SEQ", "Starting dual reset test sequence", UVM_LOW)
    
    // Phase 1: Normal operations
    `uvm_info("DUAL_RESET_SEQ", "Phase 1: Normal operations", UVM_LOW)
    for (int i = 0; i < 6; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_normal_%0d", i));
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
    `uvm_info("DUAL_RESET_SEQ", "Phase 2: Asserting both resets", UVM_LOW)
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
    `uvm_info("DUAL_RESET_SEQ", "Phase 3: Operations during dual reset", UVM_LOW)
    for (int i = 0; i < 4; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_during_dual_reset_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 0;  // Keep async reset asserted
        pck_proc_int_mem_fsm_sw_rstn == 0;  // Keep sync reset asserted
        enq_req dist {1 := 80, 0 := 20};
        deq_req dist {1 := 80, 0 := 20};
      });
      finish_item(tr);
    end
    
    // Phase 4: De-assert sync reset first
    `uvm_info("DUAL_RESET_SEQ", "Phase 4: De-asserting sync reset first", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_deassert_sync_first");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 0;  // Keep async reset asserted
      pck_proc_int_mem_fsm_sw_rstn == 1;  // De-assert sync reset
      enq_req == 1;
      deq_req == 0;
    });
    finish_item(tr);
    
    // Phase 5: Operations with only async reset
    `uvm_info("DUAL_RESET_SEQ", "Phase 5: Operations with only async reset", UVM_LOW)
    for (int i = 0; i < 3; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_async_only_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 0;  // Keep async reset asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;  // Sync reset de-asserted
        enq_req dist {1 := 60, 0 := 40};
        deq_req dist {1 := 60, 0 := 40};
      });
      finish_item(tr);
    end
    
    // Phase 6: De-assert async reset
    `uvm_info("DUAL_RESET_SEQ", "Phase 6: De-asserting async reset", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_deassert_async");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1;  // De-assert async reset
      pck_proc_int_mem_fsm_sw_rstn == 1;  // Sync reset already de-asserted
      enq_req == 1;
      deq_req == 0;
    });
    finish_item(tr);
    
    // Phase 7: Normal operations after all resets
    `uvm_info("DUAL_RESET_SEQ", "Phase 7: Normal operations after all resets", UVM_LOW)
    for (int i = 0; i < 10; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_final_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Both resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req dist {1 := 50, 0 := 50};
        deq_req dist {1 := 50, 0 := 50};
        enq_req || deq_req;  // At least one operation
      });
      finish_item(tr);
    end
    
    `uvm_info("DUAL_RESET_SEQ", "Dual reset test sequence completed", UVM_LOW)
  endtask
endclass

// Test reset during packet transmission
class reset_during_packet_sequence extends reset_test_sequence_base;
  `uvm_object_utils(reset_during_packet_sequence)

  function new(string name = "reset_during_packet_sequence");
    super.new(name);
  endfunction

  task automatic body();
    pkt_proc_seq_item tr;
    
    `uvm_info("RESET_PACKET_SEQ", "Starting reset during packet test sequence", UVM_LOW)
    
    // Phase 1: Start packet transmission
    `uvm_info("RESET_PACKET_SEQ", "Phase 1: Starting packet transmission", UVM_LOW)
    
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
    `uvm_info("RESET_PACKET_SEQ", "Phase 2: Asserting reset during packet", UVM_LOW)
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
    `uvm_info("RESET_PACKET_SEQ", "Phase 3: Continuing packet during reset", UVM_LOW)
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
    `uvm_info("RESET_PACKET_SEQ", "Phase 4: De-asserting reset and completing packet", UVM_LOW)
    tr = pkt_proc_seq_item::type_id::create("tr_complete_packet");
    start_item(tr);
    assert(tr.randomize() with {
      pck_proc_int_mem_fsm_rstn == 1;  // De-assert async reset
      pck_proc_int_mem_fsm_sw_rstn == 1;  // De-assert sync reset
      enq_req == 1;
      deq_req == 0;
      in_sop == 0;
      in_eop == 1;  // End of packet
      wr_data_i == 32'hD000;
    });
    finish_item(tr);
    
    // Phase 5: Read operations after reset
    `uvm_info("RESET_PACKET_SEQ", "Phase 5: Read operations after reset", UVM_LOW)
    for (int i = 0; i < 8; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_read_after_reset_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req == 0;
        deq_req == 1;  // Read operations
      });
      finish_item(tr);
    end
    
    `uvm_info("RESET_PACKET_SEQ", "Reset during packet test sequence completed", UVM_LOW)
  endtask
endclass

// Test reset during read operations
class reset_during_read_sequence extends reset_test_sequence_base;
  `uvm_object_utils(reset_during_read_sequence)

  function new(string name = "reset_during_read_sequence");
    super.new(name);
  endfunction

  task automatic body();
    pkt_proc_seq_item tr;
    
    `uvm_info("RESET_READ_SEQ", "Starting reset during read test sequence", UVM_LOW)
    
    // Phase 1: Write some data first
    `uvm_info("RESET_READ_SEQ", "Phase 1: Writing initial data", UVM_LOW)
    for (int i = 0; i < 5; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_write_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req == 1;
        deq_req == 0;
        in_sop dist {1 := 20, 0 := 80};
        in_eop dist {1 := 20, 0 := 80};
      });
      finish_item(tr);
    end
    
    // Phase 2: Start read operations
    `uvm_info("RESET_READ_SEQ", "Phase 2: Starting read operations", UVM_LOW)
    for (int i = 0; i < 3; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_read_start_%0d", i));
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
    `uvm_info("RESET_READ_SEQ", "Phase 3: Asserting reset during read", UVM_LOW)
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
    `uvm_info("RESET_READ_SEQ", "Phase 4: Continuing read during reset", UVM_LOW)
    for (int i = 0; i < 4; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_read_during_reset_%0d", i));
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
    `uvm_info("RESET_READ_SEQ", "Phase 5: De-asserting reset", UVM_LOW)
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
    `uvm_info("RESET_READ_SEQ", "Phase 6: Mixed operations after reset", UVM_LOW)
    for (int i = 0; i < 8; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_mixed_after_reset_%0d", i));
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
    
    `uvm_info("RESET_READ_SEQ", "Reset during read test sequence completed", UVM_LOW)
  endtask
endclass 