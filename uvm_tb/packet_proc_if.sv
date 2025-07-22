interface packet_proc_if #(parameter DATA_WIDTH=32, PCK_LEN=12, ADDR_WIDTH = 14) (input logic clk, rstn, sw_rst);
  // Inputs to DUT
  logic empty_de_assert;
  logic enq_req;
  logic in_sop;
  logic [DATA_WIDTH-1:0] wr_data_i;
  logic in_eop;
  logic pck_len_valid;
  logic [PCK_LEN-1:0] pck_len_i;
  logic deq_req;
  logic [4:0] pck_proc_almost_full_value;
  logic [4:0] pck_proc_almost_empty_value;

  // Outputs from DUT
  logic out_sop;
  logic [DATA_WIDTH-1:0] rd_data_o;
  logic out_eop;
  logic pck_proc_full;
  logic pck_proc_empty;
  logic pck_proc_almost_full;
  logic pck_proc_almost_empty;
  logic [ADDR_WIDTH:0] pck_proc_wr_lvl;
  logic pck_proc_overflow;
  logic pck_proc_underflow;
  logic packet_drop;

  // Protocol assertions
  // 1. No enq_req when overflow or full
  property no_enq_on_overflow_full;
    @(posedge clk) disable iff (!rstn || sw_rst)
      (pck_proc_overflow || pck_proc_full) |-> !enq_req;
  endproperty
  assert property (no_enq_on_overflow_full)
    else $error("enq_req asserted during overflow or full!");

  // 2. No deq_req when underflow or empty
  property no_deq_on_underflow_empty;
    @(posedge clk) disable iff (!rstn || sw_rst)
      (pck_proc_underflow || pck_proc_empty) |-> !deq_req;
  endproperty
  assert property (no_deq_on_underflow_empty)
    else $error("deq_req asserted during underflow or empty!");

  // 4. in_sop and in_eop high at same clk
  property no_in_sop_and_in_eop_same_time;
    @(posedge clk) disable iff (!rstn || sw_rst)
      in_sop && in_eop |-> 0;
  endproperty
  assert property (no_in_sop_and_in_eop_same_time)
    else $error("in_sop and in_eop asserted at the same time!");

  // 5. Packet length is 0 or 1
  property no_zero_or_one_length;
    @(posedge clk) disable iff (!rstn || sw_rst)
      in_sop && pck_len_valid |-> (pck_len_i > 1);
  endproperty
  assert property (no_zero_or_one_length)
    else $error("Packet length is 0 or 1!");

  // Clocking block for driver
  clocking drv_cb @(posedge clk);
    default input #1 output #1;
    output empty_de_assert, enq_req, in_sop, wr_data_i, in_eop, pck_len_valid, pck_len_i, deq_req, pck_proc_almost_full_value, pck_proc_almost_empty_value;
    input out_sop, rd_data_o, out_eop, pck_proc_full, pck_proc_empty, pck_proc_almost_full, pck_proc_almost_empty, pck_proc_wr_lvl, pck_proc_overflow, pck_proc_underflow, packet_drop;
  endclocking

  // Clocking block for monitor
  clocking mon_cb @(posedge clk);
    default input #1 output #1;
    input empty_de_assert, enq_req, in_sop, wr_data_i, in_eop, pck_len_valid, pck_len_i, deq_req, pck_proc_almost_full_value, pck_proc_almost_empty_value;
    input out_sop, rd_data_o, out_eop, pck_proc_full, pck_proc_empty, pck_proc_almost_full, pck_proc_almost_empty, pck_proc_wr_lvl, pck_proc_overflow, pck_proc_underflow, packet_drop;
  endclocking
endinterface 