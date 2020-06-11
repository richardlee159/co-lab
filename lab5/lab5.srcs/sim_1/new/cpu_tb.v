`timescale 1ns / 1ps

module cpu_tb;
    reg clk, rst;
    parameter PERIOD = 10, CYCLE = 80;

    cpu_pipeline CPU(.clk(clk), .rst(rst));
    
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
endmodule
