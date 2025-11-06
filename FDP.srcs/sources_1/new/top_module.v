`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/30/2025 08:24:44 PM
// Design Name: 
// Module Name: top_module
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


module top_module(
    input clk, //input clk
    input btnC, btnU, btnL, btnR, btnD, //input buttons
    input [1:0] mode_of_operation, //00 -> + , 01 -> -, 10 -> /, 11 -> X
    input [12:0] pixel_index, //from the oled_display module
    output [15:0] pixel_data //output into the oled display module
);
    //clocking functions wire
    wire freq625m;
    // numbers operations wire
    wire [16:0] num2, num1; //num 2 is the middle number , num1 is the number on the top of the screen
    wire done; // this is to indicate that num 1 and num 2 has been inputted, mode of operation can begin and can output the final number
    //mode of operation wires
    wire [19:0] num3;
    //calculator display wires /1bit, 2bit, 20bit, 17bit, 17bit == 57 bits
    wire [56:0] data_in = {done, mode_of_operation, num3, num2, num1};
    
    //clocking functions
    freq_6_25m c0(clk, freq625m);
    
    //entering of numbers operation
    // feeding in a reduced signal already
    entering_numbers f0(freq625m, btnC, btnU, btnL, btnR, btnD, num1, num2, done);
    
    //mode of operation function
    mode_of_operation f1(mode_of_operation, num1, num2, num3);
    
    //takes in all the inputs output ? || mode_of_operation || num3 || num2 || num1 and outputs it into bits 
    calculator_display f2(pixel_index, data_in, pixel_data);
    
    //the final output is pixel_data which is sent out of this function
endmodule

