`timescale 1ns / 1ps

module baud_rate_gen #(
    parameter BAUD_RATE = 9600,
    parameter FACTOR    = 16,
    parameter CLK_FREQ  = 100_000_000
)(
    input  wire sys_clk,
    input  wire sys_rst_l,
    
    output reg  baud_clk
);

localparam integer CLK_DIV = CLK_FREQ / (FACTOR * BAUD_RATE * 2);
localparam integer CW      = $clog2(CLK_DIV);

reg [CW-1:0] count;

always @(posedge sys_clk or negedge sys_rst_l)
begin
    if (!sys_rst_l)
    begin
        baud_clk <= 1'b0;
        count    <= 0;
    end
    else 
    begin
        if (count == CLK_DIV - 1) 
        begin
            count    <= 0;
            baud_clk <= ~baud_clk;
        end
        else
            count <= count + 1;
    end
end

endmodule