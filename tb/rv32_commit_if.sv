`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/30 20:15:40
// Design Name: 
// Module Name: rv32_commit_if
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

`timescale 1ns / 1ps

interface rv32_commit_if (
    input logic clk
);

    logic        rst;

    logic        commit_valid;
    logic [31:0] commit_pc;
    logic [31:0] commit_instr;

    logic        commit_rd_we;
    logic [4:0]  commit_rd;
    logic [31:0] commit_rd_data;

    logic        commit_mem_we;
    logic [31:0] commit_mem_addr;
    logic [31:0] commit_mem_wdata;

endinterface
