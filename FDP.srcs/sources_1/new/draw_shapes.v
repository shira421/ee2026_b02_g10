`timescale 1ns / 1ps

module draw_shapes(
    input  clk_6_25mhz,
    input [7:0] circle_x, 
    input [7:0] circle_y,
    input [6:0] x, 
    input [5:0]y,
    input  [12:0] pixel_index,
    output reg [15:0] oled_data
);

    parameter CIRCLE_RADIUS    = 12;
    parameter RADIUS_SQ        = CIRCLE_RADIUS * CIRCLE_RADIUS;
    parameter SQUARE_SIDE      = 24;
    parameter SQUARE_THICKNESS = 3;
    localparam signed [7:0] square_x = 4;
    localparam signed [7:0] square_y = 36;



    reg signed [8:0] dx, dy;
    reg [16:0] dist_sq;
    reg draw_circle, draw_square_outer, draw_square_inner, draw_square, draw_digit;
    function get_digit_pixel;
        input signed [7:0] px;
        input signed [7:0] py;
        begin
            get_digit_pixel = 0;
            if (px >= 0 && px <= 7 && py >= 0 && py < 13) begin
                if (px >= 0 && px <= 2 && py >= 0 && py <= 8) get_digit_pixel = 1;
                if (px >= 0 && px <= 7 && py >= 6 && py <= 8) get_digit_pixel = 1;
                if (px >= 5 && px <= 7 && py >= 0 && py <= 12) get_digit_pixel = 1;
            end
        end
    endfunction
always @(posedge clk_6_25mhz) begin
    dx <= $signed({1'b0, x}) - circle_x;
    dy <= $signed({1'b0, y}) - circle_y;
    dist_sq <= (dx * dx) + (dy * dy);
    draw_circle <= (dist_sq <= RADIUS_SQ);

    draw_square_outer <= (x >= square_x) && (x < square_x + SQUARE_SIDE) &&
                         (y >= square_y) && (y < square_y + SQUARE_SIDE);

    draw_square_inner <= (x >= square_x + SQUARE_THICKNESS) &&
                         (x < square_x + SQUARE_SIDE - SQUARE_THICKNESS) &&
                         (y >= square_y + SQUARE_THICKNESS) &&
                         (y < square_y + SQUARE_SIDE - SQUARE_THICKNESS);

    draw_square <= draw_square_outer && !draw_square_inner;
    draw_digit <= get_digit_pixel(x - (square_x + 9), y - (square_y + 6));

    if (draw_circle)
        oled_data <= 16'hF800;
    else if (draw_square)
        oled_data <= 16'hFFFF;
    else if (draw_digit)
        oled_data <= 16'h07E0;
    else
        oled_data <= 16'h0000;
end
endmodule



