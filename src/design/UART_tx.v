module uart_tx (
    input  wire baud_clk,
    input  wire sys_rst_l,
    input  wire xmitH,
    input  wire [7:0] xmit_dataH,

    output reg uart_XMIT_dataH,
    output reg xmit_doneH,
    output reg xmit_active
);

localparam IDLE = 2'b00;
localparam TX   = 2'b01;
localparam DONE = 2'b10;

reg [1:0] cs;
reg [3:0] tick_counter;       
reg [3:0] bit_index;

reg [9:0] frame;

always @(posedge baud_clk or negedge sys_rst_l)
begin
    if(!sys_rst_l)
    begin
        cs <= IDLE;
        tick_counter <= 0;
        bit_index <= 0;
        uart_XMIT_dataH <= 1'b1;
        xmit_doneH <= 0;
        xmit_active <= 0;
        frame <= 10'b0000000001;
    end
    else
    begin
        xmit_doneH <= 0;

        case(cs)

            IDLE:
            begin
                uart_XMIT_dataH <= 1'b1;
                xmit_active <= 0;
                tick_counter <= 0;
                bit_index <= 0;

                if(xmitH)
                begin
                    frame <= {1'b1, xmit_dataH, 1'b0};
                    uart_XMIT_dataH <= 1'b0;
                    cs <= TX;
                    xmit_active <= 1;
                    bit_index <= 1;      
                end
            end

            TX:
            begin
                if(tick_counter == 15) 
                begin
                    tick_counter <= 0;

                    if(bit_index == 4'd10) 
                    begin
                        cs <= DONE;
                    end
                    else
                    begin
                        uart_XMIT_dataH <= frame[bit_index];
                        bit_index <= bit_index + 1;
                    end
                end
                else
                    tick_counter <= tick_counter + 1;
            end

            DONE:
            begin
                uart_XMIT_dataH <= 1'b1;
                xmit_doneH <= 1;
                xmit_active <= 0;
                cs <= IDLE;
            end
	    default:cs<=IDLE;

        endcase
    end
end

endmodule