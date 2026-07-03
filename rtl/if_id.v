`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/17 14:59:15
// Design Name: 
// Module Name: if_id
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


module if_id(
    input wire clk,
    input wire rst,
    input wire stall,   // load-use hazard 时 =1 冻结 IF/ID
    input wire flush,   // 分支/跳转时冲刷成 NOP（先可以接0）

    //from if
    input wire [31:0] if_pc,
    input wire [31:0] if_instr,
    
    //to id
    output reg [31:0] id_pc,
    output reg [31:0] id_instr,
    output reg        id_valid
    );
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            id_pc    <= 32'b0;
            id_instr <= 32'h00000013; // NOP
            id_valid <= 1'b0;
        end else if (flush) begin
            id_pc    <= 32'b0;
            id_instr <= 32'h00000013;
            id_valid <= 1'b0;
        end else if (!stall) begin
            id_pc    <= if_pc;
            id_instr <= if_instr;
            id_valid <= 1'b1;
        end
    end
endmodule
