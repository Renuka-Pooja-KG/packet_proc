class packet_proc_simple_seq extends packet_proc_sequence_base;
  `uvm_object_utils(packet_proc_simple_seq)
  function new(string name = "packet_proc_simple_seq");
    super.new(name);
  endfunction

  task body();
    packet_proc_transaction tr = packet_proc_transaction::type_id::create("tr");
    // Fill in fields for a simple packet
    start_item(tr);
    tr.in_sop = 1;
    tr.in_eop = 1;
    tr.wr_data_i = 32'hA5A5A5A5;
    tr.pck_len_valid = 1;
    tr.pck_len_i = 12'd64;
    tr.enq_req = 1;
    tr.deq_req = 1;
    tr.empty_de_assert = 0;
    tr.pck_proc_almost_full_value = 5'd28;
    tr.pck_proc_almost_empty_value = 5'd4;
    finish_item(tr);
  endtask
endclass 

// Sequence 1: Back-to-back in_sop without in_eop
class seq_back_to_back_in_sop extends packet_proc_sequence_base;
  `uvm_object_utils(seq_back_to_back_in_sop)
  function new(string name = "seq_back_to_back_in_sop"); super.new(name); endfunction
  task body();
    packet_proc_transaction tr;
    // Start Packet 1
    tr = packet_proc_transaction::type_id::create("tr1");
    tr.in_sop = 1; tr.in_eop = 0; tr.pck_len_valid = 1; tr.pck_len_i = 12'd4; tr.enq_req = 1;
    start_item(tr); finish_item(tr);
    // Data for Packet 1
    tr = packet_proc_transaction::type_id::create("tr2");
    tr.in_sop = 0; tr.in_eop = 0; tr.enq_req = 1;
    start_item(tr); finish_item(tr);
    // Start Packet 2 without ending Packet 1
    tr = packet_proc_transaction::type_id::create("tr3");
    tr.in_sop = 1; tr.in_eop = 0; tr.pck_len_valid = 1; tr.pck_len_i = 12'd4; tr.enq_req = 1;
    start_item(tr); finish_item(tr);
    // End Packet 2
    tr = packet_proc_transaction::type_id::create("tr4");
    tr.in_sop = 0; tr.in_eop = 1; tr.enq_req = 1;
    start_item(tr); finish_item(tr);
  endtask
endclass


// Sequence 2: in_sop and in_eop high at the same clk
class seq_in_sop_and_in_eop_same_clk extends packet_proc_sequence_base;
  `uvm_object_utils(seq_in_sop_and_in_eop_same_clk)
  function new(string name = "seq_in_sop_and_in_eop_same_clk"); super.new(name); endfunction
  task body();
    packet_proc_transaction tr;
    // Start and end packet in same cycle
    tr = packet_proc_transaction::type_id::create("tr1");
    tr.in_sop = 1; tr.in_eop = 1; tr.pck_len_valid = 1; tr.pck_len_i = 12'd1; tr.enq_req = 1;
    start_item(tr); finish_item(tr);
  endtask
endclass

// Sequence 3: Packet length is 0 or 1
class seq_pktlen_zero_or_one extends packet_proc_sequence_base;
  `uvm_object_utils(seq_pktlen_zero_or_one)
  function new(string name = "seq_pktlen_zero_or_one"); super.new(name); endfunction
  task body();
    packet_proc_transaction tr;
    // Packet length 0
    tr = packet_proc_transaction::type_id::create("tr1");
    tr.in_sop = 1; tr.in_eop = 1; tr.pck_len_valid = 1; tr.pck_len_i = 12'd0; tr.enq_req = 1;
    start_item(tr); finish_item(tr);
    // Packet length 1
    tr = packet_proc_transaction::type_id::create("tr2");
    tr.in_sop = 1; tr.in_eop = 1; tr.pck_len_valid = 1; tr.pck_len_i = 12'd1; tr.enq_req = 1;
    start_item(tr); finish_item(tr);
  endtask
endclass

