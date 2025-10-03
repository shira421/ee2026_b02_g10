`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/30/2025 04:40:10 PM
// Design Name: 
// Module Name: pixel_output_generator
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


module pixel_output_generator (
    input freq625m,
    input match_signal,
    input [2:0] colour_0, colour_1, colour_2,  // states of colours red to pink
    input [12:0] pixel_index,                 // From OLED driver (0 to 6143)
    output reg [15:0] pixel_data              // RGB565 output to OLED
);

    localparam Width = 96;
    localparam Height = 64;

    // Stylized "7" layout parameters
    localparam SevenBarWidth = 8;
    localparam SevenBarXStart = 80;
    localparam SevenBarXEnd   = SevenBarXStart + SevenBarWidth - 1;

    wire [6:0] x = pixel_index % Width;
    wire [5:0] y = pixel_index / Width;

    // Convert 3-bit RGB to 16-bit RGB565
    function [15:0] rgb3_to_rgb565(input [2:0] rgb);
        case (rgb)
            3'b000: rgb3_to_rgb565 = 16'b11111_000000_00000; // red
            3'b001: rgb3_to_rgb565 = 16'b00000_000000_11111; // blue
            3'b010: rgb3_to_rgb565 = 16'b11111_111111_00000; // yellow
            3'b011: rgb3_to_rgb565 = 16'b00000_111111_00000; // green
            3'b100: rgb3_to_rgb565 = 16'b11111_111111_11111; // white
            3'b101: rgb3_to_rgb565 = 16'b11110_100000_11111; // pink
            default: rgb3_to_rgb565 = 16'b00000_000000_00000; // black
        endcase
    endfunction

    always @(posedge freq625m) begin
        // Default to black
        pixel_data <= 16'h0000;

        // Bottom-left square: x = 4-23, y = 40-59
        if (x >= 4 && x <= 23 && y >= 40 && y <= 59)
            pixel_data <= rgb3_to_rgb565(colour_0);

        // Bottom-center square: x = 38-57, y = 40-59
        else if (x >= 38 && x <= 57 && y >= 40 && y <= 59)
            pixel_data <= rgb3_to_rgb565(colour_1);

        // Bottom-right square: x = 72-91, y = 40-59
        else if (x >= 72 && x <= 91 && y >= 40 && y <= 59)
            pixel_data <= rgb3_to_rgb565(colour_2);

        // Stylized "7" - only if match_signal is high
        else if (match_signal) begin
            // Top bar: x = 80-88, y = 4-5
            if (x >= SevenBarXStart && x <= SevenBarXEnd + 1 && y >= 4 && y <= 5)
                pixel_data <= rgb3_to_rgb565(3'b101); // pink

            // Right vertical leg: x = 87-88, y = 6-25
            else if (x >= SevenBarXEnd && x <= SevenBarXEnd + 1 && y >= 6 && y <= 20)
                pixel_data <= rgb3_to_rgb565(3'b101);
        end
    end

endmodule