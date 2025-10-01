`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2025 10:51:02 PM
// Design Name: 
// Module Name: DigitRenderer
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

`timescale 1ns / 1ps
module DigitRenderer(
    input  wire [6:0] row,   // global row (0..63)
    input  wire [6:0] col,   // global col (0..95)
    input  wire [3:0] digit, // 0..9 (we use 4 and 6)
    input  wire [6:0] x0,    // left (column) origin of the digit box
    input  wire [6:0] y0,    // top (row) origin of the digit box
    output reg        pixel_on
);
    // Geometry
    localparam integer HEIGHT = 45;
    localparam integer WIDTH  = 25;
    localparam integer THICK  = 6;

    integer r, c;
    reg in_box;
    reg top_row, bottom_row, middle_area;
    reg left_full, right_full, right_lower_half, left_upper_half;

    integer mid_start;
    integer mid_end;

    always @(*) begin
        // default off
        pixel_on = 1'b0;

        // compute local coords
        r = row - y0;
        c = col - x0;

        // bounding box check
        in_box = (r >= 0) && (r < HEIGHT) && (c >= 0) && (c < WIDTH);

        if (!in_box) begin
            pixel_on = 1'b0;
        end else begin
            // compute middle band
            mid_start = (HEIGHT - THICK) / 2;
            mid_end   = mid_start + THICK;

            // helper areas
            top_row    = (r >= 0) && (r < THICK);
            bottom_row = (r >= (HEIGHT - THICK)) && (r < HEIGHT);
            middle_area = (r >= mid_start) && (r < mid_end);

            left_full  = (c >= 0) && (c < THICK) && (r >= 0) && (r < HEIGHT);
            right_full = (c >= (WIDTH - THICK)) && (c < WIDTH) && (r >= 0) && (r < HEIGHT);

            // right vertical only lower half for '6'
            right_lower_half = (c >= (WIDTH - THICK)) && (c < WIDTH) && (r >= mid_start) && (r < HEIGHT);

            // left vertical only upper half for '4'
            left_upper_half  = (c >= 0) && (c < THICK) && (r >= 0) && (r < mid_start);

            // Decide per digit
            case (digit)
                4: begin
                    // 4: left upper vertical, right vertical, middle horizontal (flush to left)
                    if ( left_upper_half
                      || right_full
                      || (middle_area && (c >= 0) && (c < WIDTH-THICK)) )
                        pixel_on = 1'b1;
                end

                6: begin
                    // 6: top, left vertical, middle, bottom, right-lower vertical
                    if ( (top_row    && (c >= THICK) && (c < WIDTH))        // extend to WIDTH
                      || (middle_area && (c >= THICK) && (c < WIDTH-THICK))
                      || (bottom_row  && (c >= THICK) && (c < WIDTH-THICK))
                      || left_full
                      || right_lower_half )
                        pixel_on = 1'b1;
                end
            endcase
        end
    end
endmodule