// Sequence: Data payload is greater than the selected packet length (pck_len_valid version)
class seq_payload_gt_pktlen_pcklen extends packet_proc_sequence_base;
  `uvm_object_utils(seq_payload_gt_pktlen_pcklen)
  function new(string name = "seq_payload_gt_pktlen_pcklen"); super.new(name); endfunction
  task body();
    packet_proc_transaction tr;
    int pkt_len = 8;
    // Start packet with pck_len_valid and pck_len_i
    tr = packet_proc_transaction::type_id::create("tr1");
    tr.in_sop = 1;
    tr.in_eop = 0;
    tr.pck_len_valid = 1;
    tr.pck_len_i = pkt_len;
    tr.enq_req = 1;
    tr.deq_req = 0;
    tr.randomize();
    start_item(tr); finish_item(tr);
    // Send pkt_len data beats (normal)
    for (int i = 0; i < pkt_len; i++) begin
      tr = packet_proc_transaction::type_id::create($sformatf("tr_data%d", i));
      tr.in_sop = 0;
      tr.in_eop = 0;
      tr.pck_len_valid = 0;
      tr.enq_req = 1;
      tr.deq_req = 0;
      tr.randomize();
      start_item(tr); finish_item(tr);
    end
    // Send 2 extra data beats (overflow)
    for (int i = 0; i < 2; i++) begin
      tr = packet_proc_transaction::type_id::create($sformatf("tr_extra%d", i));
      tr.in_sop = 0;
      tr.in_eop = (i == 1);
      tr.pck_len_valid = 0;
      tr.enq_req = 1;
      tr.deq_req = 0;
      tr.randomize();
      start_item(tr); finish_item(tr);
    end
  endtask
endclass

// Sequence: Data payload is less than the selected packet length (pck_len_valid version)
class seq_payload_lt_pktlen_pcklen extends packet_proc_sequence_base;
  `uvm_object_utils(seq_payload_lt_pktlen_pcklen)
  function new(string name = "seq_payload_lt_pktlen_pcklen"); super.new(name); endfunction
  task body();
    packet_proc_transaction tr;
    int pkt_len = 8;
    // Start packet with pck_len_valid and pck_len_i
    tr = packet_proc_transaction::type_id::create("tr1");
    tr.in_sop = 1;
    tr.in_eop = 0;
    tr.pck_len_valid = 1;
    tr.pck_len_i = pkt_len;
    tr.enq_req = 1;
    tr.deq_req = 0;
    tr.randomize();
    start_item(tr); finish_item(tr);
    // Send only 4 data beats (less than pkt_len)
    for (int i = 0; i < 3; i++) begin
      tr = packet_proc_transaction::type_id::create($sformatf("tr_data%d", i));
      tr.in_sop = 0;
      tr.in_eop = 0;
      tr.pck_len_valid = 0;
      tr.enq_req = 1;
      tr.deq_req = 0;
      tr.randomize();
      start_item(tr); finish_item(tr);
    end
    // End packet early
    tr = packet_proc_transaction::type_id::create("tr_early_eop");
    tr.in_sop = 0;
    tr.in_eop = 1;
    tr.pck_len_valid = 0;
    tr.enq_req = 1;
    tr.deq_req = 0;
    tr.randomize();
    start_item(tr); finish_item(tr);
  endtask
endclass

