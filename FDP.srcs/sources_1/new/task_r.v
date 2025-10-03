`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2025 05:06:56 PM
// Design Name: 
// Module Name: task_r
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

module task_r(
    input clk,
    input btnC,
    input [4:0] sw,
    input [12:0] pixel_index,
    output reg [15:0] oled_data
);
    reg clk6p25m = 0;
    reg [3:0] clk_div = 0;

    always @(posedge clk) begin
        if (clk_div == 7) begin
            clk_div <= 0;
            clk6p25m <= ~clk6p25m;
        end else begin
            clk_div <= clk_div + 1;
        end
    end
    
    reg [6:0] x_pos_blue = 10;
    reg [6:0] y_pos_orange = 10;
    reg dir_blue = 1;           
    reg dir_orange = 1;    

    reg [23:0] move_counter_blue = 0;
    reg [25:0] move_counter_orange = 0;

    always @(posedge clk6p25m) begin
        if (sw[1]) begin
            move_counter_blue <= move_counter_blue + 1;
            if (move_counter_blue > 208000) begin
                move_counter_blue <= 0;
                if (dir_blue) x_pos_blue <= x_pos_blue + 1;
                else          x_pos_blue <= x_pos_blue - 1;
                if (x_pos_blue > 77) dir_blue <= 0;
                else if (x_pos_blue < 3) dir_blue <= 1;
            end
        end

        if (sw[3]) begin
            move_counter_orange <= move_counter_orange + 1;
            if (move_counter_orange > 625000) begin
                move_counter_orange <= 0;
                if (dir_orange) y_pos_orange <= y_pos_orange + 1;
                else            y_pos_orange <= y_pos_orange - 1;
                if (y_pos_orange > 36) dir_orange <= 0;
                else if (y_pos_orange < 3) dir_orange <= 1;
            end
        end
    end

    wire [6:0] x = pixel_index % 96;
    wire [6:0] y = pixel_index / 96;

    wire draw1, draw9;

    digit1 digit1_inst (
        .x(x),
        .y(y),
        .xpos(x_pos_blue),
        .ypos(20),
        .draw(draw1)
    );

    digit9 digit9_inst (
        .x(x),
        .y(y),
        .xpos(50),
        .ypos(y_pos_orange),
        .draw(draw9)
    );

    always @(*) begin
        oled_data = 16'h0000;
        if (draw1) oled_data = 16'h001F;
        if (draw9) oled_data = 16'hFD20;
    end
endmodule
