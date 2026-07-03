`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 16:45:44
// Design Name: 
// Module Name: hazard_detection
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


module hazard_detection(
    input wire          id_ex_MemRead,
    input wire [4:0]    id_ex_rd,
    input wire [4:0]    if_id_rs1,
    input wire [4:0]    if_id_rs2,
    
    input wire        if_id_uses_rs1,
    input wire        if_id_uses_rs2,
    
    output reg          stall
    );
    
    always @(*) begin
        stall = 0;
        // 只有 EX 阶段是 load，
        // 且 load 真的会写入非 x0 寄存器，
        // 且 ID 阶段指令真的使用这个源寄存器时，
        // 才产生 load-use stall。
        if(id_ex_MemRead &&  (id_ex_rd != 5'd0) && ((if_id_uses_rs1&&(id_ex_rd == if_id_rs1))||(if_id_uses_rs2&&(id_ex_rd==if_id_rs2))))
            stall =1;
    end
endmodule
