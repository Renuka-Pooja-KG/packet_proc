// Package file for Packet Processor UVM Verification
// This package includes all UVM components

package pkt_proc_pkg;

  // Import UVM
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  // Include all UVM components
  `include "./../UVME/sequence/pkt_proc_seq_item.sv"
  `include "./../UVME/sequence/pkt_proc_sequences.sv"
  `include "./../UVME/sequence/reset_test_sequences.sv"
  
  `include "./../UVME/agent/pkt_proc_driver.sv"
  `include "./../UVME/agent/pkt_proc_monitor.sv"
  `include "./../UVME/agent/pkt_proc_sequencer.sv"
  `include "./../UVME/agent/pkt_proc_agent.sv"
  
  // Environment components
  `include "./../UVME/env/pkt_proc_scoreboard.sv"
  `include "./../UVME/env/pkt_proc_coverage.sv"
  `include "./../UVME/env/pkt_proc_env.sv"
 
  

    // Add these lines to your package file
  `include "./../UVME/test/base_test.sv"
  `include "./../UVME/test/packet_write_test.sv"
  `include "./../UVME/test/packet_read_test.sv"
  `include "./../UVME/test/reset_test.sv"
  `include "./../UVME/test/concurrent_test.sv"
  `include "./../UVME/test/mixed_test.sv"
  `include "./../UVME/test/comprehensive_test.sv"
  

endpackage 