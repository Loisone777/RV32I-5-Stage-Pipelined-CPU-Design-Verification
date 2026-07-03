`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/15 14:30:48
// Design Name: 
// Module Name: imem_tb
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

module imem_tb;

    reg [31:0] addr;
    wire [31:0] instr;
    
    imem uut(
         .addr      (addr ), 
         .instr     (instr)
    );
    
    initial begin
        addr=0;
        #10; addr=4;
        #10; addr=8;
        #10; addr=12;
        
        #20;
        $finish;
    end
    
endmodule
