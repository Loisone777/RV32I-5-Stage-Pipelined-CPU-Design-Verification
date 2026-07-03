`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/15 14:37:37
// Design Name: 
// Module Name: decoder
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


module decoder(
    input wire [31:0] instr ,
    output wire [6:0] opcode,
    output wire [2:0] funct3,
    output wire [6:0] funct7,
    output wire [4:0] rs1   ,
    output wire [4:0] rs2   ,
    output wire [4:0] rd    ,
    
    output reg        uses_rs1,
    output reg        uses_rs2,
    output reg [31:0] imm
    );
    
    assign  opcode = instr[6:0];
    assign  funct3 = instr[14:12];
    assign  funct7 = instr[31:25];
    assign  rs1    = instr[19:15];
    assign  rs2    = instr[24:20];
    assign  rd     = instr[11:7];
    
    always @(*) begin
        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;
    
        case (opcode)
            // R-type:
            // add/sub/and/or/slt ...
            7'b0110011: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end
            // I-type ALU:
            // addi/andi/ori/slti ...
            7'b0010011: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b0;
            end   
            // load: lw
            7'b0000011: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b0;
            end  
            // store: sw
            7'b0100011: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end    
            // branch: beq/bne
            7'b1100011: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end   
            // jalr
            7'b1100111: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b0;
            end   
            // lui / auipc / jal:
            // 都不读取通用寄存器
            7'b0110111,
            7'b0010111,
            7'b1101111: begin
                uses_rs1 = 1'b0;
                uses_rs2 = 1'b0;
            end
    
            default: begin
                uses_rs1 = 1'b0;
                uses_rs2 = 1'b0;
            end
        endcase
    end
    
    always @(*) begin
        case(opcode)
            7'b0010011,//I-type (addi etc.)
            7'b0000011,//load
            7'b1100111://jalr
                imm = {{20{instr[31]}},instr[31:20]};
            7'b0100011://S-type store
                imm = {{20{instr[31]}},instr[31:25],instr[11:7]};
            7'b1100011://B-type branch
                imm = {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};
            7'b0110111,//lui
            7'b0010111://auipc
                imm = {instr[31:12],12'b0};
            7'b1101111://J-type jal
                imm = {{12{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0};
            default: 
                imm=32'b0;
        endcase
    end
endmodule
