# Packet Processor UVM Verification Architecture

## 📋 Table of Contents
1. [Overview](#overview)
2. [Architecture Design](#architecture-design)
3. [Directory Structure](#directory-structure)
4. [UVM Components](#uvm-components)
5. [Test Sequences](#test-sequences)
6. [Test Cases](#test-cases)
7. [Usage Guide](#usage-guide)
8. [Simulation Flow](#simulation-flow)
9. [Debugging Guide](#debugging-guide)

## 🎯 Overview

This document describes the UVM (Universal Verification Methodology) architecture for the Packet Processor verification environment. The architecture follows a **single-agent approach** with enhanced capabilities for concurrent testing, reset verification, and comprehensive coverage.

### Key Features
- **Single Agent Architecture**: Unified interface for all operations
- **Concurrent Testing**: Fork/join based concurrent read/write operations
- **Reset Verification**: Comprehensive reset scenario testing
- **Packet-based Testing**: SOP/EOP packet protocol support
- **Stress Testing**: Overflow/underflow condition testing
- **Configurable Reset**: Proper reset initialization for all tests

## 🏗️ Architecture Design

### Design Philosophy
The architecture was designed with the following principles:
1. **Simplicity**: Single agent to avoid multiple driver conflicts
2. **Concurrency**: Fork/join based concurrent operations
3. **Completeness**: All DUT functionality covered
4. **Maintainability**: Clear separation of concerns
5. **Reusability**: Modular sequence and test design

### Architecture Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                    UVM Testbench                            │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Test      │    │ Environment │    │   Agent     │     │
│  │             │    │             │    │             │     │
│  │ ┌─────────┐ │    │ ┌─────────┐ │    │ ┌─────────┐ │     │
│  │ │Sequence │ │───▶│ │Scoreboard│ │    │ │ Driver  │ │     │
│  │ └─────────┘ │    │ └─────────┘ │    │ └─────────┘ │     │
│  │             │    │             │    │             │     │
│  │ ┌─────────┐ │    │ ┌─────────┐ │    │ ┌─────────┐ │     │
│  │ │Config   │ │    │ │Coverage │ │    │ │Monitor  │ │     │
│  │ └─────────┘ │    │ └─────────┘ │    │ └─────────┘ │     │
│  └─────────────┘    └─────────────┘    │             │     │
│                                        │ ┌─────────┐ │     │
│                                        │ │Sequencer│ │     │
│                                        │ └─────────┘ │     │
│                                        └─────────────┘     │
├─────────────────────────────────────────────────────────────┤
│                    Virtual Interface                        │
├─────────────────────────────────────────────────────────────┤
│                    DUT (Packet Processor)                   │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Directory Structure

```
Verification/UVME/
├── package/
│   └── pkt_proc_pkg.sv              # Main UVM package
├── sequence/
│   ├── pkt_proc_seq_item.sv         # Transaction item
│   ├── pkt_proc_sequences.sv        # Main sequences
│   └── reset_test_sequences.sv      # Reset sequences
├── agent/
│   ├── pkt_proc_agent.sv            # Main agent
│   ├── pkt_proc_driver.sv           # Driver
│   ├── pkt_proc_monitor.sv          # Monitor
│   └── pkt_proc_sequencer.sv        # Sequencer
├── env/
│   ├── pkt_proc_env.sv              # Environment
│   └── pkt_proc_scoreboard.sv       # Scoreboard
├── test/
│   ├── base_test.sv                 # Basic test
│   ├── packet_write_test.sv         # Packet write test
│   ├── packet_read_test.sv          # Packet read test
│   ├── reset_test.sv                # Reset test
│   ├── concurrent_test.sv           # Concurrent test
│   ├── mixed_test.sv                # Mixed operations test
│   └── comprehensive_test.sv        # Comprehensive test
├── top/
│   ├── pkt_proc_interface.sv        # Virtual interface
│   └── tb_top.sv                    # Top testbench
└── SIM/
    ├── compile_list.f               # Compilation list
    └── Makefile                     # Build system
```

## 🔧 UVM Components

### 1. Transaction Item (`pkt_proc_seq_item.sv`)
**Purpose**: Defines the data structure for stimulus generation and monitoring.

**Key Features**:
- All DUT input/output signals
- Protocol constraints for write/read operations
- Randomization support
- Coverage hooks

**Important Signals**:
```systemverilog
// Control signals
logic pck_proc_int_mem_fsm_rstn;    // Async reset
logic pck_proc_int_mem_fsm_sw_rstn; // Sync reset

// Write interface
logic enq_req;                      // Write request
logic in_sop;                       // Start of packet
logic [31:0] wr_data_i;             // Write data
logic in_eop;                       // End of packet
logic pck_len_valid;                // Packet length valid
logic [11:0] pck_len_i;             // Packet length

// Read interface
logic deq_req;                      // Read request
logic out_sop;                      // Output SOP
logic [31:0] rd_data_o;             // Read data
logic out_eop;                      // Output EOP
```

### 2. Sequences (`pkt_proc_sequences.sv`)

#### Base Sequence (`sequence_base`)
**Purpose**: Provides reset initialization and common functionality.

**Features**:
- Configurable reset cycles
- Idle cycles after reset
- Enable/disable reset control

#### Main Sequences
1. **`write_only_sequence`**: Write-only operations
2. **`read_only_sequence`**: Read-only operations
3. **`concurrent_rw_sequence`**: Built-in concurrent operations
4. **`packet_write_sequence`**: Packet writing with SOP/EOP
5. **`continuous_read_sequence`**: Continuous read operations
6. **`mixed_operations_sequence`**: Natural read/write mix

### 3. Reset Sequences (`reset_test_sequences.sv`)

#### Reset Test Sequences
1. **`async_reset_test_sequence`**: Async reset during operations
2. **`sync_reset_test_sequence`**: Sync reset during operations
3. **`dual_reset_test_sequence`**: Both resets simultaneously
4. **`reset_during_packet_sequence`**: Reset during packet transmission
5. **`reset_during_read_sequence`**: Reset during read operations

### 4. Agent (`pkt_proc_agent.sv`)
**Purpose**: Encapsulates driver, monitor, and sequencer.

**Components**:
- **Driver**: Applies stimulus to DUT
- **Monitor**: Samples DUT inputs/outputs
- **Sequencer**: Manages sequence execution

### 5. Environment (`pkt_proc_env.sv`)
**Purpose**: Top-level UVM component that connects all elements.

**Features**:
- Agent instantiation
- Scoreboard connection
- Virtual interface configuration
- Coverage collection

### 6. Scoreboard (`pkt_proc_scoreboard.sv`)
**Purpose**: Functional verification and reference model.

**Features**:
- Behavioral reference model
- Write/read FSM tracking
- Buffer level monitoring
- Overflow/underflow detection
- Statistics collection

## 🧪 Test Sequences

### Sequence Hierarchy
```
sequence_base (with reset initialization)
├── write_only_sequence
├── read_only_sequence
├── concurrent_rw_sequence
├── packet_write_sequence
├── continuous_read_sequence
├── mixed_operations_sequence
├── overflow_test_sequence
└── underflow_test_sequence

reset_test_sequence_base
├── async_reset_test_sequence
├── sync_reset_test_sequence
├── dual_reset_test_sequence
├── reset_during_packet_sequence
└── reset_during_read_sequence
```

### Concurrent Testing Strategy
The architecture uses `fork/join` for concurrent operations:

```systemverilog
// Example: Concurrent read/write
fork
  write_seq.start(m_sequencer);
  read_seq.start(m_sequencer);
join
```

## 🎯 Test Cases

### 1. Basic Test (`base_test.sv`)
- Basic write operations (20 writes)
- Basic read operations (20 reads)
- Proper reset initialization

### 2. Packet Write Test (`packet_write_test.sv`)
- Basic packet writing (10 packets)
- Large packet writing (5 packets, 8-20 words)
- Small packet writing (15 packets, 2-6 words)

### 3. Packet Read Test (`packet_read_test.sv`)
- Basic read operations (50 reads)
- Continuous read operations (100 reads)
- Underflow testing (200 reads)

### 4. Reset Test (`reset_test.sv`)
- Async reset during operations
- Sync reset during operations
- Dual reset scenarios
- Reset during packet transmission
- Reset during read operations

### 5. Concurrent Test (`concurrent_test.sv`)
- Built-in concurrent sequence (20 writes, 30 reads)
- Separate sequences with fork/join
- High-load concurrent testing

### 6. Mixed Test (`mixed_test.sv`)
- Mixed operations (100 transactions)
- Overflow testing (500 writes)
- Underflow testing (500 reads)

### 7. Comprehensive Test (`comprehensive_test.sv`)
- All functionality in one test
- 10 phases covering all aspects
- Complete verification coverage

## 🚀 Usage Guide

### 1. Compilation
```bash
cd Verification/SIM
make compile
```

### 2. Running Individual Tests
```bash
# Basic operations
make base_test

# Packet operations
make packet_write_test
make packet_read_test

# Reset testing
make reset_test

# Concurrent operations
make concurrent_test

# Mixed operations
make mixed_test

# Comprehensive testing
make comprehensive_test
```

### 3. Running All Tests
```bash
make all
```

### 4. Regression Testing
```bash
make regression
```

### 5. Waveform Viewing
```bash
make waveform
```

### 6. Cleanup
```bash
make clean
```

## 🔄 Simulation Flow

### 1. Initialization Phase
```
1. UVM configuration setup
2. Virtual interface assignment
3. Environment build
4. Reset initialization
```

### 2. Test Execution Phase
```
1. Sequence creation
2. Reset initialization (if enabled)
3. Test sequence execution
4. Concurrent operations (if applicable)
5. Completion verification
```

### 3. Verification Phase
```
1. Scoreboard comparison
2. Coverage collection
3. Statistics reporting
4. Error checking
```

## 🐛 Debugging Guide

### 1. Common Issues

#### Reset Initialization Problems
```systemverilog
// Check reset configuration
reset_init_seq.reset_cycles = 5;  // Adjust as needed
reset_init_seq.idle_cycles = 3;   // Adjust as needed
```

#### Concurrent Operation Issues
```systemverilog
// Ensure child sequences don't reset
write_seq.enable_reset = 0;
read_seq.enable_reset = 0;
```

#### Sequence Randomization Issues
```systemverilog
// Check constraint satisfaction
assert(tr.randomize() with {
  enq_req || deq_req;  // At least one operation
});
```

### 2. Debug Commands

#### UVM Verbosity
```bash
# Increase verbosity
+UVM_VERBOSITY=UVM_HIGH

# Set specific component verbosity
+uvm_set_verbosity=*,UVM_HIGH,0
```

#### Waveform Debugging
```bash
# Enable waveform dumping
make waveform

# View specific signals
# Use SimVision to examine DUT behavior
```

### 3. Coverage Analysis
```bash
# Run with coverage
xrun -coverage all -f compile_list.f +UVM_TESTNAME=test_name

# View coverage report
imc -exec coverage.cmd
```

## 📊 Performance Considerations

### 1. Simulation Speed
- Use appropriate reset cycles (5-10 cycles)
- Limit test transaction counts for faster simulation
- Use `enable_reset = 0` for child sequences

### 2. Memory Usage
- Monitor buffer levels during testing
- Use reasonable packet sizes
- Clean up between tests

### 3. Coverage Optimization
- Focus on critical paths
- Use directed sequences for edge cases
- Monitor coverage progress

## 🔧 Configuration Options

### 1. Reset Configuration
```systemverilog
// In test files
reset_init_seq.reset_cycles = 5;    // Reset duration
reset_init_seq.idle_cycles = 3;     // Idle after reset
```

### 2. Test Configuration
```systemverilog
// Sequence parameters
write_seq.write_count = 20;         // Number of writes
read_seq.read_count = 20;           // Number of reads
packet_seq.packet_count = 10;       // Number of packets
```

### 3. UVM Configuration
```systemverilog
// Verbosity levels
uvm_top.set_report_verbosity_level(UVM_LOW);

// Timeout settings
#1000000; // 1ms timeout
```

## 📈 Best Practices

### 1. Test Development
- Start with basic tests
- Add complexity gradually
- Use proper reset initialization
- Test edge cases thoroughly

### 2. Sequence Design
- Inherit from base sequence
- Use proper randomization
- Handle concurrent operations carefully
- Implement proper error handling

### 3. Verification Strategy
- Use reference model in scoreboard
- Monitor all DUT outputs
- Collect comprehensive coverage
- Report meaningful statistics

## 🎉 Conclusion

This UVM architecture provides a comprehensive, maintainable, and efficient verification environment for the Packet Processor. The single-agent approach with enhanced concurrent testing capabilities ensures thorough verification while maintaining simplicity and avoiding multiple driver conflicts.

The architecture supports all major verification scenarios including basic operations, packet processing, reset verification, concurrent operations, and stress testing. The modular design allows for easy extension and modification as requirements evolve. 