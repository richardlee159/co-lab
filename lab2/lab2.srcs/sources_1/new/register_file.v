`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/04 09:56:17
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


module register_file            // 32 * WIDTH ¼Ä´æÆ÷¶Ñ
    #(parameter WIDTH = 32)(
    input clk,
    input [4:0] ra0,
    output [WIDTH-1:0] rd0,
    input [4:0] ra1,
    output [WIDTH-1:0] rd1,
    input [4:0] wa,
    input we,
    input [WIDTH-1:0] wd
    );
    reg [WIDTH-1:0] regs [1:31];
    // asynchronous read
    assign rd0 = ra0 ? regs[ra0] : 0;
    assign rd1 = ra1 ? regs[ra1] : 0;
    // synchronous write
    always @(posedge clk) begin
        if (we && wa) regs[wa] <= wd;
    end
endmodule
