// Base sequence for the enhanced single agent with proper reset initialization
class sequence_base extends uvm_sequence #(pkt_proc_seq_item);
  `uvm_object_utils(sequence_base)

  // Configuration parameters
  int reset_cycles = 5;    // Number of clock cycles to hold reset
  int idle_cycles = 3;     // Number of idle cycles after reset
  bit enable_reset = 1;    // Enable/disable reset initialization
  
  // Transaction handle
  pkt_proc_seq_item tr;
  
  function new(string name = "sequence_base");
    super.new(name);
  endfunction

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

  // Default body - should be overridden by derived classes
  virtual task body();
    // Initialize DUT first
    initialize_dut();
    
    // Derived classes should override this method
    `uvm_info("SEQUENCE_BASE", "Base sequence body - should be overridden", UVM_LOW)
  endtask
endclass

// Write-only sequence with reset initialization
class write_only_sequence extends sequence_base;
  `uvm_object_utils(write_only_sequence)

  int write_count = 10;
  
  function new(string name = "write_only_sequence");
    super.new(name);
  endfunction

  virtual task body();
    // Call parent initialization (includes reset)
    super.body();
    
    `uvm_info("WRITE_ONLY_SEQ", $sformatf("Starting write-only sequence with %0d writes", write_count), UVM_LOW)
    
    for (int i = 0; i < write_count; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_write_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        enq_req == 1;  // Write operation
        deq_req == 0;  // No read operation
      });
      finish_item(tr);
    end
    
    `uvm_info("WRITE_ONLY_SEQ", "Write-only sequence completed", UVM_LOW)
  endtask
endclass

// Read-only sequence with reset initialization
class read_only_sequence extends sequence_base;
  `uvm_object_utils(read_only_sequence)

  int read_count = 10;
  
  function new(string name = "read_only_sequence");
    super.new(name);
  endfunction

  virtual task body();
    // Call parent initialization (includes reset)
    super.body();
    
    `uvm_info("READ_ONLY_SEQ", $sformatf("Starting read-only sequence with %0d reads", read_count), UVM_LOW)
    
    for (int i = 0; i < read_count; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_read_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        deq_req == 1;  // Read operation
        enq_req == 0;  // No write operation
      });
      finish_item(tr);
    end
    
    `uvm_info("READ_ONLY_SEQ", "Read-only sequence completed", UVM_LOW)
  endtask
endclass

// Concurrent read/write sequence with reset initialization
class concurrent_rw_sequence extends sequence_base;
  `uvm_object_utils(concurrent_rw_sequence)

  int write_count = 20;
  int read_count = 30;
  
  function new(string name = "concurrent_rw_sequence");
    super.new(name);
  endfunction

  virtual task body();
    // Call parent initialization (includes reset)
    super.body();
    
    `uvm_info("CONCURRENT_SEQ", $sformatf("Starting concurrent R/W sequence: %0d writes, %0d reads", write_count, read_count), UVM_LOW)
    
    // Create child sequences but disable their reset initialization
    write_only_sequence write_seq = write_only_sequence::type_id::create("write_seq");
    read_only_sequence read_seq = read_only_sequence::type_id::create("read_seq");
    
    // Configure sequences
    write_seq.write_count = write_count;
    read_seq.read_count = read_count;
    
    // Disable reset initialization for child sequences
    write_seq.enable_reset = 0;  // Don't reset again
    read_seq.enable_reset = 0;   // Don't reset again
    
    // Run both sequences concurrently using fork/join
    fork
      write_seq.start(m_sequencer);
      read_seq.start(m_sequencer);
    join
    
    `uvm_info("CONCURRENT_SEQ", "Concurrent read/write sequence completed", UVM_LOW)
  endtask
endclass

// Packet write sequence with reset initialization
class packet_write_sequence extends sequence_base;
  `uvm_object_utils(packet_write_sequence)

  int packet_count = 5;
  int min_packet_length = 4;
  int max_packet_length = 16;
  
  function new(string name = "packet_write_sequence");
    super.new(name);
  endfunction

  virtual task body();
    // Call parent initialization (includes reset)
    super.body();
    
    int packet_length;
    
    `uvm_info("PACKET_WRITE_SEQ", $sformatf("Starting packet write sequence: %0d packets", packet_count), UVM_LOW)
    
    for (int pkt = 0; pkt < packet_count; pkt++) begin
      // Randomize packet length
      packet_length = $urandom_range(min_packet_length, max_packet_length);
      
      `uvm_info("PACKET_WRITE_SEQ", $sformatf("Writing packet %0d with length %0d", pkt, packet_length), UVM_LOW)
      
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
    
    `uvm_info("PACKET_WRITE_SEQ", "Packet write sequence completed", UVM_LOW)
  endtask
endclass

// Continuous read sequence with reset initialization
class continuous_read_sequence extends sequence_base;
  `uvm_object_utils(continuous_read_sequence)

  int read_count = 100;
  
  function new(string name = "continuous_read_sequence");
    super.new(name);
  endfunction

  virtual task body();
    // Call parent initialization (includes reset)
    super.body();
    
    `uvm_info("CONTINUOUS_READ_SEQ", $sformatf("Starting continuous read sequence: %0d reads", read_count), UVM_LOW)
    
    for (int i = 0; i < read_count; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_cont_read_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        deq_req == 1;  // Read operation
        enq_req == 0;  // No write operation
      });
      finish_item(tr);
    end
    
    `uvm_info("CONTINUOUS_READ_SEQ", "Continuous read sequence completed", UVM_LOW)
  endtask
