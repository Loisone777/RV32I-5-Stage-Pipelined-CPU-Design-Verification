`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/17 15:38:28
// Design Name: 
// Module Name: dmem
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


module dmem(
    input wire          clk,
    input wire          MemRead,
    input wire          MemWrite,
    input wire [31:0]   addr,
    input wire [31:0]   write_data,
    output reg [31:0]   read_data
    );
    reg [31:0] ram [0:255];     //1KB 数据内存
    
    // 同步写
    always @(posedge clk) begin
        if (MemWrite)
            ram[addr[31:2]] <= write_data;
    end

    // 组合读
    always @(*) begin
        if (MemRead)
            read_data = ram[addr[31:2]];
        else
            read_data = 32'b0;
    end
    
endmodule
