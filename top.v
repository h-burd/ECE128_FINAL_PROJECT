`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2024 01:47:09 PM
// Design Name: 
// Module Name: FSM
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

module top(
    input clk,
    input rst,
    input dime,
    input nickel,
    input dispense_btn,
    input test_btn,
    //input [3:0] select,
    output locked_led,
    output change,
    //output [3:0] sseg_a_0,
    //output [6:0] sseg_c_o,
    output dispense_led
    //output TEST_BTN
    );
    
    wire DIME, NICKEL, DISPENSE_BTN, RST;
    debouncing UUT1(.RAW(dime), .CLK(clk), .CLEAN(DIME));
    debouncing UUT2(.RAW(nickel), .CLK(clk), .CLEAN(NICKEL));
    debouncing UUT3(.RAW(dispense_btn), .CLK(clk), .CLEAN(DISPENSE_BTN));
    debouncing UUT4(.RAW(rst), .CLK(clk), .CLEAN(RST));
    stateMachine UUT5(
    .clk(clk),
    .rst(rst),
    .dime(DIME),
    .nickel(NICKEL),
    .dispense_btn(DISPENSE_BTN),
    .locked_led(locked_led),
    .change(change),
    .dispense_led(dispense_led)
);
    



endmodule



module stateMachine(
    input clk,
    input rst,
    input dime,
    input nickel,
    input dispense_btn,
    output reg locked_led,
    output reg change,
    output reg dispense_led
);

    reg [1:0] state;
    reg [1:0] next_state;
    
    parameter idle = 2'b00;
    parameter adding = 2'b01;
    parameter locked = 2'b10;
    
    reg [1:0] coin_added = 2'd1;
    reg [8:0] tracker = 8'd0;

    reg [4:0] coin_total = 5'd0;
    
    reg dime_sync, nickel_sync;

    // Synchronize asynchronous inputs with the clock
    always @(posedge clk or posedge rst) begin
    if (rst) begin
        dime_sync <= 1'b0;
        nickel_sync <= 1'b0;
        tracker <= 8'd0;
        state <= idle;
        coin_total <= 0;
    end else begin
        dime_sync <= dime;
        nickel_sync <= nickel;

        // Handle state transitions and update state machine
        state <= next_state;

        // Update tracker
        if ((dime_sync || nickel_sync) && state != locked) begin
            tracker <= tracker + 8'd1;
        end else if (state != locked) begin
            tracker <= 0;
        end
    end
end

// Combinational logic
always @(*) begin
    case(state)
        idle: begin
            if (dime_sync || nickel_sync) begin
                next_state = adding;
                if (dime_sync && tracker == 8'd1) begin
                    coin_total = coin_total + 5'd10;
                end else if (nickel_sync && tracker == 8'd1) begin
                    coin_total = coin_total + 5'd5;
                end
            end else begin
                next_state = idle;
            end
            dispense_led = 0;
            change = 0;
            locked_led = 0;
        end
        
        adding: begin
            if (coin_total >= 5'd25) begin
                next_state = locked;
            end else begin 
                next_state = adding;
            end

            if ((dime_sync || nickel_sync) && tracker == 8'd1) begin
                if (dime_sync) begin
                    coin_total = coin_total + 5'd10;
                end else if (nickel_sync) begin
                    coin_total = coin_total + 5'd5;
                end
            end
            dispense_led = 0;
            change = 0;
            locked_led = 0;
        end

        locked: begin
            if (tracker == 8'd1) begin
                next_state = idle;
                tracker = 8'd0;
                coin_total = 0;
            end
            change = (coin_total > 25);
            if (dispense_btn && coin_total != 0) begin
                dispense_led = 1;
                tracker = 8'd1;
            end
            locked_led = 1;
        end
    endcase
end


endmodule

module debouncing (RAW, CLK, CLEAN);
    input RAW, CLK;
    output reg CLEAN;
    reg[2:0] count;
    wire TC;
    
    always@(posedge CLK) begin
        if(~RAW)
            count <= 3'b000;
        else
            count <= count + 3'b001;
    end
    assign TC = (count == 3'b111);
    always@(posedge CLK)begin
        if(~RAW)
            CLEAN <= 1'b0;
        else
            CLEAN <= 1'b1;
    end
endmodule



