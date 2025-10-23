`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.10.2025 21:08:00
// Design Name: 
// Module Name: divide_function
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


module divide_function(input [16:0] num_1, num_2, output [19:0] num_3);
    // Note: Division is complex in hardware. The '/' operator is synthesizable
    // but can consume significant resources. For this project, it's okay.
    // A check for division by zero should be handled by the user.
    assign num_3 = num_2 == 0 ? 0 : num_1 / num_2;
endmodule
