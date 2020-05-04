`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/04 11:01:19
// Design Name: 
// Module Name: register_file_tb
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


module register_file_tb;
    reg clk;
    reg [4:0] ra0, ra1, wa;
    reg we;
    reg [31:0] wd;
    wire [31:0] rd0, rd1;
    
    parameter PERIOD = 10, CYCLE = 64;
    
    register_file #(32) RF(clk, ra0, rd0, ra1, rd1, wa, we, wd);
    
    initial begin
        clk = 0;
        repeat (2 * CYCLE)
            #(PERIOD/2) clk = ~clk;
        $finish;
    end
    
    initial begin
        wa = 0; we = 1;
        ra0 = 5; ra1 = 10;
        repeat (32) begin
            wd = wa * wa + 1;
            #PERIOD wa = wa + 1;
        end
        we = 0;
        repeat (32) begin
            #PERIOD
            ra0 = ra0 + 1;
            ra1 = ra1 + 2;
        end
    end
endmodule
