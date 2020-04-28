`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/26 19:47:28
// Design Name: 
// Module Name: alu_tb
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


module alu_tb;
    reg [3:0] a, b;
    reg [2:0] m;
    wire [3:0] y;
    wire zf, cf, of;
    
    parameter PERIOD = 10;
     
    alu #(4) ALU(.a(a), .b(b), .m(m), .y(y), .cf(cf), .of(of), .zf(zf));
    
    initial begin
        m = 0;      		//ADD
        a = 4'b0011; 
        b = 4'b1100;
        
        #PERIOD;
        a = 4'b1000;
        b = 4'b1101;
        
        #PERIOD;
        a = 4'b0101;
        b = 4'b1001;
        
        #PERIOD;
        a = 4'b1111;
        b = 4'b0001;
                
        #PERIOD m = 1;	//SUB

        #PERIOD;
        a = 4'b0011;
        b = 4'b1110;
        
        #PERIOD;
        a = 4'b1000;
        b = 4'b1101;
        
        #PERIOD;
        a = 4'b0101;
        b = 4'b1001;
        
        #PERIOD;
        a = 4'b0111;
        b = 4'b0111; 

        #PERIOD m = 2;	//AND
        a = 4'b0011;
        b = 4'b0101;
        
        #PERIOD m = 3;	//OR
        #PERIOD m = 4;	//XOR
        #PERIOD m = 5;	//other
        #PERIOD;
        $finish;      
    end
endmodule