// Sequence: Data payload is greater than the selected packet length (header version)
class seq_payload_gt_pktlen_header extends packet_proc_sequence_base;
  `uvm_object_utils(seq_payload_gt_pktlen_header)
  function new(string name = "seq_payload_gt_pktlen_header"); super.new(name); endfunction
  task body();
    packet_proc_transaction tr;
    int pkt_len = 8;
    // Start packet with header length in wr_data_i[11:0]
    tr = packet_proc_transaction::type_id::create("tr1");
    tr.in_sop = 1;
    tr.in_eop = 0;
    tr.pck_len_valid = 0;
    tr.pck_len_i = 0;
    tr.wr_data_i = 32'(pkt_len);
    tr.enq_req = 1;
    tr.deq_req = 0;
    start_item(tr); finish_item(tr);
    // Send pkt_len data beats (normal)
    for (int i = 0; i < pkt_len; i++) begin
      tr = packet_proc_transaction::type_id::create($sformatf("tr_data%d", i));
      tr.in_sop = 0;
      tr.in_eop = 0;
      tr.pck_len_valid = 0;
      tr.enq_req = 1;
      tr.deq_req = 0;
      tr.randomize();
      start_item(tr); finish_item(tr);
    end
    // Send 2 extra data beats (overflow)
    for (int i = 0; i < 2; i++) begin
      tr = packet_proc_transaction::type_id::create($sformatf("tr_extra%d", i));
      tr.in_sop = 0;
      tr.in_eop = (i == 1);
      tr.pck_len_valid = 0;
      tr.enq_req = 1;
      tr.deq_req = 0;
      tr.randomize();
      start_item(tr); finish_item(tr);
    end
  endtask
endclass

// Sequence: Data payload is less than the selected packet length (header version)
class seq_payload_lt_pktlen_header extends packet_proc_sequence_base;
  `uvm_object_utils(seq_payload_lt_pktlen_header)
  function new(string name = "seq_payload_lt_pktlen_header"); super.new(name); endfunction
  task body();
    packet_proc_transaction tr;
    int pkt_len = 8;
    // Start packet with header length in wr_data_i[11:0]
    tr = packet_proc_transaction::type_id::create("tr1");
    tr.in_sop = 1;
    tr.in_eop = 0;
    tr.pck_len_valid = 0;
    tr.pck_len_i = 0;
    tr.wr_data_i = 32'(pkt_len);
    tr.enq_req = 1;
    tr.deq_req = 0;
    start_item(tr); finish_item(tr);
    // Send only 4 data beats (less than pkt_len)
    for (int i = 0; i < 3; i++) begin
      tr = packet_proc_transaction::type_id::create($sformatf("tr_data%d", i));
      tr.in_sop = 0;
      tr.in_eop = 0;
      tr.pck_len_valid = 0;
      tr.enq_req = 1;
      tr.deq_req = 0;
      tr.randomize();
      start_item(tr); finish_item(tr);
    end
    // End packet early
    tr = packet_proc_transaction::type_id::create("tr_early_eop");
    tr.in_sop = 0;
    tr.in_eop = 1;
    tr.pck_len_valid = 0;
    tr.enq_req = 1;
    tr.deq_req = 0;
    tr.randomize();
    start_item(tr); finish_item(tr);
  endtask
endclass 

// Sequence: Overflow in the packet (simulate by filling buffer)
class seq_overflow extends packet_proc_sequence_base;
  `uvm_object_utils(seq_overflow)
  function new(string name = "seq_overflow"); super.new(name); endfunction
  task body();
    packet_proc_transaction tr;
    int max_lvl = 1 << ADDR_WIDTH; // 2^ADDR_WIDTH
    int beats_sent = 0;
    int pkt_len;

    // Fill the buffer with packets until wr_lvl reaches max
    while (beats_sent < max_lvl) begin
      pkt_len = (max_lvl - beats_sent > 8) ? 8 : (max_lvl - beats_sent); // send up to 8 beats per packet
      // Start packet
      tr = packet_proc_transaction::type_id::create($sformatf("tr_pkt%d_0", beats_sent));
      tr.in_sop = 1; tr.in_eop = 0; tr.pck_len_valid = 1; tr.pck_len_i = pkt_len; tr.enq_req = 1; tr.deq_req = 0;
      tr.randomize();
      start_item(tr); finish_item(tr);
      // Data
      for (int j = 1; j < pkt_len-1; j++) begin
        tr = packet_proc_transaction::type_id::create($sformatf("tr_pkt%d_%d", beats_sent, j));
        tr.in_sop = 0; tr.in_eop = 0; tr.pck_len_valid = 0; tr.enq_req = 1; tr.deq_req = 0;
        tr.randomize();
        start_item(tr); finish_item(tr);
      end
      // End packet
      if (pkt_len > 1) begin
        tr = packet_proc_transaction::type_id::create($sformatf("tr_pkt%d_end", beats_sent));
        tr.in_sop = 0; tr.in_eop = 1; tr.pck_len_valid = 0; tr.enq_req = 1; tr.deq_req = 0;
        tr.randomize();
        start_item(tr); finish_item(tr);
      end
      beats_sent += pkt_len;
    end

    // One more valid packet to trigger overflow
    // Start of packet
    tr = packet_proc_transaction::type_id::create("tr_overflow_start");
    tr.in_sop = 1; tr.in_eop = 0; tr.pck_len_valid = 1; tr.pck_len_i = 1; tr.enq_req = 1; tr.deq_req = 0;
    tr.randomize();
    start_item(tr); finish_item(tr);
    // End of packet
    tr = packet_proc_transaction::type_id::create("tr_overflow_end");
    tr.in_sop = 0; tr.in_eop = 1; tr.pck_len_valid = 0; tr.enq_req = 1; tr.deq_req = 0;
    tr.randomize();
    start_item(tr); finish_item(tr);
  endtask
endclass

// Sequence to Detect FULL Condition (fills the entire buffer of DEPTH=16384)
class seq_full extends packet_proc_sequence_base;
  `uvm_object_utils(seq_full)
  function new(string name = "seq_full"); super.new(name); endfunction
  task body();
    packet_proc_transaction tr;
    int DEPTH = 16384;
    int beats_sent = 0;
    int pkt_len;

    // Fill the buffer with packets, each up to 8 beats (or less for last packet)
    while (beats_sent < DEPTH) begin
      pkt_len = (DEPTH - beats_sent > 8) ? 8 : (DEPTH - beats_sent); // up to 8 beats per packet
      // Start of packet
      tr = packet_proc_transaction::type_id::create($sformatf("tr_full_pkt%d_0", beats_sent));
      tr.in_sop = 1; tr.in_eop = 0; tr.pck_len_valid = 1; tr.pck_len_i = pkt_len; tr.enq_req = 1; tr.deq_req = 0;
      tr.randomize();
      start_item(tr); finish_item(tr);
      // Middle data beats
      for (int j = 1; j < pkt_len-1; j++) begin
        tr = packet_proc_transaction::type_id::create($sformatf("tr_full_pkt%d_%d", beats_sent, j));
        tr.in_sop = 0; tr.in_eop = 0; tr.pck_len_valid = 0; tr.enq_req = 1; tr.deq_req = 0;
        tr.randomize();
        start_item(tr); finish_item(tr);
      end
      // End of packet
      if (pkt_len > 1) begin
        tr = packet_proc_transaction::type_id::create($sformatf("tr_full_pkt%d_end", beats_sent));
        tr.in_sop = 0; tr.in_eop = 1; tr.pck_len_valid = 0; tr.enq_req = 1; tr.deq_req = 0;
        tr.randomize();
        start_item(tr); finish_item(tr);
      end
      beats_sent += pkt_len;
    end

    // One more enqueue to attempt to cause FULL
    tr = packet_proc_transaction::type_id::create("tr_full_overflow");
    tr.in_sop = 1; tr.in_eop = 1; tr.pck_len_valid = 1; tr.pck_len_i = 1; tr.enq_req = 1; tr.deq_req = 0;
    tr.randomize();
    start_item(tr); finish_item(tr);
  endtask
