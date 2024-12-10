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
    input [15:0] bcd_in,
    output locked_led,
    output change,
    output [3:0] sseg_a_0,
    output [6:0] sseg_c_o,
    output dispense_led
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

     top_multi_digit(clk, bcd_in, sseg_c_o, sseg_a_o);
    
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




module top_multi_digit(clk, BCD_in, seg_cathode, seg_anode_o); //edit
	input wire clk;
	input wire [15:0] BCD_in;
	output wire [6:0] seg_cathode;
	output wire [3:0] seg_anode_o;
	wire [3:0] mux_out, decoder_out;
	assign seg_anode_o = ~decoder_out; 
	
	anode_gen UUT1(.clk(clk), .seg_anode(decoder_out));
	Mux_4to1_case UUT2(.s(decoder_out), .i0(BCD_in[15:12]), .i1(BCD_in[11:8]), .i2(BCD_in[7:4]), .i3(BCD_in[3:0]), .o(mux_out));
	BCD_7_seg_conv UUT3(.num(mux_out), .seg(seg_cathode));
	//assign seg_anode = ~seg_anode;
endmodule


module anode_gen(clk, seg_anode);
	input wire clk;
	output wire [3:0] seg_anode;
	wire [1:0] countToDecoder;
	
	
	refresh_counter UUT1(.clk(clk), .o_q(countToDecoder));
	shift_register UUT2(.count(countToDecoder), .mux(seg_anode));
	
endmodule


module refresh_counter(clk, o_q); //edit, might work 100%
	input wire clk;
	output reg [1:0] o_q = 0;
	reg [1:0] o_d = 0;
	reg [8:0] count = 9'b000000000;
	
	always@(posedge clk)
	begin
	    count = count + 9'b000000001;
		if(o_d == 2'b11 && count==9'b100000001) //&& count==32
		begin
			o_d = 2'b00;
			o_q <= o_d;
	    end
		else
		begin
			if(count == 9'b100000001)
			begin
			o_d = o_d + 1'b1;
			o_q <= o_d;
			end
		end
		if(count == 9'b100000001)
		//begin
		  count = 9'b000000000;
		//end
	end
endmodule


module shift_register(count, mux); //edit might not work 100%
	input wire [1:0] count;
	output reg [3:0] mux;
    
	always@ (*)
	begin
		case (count)
		  2'b00 : mux = 4'b1000;
		  2'b01 : mux = 4'b0100;
		  2'b10 : mux = 4'b0010;
		  2'b11 : mux = 4'b0001;
		  default : mux = 4'bxxxx;
		endcase
	end
endmodule


module Mux_4to1_case(s, i0, i1, i2, i3, o);
	input wire [3:0] s, i0, i1, i2, i3;
	output reg [3:0] o;
	
	always@(*) //means all inputs - s or i0 or i1 or i2 or i3
	begin
		case (s)
			4'b1000 : o = i0;
			4'b0100 : o = i1;
			4'b0010 : o = i2;
			4'b0001 : o = i3;
			default : o = 1'bx; //default is undefined
		endcase
	end
endmodule


module BCD_7_seg_conv(num, seg);
	input wire [3:0] num;
	//output dp;
	output reg [6:0] seg;
	//output [7:0] anode:
	
	//assign anode = {{7{1'b1}},~valid};
	//assign dp = 1'b1; //decimal point
	always@(num) //means all inputs - s or i0 or i1 or i2 or i3
	begin
		case (num) //case statement
			0 : seg = 7'b1000000; //0000001
			1 : seg = 7'b1111001; //1001111
			2 : seg = 7'b0100100; //0010010
			3 : seg = 7'b0110000; //0000110
			4 : seg = 7'b0011001; //1001100
			5 : seg = 7'b0010010; //0100100
			6 : seg = 7'b0000010; //0100000
			7 : seg = 7'b1111000; //0001111
			8 : seg = 7'b0000000; //0000000
			9 : seg = 7'b0010000; //0000100
			//switch off 7 segment character when the bcd digit is not a decimal number.
			default : seg = 7'b1111111; 
		endcase
    end
endmodule


