`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/18 22:05:57
// Design Name: 
// Module Name: cpu_top_tb
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

`timescale 1ns/1ps

import rv32_commit_pkg::*;

module cpu_top_tb;

    reg clk;
    reg rst;

    mailbox #(rv32_commit_txn) mon2sb;
    mailbox #(rv32_commit_txn) mon2cov;
    
    rv32_commit_monitor commit_monitor;
    rv32_scoreboard      scoreboard;
    rv32_coverage        coverage;
    
    parameter bit          RUN_RANDOM      = 1'b0;
    parameter logic [31:0] RANDOM_SEED     = 32'h2026_0702;
    parameter int unsigned RANDOM_BODY_LEN = 80;
    
    logic [31:0] random_program [0:255];
    
    rv32_random_program_gen random_gen;
    
    integer rand_i;

    // 实例化 DUT（Device Under Test）
    cpu_top uut (
        .clk (clk),
        .rst (rst)
    );
    
    rv32_commit_if commit_if (
        .clk(clk)
    );
    
    assign commit_if.rst             = rst;

    assign commit_if.commit_valid    = uut.commit_valid;
    assign commit_if.commit_pc       = uut.commit_pc;
    assign commit_if.commit_instr    = uut.commit_instr;
    
    assign commit_if.commit_rd_we    = uut.commit_rd_we;
    assign commit_if.commit_rd       = uut.commit_rd;
    assign commit_if.commit_rd_data  = uut.commit_rd_data;
    
    assign commit_if.commit_mem_we    = uut.commit_mem_we;
    assign commit_if.commit_mem_addr  = uut.commit_mem_addr;
    assign commit_if.commit_mem_wdata = uut.commit_mem_wdata;

    cpu_assertions u_assertions (
        .clk            (clk),
        .rst            (rst),
    
        .id_valid       (uut.id_valid),
        .ex_valid       (uut.ex_valid),
        .mem_valid      (uut.mem_valid),
        .wb_valid       (uut.wb_valid),
    
        .stall          (uut.stall),
        .redirect_valid (uut.redirect_valid),
    
        .commit_valid   (uut.commit_valid),
        .commit_rd_we   (uut.commit_rd_we),
        .commit_rd      (uut.commit_rd),
        .commit_mem_we  (uut.commit_mem_we),
    
        .x0_value       (uut.u_rf.regs[0]),
        
        .wb_regwrite   (uut.wb_RegWrite),
        .wb_rd         (uut.wb_rd),
        .wb_wdata      (uut.wb_write_data),
        
        .id_rs1        (uut.rs1),
        .id_rs2        (uut.rs2),
        .id_rs1_val    (uut.rs1_val),
        .id_rs2_val    (uut.rs2_val)
    );
    

    integer false_stall_count;
    
    always @(negedge clk) begin
        // 当前 EX 阶段是：lw x2, 4(x0)
        // 当前 ID 阶段是：addi x12, x4, 2
        //
        // 对 addi 来说，instr[24:20] 只是 imm[4:0]=2，
        // 不是真正的 rs2，因此此时 stall 必须为 0。
        if (!rst &&
            uut.id_ex_MemRead &&
            (uut.id_ex_rd == 5'd2) &&
            (uut.id_instr == 32'h00220613)) begin
    
            if (uut.stall) begin
                false_stall_count = false_stall_count + 1;
                $display("ERROR: false stall detected for addi x12, x4, 2");
            end
        end
    end
    
    integer commit_count;
    reg program_done;

    always @(posedge clk) begin
        if (!rst &&
            commit_if.commit_valid &&
            commit_if.commit_instr == 32'h0010_0073) begin
    
            $display("[PROGRAM END] EBREAK committed at PC=0x%08h",
                     commit_if.commit_pc);
    
            program_done <= 1'b1;
        end
    end

    initial begin : build_dv_environment

        mon2sb  = new();
        mon2cov = new();
    
        if (RUN_RANDOM) begin
    
            random_gen = new(RANDOM_SEED);
            random_gen.build(random_program, RANDOM_BODY_LEN);
    
            // 等 imem.v 自己的 initial $readmemh("imem.mem") 先执行完
            #1;
    
            // 把同一份随机程序加载到 DUT ROM
            // 同时清空 data memory 和 register file，保证每个 seed 独立。
            for (rand_i = 0; rand_i < 256; rand_i++) begin
                uut.u_imem.rom[rand_i] = random_program[rand_i];
                uut.u_dmem.ram[rand_i] = 32'd0;
            end
    
            for (rand_i = 0; rand_i < 32; rand_i++)
                uut.u_rf.regs[rand_i] = 32'd0;
    
            scoreboard = new(mon2sb, 1'b1);
            scoreboard.set_program(random_program);
    
            $display(
                "[RANDOM TEST] seed=0x%08h, random instructions=%0d",
                RANDOM_SEED,
                RANDOM_BODY_LEN
            );
    
        end
        else begin
            scoreboard = new(mon2sb);
        end
    
        commit_monitor = new(commit_if, mon2sb, mon2cov);
        coverage       = new(mon2cov);
    
        fork
            commit_monitor.run();
            scoreboard.run();
            coverage.run();
        join_none
    end
    
    // 生成时钟：10ns 周期 → 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 复位 & 跑一段时间
    initial begin
        // 初始化波形输出（如果用第三方仿真器，比如 iverilog/VCS）
        // $dumpfile("cpu_top.vcd");
        // $dumpvars(0, tb_cpu_top);
        false_stall_count = 0;
        commit_count = 0;
        program_done = 1'b0;

        rst = 1;
        #20;           // 复位保持 20ns
        rst = 0;

        // 跑一段时间，让流水线把指令都执行完
        wait (program_done == 1'b1);
        #10;

        // 仿真结束前，打印一些关键结果：
        $display("==== Register dump ====");
        $display("x0  = %0d", uut.u_rf.regs[0]);
        $display("x1  = %0d", uut.u_rf.regs[1]);
        $display("x2  = %0d", uut.u_rf.regs[2]);
        $display("x3  = %0d", uut.u_rf.regs[3]);
        $display("x4  = %0d", uut.u_rf.regs[4]);
        $display("x5  = %h", uut.u_rf.regs[5]);
        $display("x6  = %0d", uut.u_rf.regs[6]);
        $display("x7  = %0d", uut.u_rf.regs[7]);
        $display("x8  = %0d", uut.u_rf.regs[8]);
        $display("x9  = %0d", uut.u_rf.regs[9]);
        $display("x10 = %0d", uut.u_rf.regs[10]);
        $display("x11 = %0d", uut.u_rf.regs[11]);
        $display("x18 = %0d", uut.u_rf.regs[18]);
        
        $display("==== Data memory ====");
        $display("MEM[0] = %0d", uut.u_dmem.ram[0]);
        
        $display("x12 = %0d", uut.u_rf.regs[12]);
        $display("MEM[1] = %0d", uut.u_dmem.ram[1]);
        $display("false_stall_count = %0d", false_stall_count);
        
        $display("x13 = %0d", uut.u_rf.regs[13]);
        $display("x14 = %0d", uut.u_rf.regs[14]);
        $display("x15 = %0d", uut.u_rf.regs[15]);
        $display("x16 = %0d", uut.u_rf.regs[16]);
        $display("x17 = %0d", uut.u_rf.regs[17]);
        $display("x19 = %0d", uut.u_rf.regs[19]);
        $display("x20 = %0d", uut.u_rf.regs[20]);
        $display("x21 = %0d", uut.u_rf.regs[21]);
        $display("x22 = %0d", uut.u_rf.regs[22]);
        $display("x23 = %0d", uut.u_rf.regs[23]);
        $display("x24 = %0d", uut.u_rf.regs[24]);
        $display("x25 = %0d", uut.u_rf.regs[25]);
        $display("x26 = %0d", uut.u_rf.regs[26]);
        $display("x27 = %0d", uut.u_rf.regs[27]);
        $display("x28 = %0d", uut.u_rf.regs[28]);
        $display("x29 = 0x%08h", uut.u_rf.regs[29]);
        $display("x30 = %0d (0x%08h)", uut.u_rf.regs[30], uut.u_rf.regs[30]);
        $display("x31 = %0d (0x%08h)", uut.u_rf.regs[31], uut.u_rf.regs[31]);
        
        if (RUN_RANDOM) begin
            if ((scoreboard.error_count == 0) &&
                (scoreboard.check_count == RANDOM_BODY_LEN + 1)) begin
        
                $display(
                    "RANDOM REGRESSION PASS | seed=0x%08h | commits=%0d",
                    RANDOM_SEED,
                    scoreboard.check_count
                );
            end
            else begin
                $error(
                    "RANDOM REGRESSION FAIL | seed=0x%08h | commits=%0d | errors=%0d",
                    RANDOM_SEED,
                    scoreboard.check_count,
                    scoreboard.error_count
                );
                $fatal(1, "Random regression failed.");
            end
        end
        
        else if (
            uut.u_rf.regs[0]  == 32'd0           &&
            uut.u_rf.regs[1]  == 32'd8           &&
            uut.u_rf.regs[2]  == 32'd8           &&
            uut.u_rf.regs[3]  == 32'd16          &&
            uut.u_rf.regs[4]  == 32'd8           &&
        
            uut.u_rf.regs[5]  == 32'hFFFF_FFFF   &&
            uut.u_rf.regs[6]  == 32'd1           &&
            uut.u_rf.regs[7]  == 32'd1           &&
        
            uut.u_rf.regs[8]  == 32'd1024        &&
            uut.u_rf.regs[9]  == 32'd1           &&
            uut.u_rf.regs[10] == 32'd1025        &&
            uut.u_rf.regs[11] == 32'd6           &&
            uut.u_rf.regs[12] == 32'd10          &&
            uut.u_rf.regs[18] == 32'd9           &&
        
            uut.u_dmem.ram[0] == 32'd8           &&
            uut.u_dmem.ram[1] == 32'd8           &&
        
            false_stall_count == 0               &&
            uut.u_rf.regs[13] == 32'd5           &&
            uut.u_rf.regs[14] == 32'd6           &&
         
            uut.u_rf.regs[15] == 32'd0           &&
            uut.u_rf.regs[16] == 32'd22          &&
            uut.u_rf.regs[17] == 32'd33          &&
         
            uut.u_rf.regs[19] == 32'd0           &&
            uut.u_rf.regs[20] == 32'd44          &&
            uut.u_rf.regs[21] == 32'd55          &&
            uut.u_rf.regs[22] == 32'd160         &&
            uut.u_rf.regs[23] == 32'd0           &&
            uut.u_rf.regs[24] == 32'd66          &&
            uut.u_rf.regs[25] == 32'd200         &&
            uut.u_rf.regs[26] == 32'd196         &&
            uut.u_rf.regs[27] == 32'd0           &&
            uut.u_rf.regs[28] == 32'd77          &&
            uut.u_rf.regs[29] == 32'h1234_5000   &&
            uut.u_rf.regs[30] == 32'd4324        &&
            uut.u_rf.regs[31] == 32'd4325       
        ) begin
            $display("PHASE 1 REGRESSION TEST PASS");
        end
        else begin
            $error("PHASE 1 REGRESSION TEST FAIL");
            $fatal(1, "Directed regression failed.");
        end

        #10;
        $finish;
    end

endmodule
