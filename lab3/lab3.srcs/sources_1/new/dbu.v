`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/13 15:06:17
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

`define PC_IN  31:0
`define PC_OUT 63:32
`define INSTR  95:64
`define RF_RD1 127:96
`define RF_RD2 159:128
`define ALU_Y  191:160
`define M_RD   223:192
`define CTRL   233:224

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
    
    wire run;                   // 控制CPU的运行
    reg [7:0] m_rf_addr;        // MEM/RF的调试读口地址(字地址)
    wire [233:0] status;        // CPU内部状态(使用文件开头定义的宏来分离对应信号)
    wire [31:0] m_data, rf_data;// 从RF/MEM读取的数据字
    
    cpu_one_cycle_db CPU(
        .clk(clk), .rst(rst),
        .run(run), .status(status),
        .m_rf_addr(m_rf_addr),
        .m_data(m_data), .rf_data(rf_data)
    );
    
    // 与按钮相连的信号需要取边沿
    wire step_edge, inc_edge, dec_edge;
    signal_edge STEPEDGE(clk, step, step_edge);
    signal_edge INCEDGE(clk, inc, inc_edge);
    signal_edge DECEDGE(clk, dec, dec_edge);
    
    assign run = succ | step_edge;
    
    always @(posedge clk, posedge rst) begin
        if (rst) m_rf_addr <= 0;
        else begin
            if (inc_edge) m_rf_addr <= m_rf_addr + 1;
            else if(dec_edge) m_rf_addr <= m_rf_addr - 1;
        end
    end
    
    assign led = sel ? status[`CTRL] : m_rf_addr;
    
    reg [31:0] seg_num;         // 8个数码管上显示的数字
    always @(*) begin
        case (sel)
            3'd0: seg_num = m_rf ? m_data : rf_data;
            3'd1: seg_num = status[`PC_IN];
            3'd2: seg_num = status[`PC_OUT];
            3'd3: seg_num = status[`INSTR];
            3'd4: seg_num = status[`RF_RD1];
            3'd5: seg_num = status[`RF_RD2];
            3'd6: seg_num = status[`ALU_Y];
            3'd7: seg_num = status[`M_RD];
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
    // 取边沿电路，每次button的上升沿来临时button_redge产生一个时钟周期的脉冲信号
    
    wire button_clean;      // button去抖动后的信号(仿真阶段并未使用)
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
    //去抖动电路
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
