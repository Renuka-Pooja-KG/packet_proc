// Packet Write Test for Packet Processor
// Tests packet writing operations with proper reset initialization

class packet_write_test extends uvm_test;
  `uvm_component_utils(packet_write_test)

  pkt_proc_env env;
  
  // Packet write sequences
  packet_write_sequence packet_write_seq;
  
  // Reset initialization sequence
  reset_initialization_sequence reset_init_seq;

  function new(string name = "packet_write_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = pkt_proc_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    `uvm_info("PACKET_WRITE_TEST", "Starting packet write test suite", UVM_LOW)
    
    // Initialize DUT with reset
    `uvm_info("PACKET_WRITE_TEST", "Phase 1: Initializing DUT with reset", UVM_LOW)
    reset_init_seq = reset_initialization_sequence::type_id::create("reset_init_seq");
    reset_init_seq.reset_cycles = 5;  // 5 clock cycles of reset
    reset_init_seq.idle_cycles = 3;   // 3 idle cycles after reset
    reset_init_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between initialization and tests
    repeat(10) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 1: Basic packet write sequence
    `uvm_info("PACKET_WRITE_TEST", "Phase 2: Starting basic packet write test", UVM_LOW)
    packet_write_seq = packet_write_sequence::type_id::create("packet_write_seq");
    packet_write_seq.packet_count = 10;
    packet_write_seq.min_packet_length = 4;
    packet_write_seq.max_packet_length = 16;
    packet_write_seq.enable_reset = 0;  // Don't reset again, already done
    packet_write_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between tests
    repeat(20) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 2: Large packet write sequence
    `uvm_info("PACKET_WRITE_TEST", "Phase 3: Starting large packet write test", UVM_LOW)
    packet_write_seq = packet_write_sequence::type_id::create("packet_write_seq_large");
    packet_write_seq.packet_count = 5;
    packet_write_seq.min_packet_length = 8;
    packet_write_seq.max_packet_length = 20;
    packet_write_seq.enable_reset = 0;  // Don't reset again
    packet_write_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between tests
    repeat(20) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 3: Small packet write sequence
    `uvm_info("PACKET_WRITE_TEST", "Phase 4: Starting small packet write test", UVM_LOW)
    packet_write_seq = packet_write_sequence::type_id::create("packet_write_seq_small");
    packet_write_seq.packet_count = 15;
    packet_write_seq.min_packet_length = 2;
    packet_write_seq.max_packet_length = 6;
    packet_write_seq.enable_reset = 0;  // Don't reset again
    packet_write_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait for any remaining operations
    repeat(30) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    `uvm_info("PACKET_WRITE_TEST", "Packet write test suite completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask

endclass