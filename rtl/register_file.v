`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/14 13:36:08
// Design Name: 
// Module Name: register_file
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


module register_file(
    input wire          clk,
    input wire          we,         //write enable
    input wire [4:0]    waddr,      //write address
    input wire [31:0]   wdata,      //write data
    input wire [4:0]    raddr1,     //read address 1
    output wire [31:0]   rdata1,     //read data 1
    input wire [4:0]    raddr2,     //read address 2
    output wire [31:0]   rdata2      //read data 2
    );
    
    reg [31:0] regs [0:31];
    
    integer i;
    initial begin
        for(i=0;i<32;i=i+1)
            regs[i]=32'b0;
    end
    
    //write
    always @(posedge clk) begin
        if(we&&(waddr!=0))      //x0 is always 0
            regs[waddr]<=wdata;
    end
    
    //read
    // Read-after-write bypass:
    // 当 WB 在本周期写某寄存器，而 ID 同周期读取该寄存器时，
    // 直接把正在写回的 wdata 提供给读端，避免读到旧值。
    assign rdata1 =
        (raddr1 == 5'd0) ? 32'd0 :
        (we && (waddr != 5'd0) && (waddr == raddr1)) ? wdata :
        regs[raddr1];
    
    assign rdata2 =
        (raddr2 == 5'd0) ? 32'd0 :
        (we && (waddr != 5'd0) && (waddr == raddr2)) ? wdata :
        regs[raddr2];
    
endmodule
