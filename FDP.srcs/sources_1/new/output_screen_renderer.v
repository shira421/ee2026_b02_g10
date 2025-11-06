`timescale 1ns / 1ps

module output_screen_renderer(
    input [12:0] pixel_index,
    input [2:0] state,
    input [16:0] num1, num2,
    input [19:0] result,
    input [1:0] op_code,
    output reg [15:0] pixel_data
);

    localparam WIDTH  = 96;
    localparam HEIGHT = 64;

    // FSM State Definitions (must match FSM)
    localparam S_CHOOSE_OP   = 3'd0;
    localparam S_INPUT_NUM1  = 3'd1;
    localparam S_INPUT_NUM2  = 3'd2;
    localparam S_SHOW_RESULT = 3'd3;

    // === Colors and Layout ===
    localparam COLOR_BG     = 16'h0000;
    localparam COLOR_TEXT   = 16'hFFFF;
    localparam COLOR_RESULT = 16'h07E0; // Green
    localparam COLOR_BORDER = 16'hFFFF;

    localparam DIGIT_W = 12;
    localparam CHAR_H  = 12;

    localparam TOP_Y   = 4;   // Y-pos for Num1
    localparam MID_Y   = 28;  // Y-pos for Num2
    localparam BOT_Y   = 50;  // Y-pos for Result
    localparam X_RIGHT = WIDTH - 2;
    localparam BOX_X_START = 1, BOX_Y_START = 24, BOX_WIDTH = 18, BOX_HEIGHT = 18;

    // Coordinates
    wire [6:0] x = pixel_index % WIDTH;
    wire [6:0] y = pixel_index / WIDTH;

    // === Font table (8x8) ===
    function [7:0] font_row;
        input [3:0] digit;
        input [2:0] row;
        case(digit)
            4'd0: case(row) 0: font_row=8'b00111100;1: font_row=8'b01000010;2: font_row=8'b01000010;3: font_row=8'b01000010;4: font_row=8'b01000010;5: font_row=8'b01000010;6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
            4'd1: case(row) 0: font_row=8'b00001000;1: font_row=8'b00011000;2: font_row=8'b00001000;3: font_row=8'b00001000;4: font_row=8'b00001000;5: font_row=8'b00001000;6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
            4'd2: case(row) 0: font_row=8'b00111100;1: font_row=8'b01000010;2: font_row=8'b00000010;3: font_row=8'b00000100;4: font_row=8'b00001000;5: font_row=8'b00100000;6: font_row=8'b01111110; default: font_row=8'b00000000; endcase
            4'd3: case(row) 0: font_row=8'b00111100;1: font_row=8'b01000010;2: font_row=8'b00000010;3: font_row=8'b00011100;4: font_row=8'b00000010;5: font_row=8'b01000010;6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
            4'd4: case(row) 0: font_row=8'b00000100;1: font_row=8'b00001100;2: font_row=8'b00010100;3: font_row=8'b00100100;4: font_row=8'b01111110;5: font_row=8'b00000100;6: font_row=8'b00000100; default: font_row=8'b00000000; endcase
            4'd5: case(row) 0: font_row=8'b01111110;1: font_row=8'b01000000;2: font_row=8'b01111100;3: font_row=8'b00000010;4: font_row=8'b00000010;5: font_row=8'b01000010;6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
            4'd6: case(row) 0: font_row=8'b00111100;1: font_row=8'b01000000;2: font_row=8'b01111100;3: font_row=8'b01000010;4: font_row=8'b01000010;5: font_row=8'b01000010;6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
            4'd7: case(row) 0: font_row=8'b01111110;1: font_row=8'b00000010;2: font_row=8'b00000100;3: font_row=8'b00001000;4: font_row=8'b00010000;5: font_row=8'b00100000;6: font_row=8'b01000000; default: font_row=8'b00000000; endcase
            4'd8: case(row) 0: font_row=8'b00111100;1: font_row=8'b01000010;2: font_row=8'b01000010;3: font_row=8'b00111100;4: font_row=8'b01000010;5: font_row=8'b01000010;6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
            4'd9: case(row) 0: font_row=8'b00111100;1: font_row=8'b01000010;2: font_row=8'b01000010;3: font_row=8'b00111110;4: font_row=8'b00000010;5: font_row=8'b01000010;6: font_row=8'b00111100; default: font_row=8'b00000000; endcase
            default: font_row = 8'b00000000;
        endcase
    endfunction

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

    // === Draw operator ===
    function draw_operator;
        input [6:0] px, py;
        input [1:0] op;
        integer cx, cy, dx, dy;
        begin
             draw_operator = 0;
             cx = BOX_X_START + BOX_WIDTH / 2;
             cy = BOX_Y_START + BOX_HEIGHT / 2;
             dx = px - cx;
             dy = py - cy;
             if(px >= BOX_X_START && px < BOX_X_START+BOX_WIDTH && py >= BOX_Y_START && py < BOX_Y_START+BOX_HEIGHT) begin
                case (op)
                    2'b00: if ((dy>=-1 && dy<=1 && px>=BOX_X_START+4 && px<=BOX_X_START+BOX_WIDTH-4) || (dx>=-1 && dx<=1 && py>=BOX_Y_START+4 && py<=BOX_Y_START+BOX_HEIGHT-4)) draw_operator = 1'b1;
                    2'b01: if (dy>=-1 && dy<=1 && px>=BOX_X_START+4 && px < BOX_X_START+BOX_WIDTH-4) draw_operator = 1'b1;
                    2'b10: if (((dx == dy) || (dx == -dy) || (dx == dy+1) || (dx+1 == dy) || (dx == -dy+1) || (dx+1 == -dy)) && (px >= BOX_X_START+3 && px < BOX_X_START+BOX_WIDTH-3) && (py >= BOX_Y_START+3 && py < BOX_Y_START+BOX_HEIGHT-3) ) draw_operator=1'b1;
                    2'b11: if (((dy>=-1 && dy<=1) && (px>=BOX_X_START+4 && px<BOX_X_START+BOX_WIDTH-4)) || ((px>=cx-1 && px<=cx) && ((py>=BOX_Y_START+4 && py<=BOX_Y_START+5) || (py>=BOX_Y_START+BOX_HEIGHT-6 && py<=BOX_Y_START+BOX_HEIGHT-5)))) draw_operator=1'b1;
                endcase
            end
        end
    endfunction

    // === Main drawing logic ===
    always @(*) begin : render_logic_block // ** BLOCK NAMED **
        // --- Convert numbers to digits ---
        integer t0,t1,t2,t3,t4; // num1 digits
        integer m0,m1,m2,m3,m4; // num2 digits
        integer b0,b1,b2,b3,b4,b5; // result digits

        t0 = num1 % 10; t1 = (num1/10)%10; t2 = (num1/100)%10; t3 = (num1/1000)%10; t4 = (num1/10000)%10;
        m0 = num2 % 10; m1 = (num2/10)%10; m2 = (num2/100)%10; m3 = (num2/1000)%10; m4 = (num2/10000)%10;
        b0 = result % 10; b1 = (result/10)%10; b2 = (result/100)%10; b3 = (result/1000)%10; b4 = (result/10000)%10; b5 = (result/100000)%10;

        pixel_data = COLOR_BG;

        case(state)
            S_CHOOSE_OP: begin
                // Screen is blank
            end
            S_INPUT_NUM1: begin
                if(draw_operator(x,y,op_code)) pixel_data = COLOR_BORDER;
                if (num1 >= 10000 && draw_scaled_digit(t4,x,y,X_RIGHT-5*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (num1 >= 1000  && draw_scaled_digit(t3,x,y,X_RIGHT-4*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (num1 >= 100   && draw_scaled_digit(t2,x,y,X_RIGHT-3*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (num1 >= 10    && draw_scaled_digit(t1,x,y,X_RIGHT-2*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (draw_scaled_digit(t0,x,y,X_RIGHT-DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
            end
            S_INPUT_NUM2: begin
                if(draw_operator(x,y,op_code)) pixel_data = COLOR_BORDER;
                // Draw num1
                if (num1 >= 10000 && draw_scaled_digit(t4,x,y,X_RIGHT-5*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (num1 >= 1000  && draw_scaled_digit(t3,x,y,X_RIGHT-4*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (num1 >= 100   && draw_scaled_digit(t2,x,y,X_RIGHT-3*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (num1 >= 10    && draw_scaled_digit(t1,x,y,X_RIGHT-2*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (draw_scaled_digit(t0,x,y,X_RIGHT-DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                // Draw num2
                if (num2 >= 10000 && draw_scaled_digit(m4,x,y,X_RIGHT-5*DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
                if (num2 >= 1000  && draw_scaled_digit(m3,x,y,X_RIGHT-4*DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
                if (num2 >= 100   && draw_scaled_digit(m2,x,y,X_RIGHT-3*DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
                if (num2 >= 10    && draw_scaled_digit(m1,x,y,X_RIGHT-2*DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
                if (draw_scaled_digit(m0,x,y,X_RIGHT-DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
            end
            S_SHOW_RESULT: begin
                if(draw_operator(x,y,op_code)) pixel_data = COLOR_BORDER;
                // Draw num1
                if (num1 >= 10000 && draw_scaled_digit(t4,x,y,X_RIGHT-5*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (num1 >= 1000  && draw_scaled_digit(t3,x,y,X_RIGHT-4*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (num1 >= 100   && draw_scaled_digit(t2,x,y,X_RIGHT-3*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (num1 >= 10    && draw_scaled_digit(t1,x,y,X_RIGHT-2*DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                if (draw_scaled_digit(t0,x,y,X_RIGHT-DIGIT_W,TOP_Y)) pixel_data = COLOR_TEXT;
                // Draw num2
                if (num2 >= 10000 && draw_scaled_digit(m4,x,y,X_RIGHT-5*DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
                if (num2 >= 1000  && draw_scaled_digit(m3,x,y,X_RIGHT-4*DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
                if (num2 >= 100   && draw_scaled_digit(m2,x,y,X_RIGHT-3*DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
                if (num2 >= 10    && draw_scaled_digit(m1,x,y,X_RIGHT-2*DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
                if (draw_scaled_digit(m0,x,y,X_RIGHT-DIGIT_W,MID_Y)) pixel_data = COLOR_TEXT;
                // Draw result
                if (result >= 100000 && draw_scaled_digit(b5,x,y,X_RIGHT-6*DIGIT_W,BOT_Y)) pixel_data = COLOR_RESULT;
                if (result >= 10000  && draw_scaled_digit(b4,x,y,X_RIGHT-5*DIGIT_W,BOT_Y)) pixel_data = COLOR_RESULT;
                if (result >= 1000   && draw_scaled_digit(b3,x,y,X_RIGHT-4*DIGIT_W,BOT_Y)) pixel_data = COLOR_RESULT;
                if (result >= 100    && draw_scaled_digit(b2,x,y,X_RIGHT-3*DIGIT_W,BOT_Y)) pixel_data = COLOR_RESULT;
                if (result >= 10     && draw_scaled_digit(b1,x,y,X_RIGHT-2*DIGIT_W,BOT_Y)) pixel_data = COLOR_RESULT;
                if (draw_scaled_digit(b0,x,y,X_RIGHT-DIGIT_W,BOT_Y)) pixel_data = COLOR_RESULT;
            end
        endcase
    end
endmodule
