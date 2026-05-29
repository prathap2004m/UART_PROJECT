`timescale 1ns / 1ps

module uart_rx (
    input  wire baud_clk,    
    input  wire rst_n,
    input  wire rx,

    output reg [7:0] rx_data,
    output reg rx_done,
    output reg rx_busy
);

localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam DATA  = 2'b10;
localparam STOP  = 2'b11;

reg [1:0] state;
reg [3:0] tick_counter;      
reg [2:0] bit_index;
reg [7:0] shift_reg;

reg rx_ff1, rx_ff2;

always @(posedge baud_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        rx_ff1 <= 1'b1;
        rx_ff2 <= 1'b1;
    end
    else
    begin
        rx_ff1 <= rx;
        rx_ff2 <= rx_ff1;
    end
end

wire rx_sync = rx_ff2;

always @(posedge baud_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state        <= IDLE;
        tick_counter <= 0;
        bit_index    <= 0;
        shift_reg    <= 0;
        rx_data      <= 0;
        rx_done      <= 0;
        rx_busy      <= 0;
    end
    else
    begin
        rx_done <= 0;

        case(state)

            IDLE:
            begin
                tick_counter <= 0;
                bit_index    <= 0;
                rx_busy      <= 0;

                if(rx_sync == 0)
                begin
                    state   <= START;
                    rx_busy <= 1;
                end
            end

            START:
            begin
                if(tick_counter == 7) 
                begin
                    tick_counter <= 0;
                    if(rx_sync == 0)
                        state <= DATA;
                    else
                        state <= IDLE;
                end
                else
                    tick_counter <= tick_counter + 1;
            end

            DATA:
            begin
                if(tick_counter == 15) 
                begin
                    tick_counter <= 0;
                    shift_reg <= {rx_sync, shift_reg[7:1]};

                    if(bit_index == 3'd7)
                    begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                    else
                        bit_index <= bit_index + 1;
                end
                else
                    tick_counter <= tick_counter + 1;
            end

            STOP:
            begin
                if(tick_counter == 15) 
                begin
                    tick_counter <= 0;
                    rx_busy <= 0;

                    if(rx_sync == 1)
                    begin
                        rx_data <= shift_reg;
                        rx_done <= 1;
                    end

                    state <= IDLE;
                end
                else
                    tick_counter <= tick_counter + 1;
            end
	    default:state<= IDLE;

        endcase
    end
end

endmodule