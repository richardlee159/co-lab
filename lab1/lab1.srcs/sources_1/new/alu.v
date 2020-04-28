`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/26 19:07:58
// Design Name: 
// Module Name: alu
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


`define ADD 3'b000
`define SUB 3'b001
`define AND 3'b010
`define OR  3'b011
`define XOR 3'b100

module alu
    #(parameter WIDTH = 32)(
    output reg [WIDTH-1:0] y,   // result
    output reg zf,              // zero flag
    output reg cf,              // carry flag
    output reg of,              // overflow flag
    input [WIDTH-1:0] a, b,     // operand
    input [2:0] m               // operation
    );
    localparam MSB = WIDTH - 1;
    
    always @(*) begin
        cf = 0;
        case (m)
            `ADD : {cf,y} = a + b;
            `SUB : {cf,y} = a - b;
            `AND : y = a & b;
            `OR  : y = a | b;
            `XOR : y = a ^ b;
            default : y = 0;
        endcase
        case (m)
            `ADD : of = (~a[MSB]&~b[MSB]&y[MSB])|(a[MSB]&b[MSB]&~y[MSB]);
            `SUB : of = (~a[MSB]&b[MSB]&y[MSB])|(a[MSB]&~b[MSB]&~y[MSB]);
            default: of = 0;
        endcase
        case (m)
            `ADD, `SUB, `AND, `OR, `XOR: zf = ~|y;
            default: zf = 0;
        endcase
    end
    
endmodule