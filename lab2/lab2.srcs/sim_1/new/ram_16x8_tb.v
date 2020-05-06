`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/04 13:30:37
// Design Name: 
// Module Name: ram_16x8_tb
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


module ram_16x8_tb;
    reg clk;
    reg en, we;
    reg [3:0] addr;
    reg [7:0] din;
    wire [7:0] dout;
    
    parameter PERIOD = 10, CYCLE = 96;

    ram_16x8 RAM(clk, en, we, addr, din, dout);
    
    initial begin
        clk = 0;
        repeat (2 * CYCLE)
            #(PERIOD/2) clk = ~clk;
        $finish;
    end
    
    initial begin
        en = 1;
        we = 1;
        addr = 0;
        repeat (16) begin
            din = 2 * addr + 1;
            #(PERIOD*2) addr = addr + 1;
        end
        we = 0;
        repeat (16) begin
            #(PERIOD*2) addr = addr + 3;
        end
        en = 0;
        repeat (16) begin
            #(PERIOD*2) addr = addr + 1;
        end
    end
endmodule
