`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 16:32:17
// Design Name: 
// Module Name: forwarding_unit
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


module forwarding_unit(
    input wire          ex_mem_RegWrite,
    input wire [4:0]    ex_mem_rd,
    input wire          mem_wb_RegWrite,
    input wire [4:0]    mem_wb_rd,
    input wire [4:0]    id_ex_rs1,
    input wire [4:0]    id_ex_rs2,
    output reg [1:0]    ForwardA,
    output reg [1:0]    ForwardB
    );
    
    always @(*) begin
        //default: no forwarding
        ForwardA = 2'b00;
        ForwardB = 2'b00;
        
        //EX hazard
        if(ex_mem_RegWrite && (ex_mem_rd != 0)&&(ex_mem_rd==id_ex_rs1))
            ForwardA =2'b10;
        if(ex_mem_RegWrite && (ex_mem_rd != 0)&&(ex_mem_rd==id_ex_rs2))
            ForwardB =2'b10;
            
        //MEM hazard
        if(mem_wb_RegWrite && (mem_wb_rd != 0)&&
            !(ex_mem_RegWrite && (ex_mem_rd !=0)&&(ex_mem_rd == id_ex_rs1))&&
            (mem_wb_rd==id_ex_rs1))
            ForwardA =2'b01;
        if(mem_wb_RegWrite && (mem_wb_rd != 0)&&
            !(ex_mem_RegWrite && (ex_mem_rd !=0)&&(ex_mem_rd == id_ex_rs2))&&
            (mem_wb_rd==id_ex_rs2))
            ForwardB =2'b01;
    end
endmodule
