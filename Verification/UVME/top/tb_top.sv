// Top testbench file for Packet Processor UVM Verification
// This file instantiates the RTL DUT and UVM testbench

`timescale 1ns/1ps

module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pkt_proc_pkg::*;

  // Clock and reset signals
  logic pck_proc_int_mem_fsm_clk;  
  // Clock generation
  initial begin
    pck_proc_int_mem_fsm_clk = 0;
  end

  always #5 pck_proc_int_mem_fsm_clk = ~pck_proc_int_mem_fsm_clk; // 100MHz clock
  
  // Interface instantiation
  pkt_proc_interface pkt_proc_if(.pck_proc_int_mem_fsm_clk(pck_proc_int_mem_fsm_clk));
  
  // DUT instantiation
  pck_proc_int_mem_fsm #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(14),
    .DEPTH(16384),
    .PCK_LEN(12)
  ) dut (
    // Clock and reset
    .pck_proc_int_mem_fsm_clk(pck_proc_int_mem_fsm_clk),
    .pck_proc_int_mem_fsm_rstn(pkt_proc_if.pck_proc_int_mem_fsm_rstn),
    .pck_proc_int_mem_fsm_sw_rstn(pkt_proc_if.pck_proc_int_mem_fsm_sw_rstn),
    
    // Control signals
    .empty_de_assert(pkt_proc_if.empty_de_assert),
    
    // Write interface
    .enq_req(pkt_proc_if.enq_req),
    .in_sop(pkt_proc_if.in_sop),
    .wr_data_i(pkt_proc_if.wr_data_i),
    .in_eop(pkt_proc_if.in_eop),
    .pck_len_valid(pkt_proc_if.pck_len_valid),
    .pck_len_i(pkt_proc_if.pck_len_i),
    
    // Read interface
    .deq_req(pkt_proc_if.deq_req),
    .out_sop(pkt_proc_if.out_sop),
    .rd_data_o(pkt_proc_if.rd_data_o),
    .out_eop(pkt_proc_if.out_eop),
    
    // Status signals
    .pck_proc_full(pkt_proc_if.pck_proc_full),
    .pck_proc_empty(pkt_proc_if.pck_proc_empty),
    .pck_proc_almost_full_value(pkt_proc_if.pck_proc_almost_full_value),
    .pck_proc_almost_empty_value(pkt_proc_if.pck_proc_almost_empty_value),
    .pck_proc_almost_full(pkt_proc_if.pck_proc_almost_full),
    .pck_proc_almost_empty(pkt_proc_if.pck_proc_almost_empty),
    .pck_proc_wr_lvl(pkt_proc_if.pck_proc_wr_lvl),
    .pck_proc_overflow(pkt_proc_if.pck_proc_overflow),
    .pck_proc_underflow(pkt_proc_if.pck_proc_underflow),
    .packet_drop(pkt_proc_if.packet_drop)
  );
  
  // UVM test execution
  initial begin
    // Set up UVM configuration
    uvm_config_db#(virtual pkt_proc_interface)::set(null, "*", "vif", pkt_proc_if);
    
    // Set up UVM verbosity
    uvm_top.set_report_verbosity_level(UVM_LOW);
    
    // Enable UVM transaction recording
    uvm_top.enable_print_topology = 1;
    
    // Run the test
    run_test();
  end
  
  // Waveform dumping
  initial begin
    $shm_open("wave.shm");
    $shm_probe("AS");
  end
  
  
  // Clock edge monitoring for debugging
  always @(posedge pck_proc_int_mem_fsm_clk) begin
    // Monitor reset signals
    if (pkt_proc_if.pck_proc_int_mem_fsm_rstn == 0 || pkt_proc_if.pck_proc_int_mem_fsm_sw_rstn == 1) begin
      $display("Time %0t: RESET ACTIVE - async_rstn=%0b, sync_rstn=%0b", 
               $time, pkt_proc_if.pck_proc_int_mem_fsm_rstn, pkt_proc_if.pck_proc_int_mem_fsm_sw_rstn);
    end
    
    // Monitor write operations
    if (pkt_proc_if.enq_req) begin
      $display("Time %0t: WRITE - enq_req=1, in_sop=%0b, in_eop=%0b, wr_data=0x%0h, pck_len_valid=%0b, pck_len_i=0x%0h", 
               $time, pkt_proc_if.in_sop, pkt_proc_if.in_eop, pkt_proc_if.wr_data_i, 
               pkt_proc_if.pck_len_valid, pkt_proc_if.pck_len_i);
    end
    
    // Monitor read operations
    if (pkt_proc_if.deq_req) begin
      $display("Time %0t: READ - deq_req=1, out_sop=%0b, out_eop=%0b, rd_data=0x%0h", 
               $time, pkt_proc_if.out_sop, pkt_proc_if.out_eop, pkt_proc_if.rd_data_o);
    end
    
    // Monitor DUT internal state
    $display("Time %0t: DUT_STATE - present_state=%0d, wr_lvl=0x%0h, count_w=0x%0h", 
             $time, dut.present_state_w, dut.pck_proc_wr_lvl, dut.count_w);
    
    if (pkt_proc_if.pck_proc_overflow) begin
      $display("Time %0t: OVERFLOW detected!", $time);
    end
    
    if (pkt_proc_if.pck_proc_underflow) begin
      $display("Time %0t: UNDERFLOW detected!", $time);
    end
    
    if (pkt_proc_if.packet_drop) begin
      $display("Time %0t: PACKET DROP detected!", $time);
    end
  end

endmodule 