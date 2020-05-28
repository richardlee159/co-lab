`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/27 19:25:07
// Design Name: 
// Module Name: dbu_tb
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


module dbu_tb;
    parameter PERIOD = 10, CYCLE = 300;

    reg clk, rst;
    reg succ, step;
    reg [2:0] sel;
    reg m_rf;
    reg inc, dec;

    dbu DBU(
        .clk(clk), .rst(rst),
        .succ(succ), .step(step),
        .sel(sel), .m_rf(m_rf),
        .inc(inc), .dec(dec)
    );
    
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
        succ = 0; step = 0;
        #(PERIOD*2) step = 1;
        #(PERIOD*3) step = 0;
        #(PERIOD*2) step = 1;
        #(PERIOD*4) step = 0;
        #(PERIOD*20) succ = 1;
    end
    
    initial begin
        sel = 3'b1;
        m_rf = 0;
        inc = 0; dec = 0;
        #(PERIOD*15)
        repeat (7) begin
            #(PERIOD*2) sel = sel + 3'b1;
        end
        #(PERIOD*20)
        m_rf = 1;
        repeat(8) begin
            #(PERIOD*3) inc = 1;
            #(PERIOD*3) inc = 0;
        end
    end
endmodule
