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
module cpu_top_tb;

    reg clk;
    reg rst;

    // 实例化 DUT（Device Under Test）
    cpu_top uut (
        .clk (clk),
        .rst (rst)
    );
    
    rv32_ref_model u_ref_model (
        .clk               (clk),
        .rst               (rst),
    
        .commit_valid      (uut.commit_valid),
        .commit_pc         (uut.commit_pc),
        .commit_instr      (uut.commit_instr),
    
        .commit_rd_we      (uut.commit_rd_we),
        .commit_rd         (uut.commit_rd),
        .commit_rd_data    (uut.commit_rd_data),
    
        .commit_mem_we     (uut.commit_mem_we),
        .commit_mem_addr   (uut.commit_mem_addr),
        .commit_mem_wdata  (uut.commit_mem_wdata)
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
        if (!rst && uut.commit_valid) begin
    
            // 只接受非 X 的真实指令 commit
            if (^uut.commit_instr !== 1'bx) begin
                commit_count = commit_count + 1;
    
                $display(
                    "[COMMIT %0d] PC=0x%08h INSTR=0x%08h | rd_we=%0d rd=x%0d data=0x%08h | mem_we=%0d addr=0x%08h wdata=0x%08h",
                    commit_count,
                    uut.commit_pc,
                    uut.commit_instr,
                    uut.commit_rd_we,
                    uut.commit_rd,
                    uut.commit_rd_data,
                    uut.commit_mem_we,
                    uut.commit_mem_addr,
                    uut.commit_mem_wdata
                );
                
                if (uut.commit_instr == 32'h0010_0073) begin
                    $display("[PROGRAM END] EBREAK committed at PC=0x%08h",
                             uut.commit_pc);
                    program_done <= 1'b1;
                end
            end
        end
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
        
        if (
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
        
            uut.u_rf.regs[12] == 32'd10          &&
            uut.u_rf.regs[18] == 32'd9           &&
        
            uut.u_dmem.ram[0] == 32'd8           &&
            uut.u_dmem.ram[1] == 32'd8           &&
        
            false_stall_count == 0               &&
            uut.u_rf.regs[13] == 32'd5  &&
            uut.u_rf.regs[14] == 32'd6  &&
            
            uut.u_rf.regs[15] == 32'd0  &&
            uut.u_rf.regs[16] == 32'd22 &&
            uut.u_rf.regs[17] == 32'd33 &&
            
            uut.u_rf.regs[19] == 32'd0  &&
            uut.u_rf.regs[20] == 32'd44 &&
            uut.u_rf.regs[21] == 32'd55 &&
            uut.u_rf.regs[22] == 32'd160 &&
            uut.u_rf.regs[23] == 32'd0   &&
            uut.u_rf.regs[24] == 32'd66  &&
            uut.u_rf.regs[25] == 32'd200 &&
            uut.u_rf.regs[26] == 32'd196 &&
            uut.u_rf.regs[27] == 32'd0   &&
            uut.u_rf.regs[28] == 32'd77  &&
            uut.u_rf.regs[29] == 32'h1234_5000 &&
            uut.u_rf.regs[30] == 32'd4324       &&
            uut.u_rf.regs[31] == 32'd4325       
        ) begin
            $display("PHASE 1 REGRESSION TEST PASS");
        end
        else begin
            $display("PHASE 1 REGRESSION TEST FAIL");
        end

        #10;
        $finish;
    end

endmodule
