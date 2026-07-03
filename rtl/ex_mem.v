`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 16:58:09
// Design Name: 
// Module Name: ex_mem
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


module ex_mem(
    input wire clk,
    input wire rst,
    input wire stall,
    
    //from EX stage
    input wire        ex_valid,
    input wire [31:0] ex_pc,
    input wire [31:0] ex_instr,
    input wire [31:0] ex_branch_target,     //branch/jump destination
    input wire        ex_zero,              //ALU zero 
    input wire [31:0] ex_alu_result,        //ALU result
    input wire [31:0] ex_rs2_val,           //store data
    input wire [4:0]  ex_rd,
    
    input wire        ex_RegWrite,
    input wire        ex_MemRead,
    input wire        ex_MemWrite,
    input wire        ex_MemToReg,
    input wire        ex_Branch,
    input wire        ex_Jump,
    
    //to MEM stage
    output reg        mem_valid,
    output reg [31:0] mem_pc,
    output reg [31:0] mem_instr,
    output reg [31:0] mem_branch_target,     //branch/jump destination
    output reg        mem_zero,              //ALU zero 
    output reg [31:0] mem_alu_result,        //ALU result
    output reg [31:0] mem_rs2_val,           //store data
    output reg [4:0]  mem_rd,

    output reg        mem_RegWrite,
    output reg        mem_MemRead,
    output reg        mem_MemWrite,
    output reg        mem_MemToReg,
    output reg        mem_Branch,
    output reg        mem_Jump
    );
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_valid           <= 1'b0;
            mem_pc              <= 32'b0;
            mem_instr           <= 32'h00000013;
            mem_branch_target   <= 0;
            mem_zero            <= 0;         
            mem_alu_result      <= 0;   
            mem_rs2_val         <= 0;      
            mem_rd              <= 0;
                                   
            mem_RegWrite        <= 0;
            mem_MemRead         <= 0;
            mem_MemWrite        <= 0;
            mem_MemToReg        <= 0;
            mem_Branch          <= 0;
            mem_Jump            <= 0;
        end
        else if(!stall) begin
            mem_valid           <= ex_valid;
            mem_pc              <= ex_pc;
            mem_instr           <= ex_instr;
            mem_branch_target   <= ex_branch_target;
            mem_zero            <= ex_zero         ;         
            mem_alu_result      <= ex_alu_result   ;   
            mem_rs2_val         <= ex_rs2_val      ;      
            mem_rd              <= ex_rd           ;
                                
            mem_RegWrite        <= ex_RegWrite     ;
            mem_MemRead         <= ex_MemRead      ;
            mem_MemWrite        <= ex_MemWrite     ;
            mem_MemToReg        <= ex_MemToReg     ;
            mem_Branch          <= ex_Branch       ;
            mem_Jump            <= ex_Jump         ;
        end
    end
endmodule
