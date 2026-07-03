`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/15 16:57:59
// Design Name: 
// Module Name: id_ex
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


module id_ex(
    input wire clk,
    input wire rst,
    
    // load-use hazard 时，不冻结 ID/EX，
    // 而是向 EX 注入一条 bubble
    input wire bubble,
    
    input wire flush,  //branch预测错误，清空
    
    //signals from ID stage
    input wire          id_valid,
    input wire [31:0]   id_pc,
    input wire [31:0]   id_instr,
    input wire [31:0]   id_rs1_val,
    input wire [31:0]   id_rs2_val,
    input wire [31:0]   id_imm,
    input wire [4:0]    id_rs1,
    input wire [4:0]    id_rs2,
    input wire [4:0]    id_rd,
    
    input wire [6:0]    id_opcode,
    input wire [2:0]    id_funct3,
    input wire [6:0]    id_funct7,
    input wire          id_RegWrite,   // 是否写寄存器堆
    input wire          id_MemRead,    // Data memory 读
    input wire          id_MemWrite,   // Data memory 写
    input wire          id_MemToReg,   // WB: 1=从内存写回，0=从 ALU 写回
    input wire          id_Branch,     // 分支指令
    input wire          id_Jump,       //for Jal/Jalr
    input wire          id_ALUSrc,     // ALU 第二个操作数：0=rs2，1=imm
    input wire [1:0]    id_ALUOp,      // 给 alu_control 用的高层编码

    //signals output to EX stage
    output reg          ex_valid,
    output reg [31:0]   ex_pc,
    output reg [31:0]   ex_instr,
    output reg [31:0]   ex_rs1_val,
    output reg [31:0]   ex_rs2_val,
    output reg [31:0]   ex_imm,
    output reg [4:0]    ex_rs1,
    output reg [4:0]    ex_rs2,
    output reg [4:0]    ex_rd,
    
    output reg [6:0]    ex_opcode,
    output reg [2:0]    ex_funct3,
    output reg [6:0]    ex_funct7,
    output reg          ex_RegWrite,   // 是否写寄存器堆
    output reg          ex_MemRead,    // Data memory 读
    output reg          ex_MemWrite,   // Data memory 写
    output reg          ex_MemToReg,   // WB: 1=从内存写回，0=从 ALU 写回
    output reg          ex_Branch,     // 分支指令
    output reg          ex_Jump,       //for Jal/Jalr
    output reg          ex_ALUSrc,     // ALU 第二个操作数：0=rs2，1=imm
    output reg [1:0]    ex_ALUOp       // 给 alu_control 用的高层编码
    
    );
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_valid    <= 1'b0;
            ex_pc       <= 32'b0;
            ex_instr    <= 32'h00000013;
            ex_rs1_val  <= 32'b0;
            ex_rs2_val  <= 32'b0;
            ex_imm      <= 32'b0;
            ex_rs1      <= 5'b0;
            ex_rs2      <= 5'b0;
            ex_rd       <= 5'b0;
    
            ex_funct3   <= 3'b0;
            ex_funct7   <= 7'b0;
            ex_opcode   <= 7'b0;
    
            ex_RegWrite <= 1'b0;
            ex_MemRead  <= 1'b0;
            ex_MemWrite <= 1'b0;
            ex_MemToReg <= 1'b0;
            ex_Branch   <= 1'b0;
            ex_Jump     <= 1'b0;
            ex_ALUSrc   <= 1'b0;
            ex_ALUOp    <= 2'b0;
        end 
        else if ( bubble || flush ) begin
            ex_valid    <= 1'b0;
            ex_pc       <= 32'b0;
            ex_instr    <= 32'h00000013;
            ex_rs1_val  <= 32'b0;
            ex_rs2_val  <= 32'b0;
            ex_imm      <= 32'b0;
            ex_rs1      <= 5'b0;
            ex_rs2      <= 5'b0;
            ex_rd       <= 5'b0;
    
            ex_funct3   <= 3'b0;
            ex_funct7   <= 7'b0;
            ex_opcode   <= 7'b0;
    
            ex_RegWrite <= 1'b0;
            ex_MemRead  <= 1'b0;
            ex_MemWrite <= 1'b0;
            ex_MemToReg <= 1'b0;
            ex_Branch   <= 1'b0;
            ex_Jump     <= 1'b0;
            ex_ALUSrc   <= 1'b0;
            ex_ALUOp    <= 2'b0;
        end
        else begin
            ex_valid    <= id_valid;
            ex_pc       <= id_pc;
            ex_instr    <= id_instr;
            ex_rs1_val  <= id_rs1_val;
            ex_rs2_val  <= id_rs2_val;
            ex_imm      <= id_imm;
            ex_rs1      <= id_rs1;
            ex_rs2      <= id_rs2;
            ex_rd       <= id_rd;
    
            ex_funct3   <= id_funct3;
            ex_funct7   <= id_funct7;
            ex_opcode   <= id_opcode;
    
            ex_RegWrite <= id_RegWrite;
            ex_MemRead  <= id_MemRead;
            ex_MemWrite <= id_MemWrite;
            ex_MemToReg <= id_MemToReg;
            ex_Branch   <= id_Branch;
            ex_Jump     <= id_Jump;
            ex_ALUSrc   <= id_ALUSrc;
            ex_ALUOp    <= id_ALUOp;
        end
    end
endmodule
