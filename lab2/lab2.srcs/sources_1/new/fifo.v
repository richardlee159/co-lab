`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/04 13:56:15
// Design Name: 
// Module Name: fifo
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


module fifo(
    input clk, rst,
    input [7:0] din,
    input en_in,
    input en_out,
    output [7:0] dout,
    output [4:0] count
    );
    wire en_in_edge, en_out_edge;
    signal_edge IN_EDGE(clk, en_in, en_in_edge);
    signal_edge OUT_EDGE(clk, en_out, en_out_edge);
    reg [3:0] addr;
    reg en, we;
    blk_mem_16x8 MEM(
        .clka(clk),
        .addra(addr),
        .dina(din),
        .douta(dout),
        .ena(en),
        .wea(we)
    );
    
endmodule

module signal_edge(
    input clk,
    input button,
    output button_redge
    );
    wire button_clean;
    jitter_clr jitter_clr_stepbtn(
        .clk(clk),
        .button(button),
        .button_clean(button_clean)
    );
    reg button_r1, button_r2;
    always @(posedge clk)
    begin
        button_r1 <= button_clean;
        button_r2 <= button_r1;
    end
    assign button_redge = button_r1 & (~button_r2);
endmodule

module jitter_clr(
    input clk,
    input button,
    output button_clean
    );
    reg [20:0] cnt;
    always @(posedge clk)
    begin
        if (button==1'b0) cnt <= 21'h0;
        else if (cnt < 21'h100000) cnt <= cnt + 21'b1;
    end
    assign button_clean = cnt[20];
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