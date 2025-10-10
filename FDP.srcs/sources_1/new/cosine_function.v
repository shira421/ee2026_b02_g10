`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2025 01:17:45 AM
// Design Name: 
// Module Name: cosine_function
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


module cosine_func(
    input [7:0] x,          // x in 0-255, maps to 0-360 degrees
    input signed [7:0] k,   // multiplier
    input signed [7:0] c,   // constant added
    output reg signed [15:0] y
);

    // 256-entry LUT for cosine values scaled by 1000 (fixed-point)
    reg signed [15:0] cos_lut [0:255];

    integer i;
    real angle_rad;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            angle_rad = i * 2.0 * 3.14159265 / 256.0;
            cos_lut[i] = $rtoi($cos(angle_rad) * 1000);  // scale by 1000
        end
    end

    always @(*) begin
        // multiply x by k, wrap around 256
        y = cos_lut[(x * k) % 256] + c*1000;  // c also scaled
    end

endmodule

