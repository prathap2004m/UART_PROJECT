`timescale 1ns / 1ps

module micro_uart(
    input  wire sys_clk,
    input  wire sys_rst_l,

    input  wire xmitH,
    input  wire [7:0] xmit_dataH,

    input  wire uart_REC_dataH,

    output wire uart_XMIT_dataH,
    output wire xmit_doneH,

    output wire rec_readyH,
    output wire [7:0] rec_dataH,

    output wire rec_busy,
    output wire xmit_active
);

wire baud_clk_16x;

baud_rate_gen #(
    .BAUD_RATE(2400),
    .FACTOR(16),
    .CLK_FREQ(100_000_000)
) BAUD_GEN_INST (
    .sys_clk(sys_clk),
    .sys_rst_l(sys_rst_l),
    .baud_clk(baud_clk_16x)
);

uart_tx TX_INST (
    .baud_clk(baud_clk_16x),
    .sys_rst_l(sys_rst_l),
    
    .xmitH(xmitH),
    .xmit_dataH(xmit_dataH),
    
    .uart_XMIT_dataH(uart_XMIT_dataH),
    .xmit_doneH(xmit_doneH),
    .xmit_active(xmit_active)
);

uart_rx RX_INST (
    .baud_clk(baud_clk_16x),
    .rst_n(sys_rst_l),
    
    .rx(uart_REC_dataH),
    
    .rx_data(rec_dataH),
    .rx_done(rec_readyH),
    .rx_busy(rec_busy)
);

endmodule