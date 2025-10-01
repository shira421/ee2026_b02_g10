`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2025 02:36:13 PM
// Design Name: 
// Module Name: Digit4
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


module Digit4(
    input [6:0] x,
    input [5:0] y,
    output reg pixel_on
);
    always @(*) begin
        if ((x >= 0 && x <= 24) &&
            ((y >= 0 && y <= 5) ||       // top horizontal
             (y >= 20 && y <= 25) ||    // middle horizontal
             (x >= 20 && x <= 24) ||    // right vertical
             (x >= 0 && x <= 5 && y >= 0 && y <= 45))) // left vertical
            pixel_on = 1;
        else
            pixel_on = 0;
    end
endmodule

