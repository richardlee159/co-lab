`timescale 1ns / 1ps


module bus(
    input clk, rst,
    input btn,
    input [7:0] sw,
    output [7:0] led
    );
    wire [31:0] bus_addr;
    wire [31:0] bus_din;
    wire [31:0] bus_dout;
    wire bus_rd, bus_wr;
    
    // CPU
    cpu_top(
        .clk(clk), .rst(rst),
        .bus_addr(bus_addr),
        .bus_din (bus_din ),
        .bus_dout(bus_dout),
        .bus_rd  (bus_rd  ),
        .bus_wr  (bus_wr  )
     );
     
    // ssr: switch state register
    // sdr: switch data register
    // ldr: led data register
    reg  mem_en, ssr_en, sdr_en, ldr_en;
    wire [31:0] mem_out, ssr_out, sdr_out, ldr_out;
    
    // Memory
    dmem_256x32 DMEM(
        .a(bus_addr[9:2]), .d(bus_din),
        .clk(clk), .we(mem_en & bus_wr), .spo(mem_out)
    );
    
    // IO Interface
    register SSR(.q(ssr_out), .d(bus_din), .clk(clk), .rst(rst), .en(ssr_en & bus_wr));
    register SDR(.q(sdr_out), .d(bus_din), .clk(clk), .rst(rst), .en(sdr_en & bus_wr));
    register LDR(.q(ldr_out), .d(bus_din), .clk(clk), .rst(rst), .en(ldr_en & bus_wr));
    
    // Bus Router  
    assign bus_dout = ({32{mem_en}} & mem_out)
                    | ({32{ssr_en}} & ssr_out)
                    | ({32{sdr_en}} & sdr_out)
                    | ({32{ldr_en}} & ldr_out);
                  
    always @(*) begin
        {mem_en, ssr_en, sdr_en, ldr_en} = 4'b0;
        if (bus_addr[13] == 0)     // memory
            mem_en = 1;
        else case(bus_addr[3:2])   // IO
            2'b00: ssr_en = 1;
            2'b01: sdr_en = 1;
            2'b11: ldr_en = 1;
        endcase
    end
endmodule
