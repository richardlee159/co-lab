`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/25 18:46:25
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
    input [WIDTH-1:0] a, b,     // operand
    input [2:0] m               // operation
    );
    localparam MSB = WIDTH - 1;
    
    always @(*) begin
        case (m)
            `ALU_ADD : {y} = a + b;
            `ALU_SUB : {y} = a - b;
            `ALU_AND : y = a & b;
            `ALU_OR  : y = a | b;
            `ALU_XOR : y = a ^ b;
            default : y = 0;
        endcase
        case (m)
            `ALU_ADD, `ALU_SUB, `ALU_AND, `ALU_OR, `ALU_XOR: zf = ~|y;
            default: zf = 0;
        endcase
    end
endmodule

module register_file            // 32 * WIDTH RegisterFile
    #(parameter WIDTH = 32)(
    output [WIDTH-1:0] rd1, rd2,
    input [WIDTH-1:0] wd,
    input [4:0] ra1, ra2, wa,
    input clk, we
    );
    reg [WIDTH-1:0] regs [1:31];
    // asynchronous read
    assign rd1 = ra1 ? regs[ra1] : 0;
    assign rd2 = ra2 ? regs[ra2] : 0;
    // synchronous write
    always @(posedge clk) begin
        if (we && wa) regs[wa] <= wd;
    end
endmodule

module register_file_db            // 32 * WIDTH RF for DBU
    #(parameter WIDTH = 32)(
    output [WIDTH-1:0] rd1, rd2, rdx,
    input [WIDTH-1:0] wd,
    input [4:0] ra1, ra2, wa, rax,
    input clk, we
    );
    reg [WIDTH-1:0] regs [1:31];
    // asynchronous read
    assign rd1 = ra1 ? regs[ra1] : 0;
    assign rd2 = ra2 ? regs[ra2] : 0;
    assign rdx = rax ? regs[rax] : 0;
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
    input [WIDTH-1:0] x0, x1,
    input s
    );
    assign y = s ? x1 : x0;
endmodule

module mux4
    #(parameter WIDTH = 32)(
    output reg [WIDTH-1:0] y,
    input [WIDTH-1:0] x0, x1, x2, x3,
    input [1:0] s
    );
    always @(*)
        case (s)
            2'b00: y = x0;
            2'b01: y = x1;
            2'b10: y = x2;
            2'b11: y = x3;
        endcase
endmodule

module signext
    #(parameter IN_WIDTH = 16, OUT_WIDTH = 32)(
    output [OUT_WIDTH-1:0] dout,
    input [IN_WIDTH-1:0] din
    );
    assign dout = {{(OUT_WIDTH-IN_WIDTH){din[IN_WIDTH-1]}},din};
endmodule