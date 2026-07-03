`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 16:15:33
// Design Name: 
// Module Name: alu_control
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


module alu_control(
    input wire [1:0] ALUOp,
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    output reg [3:0] ALUCtrl
    );
    
    always @(*) begin
        case(ALUOp)
            2'b00:ALUCtrl = 4'b0010;//load/store->add
            2'b01:ALUCtrl = 4'b0110;//branch->sub
            2'b10:begin //R-type or I-type
                case(funct3)
                    // R-type:
                    // add = funct7 0000000
                    // sub = funct7 0100000
                    //
                    // I-type addi:
                    // funct7 bits are actually part of immediate,
                    // so it must always decode as ADD.
                    3'b000: begin
                        if ((opcode == 7'b0110011) &&
                            (funct7 == 7'b0100000))
                            ALUCtrl = 4'b0110; // SUB
                        else
                            ALUCtrl = 4'b0010; // ADD / ADDI
                    end
                    3'b111:ALUCtrl = 4'b0000;//and
                    3'b110:ALUCtrl = 4'b0001;//or
                    3'b010:ALUCtrl = 4'b0111;//slt
                    default:ALUCtrl = 4'b0010;
                endcase
            end
            
            default:ALUCtrl = 4'b0010;
        endcase
    end
endmodule
