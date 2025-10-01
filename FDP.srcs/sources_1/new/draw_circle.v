`timescale 1ns / 1ps

module draw_circle (
    input  clk_25mhz,
    input  sample_pixel,             // tick from OLED driver
    input  [6:0] x,
    input  [5:0] y,
    input  signed [7:0] circle_x,    // dynamic from CircleMover
    input  signed [7:0] circle_y,
    output reg draw_circle
);
    parameter CIRCLE_RADIUS = 12;
    localparam RADIUS_SQ = CIRCLE_RADIUS * CIRCLE_RADIUS;

    reg signed [8:0] dx, dy;
    reg [16:0] dist_sq;

    always @(*) begin
        if (sample_pixel) begin
        dx = $signed({1'b0, x}) - circle_x;
        dy = $signed({1'b0, y}) - circle_y;
        dist_sq = (dx * dx) + (dy * dy);
        draw_circle = (dist_sq <= RADIUS_SQ);
        end
    end

endmodule
