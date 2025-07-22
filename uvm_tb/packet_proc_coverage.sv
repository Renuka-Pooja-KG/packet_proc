class packet_proc_coverage extends uvm_subscriber #(packet_proc_transaction);
  `uvm_component_utils(packet_proc_coverage)

  // Covergroup for protocol and functional coverage
  covergroup cg;
    option.per_instance = 1;

    // Coverpoint: Start of packet
    cp_in_sop: coverpoint t.in_sop;
    // Coverpoint: End of packet
    cp_in_eop: coverpoint t.in_eop;
    // Coverpoint: enq_req
    cp_enq_req: coverpoint t.enq_req;
    // Coverpoint: deq_req
    cp_deq_req: coverpoint t.deq_req;
    // Coverpoint: pck_len_valid
    cp_pck_len_valid: coverpoint t.pck_len_valid;
    // Coverpoint: packet length (from pck_len_i)
    cp_pck_len: coverpoint t.pck_len_i {
      bins invalid = {0,1};
      bins small = {[2:4]};
      bins medium = {[5:32]};
      bins large = {[33:4095]};
    }
    // Cross: pck_len_valid and packet length
    x_pck_len_valid_len: cross cp_pck_len_valid, cp_pck_len;
    // Coverpoint: packet drop
    cp_packet_drop: coverpoint t.packet_drop;
    // Coverpoint: overflow
    cp_overflow: coverpoint t.pck_proc_overflow;
    // Coverpoint: underflow
    cp_underflow: coverpoint t.pck_proc_underflow;
    // Coverpoint: simultaneous in_sop and in_eop
    cp_in_sop_and_eop: coverpoint {t.in_sop, t.in_eop} {
      bins both_high = {2'b11};
      bins only_sop = {2'b10};
      bins only_eop = {2'b01};
      bins neither = {2'b00};
    }
    // Cross: packet length and drop
    x_pck_len_drop: cross cp_pck_len, cp_packet_drop;
    // Cross: overflow and drop
    x_overflow_drop: cross cp_overflow, cp_packet_drop;
    // Cross: underflow and drop
    x_underflow_drop: cross cp_underflow, cp_packet_drop;

    // Coverpoints
    cp_almost_full: coverpoint t.pck_proc_almost_full;
    cp_almost_empty: coverpoint t.pck_proc_almost_empty;
    cp_empty_de_assert: coverpoint t.empty_de_assert;
    cp_buffer_full: coverpoint t.pck_proc_full;
    cp_buffer_empty: coverpoint t.pck_proc_empty;

    // Crosses
    x_almost_full_enq: cross cp_almost_full, cp_enq_req;
    x_almost_empty_deq: cross cp_almost_empty, cp_deq_req;
    x_almost_full_drop: cross cp_almost_full, cp_packet_drop;
    x_almost_empty_drop: cross cp_almost_empty, cp_packet_drop;
    x_empty_de_assert_empty: cross cp_empty_de_assert, cp_buffer_empty;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  // Signals should be sampled on every transaction (i.e., every time the monitor writes a transaction),
  // which is typically once per clock cycle at the interface boundary.
  function void write(packet_proc_transaction t);
    cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COVERAGE", $sformatf("Packet Processor Coverage: %0.2f%%", cg.get_coverage()), UVM_NONE)
  endfunction
endclass 