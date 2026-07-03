# RV32I CPU Regression Summary

## Directed Regression
- Test mode: directed instruction program
- Total committed instructions: 65
- Scoreboard result: PASS
- Scoreboard mismatches: 0
- Assertion failures: 0
- Commit functional coverage: 100%
- Branch outcome coverage: 100%

## Seeded Constrained Pseudo-Random Regression
- Random instructions per seed: 80
- Program termination: EBREAK
- Total commits per seed: 81
- Scoreboard checking: instruction-by-instruction commit comparison
- Assertion failures: 0

| Seed | Result | Commits |
|---|---:|---:|
| 0x20260702 | PASS | 81 |
| 0x00000001 | PASS | 81 |
| 0x00000011 | PASS | 81 |
| 0x12345678 | PASS | 81 |
| 0x5A5A2026 | PASS | 81 |

## Bug Found by Random Regression
- Issue: WB-to-ID read-after-write hazard.
- Symptom: an instruction in ID captured stale register data when its producer wrote back in the same cycle.
- Root cause: EX-stage forwarding could not repair a stale value once the producer had already left MEM/WB.
- Fix: added register-file write-through bypass from WB write data to both read ports.
- Regression protection: added a directed WB-to-ID dependency test.