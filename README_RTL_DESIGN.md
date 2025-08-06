# Packet Processor RTL Design Documentation

## 📋 Table of Contents
1. [Overview](#overview)
2. [Block Diagram](#block-diagram)
3. [Module Hierarchy](#module-hierarchy)
4. [FSM Design](#fsm-design)
5. [Signal Interface](#signal-interface)
6. [Functionality](#functionality)
7. [Design Parameters](#design-parameters)
8. [Timing Requirements](#timing-requirements)

## 🎯 Overview

The Packet Processor is a high-performance packet buffering and processing system designed to handle packet-based data streams with configurable buffer depths and packet lengths. The design implements separate write and read finite state machines (FSMs) for concurrent operation.

### Key Features
- **Dual FSM Architecture**: Separate write and read state machines
- **Configurable Buffer**: Adjustable depth and data width
- **Packet Protocol**: SOP/EOP based packet handling
- **Dual Reset Support**: Asynchronous and synchronous reset
- **Status Monitoring**: Full, empty, almost full/empty indicators
- **Overflow/Underflow Protection**: Error detection and handling

## 🏗️ Block Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Packet Processor                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐                    ┌─────────────┐         │
│  │  Write FSM  │                    │  Read FSM   │         │
│  │             │                    │             │         │
│  │ ┌─────────┐ │                    │ ┌─────────┐ │         │
│  │ │ IDLE_W  │ │                    │ │ IDLE_R  │ │         │
│  │ └─────────┘ │                    │ └─────────┘ │         │
│  │ ┌─────────┐ │                    │ ┌─────────┐ │         │
│  │ │WRITE_   │ │                    │ │READ_    │ │         │
│  │ │HEADER   │ │                    │ │HEADER   │ │         │
│  │ └─────────┘ │                    │ └─────────┘ │         │
│  │ ┌─────────┐ │                    │ ┌─────────┐ │         │
│  │ │WRITE_   │ │                    │ │READ_    │ │         │
│  │ │DATA     │ │                    │ │DATA     │ │         │
│  │ └─────────┘ │                    │ └─────────┘ │         │
│  └─────────────┘                    └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐                    ┌─────────────┐         │
│  │  Internal   │                    │  Packet     │         │
│  │  Buffer     │                    │  Length     │         │
│  │             │                    │  Buffer     │         │
│  │ ┌─────────┐ │                    │ ┌─────────┐ │         │
│  │ │ Memory  │ │                    │ │ FIFO    │ │         │
│  │ │ Array   │ │                    │ │ Buffer  │ │         │
│  │ └─────────┘ │                    │ └─────────┘ │         │
│  └─────────────┘                    └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐                    ┌─────────────┐         │
│  │  Status     │                    │  Control    │         │
│  │  Logic      │                    │  Logic      │         │
│  │             │                    │             │         │
│  │ • Full      │                    │ • Reset     │         │
│  │ • Empty     │                    │ • Enable    │         │
│  │ • Almost    │                    │ • Valid     │         │
│  │   Full/Empty│                    │ • Protocol  │         │
│  └─────────────┘                    └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Module Hierarchy

```
pck_proc_int_mem_fsm (TOP)
├── int_buffer_top
│   └── int_buffer
├── pck_len_buffer
└── pck_len_fifo
```

### Module Descriptions

#### 1. `pck_proc_int_mem_fsm` (Top Module)
- **Purpose**: Main packet processor with dual FSM control
- **Features**: Write/read FSMs, status monitoring, error handling

#### 2. `int_buffer_top`
- **Purpose**: Internal buffer wrapper
- **Features**: Memory interface, address management

#### 3. `int_buffer`
- **Purpose**: Core memory storage
- **Features**: Dual-port memory, write/read control

#### 4. `pck_len_buffer`
- **Purpose**: Packet length storage
- **Features**: Length tracking, validation

#### 5. `pck_len_fifo`
- **Purpose**: Packet length FIFO
- **Features**: Length queuing, overflow protection

## 🔄 FSM Design

### Write FSM States

| State | Code | Description |
|-------|------|-------------|
| `IDLE_W` | 2'd0 | Waiting for write request |
| `WRITE_HEADER` | 2'd1 | Processing packet header |
| `WRITE_DATA` | 2'd2 | Writing packet data |
| `ERROR` | 2'd3 | Error state |

### Write FSM Transitions
```
IDLE_W ──enq_req & in_sop──▶ WRITE_HEADER
WRITE_HEADER ──valid──▶ WRITE_DATA
WRITE_DATA ──in_eop──▶ IDLE_W
WRITE_DATA ──overflow──▶ ERROR
ERROR ──reset──▶ IDLE_W
```

### Read FSM States

| State | Code | Description |
|-------|------|-------------|
| `IDLE_R` | 2'd0 | Waiting for read request |
| `READ_HEADER` | 2'd1 | Reading packet header |
| `READ_DATA` | 2'd2 | Reading packet data |

### Read FSM Transitions
```
IDLE_R ──deq_req & ~empty──▶ READ_HEADER
READ_HEADER ──valid──▶ READ_DATA
READ_DATA ──out_eop──▶ IDLE_R
```

## 🔌 Signal Interface

### Input Signals

| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| `pck_proc_int_mem_fsm_clk` | 1 | Input | System clock |
| `pck_proc_int_mem_fsm_rstn` | 1 | Input | Asynchronous reset (active low) |
| `pck_proc_int_mem_fsm_sw_rstn` | 1 | Input | Synchronous reset (active low) |
| `empty_de_assert` | 1 | Input | Empty de-assert control |
| `enq_req` | 1 | Input | Write request |
| `in_sop` | 1 | Input | Start of packet |
| `wr_data_i` | 32 | Input | Write data |
| `in_eop` | 1 | Input | End of packet |
| `pck_len_valid` | 1 | Input | Packet length valid |
| `pck_len_i` | 12 | Input | Packet length |
| `deq_req` | 1 | Input | Read request |
| `pck_proc_almost_full_value` | 5 | Input | Almost full threshold |
| `pck_proc_almost_empty_value` | 5 | Input | Almost empty threshold |

### Output Signals

| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| `out_sop` | 1 | Output | Output start of packet |
| `rd_data_o` | 32 | Output | Read data |
| `out_eop` | 1 | Output | Output end of packet |
| `pck_proc_full` | 1 | Output | Buffer full indicator |
| `pck_proc_empty` | 1 | Output | Buffer empty indicator |
| `pck_proc_almost_full` | 1 | Output | Almost full indicator |
| `pck_proc_almost_empty` | 1 | Output | Almost empty indicator |
| `pck_proc_wr_lvl` | 15 | Output | Write level |
| `pck_proc_overflow` | 1 | Output | Overflow indicator |
| `pck_proc_underflow` | 1 | Output | Underflow indicator |
| `packet_drop` | 1 | Output | Packet drop indicator |

## ⚙️ Functionality

### 1. Write Operation Flow

#### Packet Header Processing
```systemverilog
// When in_sop is asserted
if (in_sop && enq_req) begin
    // Capture packet length
    if (pck_len_valid)
        pck_len_r <= pck_len_i;
    else
        pck_len_r <= wr_data_i[11:0];
    
    // Transition to WRITE_HEADER
    next_state_w <= WRITE_HEADER;
end
```

#### Packet Data Writing
```systemverilog
// In WRITE_DATA state
if (enq_req && ~pck_proc_full) begin
    // Write data to buffer
    wr_en <= 1'b1;
    wr_data <= wr_data_i;
    
    // Increment counter
    count_w <= count_w + 1;
    
    // Check for packet end
    if (in_eop)
        next_state_w <= IDLE_W;
end
```

### 2. Read Operation Flow

#### Packet Header Reading
```systemverilog
// When deq_req is asserted and buffer not empty
if (deq_req && ~pck_proc_empty) begin
    // Read packet length
    pck_len_rd_en <= 1'b1;
    
    // Transition to READ_HEADER
    next_state_r <= READ_HEADER;
end
```

#### Packet Data Reading
```systemverilog
// In READ_DATA state
if (deq_req && ~pck_proc_empty) begin
    // Read data from buffer
    rd_en <= 1'b1;
    rd_data_o <= rd_data_out_w;
    
    // Increment counter
    count_r <= count_r + 1;
    
    // Check for packet end
    if (count_r == packet_length - 1)
        next_state_r <= IDLE_R;
end
```

### 3. Status Monitoring

#### Buffer Level Tracking
```systemverilog
// Write level calculation
always_ff @(posedge clk) begin
    if (wr_en && ~rd_en)
        pck_proc_wr_lvl <= pck_proc_wr_lvl + 1;
    else if (~wr_en && rd_en)
        pck_proc_wr_lvl <= pck_proc_wr_lvl - 1;
end
```

#### Status Indicators
```systemverilog
// Full condition
assign pck_proc_full = (pck_proc_wr_lvl == DEPTH);

// Empty condition
assign pck_proc_empty = (pck_proc_wr_lvl == 0);

// Almost full/empty
assign pck_proc_almost_full = (pck_proc_wr_lvl >= pck_proc_almost_full_value);
assign pck_proc_almost_empty = (pck_proc_wr_lvl <= pck_proc_almost_empty_value);
```

### 4. Error Handling

#### Overflow Detection
```systemverilog
// Overflow occurs when writing to full buffer
assign pck_proc_overflow = (enq_req && pck_proc_full);

// Packet drop when overflow occurs
assign packet_drop = pck_proc_overflow;
```

#### Underflow Detection
```systemverilog
// Underflow occurs when reading from empty buffer
assign pck_proc_underflow = (deq_req && pck_proc_empty);
```

## 📊 Design Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DATA_WIDTH` | 32 | Data bus width |
| `ADDR_WIDTH` | 14 | Address bus width |
| `DEPTH` | 16384 | Buffer depth (2^ADDR_WIDTH) |
| `PCK_LEN` | 12 | Packet length field width |

### Parameter Relationships
```systemverilog
// Buffer depth calculation
DEPTH = 1 << ADDR_WIDTH  // 2^14 = 16384

// Memory size
MEMORY_SIZE = DEPTH * DATA_WIDTH  // 16384 * 32 = 524,288 bits
```

## ⏱️ Timing Requirements

### Clock Requirements
- **Frequency**: Configurable (typically 100MHz)
- **Duty Cycle**: 50%
- **Jitter**: < 1% of clock period

### Reset Requirements
- **Async Reset**: Asserted for minimum 5 clock cycles
- **Sync Reset**: Asserted for minimum 3 clock cycles
- **Recovery Time**: 2 clock cycles after reset de-assertion

### Protocol Timing
- **Setup Time**: 2ns before clock edge
- **Hold Time**: 1ns after clock edge
- **Propagation Delay**: < 10ns for status signals

## 🔧 Configuration Examples

### 1. Standard Configuration
```systemverilog
pck_proc_int_mem_fsm #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(14),
    .DEPTH(16384),
    .PCK_LEN(12)
) dut (
    // Port connections
);
```

### 2. High-Performance Configuration
```systemverilog
pck_proc_int_mem_fsm #(
    .DATA_WIDTH(64),
    .ADDR_WIDTH(16),
    .DEPTH(65536),
    .PCK_LEN(16)
) dut (
    // Port connections
);
```

### 3. Low-Power Configuration
```systemverilog
pck_proc_int_mem_fsm #(
    .DATA_WIDTH(16),
    .ADDR_WIDTH(12),
    .DEPTH(4096),
    .PCK_LEN(8)
) dut (
    // Port connections
);
```

## 🎯 Design Features

### 1. Concurrent Operation
- Independent write and read FSMs
- No blocking between write and read operations
- Efficient resource utilization

### 2. Packet Integrity
- SOP/EOP protocol support
- Packet length validation
- Error detection and reporting

### 3. Status Monitoring
- Real-time buffer level tracking
- Configurable threshold indicators
- Overflow/underflow protection

### 4. Reset Flexibility
- Asynchronous reset for power-up
- Synchronous reset for runtime control
- Independent reset domains

## 🔍 Debug Features

### 1. Status Monitoring
- Buffer level indicators
- FSM state monitoring
- Error condition reporting

### 2. Performance Metrics
- Write/read throughput
- Buffer utilization
- Error rate tracking

### 3. Protocol Compliance
- SOP/EOP sequence validation
- Packet length verification
- Timing compliance checking

## 📈 Performance Characteristics

### 1. Throughput
- **Write Throughput**: 1 word per clock cycle
- **Read Throughput**: 1 word per clock cycle
- **Concurrent Throughput**: 2 words per clock cycle

### 2. Latency
- **Write Latency**: 1 clock cycle
- **Read Latency**: 1 clock cycle
- **Reset Recovery**: 5 clock cycles

### 3. Resource Utilization
- **Memory**: DEPTH × DATA_WIDTH bits
- **Logic**: ~2000 LUTs
- **Registers**: ~500 FFs

## 🎉 Conclusion

The Packet Processor RTL design provides a robust, high-performance solution for packet buffering and processing. The dual FSM architecture enables efficient concurrent operations while maintaining packet integrity and providing comprehensive status monitoring.

The design is highly configurable and can be adapted for various performance and resource requirements. The modular structure facilitates easy integration and verification in larger systems. 