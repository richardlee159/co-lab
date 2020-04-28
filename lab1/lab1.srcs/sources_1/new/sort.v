`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/26 21:02:47
// Design Name: 
// Module Name: sort
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


`define LOAD  3'h0
`define CX01  3'h1
`define CX12  3'h2
`define CX23  3'h3
`define CX01S 3'h4
`define CX12S 3'h5
`define CX01T 3'h6
`define HALT  3'h7

module sort
    #(parameter N = 4)(
    output [N-1:0] s0,s1,s2,s3, //sorted data: s3..s0 ascending
    output reg done,            //finished
    input [N-1:0] x0,x1,x2,x3,  //original data
    input clk, rst
    );
    wire [N-1:0] i0,i1,i2,i3;   // input to register (port d)
    wire [N-1:0] r0,r1,r2,r3;   // output from register (port q)
    wire [N-1:0] a,b;           // two operands of alu
    wire of,sf;                 // flags
    wire altb;                  // altb = a < b
    wire [N-2:0] idle;          // not used
    reg en0,en1,en2,en3;        // register enable (port en)
    reg m0,m1,rsrc;             // select bits of multiplexers (port s)
    
    /*---------- DATA PATH ----------*/
    
    register #(N) R0(r0, i0, clk, rst, en0),
                  R1(r1, i1, clk, rst, en1),
                  R2(r2, i2, clk, rst, en2),
                  R3(r3, i3, clk, rst, en3);
    assign {s0,s1,s2,s3} = {r0,r1,r2,r3};

    alu #(N) ALU0(.y({sf,idle}), .of(of), .a(a), .b(b), .m(`SUB));
    assign altb = of ^ sf;
    
    mux2 #(N) MUX0(a, r0, r2, m0),
              MUX1(b, r1, r3, m1),
              RSRC0(i0, x0, b, rsrc),
              RSRC1(i1, x1, a, rsrc),
              RSRC2(i2, x2, b, rsrc),
              RSRC3(i3, x3, a, rsrc);
    
    /*---------- CONTROL UNIT ----------*/
    
    // state register
    reg [2:0] current_state, next_state;
    always @(posedge clk, posedge rst) begin
        if (rst) current_state <= `LOAD;
        else     current_state <= next_state;
    end
    
    // next state logic
    always @(*) begin
        case (current_state)
            `LOAD  : next_state = `CX01;
            `CX01  : next_state = `CX12;
            `CX12  : next_state = `CX23;
            `CX23  : next_state = `CX01S;
            `CX01S : next_state = `CX12S;
            `CX12S : next_state = `CX01T;
            `CX01T : next_state = `HALT;
            default: next_state = `HALT;
        endcase
    end
    
    // output logic
    always @(*) begin
        {rsrc,en0,en1,en2,en3,m0,m1,done} = 8'b10000000;
        case (current_state)
            `LOAD :
                begin rsrc = 0; {en0,en1,en2,en3} = 4'b1111; end
            `CX01, `CX01S, `CX01T :
                begin {en0,en1} = {2{altb}}; end
            `CX12, `CX12S :
                begin {en1,en2} = {2{~altb}}; m0 = 1; end
            `CX23 :
                begin {en2,en3} = {2{altb}}; m0 = 1; m1 = 1; end
            `HALT :
                done = 1;
        endcase
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