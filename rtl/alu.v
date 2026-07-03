`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/14 15:08:10
// Design Name: 
// Module Name: alu
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


module alu(
    input wire [31:0] a,b,      //operator
    input wire [3:0]  alu_ctrl, //operation
    output reg [31:0] result,
    output wire zero
    );
    
    always @(*)begin
        case(alu_ctrl)
            4'b0000:result=a&b;         //and
            4'b0001:result=a|b;         //or
            4'b0010:result=a+b;         //add
            4'b0110:result=a-b;         //sub
            4'b0111: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // slt, signed
            4'b1100:result=~(a|b);      //nor
            default:result=32'b0;
        endcase
    end
    
    assign zero=(result==0);
    
endmodule
