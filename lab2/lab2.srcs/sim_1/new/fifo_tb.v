`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/04 19:35:06
// Design Name: 
// Module Name: fifo_tb
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


module fifo_tb;
    reg clk, rst;
    reg [7:0] din;
    reg en_in;
    reg en_out;
    wire [7:0] dout;
    wire [4:0] count;
    
    parameter PERIOD = 10, CYCLE = 64;
    
    fifo FIFO(clk, rst, din, en_in, en_out, dout, count);
    
    initial begin
        clk = 0;
        repeat (2 * CYCLE)
            #(PERIOD/2) clk = ~clk;
        $finish;
    end
    
    initial begin
        rst = 1;
        #(PERIOD) rst = 0;
    end
    
    initial begin
        en_in = 0;
        en_out = 0;
        din = 8'h34;
        #(PERIOD*3) en_in = 1;
        #(PERIOD*5) en_in = 0;
        #(PERIOD*2) din = 8'ha0;
        #(PERIOD*2) en_in = 1;
        #(PERIOD*7) en_in = 0;
        #(PERIOD*3) en_out = 1;
        #(PERIOD*2) en_out = 0;
        #(PERIOD*2) din = 8'h0d;
        #(PERIOD*4) en_in = 1;
        #(PERIOD*5) en_in = 0;
        #(PERIOD*2) din = 8'hff;
        en_in = 1;
        #(PERIOD*2) en_in = 0;
        #(PERIOD*3) en_out = 1;
        #(PERIOD*3) en_out = 0;
        #(PERIOD*3) en_out = 1;
        #(PERIOD*3) en_out = 0;
        #(PERIOD*3) en_out = 1;
        #(PERIOD*3) en_out = 0;
        #(PERIOD*3) en_out = 1;
        #(PERIOD*3) en_out = 0;
    end
endmodule
