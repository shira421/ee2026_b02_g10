`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/06/2025 02:26:48 PM
// Design Name:
// Module Name: calculator_display
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
module calculator_display(
    input  wire [12:0] pixel_index,  // current pixel index (0-6143)
    input  wire [56:0] data_in,      // expanded to 60 bits
    output reg  [15:0] pixel_data    // 16-bit RGB565 color
);
    localparam WIDTH  = 96;
    localparam HEIGHT = 64;

    // === Decode input fields ===
    // 5 digits = up to 17 bits (max 99999 < 2^17)
    // 6 digits = up to 20 bits (max 999999 < 2^20)
    wire [16:0] num_top   = data_in[16:0];      // 17 bits for 5-digit number
    wire [16:0] num_mid   = data_in[33:17];     // next 17 bits
    wire [19:0] num_bot   = data_in[53:34];     // 20 bits for 6-digit number
    wire [1:0]  op_code   = data_in[55:54];
    wire        show_flag = data_in[56];

    // === Display layout ===
    localparam BOX_X_START = 1;
    localparam BOX_Y_START = 1;
    localparam BOX_WIDTH   = 18;
    localparam BOX_HEIGHT  = 18;
    localparam BORDER      = 2;

    // === Colors ===
    localparam COLOR_BORDER = 16'hFFFF;
    localparam COLOR_FILL   = 16'h0000;
    localparam COLOR_TEXT   = 16'hFFFF;
    localparam COLOR_RESULT = 16'h07E0;

    // === Coordinates ===
    wire [6:0] x = pixel_index % WIDTH;
    wire [6:0] y = pixel_index / WIDTH;

    // === Font size (scaled 1.5×) ===
    localparam DIGIT_W = 12;
    localparam CHAR_H  = 12;

    localparam TOP_Y   = 4;
    localparam MID_Y   = 28;
    localparam BOT_Y   = 50;
    localparam X_RIGHT = WIDTH - 2;

    // === Box border ===
    function in_box_border;
        input [6:0] px, py;
        begin
            in_box_border = (px >= BOX_X_START && px < BOX_X_START + BOX_WIDTH &&
                             py >= BOX_Y_START && py < BOX_Y_START + BOX_HEIGHT &&
                             ((py - BOX_Y_START < BORDER) ||
                              (py >= BOX_Y_START + BOX_HEIGHT - BORDER) ||
                              (px - BOX_X_START < BORDER) ||
                              (px >= BOX_X_START + BOX_WIDTH - BORDER)));
        end
    endfunction

    // === Font table (8×8) ===
    function [7:0] font_row;
        input [3:0] digit;
        input [2:0] row;
        begin
            case(digit)
                4'd0: case(row) 0: font_row=8'b00111100;1: font_row=8'b01000010;2: font_row=8'b01000010;
                                 3: font_row=8'b01000010;4: font_row=8'b01000010;5: font_row=8'b01000010;
                                 6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
                4'd1: case(row) 0: font_row=8'b00001000;1: font_row=8'b00011000;2: font_row=8'b00001000;
                                 3: font_row=8'b00001000;4: font_row=8'b00001000;5: font_row=8'b00001000;
                                 6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
                4'd2: case(row) 0: font_row=8'b00111100;1: font_row=8'b01000010;2: font_row=8'b00000010;
                                 3: font_row=8'b00000100;4: font_row=8'b00001000;5: font_row=8'b00100000;
                                 6: font_row=8'b01111110; default: font_row=8'b00000000; endcase
                4'd3: case(row) 0: font_row=8'b00111100;1: font_row=8'b01000010;2: font_row=8'b00000010;
                                 3: font_row=8'b00011100;4: font_row=8'b00000010;5: font_row=8'b01000010;
                                 6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
                4'd4: case(row) 0: font_row=8'b00000100;1: font_row=8'b00001100;2: font_row=8'b00010100;
                                 3: font_row=8'b00100100;4: font_row=8'b01111110;5: font_row=8'b00000100;
                                 6: font_row=8'b00000100; default: font_row=8'b00000000; endcase
                4'd5: case(row) 0: font_row=8'b01111110;1: font_row=8'b01000000;2: font_row=8'b01111100;
                                 3: font_row=8'b00000010;4: font_row=8'b00000010;5: font_row=8'b01000010;
                                 6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
                4'd6: case(row) 0: font_row=8'b00111100;1: font_row=8'b01000000;2: font_row=8'b01111100;
                                 3: font_row=8'b01000010;4: font_row=8'b01000010;5: font_row=8'b01000010;
                                 6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
                4'd7: case(row) 0: font_row=8'b01111110;1: font_row=8'b00000010;2: font_row=8'b00000100;
                                 3: font_row=8'b00001000;4: font_row=8'b00010000;5: font_row=8'b00100000;
                                 6: font_row=8'b01000000; default: font_row=8'b00000000; endcase
                4'd8: case(row) 0: font_row=8'b00111100;1: font_row=8'b01000010;2: font_row=8'b01000010;
                                 3: font_row=8'b00111100;4: font_row=8'b01000010;5: font_row=8'b01000010;
                                 6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
                4'd9: case(row) 0: font_row=8'b00111100;1: font_row=8'b01000010;2: font_row=8'b01000010;
                                 3: font_row=8'b00111110;4: font_row=8'b00000010;5: font_row=8'b01000010;
                                 6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
                default: font_row = 8'b00000000;
            endcase
        end
    endfunction

    // === Convert numbers to digits ===
    integer t0,t1,t2,t3,t4;
    integer m0,m1,m2,m3,m4;
    integer b0,b1,b2,b3,b4,b5;

    always @(*) begin
        t0 = num_top % 10;     t1 = (num_top/10)%10;
        t2 = (num_top/100)%10; t3 = (num_top/1000)%10;
        t4 = (num_top/10000)%10;

        m0 = num_mid % 10;     m1 = (num_mid/10)%10;
        m2 = (num_mid/100)%10; m3 = (num_mid/1000)%10;
        m4 = (num_mid/10000)%10;

        b0 = num_bot % 10;      b1 = (num_bot/10)%10;
        b2 = (num_bot/100)%10;  b3 = (num_bot/1000)%10;
        b4 = (num_bot/10000)%10; b5 = (num_bot/100000)%10;
    end

    // === Draw scaled digit ===
    function draw_scaled_digit;
        input [3:0] digit;
        input [6:0] px, py, x0, y0;
        integer fx, fy;
        reg [7:0] rowbits;
        begin
            draw_scaled_digit = 0;
            if ((px >= x0) && (px < x0 + DIGIT_W) &&
                (py >= y0) && (py < y0 + CHAR_H)) begin
                fx = ((px - x0) * 8) / DIGIT_W;
                fy = ((py - y0) * 8) / CHAR_H;
                rowbits = font_row(digit, fy);
                draw_scaled_digit = rowbits[7 - fx];
            end
        end
    endfunction

    // === Draw operator (centered and symmetric) ===
    function draw_operator;
        input [6:0] px, py;
        input [1:0] op;
        integer cx, cy;  // exact integer center of box
        integer dx, dy;
        begin
            cx = BOX_X_START + BOX_WIDTH / 2;
            cy = BOX_Y_START + BOX_HEIGHT / 2;
            dx = px - cx;
            dy = py - cy;
            draw_operator = 1'b0;

            case (op)
                // --- '+' operator ---
                2'b00: begin
                    // horizontal and vertical bars 3 pixels thick, centered on cx, cy
                    if ((dy >= -1 && dy <= 1 && px >= BOX_X_START + 4 && px <= BOX_X_START + BOX_WIDTH - 4) ||
                        (dx >= -1 && dx <= 1 && py >= BOX_Y_START + 4 && py <= BOX_Y_START + BOX_HEIGHT - 4))
                        draw_operator = 1'b1;
                end

                // --- '-' operator ---
                2'b01: begin
                    if (dy >= -1 && dy <= 1 && px >= BOX_X_START + 4 && px < BOX_X_START + BOX_WIDTH - 4)
                        draw_operator = 1'b1;
                end

                // --- '÷' operator ---
                 2'b10: begin
                    // Center coordinates
                    cx = BOX_X_START + BOX_WIDTH/2;
                    cy = BOX_Y_START + BOX_HEIGHT/2;
                    dy = py - cy;

                    // Division sign (÷)
                    draw_operator =
                        // Horizontal division bar (thickness 2 pixels)
                        ((dy >= -1 && dy <= 1) &&
                         (px >= BOX_X_START + 4 && px < BOX_X_START + BOX_WIDTH - 4))
                        ||
                        // Top and bottom dots (2×2 pixels each)
                        ((px >= cx-1 && px <= cx) &&
                         ((py >= BOX_Y_START + 4 && py <= BOX_Y_START + 5) ||
                          (py >= BOX_Y_START + BOX_HEIGHT - 6 && py <= BOX_Y_START + BOX_HEIGHT - 5)));
                end

                // --- '×' operator ---
                2'b11: begin
                    cx = BOX_X_START + BOX_WIDTH/2;
                    cy = BOX_Y_START + BOX_HEIGHT/2;
                    dx = px - cx;
                    dy = py - cy;

                    // limit drawing to within 9 pixels in any direction (since 18x18 box)
                    if ((px >= BOX_X_START + 3 && px < BOX_X_START + BOX_WIDTH - 3) &&
                        (py >= BOX_Y_START + 3 && py < BOX_Y_START + BOX_HEIGHT - 3)) begin

                        if ((dx == dy) || (dx == -dy) ||
                            (dx == dy + 1) || (dx + 1 == dy) ||
                            (dx == -dy + 1) || (dx + 1 == -dy))
                            draw_operator = 1'b1;
                        else
                            draw_operator = 1'b0;
                    end else
                        draw_operator = 1'b0;
                end
                default: draw_operator = 1'b0;
            endcase
        end
    endfunction

    // === Main drawing ===
    always @(*) begin
        pixel_data = COLOR_FILL;

        if (in_box_border(x,y))
            pixel_data = COLOR_BORDER;
        else if (draw_operator(x,y,op_code))
            pixel_data = COLOR_BORDER;
        else begin
            // --- Top (5 digits) ---
            if (y >= TOP_Y && y < TOP_Y+CHAR_H) begin
                if (num_top >= 10000 && draw_scaled_digit(t4,x,y,X_RIGHT-5*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (num_top >= 1000  && draw_scaled_digit(t3,x,y,X_RIGHT-4*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (num_top >= 100   && draw_scaled_digit(t2,x,y,X_RIGHT-3*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (num_top >= 10    && draw_scaled_digit(t1,x,y,X_RIGHT-2*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (draw_scaled_digit(t0,x,y,X_RIGHT-DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
            end
            // --- Middle (5 digits) ---
            else if (y >= MID_Y && y < MID_Y+CHAR_H) begin
                if (num_mid >= 10000 && draw_scaled_digit(m4,x,y,X_RIGHT-5*DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
                if (num_mid >= 1000  && draw_scaled_digit(m3,x,y,X_RIGHT-4*DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
                if (num_mid >= 100   && draw_scaled_digit(m2,x,y,X_RIGHT-3*DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
                if (num_mid >= 10    && draw_scaled_digit(m1,x,y,X_RIGHT-2*DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
                if (draw_scaled_digit(m0,x,y,X_RIGHT-DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
            end
            // --- Bottom (6 digits) ---
            else if (y >= BOT_Y && y < BOT_Y+CHAR_H) begin
                if (num_bot >= 100000 && draw_scaled_digit(b5,x,y,X_RIGHT-6*DIGIT_W,BOT_Y)) pixel_data = show_flag ? COLOR_RESULT : COLOR_TEXT;
                if (num_bot >= 10000  && draw_scaled_digit(b4,x,y,X_RIGHT-5*DIGIT_W,BOT_Y)) pixel_data = show_flag ? COLOR_RESULT : COLOR_TEXT;
                if (num_bot >= 1000   && draw_scaled_digit(b3,x,y,X_RIGHT-4*DIGIT_W,BOT_Y)) pixel_data = show_flag ? COLOR_RESULT : COLOR_TEXT;
                if (num_bot >= 100    && draw_scaled_digit(b2,x,y,X_RIGHT-3*DIGIT_W,BOT_Y)) pixel_data = show_flag ? COLOR_RESULT : COLOR_TEXT;
                if (num_bot >= 10     && draw_scaled_digit(b1,x,y,X_RIGHT-2*DIGIT_W,BOT_Y)) pixel_data = show_flag ? COLOR_RESULT : COLOR_TEXT;
                if (draw_scaled_digit(b0,x,y,X_RIGHT-DIGIT_W,BOT_Y)) pixel_data = show_flag ? COLOR_RESULT : COLOR_TEXT;
            end
        end
    end
endmodule
