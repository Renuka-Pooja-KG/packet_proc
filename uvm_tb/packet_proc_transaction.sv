class packet_proc_transaction #(
  parameter int DATA_WIDTH = 32,
  parameter int PCK_LEN = 12,
  parameter int ADDR_WIDTH = 14
) extends uvm_sequence_item;
  rand bit in_sop;
  rand bit in_eop;
  rand bit [DATA_WIDTH-1:0] wr_data_i;
  rand bit pck_len_valid;
  rand bit [PCK_LEN-1:0] pck_len_i;
  rand bit enq_req;
  rand bit deq_req;
  rand bit empty_de_assert;
  rand bit [4:0] pck_proc_almost_full_value;
  rand bit [4:0] pck_proc_almost_empty_value;

  // Expected outputs
  bit out_sop;
  bit [DATA_WIDTH-1:0] rd_data_o;
  bit out_eop;
  bit pck_proc_full;
  bit pck_proc_empty;
  bit pck_proc_almost_full;
  bit pck_proc_almost_empty;
  bit [ADDR_WIDTH:0] pck_proc_wr_lvl;
  bit pck_proc_overflow;
  bit pck_proc_underflow;
  bit packet_drop;

  `uvm_object_param_utils(packet_proc_transaction #(.DATA_WIDTH(DATA_WIDTH), .PCK_LEN(PCK_LEN), .ADDR_WIDTH(ADDR_WIDTH)))

  function new(string name = "packet_proc_transaction");
    super.new(name);
  endfunction

  function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field_int("in_sop", in_sop, $bits(in_sop));
    printer.print_field_int("in_eop", in_eop, $bits(in_eop));
    printer.print_field_int("wr_data_i", wr_data_i, DATA_WIDTH);
    printer.print_field_int("pck_len_valid", pck_len_valid, $bits(pck_len_valid));
    printer.print_field_int("pck_len_i", pck_len_i, PCK_LEN);
    printer.print_field_int("enq_req", enq_req, $bits(enq_req));
    printer.print_field_int("deq_req", deq_req, $bits(deq_req));
    printer.print_field_int("empty_de_assert", empty_de_assert, $bits(empty_de_assert));
    printer.print_field_int("pck_proc_almost_full_value", pck_proc_almost_full_value, 5);
    printer.print_field_int("pck_proc_almost_empty_value", pck_proc_almost_empty_value, 5);
    printer.print_field_int("out_sop", out_sop, $bits(out_sop));
    printer.print_field_int("rd_data_o", rd_data_o, DATA_WIDTH);
    printer.print_field_int("out_eop", out_eop, $bits(out_eop));
    printer.print_field_int("pck_proc_full", pck_proc_full, $bits(pck_proc_full));
    printer.print_field_int("pck_proc_empty", pck_proc_empty, $bits(pck_proc_empty));
    printer.print_field_int("pck_proc_almost_full", pck_proc_almost_full, $bits(pck_proc_almost_full));
    printer.print_field_int("pck_proc_almost_empty", pck_proc_almost_empty, $bits(pck_proc_almost_empty));
    printer.print_field_int("pck_proc_wr_lvl", pck_proc_wr_lvl, ADDR_WIDTH+1);
    printer.print_field_int("pck_proc_overflow", pck_proc_overflow, $bits(pck_proc_overflow));
    printer.print_field_int("pck_proc_underflow", pck_proc_underflow, $bits(pck_proc_underflow));
    printer.print_field_int("packet_drop", packet_drop, $bits(packet_drop));
  endfunction
endclass 