endclass

// Sequence to Detect EMPTY Condition
class seq_empty extends packet_proc_sequence_base;
  `uvm_object_utils(seq_empty)
  function new(string name = "seq_empty"); super.new(name); endfunction
  task body();
    packet_proc_transaction tr;
    // Ensure buffer is empty, then try to dequeue
    for (int i = 0; i < 3; i++) begin
      tr = packet_proc_transaction::type_id::create($sformatf("tr_empty%d", i));
      tr.enq_req = 0;
      tr.deq_req = 1;
      tr.in_sop = 0;
      tr.in_eop = 0;
      start_item(tr); finish_item(tr);
    end
  endtask
endclass

// Sequence to Detect UNDERFLOW Condition
class seq_underflow extends packet_proc_sequence_base;
  `uvm_object_utils(seq_underflow)
  function new(string name = "seq_underflow"); super.new(name); endfunction
  task body();
    packet_proc_transaction tr;
    int pkt_len = 4;
    // Fill and then empty the buffer
    for (int i = 0; i < pkt_len; i++) begin
      tr = packet_proc_transaction::type_id::create($sformatf("tr_fill%d", i));
      tr.in_sop = (i == 0);
      tr.in_eop = (i == pkt_len-1);
      tr.pck_len_valid = (i == 0);
      tr.pck_len_i = pkt_len;
      tr.enq_req = 1;
      tr.deq_req = 0;
      tr.randomize();
      start_item(tr); finish_item(tr);
    end
    // Dequeue to empty the buffer
    for (int i = 0; i < pkt_len; i++) begin
      tr = packet_proc_transaction::type_id::create($sformatf("tr_deq%d", i));
      tr.enq_req = 0;
      tr.deq_req = 1;
      tr.in_sop = 0;
      tr.in_eop = 0;
      start_item(tr); finish_item(tr);
    end
    // Continue to dequeue to cause underflow
    for (int i = 0; i < 3; i++) begin
      tr = packet_proc_transaction::type_id::create($sformatf("tr_underflow%d", i));
      tr.enq_req = 0;
      tr.deq_req = 1;
      tr.in_sop = 0;
      tr.in_eop = 0;
      start_item(tr); finish_item(tr);
    end
  endtask
endclass 
