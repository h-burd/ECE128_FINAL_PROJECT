
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2024 03:17:18 PM
// Design Name: 
// Module Name: top_tb
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


module top_tb();

    // Inputs to DUT
    reg clk;
    reg rst;
    reg dime;
    reg nickel;
    reg dispense_btn;

    // Outputs from DUT
    wire locked_led;
    wire change;
    wire dispense_led;

    // Instantiate the Device Under Test (DUT)
    top uut (
        .clk(clk),
        .rst(rst),
        .dime(dime),
        .nickel(nickel),
        .dispense_btn(dispense_btn),
        .locked_led(locked_led),
        .change(change),
        .dispense_led(dispense_led)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #1 clk = ~clk; // 10ns clock period
    end

    // Stimulus
    initial begin
        // Initialize inputs
        rst = 1;
        dime = 0;
        nickel = 0;
        dispense_btn = 0;

        // Reset the DUT
        #10 rst = 0;

        // Add a nickel (5 cents)
        #10 nickel = 1;
        #10 nickel = 0;

        // Add a dime (10 cents)
        #10 dime = 1;
        #10 dime = 0;

        // Add another dime (10 cents, total 25 cents)
        #10 dime = 1;
        #10 dime = 0;

        // Attempt to dispense (should succeed)
        #20 dispense_btn = 1;
        #10 dispense_btn = 0;

        // Add more coins to trigger change
        #10 nickel = 1;
        #10 nickel = 0;
        
        
        #10 rst = 1;
        #10 rst = 0;

                // Add another dime (10 cents, total 25 cents)
        #10 dime = 1;
        #10 dime = 0;
        
                // Add another dime (10 cents, total 25 cents)
        #10 dime = 1;
        #10 dime = 0;
        
                // Add another dime (10 cents, total 25 cents)
        #10 dime = 1;
        #10 dime = 0;
        
        #20 dispense_btn = 1;
        #10 dispense_btn = 0;
        // Wait and finish simulation
        #50;
        $stop;
    end

endmodule
