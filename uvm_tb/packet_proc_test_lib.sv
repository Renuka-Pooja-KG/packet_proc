class packet_proc_simple_test extends packet_proc_test_base;
  `uvm_component_utils(packet_proc_simple_test)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    packet_proc_simple_seq seq = packet_proc_simple_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);
    phase.raise_objection(this);
    #1000ns;
    phase.drop_objection(this);
  endtask
endclass

// Test for back-to-back in_sop without in_eop
class test_back_to_back_in_sop extends packet_proc_test_base;
  `uvm_component_utils(test_back_to_back_in_sop)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    seq_back_to_back_in_sop seq = seq_back_to_back_in_sop::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// Test for packet length < actual data payload
class test_pktlen_lt_payload extends packet_proc_test_base;
  `uvm_component_utils(test_pktlen_lt_payload)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    seq_pktlen_lt_payload seq = seq_pktlen_lt_payload::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// Test for packet length > actual data payload
class test_pktlen_gt_payload extends packet_proc_test_base;
  `uvm_component_utils(test_pktlen_gt_payload)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    seq_pktlen_gt_payload seq = seq_pktlen_gt_payload::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// Test for in_sop and in_eop high at the same clk
class test_in_sop_and_in_eop_same_clk extends packet_proc_test_base;
  `uvm_component_utils(test_in_sop_and_in_eop_same_clk)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    seq_in_sop_and_in_eop_same_clk seq = seq_in_sop_and_in_eop_same_clk::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// Test for packet length is 0 or 1
class test_pktlen_zero_or_one extends packet_proc_test_base;
  `uvm_component_utils(test_pktlen_zero_or_one)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    seq_pktlen_zero_or_one seq = seq_pktlen_zero_or_one::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// Test for overflow (buffer full)
class test_overflow extends packet_proc_test_base;
  `uvm_component_utils(test_overflow)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    seq_overflow seq = seq_overflow::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// Test for full condition
class test_full extends packet_proc_test_base;
  `uvm_component_utils(test_full)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    seq_full seq = seq_full::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// Test for empty condition
class test_empty extends packet_proc_test_base;
  `uvm_component_utils(test_empty)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    seq_empty seq = seq_empty::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// Test for underflow condition
class test_underflow extends packet_proc_test_base;
  `uvm_component_utils(test_underflow)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    seq_underflow seq = seq_underflow::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// Test for payload > pck_len_i (pck_len_valid version)
class test_payload_gt_pktlen_pcklen extends packet_proc_test_base;
  `uvm_component_utils(test_payload_gt_pktlen_pcklen)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    seq_payload_gt_pktlen_pcklen seq = seq_payload_gt_pktlen_pcklen::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// Test for payload < pck_len_i (pck_len_valid version)
class test_payload_lt_pktlen_pcklen extends packet_proc_test_base;
  `uvm_component_utils(test_payload_lt_pktlen_pcklen)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    seq_payload_lt_pktlen_pcklen seq = seq_payload_lt_pktlen_pcklen::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// Test for payload > header length (header version)
class test_payload_gt_pktlen_header extends packet_proc_test_base;
  `uvm_component_utils(test_payload_gt_pktlen_header)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    seq_payload_gt_pktlen_header seq = seq_payload_gt_pktlen_header::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// Test for payload < header length (header version)
class test_payload_lt_pktlen_header extends packet_proc_test_base;
  `uvm_component_utils(test_payload_lt_pktlen_header)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    seq_payload_lt_pktlen_header seq = seq_payload_lt_pktlen_header::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// Master test to run all sequences in order
typedef packet_proc_test_base super_t;
class test_all_packet_drop_cases extends super_t;
  `uvm_component_utils(test_all_packet_drop_cases)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq_back_to_back_in_sop::type_id::create("seq1").start(env.agent.sequencer);
    #100ns;
    seq_in_sop_and_in_eop_same_clk::type_id::create("seq2").start(env.agent.sequencer);
    #100ns;
    seq_pktlen_zero_or_one::type_id::create("seq3").start(env.agent.sequencer);
    #100ns;
    seq_overflow::type_id::create("seq4").start(env.agent.sequencer);
    #100ns;
    seq_full::type_id::create("seq5").start(env.agent.sequencer);
    #100ns;
    seq_empty::type_id::create("seq6").start(env.agent.sequencer);
    #100ns;
    seq_underflow::type_id::create("seq7").start(env.agent.sequencer);
    #100ns;
    seq_payload_gt_pktlen_pcklen::type_id::create("seq8").start(env.agent.sequencer);
    #100ns;
    seq_payload_lt_pktlen_pcklen::type_id::create("seq9").start(env.agent.sequencer);
    #100ns;
    seq_payload_gt_pktlen_header::type_id::create("seq10").start(env.agent.sequencer);
    #100ns;
    seq_payload_lt_pktlen_header::type_id::create("seq11").start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass 