`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/01 16:36:04
// Design Name: 
// Module Name: rv32_commit_pkg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


package rv32_commit_pkg;

    // =========================================
    // Commit transaction
    // =========================================
    class rv32_commit_txn;

        int unsigned seq_id;

        logic        valid;
        logic [31:0] pc;
        logic [31:0] instr;

        logic        rd_we;
        logic [4:0]  rd;
        logic [31:0] rd_data;

        logic        mem_we;
        logic [31:0] mem_addr;
        logic [31:0] mem_wdata;

        function void print();
            $display(
                "[TXN %0d] PC=0x%08h INSTR=0x%08h | rd_we=%0d rd=x%0d data=0x%08h | mem_we=%0d addr=0x%08h wdata=0x%08h",
                seq_id,
                pc,
                instr,
                rd_we,
                rd,
                rd_data,
                mem_we,
                mem_addr,
                mem_wdata
            );
        endfunction

    endclass


    // =========================================
    // Passive commit monitor
    // =========================================
    class rv32_commit_monitor;

        virtual rv32_commit_if vif;
        mailbox #(rv32_commit_txn) mon2sb;
        mailbox #(rv32_commit_txn) mon2cov;

        int unsigned txn_count;

        function new(
            virtual rv32_commit_if vif,
            mailbox #(rv32_commit_txn) mon2sb,
            mailbox #(rv32_commit_txn) mon2cov
        );
            this.vif       = vif;
            this.mon2sb    = mon2sb;
            this.mon2cov   = mon2cov;
            this.txn_count = 0;
        endfunction

        task run();
            rv32_commit_txn txn;

            forever begin
                @(posedge vif.clk);

                if (!vif.rst &&
                    vif.commit_valid &&
                    (^vif.commit_instr !== 1'bx)) begin

                    txn = new();

                    txn_count = txn_count + 1;

                    txn.seq_id    = txn_count;
                    txn.valid     = vif.commit_valid;
                    txn.pc        = vif.commit_pc;
                    txn.instr     = vif.commit_instr;

                    txn.rd_we     = vif.commit_rd_we;
                    txn.rd        = vif.commit_rd;
                    txn.rd_data   = vif.commit_rd_data;

                    txn.mem_we    = vif.commit_mem_we;
                    txn.mem_addr  = vif.commit_mem_addr;
                    txn.mem_wdata = vif.commit_mem_wdata;

                    mon2sb.put(txn);
                    mon2cov.put(txn);
                    txn.print();
                end
            end
        endtask

    endclass
    
    // =========================================
    // Transaction-based reference-model scoreboard
    // =========================================
    class rv32_scoreboard;

        mailbox #(rv32_commit_txn) mon2sb;

        logic [31:0] ref_regs [0:31];
        logic [31:0] ref_mem  [0:255];
        logic [31:0] ref_imem [0:255];

        logic [31:0] ref_pc;
        bit use_external_program;

        int unsigned check_count;
        int unsigned error_count;

        // Expected side effects for one ISA instruction
        logic        exp_rd_we;
        logic [4:0]  exp_rd;
        logic [31:0] exp_rd_data;

        logic        exp_mem_we;
        logic [31:0] exp_mem_addr;
        logic [31:0] exp_mem_wdata;

        logic [31:0] instr;
        logic [6:0]  opcode;
        logic [2:0]  funct3;
        logic [6:0]  funct7;
        logic [4:0]  rs1;
        logic [4:0]  rs2;
        logic [4:0]  rd;

        logic [31:0] rs1_data;
        logic [31:0] rs2_data;

        logic [31:0] imm_i;
        logic [31:0] imm_s;
        logic [31:0] imm_b;
        logic [31:0] imm_u;
        logic [31:0] imm_j;

        logic [31:0] next_pc;
        logic [31:0] alu_result;
        logic        branch_taken;

        function new(
            mailbox #(rv32_commit_txn) mon2sb,
            bit use_external_program = 1'b0
        );
            this.mon2sb = mon2sb;
            this.use_external_program = use_external_program;
        endfunction

        task set_program(input logic [31:0] prog_mem [0:255]);
            int i;
            begin
                for (i = 0; i < 256; i++)
                    ref_imem[i] = prog_mem[i];
        
                use_external_program = 1'b1;
            end
        endtask

        task initialize();
            int i;

            if (!use_external_program)
                $readmemh("imem.mem", ref_imem);

            for (i = 0; i < 32; i++)
                ref_regs[i] = 32'd0;

            for (i = 0; i < 256; i++)
                ref_mem[i] = 32'd0;

            ref_pc      = 32'd0;
            check_count = 0;
            error_count = 0;
        endtask

        task execute_reference_instruction();
            begin
                instr  = ref_imem[ref_pc[9:2]];
                opcode = instr[6:0];
                funct3 = instr[14:12];
                funct7 = instr[31:25];
                rs1    = instr[19:15];
                rs2    = instr[24:20];
                rd     = instr[11:7];

                rs1_data = (rs1 == 0) ? 32'd0 : ref_regs[rs1];
                rs2_data = (rs2 == 0) ? 32'd0 : ref_regs[rs2];

                imm_i = {{20{instr[31]}}, instr[31:20]};
                imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
                imm_b = {{19{instr[31]}}, instr[31], instr[7],
                         instr[30:25], instr[11:8], 1'b0};
                imm_u = {instr[31:12], 12'b0};
                imm_j = {{11{instr[31]}}, instr[31], instr[19:12],
                         instr[20], instr[30:21], 1'b0};

                exp_rd_we    = 1'b0;
                exp_rd       = rd;
                exp_rd_data  = 32'd0;

                exp_mem_we    = 1'b0;
                exp_mem_addr  = 32'd0;
                exp_mem_wdata = 32'd0;

                alu_result   = 32'd0;
                branch_taken = 1'b0;
                next_pc      = ref_pc + 32'd4;

                case (opcode)

                    // R-type: ADD/SUB/AND/OR/SLT
                    7'b0110011: begin
                        case (funct3)
                            3'b000:
                                if (funct7 == 7'b0100000)
                                    alu_result = rs1_data - rs2_data;
                                else
                                    alu_result = rs1_data + rs2_data;

                            3'b111: alu_result = rs1_data & rs2_data;
                            3'b110: alu_result = rs1_data | rs2_data;
                            3'b010: alu_result =
                                ($signed(rs1_data) < $signed(rs2_data)) ?
                                32'd1 : 32'd0;

                            default: alu_result = 32'd0;
                        endcase

                        exp_rd_we   = (rd != 0);
                        exp_rd_data = alu_result;
                    end

                    // I-type ALU: ADDI/ANDI/ORI/SLTI
                    7'b0010011: begin
                        case (funct3)
                            3'b000: alu_result = rs1_data + imm_i;
                            3'b111: alu_result = rs1_data & imm_i;
                            3'b110: alu_result = rs1_data | imm_i;
                            3'b010: alu_result =
                                ($signed(rs1_data) < $signed(imm_i)) ?
                                32'd1 : 32'd0;

                            default: alu_result = 32'd0;
                        endcase

                        exp_rd_we   = (rd != 0);
                        exp_rd_data = alu_result;
                    end

                    // LW
                    7'b0000011: begin
                        alu_result   = rs1_data + imm_i;
                        exp_rd_we    = (rd != 0);
                        exp_rd_data  = ref_mem[alu_result[9:2]];
                    end

                    // SW
                    7'b0100011: begin
                        alu_result    = rs1_data + imm_s;
                        exp_mem_we    = 1'b1;
                        exp_mem_addr  = alu_result;
                        exp_mem_wdata = rs2_data;
                    end

                    // BEQ / BNE
                    7'b1100011: begin
                        case (funct3)
                            3'b000: branch_taken = (rs1_data == rs2_data);
                            3'b001: branch_taken = (rs1_data != rs2_data);
                            default: branch_taken = 1'b0;
                        endcase

                        if (branch_taken)
                            next_pc = ref_pc + imm_b;
                    end

                    // LUI
                    7'b0110111: begin
                        exp_rd_we   = (rd != 0);
                        exp_rd_data = imm_u;
                    end

                    // AUIPC
                    7'b0010111: begin
                        exp_rd_we   = (rd != 0);
                        exp_rd_data = ref_pc + imm_u;
                    end

                    // JAL
                    7'b1101111: begin
                        exp_rd_we   = (rd != 0);
                        exp_rd_data = ref_pc + 32'd4;
                        next_pc     = ref_pc + imm_j;
                    end

                    // JALR
                    7'b1100111: begin
                        exp_rd_we   = (rd != 0);
                        exp_rd_data = ref_pc + 32'd4;
                        next_pc     = (rs1_data + imm_i) & 32'hFFFF_FFFE;
                    end

                    // EBREAK
                    7'b1110011: begin
                    end

                    default: begin
                        $display(
                            "[SB WARNING] Unsupported opcode at PC=0x%08h, instr=0x%08h",
                            ref_pc, instr
                        );
                    end
                endcase
            end
        endtask

        task compare_transaction(rv32_commit_txn txn);
            begin
                check_count++;

                if (txn.pc !== ref_pc) begin
                    error_count++;
                    $error("[SB %0d] PC mismatch: EXP=0x%08h ACT=0x%08h",
                           check_count, ref_pc, txn.pc);
                end

                if (txn.instr !== instr) begin
                    error_count++;
                    $error("[SB %0d] INSTR mismatch: EXP=0x%08h ACT=0x%08h",
                           check_count, instr, txn.instr);
                end

                if (txn.rd_we !== exp_rd_we) begin
                    error_count++;
                    $error("[SB %0d] rd_we mismatch: EXP=%0d ACT=%0d",
                           check_count, exp_rd_we, txn.rd_we);
                end

                if (exp_rd_we) begin
                    if (txn.rd !== exp_rd) begin
                        error_count++;
                        $error("[SB %0d] rd mismatch: EXP=x%0d ACT=x%0d",
                               check_count, exp_rd, txn.rd);
                    end

                    if (txn.rd_data !== exp_rd_data) begin
                        error_count++;
                        $error("[SB %0d] rd_data mismatch: EXP=0x%08h ACT=0x%08h",
                               check_count, exp_rd_data, txn.rd_data);
                    end
                end

                if (txn.mem_we !== exp_mem_we) begin
                    error_count++;
                    $error("[SB %0d] mem_we mismatch: EXP=%0d ACT=%0d",
                           check_count, exp_mem_we, txn.mem_we);
                end

                if (exp_mem_we) begin
                    if (txn.mem_addr !== exp_mem_addr) begin
                        error_count++;
                        $error("[SB %0d] store addr mismatch: EXP=0x%08h ACT=0x%08h",
                               check_count, exp_mem_addr, txn.mem_addr);
                    end

                    if (txn.mem_wdata !== exp_mem_wdata) begin
                        error_count++;
                        $error("[SB %0d] store data mismatch: EXP=0x%08h ACT=0x%08h",
                               check_count, exp_mem_wdata, txn.mem_wdata);
                    end
                end
            end
        endtask

        task update_reference_state();
            begin
                if (exp_mem_we)
                    ref_mem[exp_mem_addr[9:2]] = exp_mem_wdata;

                if (exp_rd_we && (exp_rd != 0))
                    ref_regs[exp_rd] = exp_rd_data;

                ref_regs[0] = 32'd0;
                ref_pc = next_pc;
            end
        endtask

        task run();
            rv32_commit_txn txn;

            initialize();

            forever begin
                mon2sb.get(txn);

                execute_reference_instruction();
                compare_transaction(txn);
                update_reference_state();

                if (txn.instr == 32'h0010_0073) begin
                    if (error_count == 0)
                        $display(
                            "[SCOREBOARD PASS] %0d committed instructions matched.",
                            check_count
                        );
                    else
                        $display(
                            "[SCOREBOARD FAIL] %0d mismatches found.",
                            error_count
                        );
                end
            end
        endtask

    endclass

    // =========================================
    // Commit-level functional coverage
    // =========================================
    class rv32_coverage;

        mailbox #(rv32_commit_txn) mon2cov;

        bit        pending_branch;
        logic [31:0] branch_target;
        logic [31:0] branch_fallthrough;

        // opcode / side-effect / control-type coverage
        covergroup commit_cg with function sample(
            logic [6:0] opcode,
            logic       rd_we,
            logic       mem_we
        );

            option.per_instance = 1;

            cp_opcode: coverpoint opcode {
                bins r_type = {7'b0110011};
                bins i_type = {7'b0010011};
                bins lw     = {7'b0000011};
                bins sw     = {7'b0100011};
                bins branch = {7'b1100011};
                bins lui    = {7'b0110111};
                bins auipc  = {7'b0010111};
                bins jal    = {7'b1101111};
                bins jalr   = {7'b1100111};
                bins ebreak = {7'b1110011};
            }

            cp_rd_we: coverpoint rd_we {
                bins no_write  = {0};
                bins reg_write = {1};
            }

            cp_mem_we: coverpoint mem_we {
                bins no_store = {0};
                bins store    = {1};
            }

        endgroup


        // Branch 实际 taken / not-taken coverage
        covergroup branch_cg with function sample(bit taken);

            option.per_instance = 1;

            cp_branch_outcome: coverpoint taken {
                bins not_taken = {0};
                bins taken     = {1};
            }

        endgroup


        function new(mailbox #(rv32_commit_txn) mon2cov);
            this.mon2cov = mon2cov;

            pending_branch    = 1'b0;
            branch_target     = 32'd0;
            branch_fallthrough = 32'd0;

            commit_cg = new();
            branch_cg = new();
        endfunction


        function automatic logic [31:0] decode_b_imm(
            input logic [31:0] instr
        );
            decode_b_imm = {
                {19{instr[31]}},
                instr[31],
                instr[7],
                instr[30:25],
                instr[11:8],
                1'b0
            };
        endfunction


        task sample_transaction(rv32_commit_txn txn);

            logic [6:0]  opcode;
            logic [31:0] branch_imm;
            bit          taken;

            begin
                opcode = txn.instr[6:0];

                // 上一条退休指令若为 branch，
                // 当前退休 PC 就能反映 branch 最终是否 taken。
                if (pending_branch) begin
                    taken = (txn.pc == branch_target);

                    branch_cg.sample(taken);

                    pending_branch = 1'b0;
                end

                // 基础 instruction / side effect coverage
                commit_cg.sample(
                    opcode,
                    txn.rd_we,
                    txn.mem_we
                );

                // 当前若为 BEQ/BNE，等待下一条 commit 判断方向
                if (opcode == 7'b1100011) begin
                    branch_imm       = decode_b_imm(txn.instr);
                    branch_target    = txn.pc + branch_imm;
                    branch_fallthrough = txn.pc + 32'd4;
                    pending_branch   = 1'b1;
                end
            end
        endtask


        task run();
            rv32_commit_txn txn;

            forever begin
                mon2cov.get(txn);

                sample_transaction(txn);

                if (txn.instr == 32'h0010_0073) begin
                    $display(
                        "[COVERAGE] Commit functional coverage = %0.2f%%",
                        commit_cg.get_inst_coverage()
                    );

                    $display(
                        "[COVERAGE] Branch outcome coverage  = %0.2f%%",
                        branch_cg.get_inst_coverage()
                    );
                end
            end
        endtask

    endclass
    
    // =========================================
    // Reproducible constrained pseudo-random program generator
    // XSim-compatible: no $urandom / rand / randomize required
    // =========================================
    class rv32_random_program_gen;

        logic [31:0] prng_state;

        logic [3:0]  op_kind;
        logic [4:0]  rd;
        logic [4:0]  rs1;
        logic [4:0]  rs2;
        logic [11:0] imm12;
        logic [5:0]  mem_word;

        function new(input logic [31:0] seed);
            if (seed == 32'd0)
                prng_state = 32'h1;
            else
                prng_state = seed;
        endfunction

        // Linear congruential generator:
        // same seed -> same instruction program
        function automatic logic [31:0] next_rand();
            begin
                prng_state = prng_state * 32'd1664525 +
                             32'd1013904223;
                next_rand = prng_state;
            end
        endfunction

        // Generate one set of legal, bounded instruction fields
        task choose_fields();
            logic [31:0] r;
            begin
                // 0~11:
                // 0~4 R-type, 5~8 I-type, 9 LW, 10 SW, 11 NOP
                r = next_rand();
                op_kind = r[3:0] % 12;

                // rd: x1~x15; avoid x0 and keep debugging manageable
                r = next_rand();
                rd = (r[4:0] % 15) + 5'd1;

                // source registers limited to x0~x15
                r = next_rand();
                rs1 = r[3:0];

                r = next_rand();
                rs2 = r[3:0];

                // Immediate limited to +0~+31 or -32~-1
                r = next_rand();
                if (r[0])
                    imm12 = {7'b0000000, r[6:2]};
                else
                    imm12 = {7'b1111111, r[6:2]};

                // Word-aligned dmem offsets: 0~252 bytes
                r = next_rand();
                mem_word = r[5:0];
            end
        endtask

        function automatic logic [31:0] enc_r(
            input logic [6:0] funct7,
            input logic [4:0] rs2_i,
            input logic [4:0] rs1_i,
            input logic [2:0] funct3,
            input logic [4:0] rd_i
        );
            enc_r = {funct7, rs2_i, rs1_i, funct3, rd_i, 7'b0110011};
        endfunction

        function automatic logic [31:0] enc_i(
            input logic [11:0] imm_i,
            input logic [4:0]  rs1_i,
            input logic [2:0]  funct3,
            input logic [4:0]  rd_i,
            input logic [6:0]  opcode_i
        );
            enc_i = {imm_i, rs1_i, funct3, rd_i, opcode_i};
        endfunction

        function automatic logic [31:0] enc_s(
            input logic [11:0] imm_s,
            input logic [4:0]  rs2_i,
            input logic [4:0]  rs1_i,
            input logic [2:0]  funct3
        );
            enc_s = {
                imm_s[11:5],
                rs2_i,
                rs1_i,
                funct3,
                imm_s[4:0],
                7'b0100011
            };
        endfunction

        function automatic logic [31:0] make_instruction();
            logic [11:0] mem_imm;
            begin
                mem_imm = {4'b0000, mem_word, 2'b00};

                case (op_kind)
                    0:  make_instruction = enc_r(7'b0000000, rs2, rs1, 3'b000, rd); // ADD
                    1:  make_instruction = enc_r(7'b0100000, rs2, rs1, 3'b000, rd); // SUB
                    2:  make_instruction = enc_r(7'b0000000, rs2, rs1, 3'b111, rd); // AND
                    3:  make_instruction = enc_r(7'b0000000, rs2, rs1, 3'b110, rd); // OR
                    4:  make_instruction = enc_r(7'b0000000, rs2, rs1, 3'b010, rd); // SLT

                    5:  make_instruction = enc_i(imm12, rs1, 3'b000, rd, 7'b0010011); // ADDI
                    6:  make_instruction = enc_i(imm12, rs1, 3'b111, rd, 7'b0010011); // ANDI
                    7:  make_instruction = enc_i(imm12, rs1, 3'b110, rd, 7'b0010011); // ORI
                    8:  make_instruction = enc_i(imm12, rs1, 3'b010, rd, 7'b0010011); // SLTI

                    9:  make_instruction = enc_i(mem_imm, 5'd0, 3'b010, rd, 7'b0000011); // LW
                    10: make_instruction = enc_s(mem_imm, rs2, 5'd0, 3'b010);             // SW

                    default:
                        make_instruction = 32'h0000_0013; // NOP
                endcase
            end
        endfunction

        task build(
            ref logic [31:0] prog_mem [0:255],
            input int unsigned body_len
        );
            int i;
            begin
                if (body_len > 255)
                    $fatal(1, "Random program is too large: %0d", body_len);

                // EBREAK 后的地址也填 NOP，避免 X
                for (i = 0; i < 256; i++)
                    prog_mem[i] = 32'h0000_0013;

                for (i = 0; i < body_len; i++) begin
                    choose_fields();
                    prog_mem[i] = make_instruction();
                end

                prog_mem[body_len] = 32'h0010_0073; // EBREAK
            end
        endtask

    endclass

endpackage
