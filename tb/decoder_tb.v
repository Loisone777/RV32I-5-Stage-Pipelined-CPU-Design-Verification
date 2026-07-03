`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/15 15:28:18
// Design Name: 
// Module Name: decoder_tb
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
module decoder_tb;
    reg [31:0] instr;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [4:0] rs1   ;
    wire [4:0] rs2   ;
    wire [4:0] rd    ;
                      
    wire [31:0] imm   ;
    wire uses_rs1;
    wire uses_rs2;
    
    decoder uut(
        .instr (instr ),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .rs1   (rs1   ),
        .rs2   (rs2   ),
        .rd    (rd    ),
        .uses_rs1(uses_rs1),
        .uses_rs2(uses_rs2),       
        .imm   (imm   )    
    );
    
    initial begin
        // add x5, x6, x7   --> funct7(31:25)=0000000 rs2(24:20)=7 rs1=6 funct3=000 rd=5 opcode=0110011
        instr = 32'b0000000_00111_00110_000_00101_0110011;
        
        #10;
        // addi x5, x6, 10
        instr = {20'd10, 5'd6, 3'b000, 5'd5, 7'b0010011};
        
        #20 $finish;
    end
endmodule
