`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/15 14:17:06
// Design Name: 
// Module Name: imem
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


module imem(
    input wire [31:0] addr,     //PC address
    output wire [31:0] instr    //32-bit instruction
    );
    
    reg [31:0] rom [0:255];     //rom with 256 instrcutions
    
    initial begin
        $readmemh("imem.mem",rom);
    end
    
    assign instr = rom[addr[31:2]];
endmodule
