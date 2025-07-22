class packet_proc_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp #(packet_proc_transaction, packet_proc_scoreboard) analysis_export;

  typedef struct {
    int expected_length;
    int actual_count;
    bit error_flag;
    bit [31:0] expected_data[$]; // queue for expected data
    int header_length;
  } packet_info_t;

  packet_info_t curr_packet;
  bit in_packet;

  `uvm_component_utils(packet_proc_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
    in_packet = 0;
    curr_packet = '{expected_length:0, actual_count:0, error_flag:0, expected_data:{}, header_length:0};
  endfunction

  function void write(packet_proc_transaction tr);
    // Track packet state and expected outputs
    if (tr.in_sop) begin
      if (in_packet) begin
        `uvm_error("SCOREBOARD", "Back-to-back in_sop without in_eop! Packet drop expected.")
        if (!tr.packet_drop)
          `uvm_error("SCOREBOARD", "Packet drop not asserted for back-to-back in_sop without in_eop!")
      end
      in_packet = 1;
      curr_packet.expected_length = tr.pck_len_i;
      curr_packet.header_length = tr.wr_data_i[11:0];
      curr_packet.actual_count = 1;
      curr_packet.error_flag = 0;
      curr_packet.expected_data.delete();
      curr_packet.expected_data.push_back(tr.wr_data_i);
      // Check out_sop
      if (!tr.out_sop)
        `uvm_error("SCOREBOARD", "Expected out_sop=1 at start of packet")
      // Check output data
      if (tr.rd_data_o !== tr.wr_data_i)
        `uvm_error("SCOREBOARD", $sformatf("Expected rd_data_o=0x%0h, got 0x%0h", tr.wr_data_i, tr.rd_data_o))
      // Check for packet length mismatch between pck_len_i and wr_data_i[11:0]
      if (tr.pck_len_valid && (tr.pck_len_i != tr.wr_data_i[11:0])) begin
        `uvm_error("SCOREBOARD", $sformatf("Packet length mismatch: pck_len_i=%0d, header[11:0]=%0d. Packet drop expected.", tr.pck_len_i, tr.wr_data_i[11:0]))
        if (!tr.packet_drop)
          `uvm_error("SCOREBOARD", "Packet drop not asserted for packet length mismatch!")
      end
      // Check for invalid packet length (0 or 1)
      if (tr.pck_len_valid && (tr.pck_len_i <= 1)) begin
        `uvm_error("SCOREBOARD", $sformatf("Invalid packet length: %0d. Packet drop expected.", tr.pck_len_i))
        if (!tr.packet_drop)
          `uvm_error("SCOREBOARD", "Packet drop not asserted for invalid packet length!")
      end
      // Check for in_sop and in_eop high at the same time
      if (tr.in_sop && tr.in_eop) begin
        `uvm_error("SCOREBOARD", "in_sop and in_eop asserted at the same time! Packet drop expected.")
        if (!tr.packet_drop)
          `uvm_error("SCOREBOARD", "Packet drop not asserted for in_sop and in_eop high at the same time!")
      end
    end else if (in_packet) begin
      curr_packet.actual_count++;
      curr_packet.expected_data.push_back(tr.wr_data_i);
      // Check output data
      if (tr.rd_data_o !== tr.wr_data_i)
        `uvm_error("SCOREBOARD", $sformatf("Expected rd_data_o=0x%0h, got 0x%0h", tr.wr_data_i, tr.rd_data_o))
    end

    // Check out_eop at end of packet
    if (tr.in_eop && in_packet) begin
      if (!tr.out_eop)
        `uvm_error("SCOREBOARD", "Expected out_eop=1 at end of packet")
      // Check for length < actual data payload
      if (curr_packet.actual_count > curr_packet.expected_length) begin
        `uvm_error("SCOREBOARD", $sformatf("Packet length (%0d) < actual data payload (%0d). Packet drop expected.", curr_packet.expected_length, curr_packet.actual_count))
        if (!tr.packet_drop)
          `uvm_error("SCOREBOARD", "Packet drop not asserted for length < actual data payload!")
      end
      // Check for length > actual data payload
      if (curr_packet.actual_count < curr_packet.expected_length) begin
        `uvm_error("SCOREBOARD", $sformatf("Packet length (%0d) > actual data payload (%0d). Packet drop expected.", curr_packet.expected_length, curr_packet.actual_count))
        if (!tr.packet_drop)
          `uvm_error("SCOREBOARD", "Packet drop not asserted for length > actual data payload!")
      end
      in_packet = 0;
    end

    // Check overflow/underflow/drop flags
    if (tr.pck_proc_overflow && !tr.packet_drop)
      `uvm_error("SCOREBOARD", "Overflow occurred but packet_drop not asserted")
    if (tr.pck_proc_underflow && !tr.packet_drop)
      `uvm_error("SCOREBOARD", "Underflow occurred but packet_drop not asserted")
    if (tr.packet_drop && !(tr.pck_proc_overflow || tr.pck_proc_underflow || (curr_packet.actual_count != curr_packet.expected_length) || (curr_packet.expected_length != curr_packet.header_length) || (tr.pck_len_valid && (tr.pck_len_i <= 1)) || (tr.in_sop && tr.in_eop) || (in_packet && tr.in_sop)))
      `uvm_warning("SCOREBOARD", "Packet drop asserted without a clear invalid or error condition")

    // Print all transactions for debug
    `uvm_info("SCOREBOARD", $sformatf("Received: %p", tr), UVM_LOW)
  endfunction
endclass 