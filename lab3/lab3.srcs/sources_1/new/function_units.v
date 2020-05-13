`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/12 19:58:43
// Design Name: 
// Module Name: function_units
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


`define ALU_ADD 3'b000
`define ALU_SUB 3'b001
`define ALU_AND 3'b010
`define ALU_OR  3'b011
`define ALU_XOR 3'b100

module alu
    #(parameter WIDTH = 32)(
    output reg [WIDTH-1:0] y,   // result
    output reg zf,              // zero flag
//    output reg cf,              // carry flag
//    output reg of,              // overflow flag
    input [WIDTH-1:0] a, b,     // operand
    input [2:0] m               // operation
    );
    localparam MSB = WIDTH - 1;
    
    always @(*) begin
//        cf = 0;
        case (m)
            `ALU_ADD : {y} = a + b;
            `ALU_SUB : {y} = a - b;
            `ALU_AND : y = a & b;
            `ALU_OR  : y = a | b;
            `ALU_XOR : y = a ^ b;
            default : y = 0;
        endcase
//        case (m)
//            `ALU_ADD : of = (~a[MSB]&~b[MSB]&y[MSB])|(a[MSB]&b[MSB]&~y[MSB]);
//            `ALU_SUB : of = (~a[MSB]&b[MSB]&y[MSB])|(a[MSB]&~b[MSB]&~y[MSB]);
//            default: of = 0;
//        endcase
        case (m)
            `ALU_ADD, `ALU_SUB, `ALU_AND, `ALU_OR, `ALU_XOR: zf = ~|y;
            default: zf = 0;
        endcase
    end
endmodule

module register_file            // 32 * WIDTH ¼Ä´æÆ÷¶Ñ
    #(parameter WIDTH = 32)(
    output [WIDTH-1:0] rd0, rd1,
    input [WIDTH-1:0] wd,
    input [4:0] ra0, ra1, wa,
    input clk, we
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

module register
    #(parameter WIDTH = 32,
    RST_VALUE = 0)(
    output reg [WIDTH-1:0] q,
    input [WIDTH-1:0] d,
    input clk, rst, en
    );
    always @(posedge clk, posedge rst)
        if (rst) q <= RST_VALUE;
        else if (en) q <= d;
endmodule

module mux2
    #(parameter WIDTH = 32)(
    output [WIDTH-1:0] y,
    input [WIDTH-1:0] a, b,
    input s
    );
    assign y = s ? b : a;
endmodule

module signext
    #(parameter IN_WIDTH = 16, OUT_WIDTH = 32)(
    output [OUT_WIDTH-1:0] dout,
    input [IN_WIDTH-1:0] din
    );
    assign dout = {{(OUT_WIDTH-IN_WIDTH){din[IN_WIDTH-1]}},din};
endmodule