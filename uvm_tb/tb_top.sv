`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

// Include all UVM files and interface
`include "packet_proc_if.sv"
`include "packet_proc_transaction.sv"
`include "packet_proc_driver.sv"
`include "packet_proc_sequencer.sv"
`include "packet_proc_monitor.sv"
`include "packet_proc_scoreboard.sv"
`include "packet_proc_agent.sv"
`include "packet_proc_env.sv"
`include "packet_proc_sequence_base.sv"
`include "packet_proc_seq_lib.sv"
`include "packet_proc_test_base.sv"
`include "packet_proc_test_lib.sv"
`include "packet_proc_coverage.sv"

module tb_top;
  // Parameters
  parameter DATA_WIDTH = 32;
  parameter ADDR_WIDTH = 14;
  parameter DEPTH = 1 << ADDR_WIDTH;
  parameter PCK_LEN = 12;

  // Clock and reset
  logic clk;
  logic rstn;
  logic sw_rst;

  // Instantiate interface
  packet_proc_if #(DATA_WIDTH, PCK_LEN, ADDR_WIDTH) pif(clk, rstn, sw_rst);

  // DUT instantiation
  pck_proc_int_mem_fsm #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DEPTH(DEPTH),
    .PCK_LEN(PCK_LEN)
  ) dut (
    .pck_proc_int_mem_fsm_clk(pif.clk),
    .pck_proc_int_mem_fsm_rstn(pif.rstn),
    .pck_proc_int_mem_fsm_sw_rst(pif.sw_rst),
    .empty_de_assert(pif.empty_de_assert),
    .enq_req(pif.enq_req),
    .in_sop(pif.in_sop),
    .wr_data_i(pif.wr_data_i),
    .in_eop(pif.in_eop),
    .pck_len_valid(pif.pck_len_valid),
    .pck_len_i(pif.pck_len_i),
    .deq_req(pif.deq_req),
    .out_sop(pif.out_sop),
    .rd_data_o(pif.rd_data_o),
    .out_eop(pif.out_eop),
    .pck_proc_full(pif.pck_proc_full),
    .pck_proc_empty(pif.pck_proc_empty),
    .pck_proc_almost_full_value(pif.pck_proc_almost_full_value),
    .pck_proc_almost_empty_value(pif.pck_proc_almost_empty_value),
    .pck_proc_almost_full(pif.pck_proc_almost_full),
    .pck_proc_almost_empty(pif.pck_proc_almost_empty),
    .pck_proc_wr_lvl(pif.pck_proc_wr_lvl),
    .pck_proc_overflow(pif.pck_proc_overflow),
    .pck_proc_underflow(pif.pck_proc_underflow),
    .packet_drop(pif.packet_drop)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rstn = 0;
    sw_rst = 0;
    #20;
    rstn = 1;
    #20;
    sw_rst = 1;
    #20;
    sw_rst = 0;
  end

  // UVM configuration
  initial begin
    uvm_config_db#(virtual packet_proc_if)::set(null, "*", "vif", pif);
    run_test();
  end

  // Waveform dumping
  initial begin
    $dumpfile("packet_proc_tb.vcd");
    $dumpvars(0, tb_top);
  end

  // Timeout
  initial begin
    #1000000; // 1ms timeout
    $display("Simulation timeout");
    $finish;
  end 

endmodule 