endclass

// Mixed operations sequence with reset initialization
class mixed_operations_sequence extends sequence_base;
  `uvm_object_utils(mixed_operations_sequence)

  int transaction_count = 50;
  
  function new(string name = "mixed_operations_sequence");
    super.new(name);
  endfunction

  virtual task body();
    // Call parent initialization (includes reset)
    super.body();
    
    `uvm_info("MIXED_OPS_SEQ", $sformatf("Starting mixed operations sequence: %0d transactions", transaction_count), UVM_LOW)
    
    for (int i = 0; i < transaction_count; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_mixed_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        // Allow both read and write operations naturally
        enq_req dist {1 := 40, 0 := 60};  // 40% write operations
        deq_req dist {1 := 40, 0 := 60};  // 40% read operations
      });
      finish_item(tr);
    end
    
    `uvm_info("MIXED_OPS_SEQ", "Mixed operations sequence completed", UVM_LOW)
  endtask
endclass

// Overflow test sequence with reset initialization
class overflow_test_sequence extends sequence_base;
  `uvm_object_utils(overflow_test_sequence)

  int write_count = 1000;
  
  function new(string name = "overflow_test_sequence");
    super.new(name);
  endfunction

  virtual task body();
    // Call parent initialization (includes reset)
    super.body();
    
    `uvm_info("OVERFLOW_SEQ", $sformatf("Starting overflow test sequence: %0d writes", write_count), UVM_LOW)
    
    // Try to write continuously to cause overflow
    for (int i = 0; i < write_count; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_overflow_%0d", i));
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
    end
    
    `uvm_info("OVERFLOW_SEQ", "Overflow test sequence completed", UVM_LOW)
  endtask
endclass

// Underflow test sequence with reset initialization
class underflow_test_sequence extends sequence_base;
  `uvm_object_utils(underflow_test_sequence)

  int read_count = 1000;
  
  function new(string name = "underflow_test_sequence");
    super.new(name);
  endfunction

  virtual task body();
    // Call parent initialization (includes reset)
    super.body();
    
    `uvm_info("UNDERFLOW_SEQ", $sformatf("Starting underflow test sequence: %0d reads", read_count), UVM_LOW)
    
    // Try to read continuously to cause underflow
    for (int i = 0; i < read_count; i++) begin
      tr = pkt_proc_seq_item::type_id::create($sformatf("tr_underflow_%0d", i));
      start_item(tr);
      assert(tr.randomize() with {
        pck_proc_int_mem_fsm_rstn == 1;  // Keep resets de-asserted
        pck_proc_int_mem_fsm_sw_rstn == 1;
        deq_req == 1;  // Read operation
        enq_req == 0;  // No write operation
      });
      finish_item(tr);
    end
    
    `uvm_info("UNDERFLOW_SEQ", "Underflow test sequence completed", UVM_LOW)
  endtask
endclass 