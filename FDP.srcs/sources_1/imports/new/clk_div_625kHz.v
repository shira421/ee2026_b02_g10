`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2025 10:56:11 PM
// Design Name: 
// Module Name: clk_div_625kHz
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


module clk_div_625kHz(
    input clk,            // 100 MHz board clock
    input reset,          // reset button (active high)
    output reg clk_out    // 6.25 MHz clock
);
    reg [3:0] counter;    // 4-bit counter

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            counter <= counter + 1;
            if (counter == 7) begin
                clk_out <= ~clk_out; // Toggle every 8 ticks
                counter <= 0;
            end
        end
    end
endmodule