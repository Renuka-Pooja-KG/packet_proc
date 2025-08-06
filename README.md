# Packet Processor RTL and UVM Verification

## Overview

This project implements a sophisticated packet processing system with dual FIFO architecture, featuring separate write and read state machines for handling packet data and length information. The system is designed for high-throughput packet processing with comprehensive error detection and flow control mechanisms.

## Table of Contents

1. [RTL Architecture](#rtl-architecture)
2. [Key Features](#key-features)
3. [State Machine Design](#state-machine-design)
4. [Error Detection and Packet Drop Logic](#error-detection-and-packet-drop-logic)
5. [UVM Verification Architecture](#uvm-verification-architecture)
6. [Reference Model Implementation](#reference-model-implementation)
7. [Usage and Testing](#usage-and-testing)

## RTL Architecture

### Module: `pck_proc_int_mem_fsm`

The main packet processor module implements a dual-FIFO architecture with the following key components:

#### Parameters
- `DATA_WIDTH = 32`: Data bus width
- `ADDR_WIDTH = 14`: Address width for main buffer (16,384 deep)
- `DEPTH = 1<<ADDR_WIDTH`: Buffer depth (16,384)
- `PCK_LEN = 12`: Packet length field width

#### Dual FIFO Structure
1. **Main Data Buffer**: 16,384 × 32-bit FIFO for packet data
2. **Packet Length Buffer**: 32 × 12-bit FIFO for packet length information

#### Interface Signals

**Inputs:**
- `pck_proc_int_mem_fsm_clk`: System clock
- `pck_proc_int_mem_fsm_rstn`: Asynchronous reset (active low)
- `pck_proc_int_mem_fsm_sw_rstn`: Synchronous reset (active low)
- `empty_de_assert`: Empty de-assert control
- `enq_req`: Enqueue request
- `in_sop`: Start of packet indicator
- `wr_data_i[31:0]`: Write data input
- `in_eop`: End of packet indicator
- `pck_len_valid`: Packet length valid signal
- `pck_len_i[11:0]`: Packet length input
- `deq_req`: Dequeue request
- `pck_proc_almost_full_value[4:0]`: Almost full threshold
- `pck_proc_almost_empty_value[4:0]`: Almost empty threshold

**Outputs:**
- `out_sop`: Start of packet output
- `rd_data_o[31:0]`: Read data output
- `out_eop`: End of packet output
- `pck_proc_full`: Buffer full indicator
- `pck_proc_empty`: Buffer empty indicator
- `pck_proc_almost_full`: Almost full indicator
- `pck_proc_almost_empty`: Almost empty indicator
- `pck_proc_wr_lvl[14:0]`: Write level indicator
- `pck_proc_overflow`: Overflow indicator
- `pck_proc_underflow`: Underflow indicator
- `packet_drop`: Packet drop indicator

## Key Features

### 1. Dual State Machine Architecture
- **Write FSM**: Handles packet reception and storage
- **Read FSM**: Manages packet retrieval and output

### 2. Packet Length Handling
Two modes for packet length specification:
- **Mode 1**: `pck_len_valid` signal with `pck_len_i` field
- **Mode 2**: Header-based length extraction from `wr_data_i[11:0]`

### 3. Flow Control
- Configurable almost full/empty thresholds
- Overflow/underflow detection
- Write level monitoring

### 4. Error Detection
Comprehensive packet validation with 7 distinct error conditions

### 5. Data Integrity
- Multi-cycle pipeline for signal registration
- Proper packet boundary handling
- FIFO pointer management

## State Machine Design

### Write FSM States

```systemverilog
localparam IDLE_W       = 2'd0;  // Idle state
localparam WRITE_HEADER = 2'd1;  // Writing packet header
localparam WRITE_DATA   = 2'd2;  // Writing packet data
localparam ERROR        = 2'd3;  // Error state
```

**State Transitions:**
- `IDLE_W → WRITE_HEADER`: When `enq_req && in_sop`
- `WRITE_HEADER → WRITE_DATA`: After valid header processing
- `WRITE_HEADER → ERROR`: When packet is invalid
- `WRITE_DATA → WRITE_HEADER`: When new packet starts
- `WRITE_DATA → IDLE_W`: When packet ends
- `ERROR → IDLE_W`: Return to idle after error

### Read FSM States

```systemverilog
localparam IDLE_R      = 2'd0;  // Idle state
localparam READ_HEADER = 2'd1;  // Reading packet header
localparam READ_DATA   = 2'd2;  // Reading packet data
```

**State Transitions:**
- `IDLE_R → READ_HEADER`: When `deq_req && !buffer_empty`
- `READ_HEADER → READ_DATA`: Always transition after header
- `READ_DATA → READ_HEADER`: When packet ends and new packet available
- `READ_DATA → IDLE_R`: When buffer empty or no more dequeue requests

## Error Detection and Packet Drop Logic

The system implements sophisticated error detection with 7 distinct invalid packet conditions:

### Invalid Packet Conditions

1. **Condition 1**: `in_sop && in_eop` - Start and end of packet in same cycle
2. **Condition 2**: `in_sop_r && in_sop_r1` - Back-to-back start of packet without end
3. **Condition 3**: `in_sop && (~in_eop_r1) && (present_state_w==WRITE_DATA)` - Start during data phase
4. **Condition 4**: `(count_w < pck_len_r2 - 1) && (pck_len_r2 != 0) && (in_eop_r1)` - Early end of packet
5. **Condition 5**: `(count_w == pck_len_r2-1 || pck_len_r2 == 0) && (~in_eop_r1) && (present_state_w==WRITE_DATA)` - Late end of packet
6. **Condition 6**: `pck_proc_overflow` - Buffer overflow condition
7. **Condition 7**: `pck_len_valid && (pck_len_i <= 1)` - Invalid packet length (0 or 1)

### Packet Drop Handling
When any invalid condition is detected:
- Packet is marked for dropping (`packet_drop = 1`)
- Write pointer is rolled back
- Write level is adjusted
- Packet counter is reset

## UVM Verification Architecture

### Project Structure
```
packet-processor-1/
├── RTL/                          # RTL implementation
│   ├── pck_proc_int_mem_TOP.sv   # Main packet processor
│   ├── int_buffer_top.sv         # Main FIFO controller
│   ├── int_buffer.sv             # Main data buffer
│   ├── pck_len_buffer.sv         # Packet length buffer
│   └── pck_len_fifo.sv           # Packet length FIFO controller
└── Verification/UVME/            # UVM environment
    ├── top/pkt_proc_interface.sv # Interface with assertions
    ├── env/pkt_proc_scoreboard.sv # Enhanced scoreboard
    └── sequence/pkt_proc_seq_item.sv # Sequence item
```

### UVM Components

#### 1. Interface (`packet_proc_if`)
- Clocking blocks for driver and monitor
- Protocol assertions for interface validation
- Signal definitions matching RTL interface

#### 2. Transaction Class (`packet_proc_transaction`)
- Randomizable input fields
- Expected output fields
- Protocol constraints for valid packet generation
- Error testing capabilities

#### 3. Driver (`packet_proc_driver`)
- Drives interface signals based on transaction data
- Implements proper timing with clocking blocks
- Handles non-blocking assignments for signal integrity

#### 4. Monitor (`packet_proc_monitor`)
- Samples interface signals on clock edges
- Creates transaction objects from sampled data
- Sends transactions to scoreboard and coverage

#### 5. Scoreboard (`packet_proc_scoreboard`)
- **Reference Model Implementation**: Complete behavioral model of RTL
- **State Machine Tracking**: Dual FSM state management
- **FIFO Simulation**: Accurate buffer and pointer modeling
- **Error Detection**: All 7 invalid packet conditions
- **Output Comparison**: Comprehensive output validation

#### 6. Coverage (`packet_proc_coverage`)
- Protocol coverage for all interface signals
- Cross coverage for error conditions
- Functional coverage for state transitions
- Packet length and data coverage

### Reference Model Implementation

The scoreboard implements a comprehensive reference model that accurately mirrors the RTL behavior:

#### Key Components:
1. **Dual State Machines**: Exact FSM behavior matching RTL
2. **FIFO Simulation**: 16,384 × 32-bit main buffer + 32 × 12-bit length buffer
3. **Registered Signal Pipeline**: Multi-cycle signal registration
4. **Error Detection Logic**: All 7 invalid packet conditions
5. **Packet Drop Handling**: Proper rollback and state management
6. **Output Generation**: Expected outputs based on current state

#### Reference Model Functions:
- `update_registered_signals()`: Signal pipeline management
- `update_write_fsm()`: Write state machine transitions
- `update_read_fsm()`: Read state machine transitions
- `update_buffer_operations()`: FIFO read/write operations
- `is_packet_invalid()`: Error condition detection
- `update_outputs()`: Expected output generation
- `compare_outputs()`: Output validation

## Usage and Testing

### Running the Testbench

1. **Compilation**:
   ```bash
   cd uvm_tb
   make
   ```

2. **Simulation**:
   ```bash
   make run TEST=packet_proc_simple_test
   ```

### Available Tests

1. **Basic Tests**:
   - `packet_proc_simple_test`: Basic packet processing
   - `test_back_to_back_in_sop`: Back-to-back packet testing
   - `test_pktlen_lt_payload`: Packet length validation

2. **Error Condition Tests**:
   - `test_in_sop_and_in_eop_same_clk`: Same cycle SOP/EOP
   - `test_pktlen_zero_or_one`: Invalid packet length
   - `test_overflow`: Buffer overflow testing
   - `test_underflow`: Buffer underflow testing

3. **Comprehensive Tests**:
   - `test_all_packet_drop_cases`: All error conditions
   - `test_payload_gt_pktlen`: Payload vs length mismatch

### Verification Features

#### 1. Protocol Assertions
- No enqueue during overflow/full conditions
- No dequeue during underflow/empty conditions
- No simultaneous SOP/EOP
- Valid packet length constraints

#### 2. Coverage Goals
- 100% state machine coverage
- 100% error condition coverage
- 100% packet length range coverage
- Cross coverage for error scenarios

#### 3. Scoreboard Validation
- All output signal validation
- State machine synchronization
- FIFO pointer accuracy
- Packet drop condition verification

## Critical Aspects

### 1. Timing Considerations
- Multi-cycle pipeline requires careful signal registration
- Non-blocking assignments ensure proper timing
- Clock domain crossing handled correctly

### 2. Error Handling
- Comprehensive error detection prevents data corruption
- Proper packet drop handling maintains FIFO integrity
- State machine recovery after errors

### 3. Performance Optimization
- Dual FIFO architecture enables parallel processing
- Configurable thresholds for flow control
- Efficient pointer management

### 4. Verification Completeness
- Reference model matches RTL behavior exactly
- All error conditions are tested
- Coverage ensures comprehensive validation

## Conclusion

This packet processor implementation provides a robust, high-performance solution for packet processing with comprehensive error detection and flow control. The UVM verification environment ensures thorough validation through a complete reference model, extensive test coverage, and protocol assertions.

The dual FIFO architecture with separate state machines for read and write operations enables efficient packet handling while maintaining data integrity and providing detailed error reporting. 