`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2025 02:36:59 PM
// Design Name: 
// Module Name: Circle
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


module Circle(
    input [6:0] x,
    input [5:0] y,
    output reg pixel_on
);
    always @(*) begin
        if ((x-6)*(x-6) + (y-6)*(y-6) <= 36) // radius = 6
            pixel_on = 1;
        else
            pixel_on = 0;
    end
endmodule

