`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.10.2025 20:58:37
// Design Name: 
// Module Name: digit9
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

module digit9 (
    input [6:0] x,
    input [6:0] y,
    input [6:0] xpos,
    input [6:0] ypos,
    output reg draw
);
    always @(*) begin
        draw = 0;
        if (x >= xpos+2 && x <= xpos+16 && y >= ypos && y <= ypos+4)
            draw = 1;
        if (x >= xpos+2 && x <= xpos+16 && y >= ypos+10 && y <= ypos+14)
            draw = 1;
        if (x >= xpos+2 && x <= xpos+16 && y >= ypos+21 && y <= ypos+25)
            draw = 1;
        if (x >= xpos+2 && x <= xpos+6 && y >= ypos && y <= ypos+10)
            draw = 1;
        if (x >= xpos+12 && x <= xpos+16 && y >= ypos && y <= ypos+25)
            draw = 1;
    end
endmodule

