# RV32I 5-Stage Pipelined CPU Design & Verification

A synthesizable RV32I subset CPU with a SystemVerilog verification environment.

## Overview

This project implements a five-stage pipelined RV32I subset processor:

```text
IF → ID → EX → MEM → WB
```

The design includes pipelined datapath/control logic, forwarding, load-use hazard handling, branch/jump flushing, explicit valid-bit propagation, and a commit-level verification interface.

## Supported Instructions

| Category | Instructions |
|---|---|
| R-type | ADD, SUB, AND, OR, SLT |
| I-type | ADDI, ANDI, ORI, SLTI |
| Memory | LW, SW |
| Branch | BEQ, BNE |
| Jump | JAL, JALR |
| U-type | LUI, AUIPC |
| Termination | EBREAK |

## Key RTL Features

- Five-stage IF/ID/EX/MEM/WB pipeline
- EX/MEM and MEM/WB forwarding paths
- WB-to-ID register-file write-through bypass
- Load-use hazard detection with bubble insertion
- BEQ/BNE control-hazard flushing
- JAL/JALR redirect handling
- Explicit valid-bit propagation across pipeline registers
- EBREAK-based clean program termination
- Retire-level commit trace interface

## Architecture

### CPU Pipeline and Hazard Control

<img width="3179" height="1380" alt="rv32i_pipeline_architecture" src="https://github.com/user-attachments/assets/1a932765-a6b2-4b61-97f2-aae40f3ca313" />


### Verification Architecture

<img width="3179" height="1580" alt="rv32i_verification_architecture" src="https://github.com/user-attachments/assets/fe97c69c-f6a8-4f0d-a78d-18d95013f0e0" />


```text
DUT
 ↓
commit interface
 ↓
passive monitor
 ↓
transaction mailbox
 ├─ scoreboard + ISA reference model
 └─ functional coverage
```

## Verification Components

- `rv32_commit_if.sv` — architectural commit interface
- `rv32_commit_pkg.sv` — transaction, passive monitor, mailbox-based scoreboard, coverage, and seeded pseudo-random generator
- `cpu_assertions.sv` — SystemVerilog assertions
- `cpu_top_tb.sv` — top-level simulation testbench
- `run_random_regression.tcl` — multi-seed random regression script

## Verification Strategy

- Directed instruction regression
- Commit-level ISA reference-model checking
- SystemVerilog assertions
- Functional coverage
- Seeded constrained pseudo-random regression
- Multi-seed automated regression

## Key Checks

- `x0` remains zero
- Register write-back matches the ISA reference model
- Store address and data match the ISA reference model
- Load-use hazards insert bubbles
- Invalid pipeline stages cannot redirect control flow
- Wrong-path branch/jump instructions do not commit
- EBREAK terminates execution without X-state commits
- WB-to-ID bypass returns same-cycle write-back data

## Regression Results

### Directed Regression

| Metric | Result |
|---|---:|
| Committed instructions | 65 |
| Scoreboard mismatches | 0 |
| Assertion failures | 0 |
| Commit functional coverage | 100% |
| Branch outcome coverage | 100% |

### Seeded Constrained Pseudo-Random Regression

| Seed | Random Instructions | Commits | Result |
|---|---:|---:|---|
| `0x20260702` | 80 | 81 | PASS |
| `0x00000001` | 80 | 81 | PASS |
| `0x00000011` | 80 | 81 | PASS |
| `0x12345678` | 80 | 81 | PASS |
| `0x5A5A2026` | 80 | 81 | PASS |

## Bug Found by Random Regression

Seeded pseudo-random testing exposed a WB-to-ID read-after-write hazard.

### Symptom

A consumer instruction in ID captured stale source-register data when the producer wrote the same register during WB in the same cycle.

### Root Cause

EX-stage forwarding could not repair the operand because the producer had already exited the EX/MEM and MEM/WB forwarding stages.

### Fix

A write-through bypass was added inside the register file:

```text
WB write data → ID read port
```

The fix was validated through the directed regression and five seeded pseudo-random regressions.

## Tools

- Vivado
- XSim
- Verilog
- SystemVerilog
- Tcl

## Project Scope

This project focuses on a verified RV32I subset pipeline and commit-level verification infrastructure. It does not include caches, CSR, interrupts, AXI, or full privileged architecture support.
