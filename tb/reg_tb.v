`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/14 14:41:26
// Design Name: 
// Module Name: reg_tb
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
module reg_tb;

    reg clk;
    reg we;
    reg [4:0] waddr,raddr1,raddr2;
    wire [31:0] rdata1,rdata2;
    reg [31:0] wdata;
    
    register_file uut(
        .clk    (clk   ),
        .we     (we    ),         //write enable
        .waddr  (waddr ),      //write address
        .wdata  (wdata ),      //write data
        .raddr1 (raddr1),     //read address 1
        .rdata1 (rdata1),     //read data 1
        .raddr2 (raddr2),     //read address 2
        .rdata2 (rdata2)      //read data 2
    );
    
    //clk
    always #5 clk=~clk;

    initial begin
        clk    = 0;
        we     = 0;
        waddr  = 0;
        wdata  = 0;
        raddr1 = 0;
        raddr2 = 0;
        
        //x1=10
        #10;
        we=1;waddr=5'd1;wdata=32'd10;
        #10;
        we=0;
        
        //x2=20
        #10;
        we=1;waddr=5'd2;wdata=32'd20;
        #10;
        we=0;
        
        //read x1,x2
        #10;
        raddr1=5'd1;raddr2=5'd2;
        
        #20;
        
        $finish;
        
    end
endmodule
