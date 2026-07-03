# RV32I CPU Verification Plan

## DUT Scope
- Synthesizable 5-stage RV32I subset CPU
- IF / ID / EX / MEM / WB pipeline
- Forwarding, load-use stall/bubble insertion, branch/jump flush
- Architectural commit interface

## Supported Instructions
- R-type: ADD, SUB, AND, OR, SLT
- I-type: ADDI, ANDI, ORI, SLTI
- Memory: LW, SW
- Control: BEQ, BNE, JAL, JALR
- U-type: LUI, AUIPC
- Program termination: EBREAK

## Verification Architecture
DUT → commit interface → passive monitor → transaction mailbox → scoreboard

## Checking Strategy
- Commit-level ISA reference model
- Directed regression programs
- Seeded constrained pseudo-random programs
- SystemVerilog assertions
- Functional coverage

## Key Checks
- x0 remains constant at zero
- Register write-back matches the reference model
- Store address and data match the reference model
- Load-use hazards inject bubbles
- Branch and jump wrong-path instructions do not commit
- Invalid pipeline stages cannot redirect control flow
- EBREAK ends the program without X-state commits
- WB-to-ID bypass returns same-cycle write-back data