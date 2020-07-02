`timescale 1ns / 1ps


module bus_tb;
    reg clk, rst;
    reg btn;
    reg [7:0] sw;
    wire [7:0] led;
    parameter PERIOD = 10, CYCLE = 600;

    bus BUS(.clk(clk), .rst(rst), .btn(btn), .sw(sw), .led(led));
    
    initial begin
        clk = 0;
        repeat (2 * CYCLE)
            #(PERIOD/2) clk = ~clk;
        $finish;
    end
    
    initial begin
        rst = 1;
        btn = 0;
        #(PERIOD) rst = 0;
        #(PERIOD*2) sw = 8'd40;
        #(PERIOD*3) btn = 1;
        #(PERIOD*2) btn = 0;
        #(PERIOD*4) sw = 8'd28;
        #(PERIOD*2) btn = 1;
        #(PERIOD*2) btn = 0;
    end
endmodule
