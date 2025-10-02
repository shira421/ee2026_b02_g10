`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.10.2025 20:54:38
// Design Name: 
// Module Name: digit1
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

module digit1 (
    input [6:0] x,
    input [6:0] y,
    input [6:0] xpos,
    input [6:0] ypos,
    output reg draw
);
    always @(*) begin
        draw = 0;
        if (x >= xpos+12 && x <= xpos+16 && y >= ypos && y <= ypos+25)
            draw = 1;
    end
endmodule
