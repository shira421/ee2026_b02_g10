`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2025 02:36:13 PM
// Design Name: 
// Module Name: Digit6
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


module Digit6(
    input [6:0] x,
    input [5:0] y,
    output reg pixel_on
);
    always @(*) begin
        if ((x >= 70 && x <= 94) &&
            ((y >= 0 && y <= 5) ||        // top horizontal
             (y >= 20 && y <= 25) ||     // middle horizontal
             (y >= 40 && y <= 45) ||     // bottom horizontal
             (x >= 70 && x <= 75 && y >= 0 && y <= 45) || // left vertical
             (x >= 90 && x <= 94 && y >= 20 && y <= 45))) // right vertical bottom
            pixel_on = 1;
        else
            pixel_on = 0;
    end
endmodule

