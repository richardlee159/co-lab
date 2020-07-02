`ifndef CPU_MACROS
`define CPU_MACROS

`define RTYPE 6'b000000
`define ADDI  6'b001000
`define LW    6'b100011
`define SW    6'b101011
`define BEQ   6'b000100
`define J     6'b000010

`define FUNCT_ADD 6'b100000
`define FUNCT_SUB 6'b100010
`define FUNCT_AND 6'b100100
`define FUNCT_OR  6'b100101
`define FUNCT_XOR 6'b100110
`define FUNCT_SLT 6'b101010

`define ALU_ADD 3'b000
`define ALU_SUB 3'b001
`define ALU_AND 3'b010
`define ALU_OR  3'b011
`define ALU_XOR 3'b100
`define ALU_SLT 3'b101
`define ALU_DEF 3'b111

`endif