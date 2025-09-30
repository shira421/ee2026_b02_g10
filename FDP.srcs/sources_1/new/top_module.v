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
    input clk,
    input [15:12] sw,   // SW15-SW12
    input btnC, btnU, btnL, btnR, btnD,
    output [3:0] an,
    output [7:0] seg,
    output [7:0] JB
);
    // Always running seven segment
    seven_segment_display f0(clk, an, seg);
endmodule
