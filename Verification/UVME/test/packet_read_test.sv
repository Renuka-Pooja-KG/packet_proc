// Packet Read Test for Packet Processor
// Tests packet reading operations with proper reset initialization

class packet_read_test extends uvm_test;
  `uvm_component_utils(packet_read_test)

  pkt_proc_env env;
  
  // Packet read sequences
  continuous_read_sequence continuous_read_seq;
  read_only_sequence read_seq;
  
  // Reset initialization sequence
  reset_initialization_sequence reset_init_seq;

  function new(string name = "packet_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = pkt_proc_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    `uvm_info("PACKET_READ_TEST", "Starting packet read test suite", UVM_LOW)
    
    // Initialize DUT with reset
    `uvm_info("PACKET_READ_TEST", "Phase 1: Initializing DUT with reset", UVM_LOW)
    reset_init_seq = reset_initialization_sequence::type_id::create("reset_init_seq");
    reset_init_seq.reset_cycles = 5;  // 5 clock cycles of reset
    reset_init_seq.idle_cycles = 3;   // 3 idle cycles after reset
    reset_init_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between initialization and tests
    repeat(10) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 1: Basic read sequence
    `uvm_info("PACKET_READ_TEST", "Phase 2: Starting basic read test", UVM_LOW)
    read_seq = read_only_sequence::type_id::create("read_seq");
    read_seq.read_count = 50;
    read_seq.enable_reset = 0;  // Don't reset again, already done
    read_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between tests
    repeat(20) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 2: Continuous read sequence
    `uvm_info("PACKET_READ_TEST", "Phase 3: Starting continuous read test", UVM_LOW)
    continuous_read_seq = continuous_read_sequence::type_id::create("continuous_read_seq");
    continuous_read_seq.read_count = 100;
    continuous_read_seq.enable_reset = 0;  // Don't reset again
    continuous_read_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between tests
    repeat(20) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 3: Underflow test (read from empty buffer)
    `uvm_info("PACKET_READ_TEST", "Phase 4: Starting underflow test", UVM_LOW)
    continuous_read_seq = continuous_read_sequence::type_id::create("continuous_read_seq_underflow");
    continuous_read_seq.read_count = 200;  // More reads to cause underflow
    continuous_read_seq.enable_reset = 0;  // Don't reset again
    continuous_read_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait for any remaining operations
    repeat(30) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    `uvm_info("PACKET_READ_TEST", "Packet read test suite completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask

endclass