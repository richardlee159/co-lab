`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/13 15:06:17
// Design Name: 
// Module Name: cpu_one_cycle_db
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


`define ALU_ADD 3'b000
`define ALU_SUB 3'b001
`define ALU_AND 3'b010
`define ALU_OR  3'b011
`define ALU_XOR 3'b100

`define RTYPE 6'b000000
`define ADDI  6'b001000
`define LW    6'b100011
`define SW    6'b101011
`define BEQ   6'b000100
`define J     6'b000010

`define FUNC_ADD 6'b100000

`define PC_IN  31:0
`define PC_OUT 63:32
`define INSTR  95:64
`define RF_RD1 127:96
`define RF_RD2 159:128
`define ALU_Y  191:160
`define M_RD   223:192
`define CTRL   233:224

module cpu_one_cycle_db(
    input clk, rst,
    input run,
    input [29:0] m_rf_addr,
    output [31:0] m_data, rf_data,
    output [233:0] status
    );
    wire [31:0] inst;

    /* ---------- CONTROL ---------- */
    reg Jump, Branch, MemWrite, RegWrite;
    reg RegDst, MemtoReg, ALUSrc;
    reg [2:0] ALUOp;
    always @(*) begin
        {Jump,Branch,MemWrite,RegWrite,RegDst,MemtoReg,ALUSrc,ALUOp} = 10'b0;
        case (inst[31:26])
            `RTYPE: begin
                {RegWrite,RegDst,MemtoReg,ALUSrc} = 4'b1100;
                case (inst[5:0])
                    `FUNC_ADD: ALUOp = `ALU_ADD;
                endcase
             end
            `ADDI : {{RegWrite,RegDst,MemtoReg,ALUSrc},ALUOp} = {4'b1001,`ALU_ADD};
            `LW   : {{RegWrite,RegDst,MemtoReg,ALUSrc},ALUOp} = {4'b1011,`ALU_ADD};
            `SW   : {{MemWrite,ALUSrc},ALUOp} = {2'b11,`ALU_ADD};
            `BEQ  : {{Branch,ALUSrc},ALUOp} = {2'b10,`ALU_XOR};
            `J    : Jump = 1'b1;
        endcase
    end
    
    /* ---------- DATA PATH ---------- */
    wire [31:0] nextpc, pc;
    register PC(.q(pc), .d(nextpc), .clk(clk), .rst(rst), .en(run));
    
    // Fetch
    dist_mem_gen_256x32 I_MEM(.spo(inst), .a(pc[31:2]), .clk(clk), .we(0));
    
    // Decode & WriteBack
    wire [4:0] wa;
    wire [31:0] rd0, rd1, wd;
    mux2 #(5) WA_MUX(.y(wa), .a(inst[20:16]), .b(inst[15:11]), .s(RegDst));
    register_file_db REGFILE(
        .rd0(rd0), .rd1(rd1), .wd(wd),
        .ra0(inst[25:21]), .ra1(inst[20:16]), .wa(wa),
        .clk(clk), .we(RegWrite&run),
        .rax(m_rf_addr[4:0]), .rdx(rf_data)
    );
    
    wire [31:0] addrext;
    signext ADDR_EXT(.dout(addrext), .din(inst[15:0]));
    
    // Execute
    wire [31:0] aluout, alub;
    wire Zero;
    mux2 ALUb_MUX(.y(alub), .a(rd1), .b(addrext), .s(ALUSrc));
    alu ALU(.y(aluout), .zf(Zero), .a(rd0), .b(alub), .m(ALUOp));
    
    // Memory
    wire [31:0] memout;
    dist_dmem_gen_256x32 D_MEM(
        .spo(memout), .a(aluout[31:2]), .d(rd1),
        .clk(clk), .we(MemWrite&run),
        .dpra(m_rf_addr), .dpo(m_data)
    );
    mux2 WD_MUX(.y(wd), .a(aluout), .b(memout), .s(MemtoReg));
    
    // NextPC
    wire [31:0] pc_add_4, br_target, j_target, temppc;
    assign pc_add_4 = pc + 4;
    assign br_target = pc_add_4 + {addrext[29:0],2'b00};
    assign j_target = {pc_add_4[31:28], inst[25:0], 2'b00};
    mux2 BR_MUX(.y(temppc), .a(pc_add_4), .b(br_target), .s(Branch&Zero));
    mux2 J_MUX(.y(nextpc), .a(temppc), .b(j_target), .s(Jump));
    
    assign status[`PC_IN] = nextpc;
    assign status[`PC_OUT] = pc;
    assign status[`INSTR] = inst;
    assign status[`RF_RD1] = rd0;
    assign status[`RF_RD2] = rd1;
    assign status[`ALU_Y] = aluout;
    assign status[`M_RD] = memout;
    assign status[`CTRL] = {Jump, Branch, RegDst, RegWrite, MemtoReg, MemWrite, ALUOp, ALUSrc};
endmodule
