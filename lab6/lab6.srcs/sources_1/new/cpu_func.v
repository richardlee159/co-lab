`timescale 1ns / 1ps


`include "cpu_macros.v"

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
            `ALU_SLT : y = (a < b) ? 1 : 0;
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
    always @(negedge clk) begin
        if (we && wa) regs[wa] <= wd;
    end
    
    integer i;
    initial begin
        for (i = 1; i < 32; i = i + 1)
           regs[i] = 32'b0;
    end
endmodule

module register
    #(parameter WIDTH = 32,
    RST_VALUE = 0)(
    output reg [WIDTH-1:0] q,
    input [WIDTH-1:0] d,
    input clk, rst, en
    );
    always @(posedge clk)
        if (rst) q <= RST_VALUE;
        else if (en) q <= d;
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