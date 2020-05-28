`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/25 18:46:25
// Design Name: 
// Module Name: dbu
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


`define SIMULATION

`define PC     31:0
`define IR     63:32
`define MD     95:64
`define A      127:96
`define B      159:128
`define ALUOUT 191:160
`define CTRL   207:192

module dbu(
    input clk, rst,
    input succ, step,
    input [2:0] sel,
    input m_rf,
    input inc, dec,
    output [15:0] led,
    output [7:0] an,
    output [7:0] seg
    );
    
    wire clkd;
    reg [7:0] m_rf_addr;
    wire [207:0] status;
    wire [31:0] m_data, rf_data;
    
    cpu_multicycle_db CPU(
        .clk(clkd), .rst(rst),
        .status(status),
        .m_rf_addr(m_rf_addr),
        .m_data(m_data), .rf_data(rf_data)
    );
    
    wire step_edge, inc_edge, dec_edge;
    signal_edge STEPEDGE(clk, step, step_edge);
    signal_edge INCEDGE(clk, inc, inc_edge);
    signal_edge DECEDGE(clk, dec, dec_edge);
    
    assign clkd = (succ | step_edge) & clk;
    
    always @(posedge clk, posedge rst) begin
        if (rst) m_rf_addr <= 0;
        else begin
            if (inc_edge) m_rf_addr <= m_rf_addr + 1;
            else if(dec_edge) m_rf_addr <= m_rf_addr - 1;
        end
    end
    
    assign led = sel ? status[`CTRL] : m_rf_addr;
    
    reg [31:0] seg_num;
    always @(*) begin
        case (sel)
            3'd0: seg_num = m_rf ? m_data : rf_data;
            3'd1: seg_num = status[`PC];
            3'd2: seg_num = status[`IR];
            3'd3: seg_num = status[`MD];
            3'd4: seg_num = status[`A];
            3'd5: seg_num = status[`B];
            3'd6: seg_num = status[`ALUOUT];
            3'd7: seg_num = 32'b0;
        endcase
    end
    seg_display SEGDISP(
        .clk(clk),
        .seg_en(8'hff),
        .num(seg_num),
        .ca(seg),
        .an(an)
    );
endmodule

module signal_edge(
    input clk,
    input button,
    output button_redge
    );
    
    wire button_clean;
    `ifdef SIMULATION
    assign button_clean = button;
    `else
    jitter_clr jitter_clr_stepbtn(
        .clk(clk),
        .button(button),
        .button_clean(button_clean)
    );
    `endif
    
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
    //???????¡¤
    reg [20:0] cnt;
    always @(posedge clk)
    begin
        if (button==1'b0) cnt <= 21'h0;
        else if (cnt < 21'h100000) cnt <= cnt + 21'b1;
    end
    assign button_clean = cnt[20];
endmodule

module pulse_1khz_gen(
    input clk,
    output pulse
    );
    reg [16:0] cnt;
    always @(posedge clk)
    begin
        if (cnt >= 100000) cnt <= 17'h0;
        else cnt <= cnt + 17'h1;
    end
    assign pulse = (cnt == 17'h1);
endmodule

module seg_encode(
    input [3:0] num,
    output [7:0] seg
    );
    wire [127:0] segs = 128'hc0_f9_a4_b0_99_92_82_f8_80_90_88_83_c6_a1_86_8e;
    assign seg = segs >> (num << 3);
endmodule

module seg_display(
    input clk,
    input [7:0] seg_en,
    input [31:0] num,
    output [7:0] ca,
    output [7:0] an
    );
    wire pulse_1khz;
    reg [3:0] num0;
    reg [2:0] sel;
    
    pulse_1khz_gen pulse_1khz_gen_inst(
        .clk(clk),
        .pulse(pulse_1khz)
    );
    
    always @(posedge clk)
        if (pulse_1khz) sel <= sel + 3'b1;
        else sel <= sel;
    
    seg_encode seg_encode_inst1(
        .num(num0),
        .seg(ca)
    );

    always @(*) begin
        case (sel)
            3'd0: num0 = num[3:0];
            3'd1: num0 = num[7:4];
            3'd2: num0 = num[11:8];
            3'd3: num0 = num[15:12];
            3'd4: num0 = num[19:16];
            3'd5: num0 = num[23:20];
            3'd6: num0 = num[27:24];
            3'd7: num0 = num[31:28];
        endcase
    end
    
    assign an = (8'b11111110 << sel) | ~seg_en;
endmodule