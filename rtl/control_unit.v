`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/15 16:03:39
// Design Name: 
// Module Name: control_unit
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


module control_unit(
    input wire [6:0] opcode,
    
    output reg      RegWrite,   // 是否写寄存器堆
    output reg      MemRead,    // Data memory 读
    output reg      MemWrite,   // Data memory 写
    output reg      MemToReg,   // WB: 1=从内存写回，0=从 ALU 写回
    output reg      Branch,     // 分支指令
    output reg      Jump,       //for Jal/Jalr
    output reg      ALUSrc,     // ALU 第二个操作数：0=rs2，1=imm
    output reg[1:0] ALUOp       // 给 alu_control 用的高层编码
    );
    
    always @(*) begin 
        //initial
        RegWrite  = 1'b0;
        MemRead   = 1'b0;
        MemWrite  = 1'b0;
        MemToReg  = 1'b0;
        Branch    = 1'b0;
        Jump      = 1'b0;
        ALUSrc    = 1'b0;
        ALUOp     = 2'b00;
        
        case(opcode)
            //R-type: add/sub/and/or/xor/slt...
            7'b0110011:begin
                RegWrite  = 1'b1;       //Write Register
                MemRead   = 1'b0;       
                MemWrite  = 1'b0;
                MemToReg  = 1'b0;       //从ALU结果写回
                Branch    = 1'b0;
                Jump      = 1'b0;
                ALUSrc    = 1'b0;       //第二个操作数来自rs2
                ALUOp     = 2'b10;      //交给ALU Control，看funct3/funct7
            end
            
            // I-type ALU: addi/ori/xori/andi/slti...
            7'b0010011:begin
                RegWrite  = 1'b1;
                MemRead   = 1'b0;
                MemWrite  = 1'b0;
                MemToReg  = 1'b0;
                Branch    = 1'b0;
                Jump      = 1'b0;
                ALUSrc    = 1'b1;       //第二个操作数是imm
                ALUOp     = 2'b10;      //交给ALU Control，看funct3
            end
            
            // Load: lw
            7'b0000011:begin
                RegWrite  = 1'b1;
                MemRead   = 1'b1;       // 访问数据存储器
                MemWrite  = 1'b0;
                MemToReg  = 1'b1;       // 从内存写回寄存器
                Branch    = 1'b0;
                Jump      = 1'b0;
                ALUSrc    = 1'b1;       // base+offset，用 imm 做偏移
                ALUOp     = 2'b00;      // ALU 做加法（地址 = rs1 + imm）
            end
            
            // Store: sw
            7'b0100011:begin
                RegWrite  = 1'b0;       //不写寄存器
                MemRead   = 1'b0;       
                MemWrite  = 1'b1;       // 写数据存储器
                MemToReg  = 1'b0;       
                Branch    = 1'b0;
                Jump      = 1'b0;
                ALUSrc    = 1'b1;       // base+offset，用 imm 做偏移
                ALUOp     = 2'b00;      // ALU 做加法（地址 = rs1 + imm）
            end
            
            // Branch: beq/bne/...
            7'b1100011: begin
                RegWrite  = 1'b0;       // 分支不写寄存器
                MemRead   = 1'b0;       
                MemWrite  = 1'b0;
                MemToReg  = 1'b0;       
                Branch    = 1'b1;       //控制PC选择
                Jump      = 1'b0;
                ALUSrc    = 1'b0;       // 两个寄存器比较
                ALUOp     = 2'b01;      // 让 ALU 做减法，用 zero 标志判断是否相等
            end
            
            // LUI
            7'b0110111: begin
                RegWrite  = 1'b1;       
                MemRead   = 1'b0;       
                MemWrite  = 1'b0;
                MemToReg  = 1'b0;       
                Branch    = 1'b0;       //控制PC选择
                Jump      = 1'b0;
                ALUSrc    = 1'b1;       // 直接用 imm，上层 datapath 可用"ALU pass B"实现
                ALUOp     = 2'b00;      
            end
            
            // AUIPC
            7'b0010111: begin
                RegWrite  = 1'b1;       
                MemRead   = 1'b0;       
                MemWrite  = 1'b0;
                MemToReg  = 1'b0;       
                Branch    = 1'b0;       //控制PC选择
                Jump      = 1'b0;
                ALUSrc    = 1'b1;       // PC + imm
                ALUOp     = 2'b00;      // 用 ALU 做加法 (PC + imm)
            end
            
            // JAL
            7'b1101111: begin
                RegWrite  = 1'b1;      //写 rd = PC+4 
                MemRead   = 1'b0;       
                MemWrite  = 1'b0;
                MemToReg  = 1'b0;       // WB 用 PC+4
                Branch    = 1'b0;       
                Jump      = 1'b1;       //控制PC选择
                ALUSrc    = 1'b0;       // ALU不一定参与
                ALUOp     = 2'b00;      
            end
            
            // JALR
            7'b1100111: begin
                RegWrite  = 1'b1;      
                MemRead   = 1'b0;       
                MemWrite  = 1'b0;
                MemToReg  = 1'b0;       
                Branch    = 1'b0;       
                Jump      = 1'b1;       //控制PC选择
                ALUSrc    = 1'b1;       // rs1 + imm 作为跳转地址
                ALUOp     = 2'b00;      
            end
            
            default: begin
                // 保持默认 NOP，不写寄存器、不访存、不跳转
            end
            
        endcase
    end
endmodule
