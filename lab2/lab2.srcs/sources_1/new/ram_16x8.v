`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/04 11:48:21
// Design Name: 
// Module Name: ram_16x8
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


module ram_16x8(
    input clk,
    input en, we,
    input [3:0] addr,
    input [7:0] din,
    output [7:0] dout
    );
    
// 需要例化一种ram时将另一种ram的代码注释掉，否则dout会有多驱动

//    dist_mem_16x8 MEM0(
//        .clk(clk),
//        .a(addr),
//        .d(din),
//        .we(we),
//        .spo(dout)
//    );
    
    blk_mem_16x8 MEM1(
        .clka(clk),
        .addra(addr),
        .dina(din),
        .douta(dout),
        .ena(en),
        .wea(we)
    );
endmodule
