`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/17 15:44:35
// Design Name: 
// Module Name: mem_wb
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


module mem_wb(
    input wire clk,
    input wire rst,
    input wire stall,             // 一般接 0 也行，接口统一

    // from MEM
    input wire        mem_valid,
    
    input wire [31:0] mem_pc,
    input wire [31:0] mem_instr,
    
    input wire        mem_store_we,
    input wire [31:0] mem_store_addr,
    input wire [31:0] mem_store_wdata,

    input wire [31:0] mem_read_data,
    input wire [31:0] mem_alu_result,
    input wire [4:0]  mem_rd,
    input wire        mem_RegWrite,
    input wire        mem_MemToReg,

    // to WB
    output reg        wb_valid,
    
    output reg [31:0] wb_pc,
    output reg [31:0] wb_instr,
    
    output reg        wb_store_we,
    output reg [31:0] wb_store_addr,
    output reg [31:0] wb_store_wdata,

    output reg [31:0] wb_read_data,
    output reg [31:0] wb_alu_result,
    output reg [4:0]  wb_rd,
    output reg        wb_RegWrite,
    output reg        wb_MemToReg
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_valid       <= 1'b0;
            
            wb_pc          <= 32'b0;
            wb_instr       <= 32'h00000013;
            
            wb_store_we    <= 1'b0;
            wb_store_addr  <= 32'b0;
            wb_store_wdata <= 32'b0;
            
            wb_read_data  <= 0;
            wb_alu_result <= 0;
            wb_rd         <= 0;
            wb_RegWrite   <= 0;
            wb_MemToReg   <= 0;
        end
        else if (!stall) begin
            wb_valid      <= mem_valid;
            
            wb_pc          <= mem_pc;
            wb_instr       <= mem_instr;
            
            wb_store_we    <= mem_store_we;
            wb_store_addr  <= mem_store_addr;
            wb_store_wdata <= mem_store_wdata;

            wb_read_data  <= mem_read_data;
            wb_alu_result <= mem_alu_result;
            wb_rd         <= mem_rd;
            wb_RegWrite   <= mem_RegWrite;
            wb_MemToReg   <= mem_MemToReg;
        end
    end
endmodule

