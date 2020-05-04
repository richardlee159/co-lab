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
    wire [3:0] addr, addr_inc, head_q, tail_q;
    wire [4:0] ctr_q, ctr_d, addend;
    reg ram_en, ram_we;
    reg head_en, tail_en, ctr_en;
    reg addr_src, inc_dec;
    
    /* ---------- DATA PATH ---------- */
    signal_edge IN_EDGE(clk, en_in, en_in_edge);
    signal_edge OUT_EDGE(clk, en_out, en_out_edge);
    
    blk_mem_16x8 MEM(
        .clka(clk),
        .addra(addr),
        .dina(din),
        .douta(dout),
        .ena(ram_en),
        .wea(ram_we)
    );
    
    assign addr_inc = addr + 1;
    register #(4) HEAD(head_q, addr_inc, clk, rst, head_en);
    register #(4) TAIL(tail_q, addr_inc, clk, rst, tail_en);
    mux2 #(4) ADDRMUX(addr, head_q, tail_q, addr_src);
    
    assign ctr_d = ctr_q + addend;
    register #(5) COUNTER(ctr_q, ctr_d, clk, rst, ctr_en);
    mux2 #(5) CTRMUX(addend, 5'd1, -5'd1, inc_dec);
    assign count = ctr_q;
    
    /* ---------- CONTROL UNIT ---------- */
    localparam WAIT = 2'b00, ENQ = 2'b01, DEQ = 2'b10, HOLD = 2'b11;
    // state register
    reg [1:0] current_state, next_state;
    always @(posedge clk, posedge rst) begin
        if (rst)
            current_state <= WAIT;
        else
            current_state <= next_state;
    end
    
    // next state logic
    always @(*) begin
        case (current_state)
            WAIT : begin 
                if (en_in_edge && (ctr_q != 5'd16)) next_state = ENQ;
                else if (en_out_edge && (ctr_q != 5'd0)) next_state = DEQ;
                else next_state = WAIT;
            end
            ENQ, DEQ : next_state = HOLD;
            default : next_state = WAIT;
        endcase
    end
    
    // output logic
    always @(*) begin
        {ram_en, ram_we, head_en, tail_en, ctr_en, addr_src, inc_dec} = 7'b0000000;
        case (current_state)
            ENQ : {ram_en, ram_we, tail_en, ctr_en, addr_src} = 5'b11111;
            DEQ : {ram_en, head_en, ctr_en, inc_dec} = 4'b1111;
            HOLD : ram_en = 1;
        endcase
    end
    
endmodule

module signal_edge(
    input clk,
    input button,
    output button_redge
    );
//    wire button_clean;
//    jitter_clr jitter_clr_stepbtn(
//        .clk(clk),
//        .button(button),
//        .button_clean(button_clean)
//    );
    reg button_r1, button_r2;
    always @(posedge clk)
    begin
        button_r1 <= button;
        button_r2 <= button_r1;
    end
    assign button_redge = button_r1 & (~button_r2);
endmodule

//module jitter_clr(
//    input clk,
//    input button,
//    output button_clean
//    );
//    reg [20:0] cnt;
//    always @(posedge clk)
//    begin
//        if (button==1'b0) cnt <= 21'h0;
//        else if (cnt < 21'h100000) cnt <= cnt + 21'b1;
//    end
//    assign button_clean = cnt[20];
//endmodule

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