`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2025 04:48:08 PM
// Design Name: 
// Module Name: flexible_clock
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

module CircleMover (
    input clk,                    // 100 MHz system clock
    input move_tick,              // 1 tick ~ 35-55 pixels/sec
    input btnU, btnD, btnL, btnR,
    output reg signed [7:0] circle_x,
    output reg signed [7:0] circle_y
);
    parameter RADIUS = 12;
    parameter LENGTH = 95;        // screen width-1
    parameter HEIGHT = 63;        // screen height-1
    parameter SQUARE_SIDE = 24;
    
    localparam signed [7:0] square_x = 4;
    localparam signed [7:0] square_y = 36;
    
    // dx/dy represent movement direction (-1, 0, +1)
    reg signed [2:0] dx, dy;
    
    initial begin
        circle_x = 48;  // start in center
        circle_y = 32;
        dx = 0;
        dy = 0;
    end
    
    // ---- EDGE DETECTION FOR move_tick ----
    reg move_tick_prev;
    wire move_tick_edge;
    
    always @(posedge clk) begin
        move_tick_prev <= move_tick;
    end
    
    assign move_tick_edge = move_tick && !move_tick_prev;
    
    // latch direction on button press
    always @(posedge clk) begin
        if (btnU) begin
            dx <= 0;
            dy <= -1;  // up
        end
        else if (btnD) begin
            dx <= 0;
            dy <= 1;   // down
        end
        else if (btnL) begin
            dx <= -1;
            dy <= 0;   // left
        end
        else if (btnR) begin
            dx <= 1;
            dy <= 0;   // right
        end
    end
    
    reg signed [7:0] new_x;
    reg signed [7:0] new_y;
    
    // update position at movement tick
    always @(posedge clk) begin
        if (move_tick_edge) begin
            new_x = circle_x + dx;
            new_y = circle_y + dy;
    
            // Screen bounds - Fixed with >= to prevent wraparound
            if (new_x - RADIUS < 0 || new_x + RADIUS >= LENGTH)
                new_x = circle_x;
            if (new_y - RADIUS < 0 || new_y + RADIUS >= HEIGHT)
                new_y = circle_y;
    
            // TOP border: moving UP
            if (dy == -1 &&
                new_y - RADIUS <= square_y + SQUARE_SIDE &&
                new_y - RADIUS >= square_y &&
                new_x + RADIUS > square_x &&              // Check right edge of circle
                new_x - RADIUS < square_x + SQUARE_SIDE)  // Check left edge of circle
                new_y = circle_y;
    
            // BOTTOM border: moving DOWN
            if (dy == 1 &&
                new_y + RADIUS >= square_y &&
                new_y + RADIUS <= square_y + SQUARE_SIDE &&
                new_x + RADIUS > square_x &&              // Check right edge of circle
                new_x - RADIUS < square_x + SQUARE_SIDE)  // Check left edge of circle
                new_y = circle_y;
    
            // LEFT border: moving LEFT
            if (dx == -1 &&
                new_x - RADIUS <= square_x + SQUARE_SIDE &&
                new_x - RADIUS >= square_x &&
                new_y + RADIUS > square_y &&              // Check bottom edge of circle
                new_y - RADIUS < square_y + SQUARE_SIDE)  // Check top edge of circle
                new_x = circle_x;
    
            // RIGHT border: moving RIGHT - FIXED
            if (dx == 1 && 
                new_x + RADIUS >= square_x &&                // Circle reaching LEFT edge of square
                new_x + RADIUS <= square_x + SQUARE_SIDE &&  // Within square's horizontal span
                new_y + RADIUS > square_y &&                 // Check bottom edge of circle
                new_y - RADIUS < square_y + SQUARE_SIDE)     // Check top edge of circle
                new_x = circle_x;
    
            // Commit update
            circle_x <= new_x;
            circle_y <= new_y;
        end
    end
endmodule
