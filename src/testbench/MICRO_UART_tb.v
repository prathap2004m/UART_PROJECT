`timescale 1ns/1ps

module uart_tb;

    parameter BAUD_RATE = 2400;
    localparam BIT_PERIOD = 1_000_000_000 / BAUD_RATE;
    
    integer file_id;

    
    reg        sys_clk;
    reg        sys_rst_l;
    
    reg        xmitH;
    reg  [7:0] xmit_dataH;
    wire       uart_REC_dataH;
    
    wire       uart_XMIT_dataH;
    wire       xmit_doneH;
    
    wire       rec_readyH;
    wire [7:0] rec_dataH;
    
    wire       rec_busy;
    wire       xmit_active;

    assign uart_REC_dataH = uart_XMIT_dataH;

    micro_uart DUT (
        .sys_clk(sys_clk),
        .sys_rst_l(sys_rst_l),
        .xmitH(xmitH),
        .xmit_dataH(xmit_dataH),
        .uart_REC_dataH(uart_REC_dataH),
        .uart_XMIT_dataH(uart_XMIT_dataH),
        .xmit_doneH(xmit_doneH),
        .rec_readyH(rec_readyH),
        .rec_dataH(rec_dataH),
        .rec_busy(rec_busy),
        .xmit_active(xmit_active)
    );

    always #5 sys_clk = ~sys_clk;

    
    task uart_driver(input [7:0] data);
    begin
        @(posedge sys_clk);
        
        wait(xmit_active == 1'b0); 

        xmit_dataH = data;
        xmitH = 1'b1;

        wait(xmit_active == 1'b1);
        @(posedge sys_clk);
        xmitH = 1'b0;

        begin : timeout_block
            fork
                begin
                   
                    wait(rec_readyH == 1'b0); 
                    wait(rec_readyH == 1'b1);
                    
                    if(rec_dataH === data) begin
                        $fdisplay(file_id, "    PASS -> EXPECTED=%h RECEIVED=%h", data, rec_dataH);
                        $display("SCOREBOARD PASS EXPECTED=%h RECEIVED=%h", data, rec_dataH);
                    end else begin
                        $fdisplay(file_id, "    FAIL -> EXPECTED=%h RECEIVED=%h", data, rec_dataH);
                        $display("SCOREBOARD FAIL EXPECTED=%h RECEIVED=%h", data, rec_dataH);
                    end
                    
                    
                    wait(rec_readyH == 1'b0);
                    disable timeout_block;
                end
                begin
                    #(BIT_PERIOD * 15);
                    $fdisplay(file_id, "    FAIL -> TIMEOUT EXPECTED=%h", data);
                    $display("SCOREBOARD FAIL TIMEOUT EXPECTED=%h", data);
                    disable timeout_block;
                end
            join
        end
       
        #(BIT_PERIOD);
        
        @(posedge sys_clk);
    end
    endtask

    initial begin
        file_id = $fopen("system_report.txt", "w");
        $fdisplay(file_id, "========================================");
        $fdisplay(file_id, "   UART SYSTEM COMBINED TEST REPORT     ");
        $fdisplay(file_id, "========================================\n");

        sys_clk = 0;
        sys_rst_l = 0;
        xmitH = 0;
        xmit_dataH = 8'h00;
        
        $fdisplay(file_id, "--- Applying Initial Hardware Reset ---");
        #100;
        sys_rst_l = 1;
        #100;
        
        if (uart_XMIT_dataH === 1'b1 && xmit_active === 1'b0 && rec_busy === 1'b0)
            $fdisplay(file_id, "    PASS -> System safely initialized after reset\n");
        else
            $fdisplay(file_id, "    FAIL -> System failed to initialize after reset\n");

        $fdisplay(file_id, "--- TEST: Single Byte Verify ---");
        uart_driver(8'h55);
        #500;

        $fdisplay(file_id, "\n--- TEST: Mid-Operation Reset ---");
        @(posedge sys_clk);
        wait(xmit_active == 1'b0);
        xmit_dataH = 8'hC3;
        xmitH = 1'b1;
        wait(xmit_active == 1'b1);
        @(posedge sys_clk);
        xmitH = 1'b0;
        
        #(BIT_PERIOD * 4); 
        
        sys_rst_l = 0;  
        #(BIT_PERIOD);
        sys_rst_l = 1;
        #200;
        
        if(xmit_active == 1'b0 && rec_busy == 1'b0)
            $fdisplay(file_id, "    PASS -> System gracefully halted on mid-op reset");
        else
            $fdisplay(file_id, "    FAIL -> System did not halt on mid-op reset");

        $fdisplay(file_id, "\n--- TEST: Walk 1/0 ---");
        uart_driver(8'h01);
        uart_driver(8'h02);
        uart_driver(8'h04);
        uart_driver(8'h08);

        $fdisplay(file_id, "\n--- TEST: All Zeros & All Ones ---");
        uart_driver(8'h00);
        uart_driver(8'hFF);

        $fdisplay(file_id, "\n--- TEST: Alternating Patterns ---");
        uart_driver(8'hAA);
        uart_driver(8'h55);

        $fdisplay(file_id, "\n--- TEST: Continuous Burst Sequence ---");
        uart_driver(8'hAA);
        uart_driver(8'hF0);
        uart_driver(8'hAA);
        uart_driver(8'hF0);
        uart_driver(8'hAA);
        uart_driver(8'hF0);
        uart_driver(8'hAA);
        uart_driver(8'hF0);
        uart_driver(8'hAA);
        uart_driver(8'hF0);

        $fdisplay(file_id, "\n========================================");
        $fdisplay(file_id, "           END OF TEST REPORT           ");
        $fdisplay(file_id, "========================================");
        
        $fclose(file_id);
        #500;
        $finish;
    end
    initial begin
        #60000000; 
        
        force DUT.TX_INST.cs = 2'b11;
	force DUT.RX_INST.state = 2'b1x;
        
        @(posedge sys_clk);
        
        release DUT.TX_INST.cs;
	release DUT.RX_INST.state;
    end

    

endmodule
