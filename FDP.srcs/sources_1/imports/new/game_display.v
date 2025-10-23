`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: game_display
// Description: Renders math game on 96x64 OLED display with timer bar
//////////////////////////////////////////////////////////////////////////////////

module game_display(
    input clk_6p25M,
    input [12:0] pixel_index,
    input [1:0] game_state,
    input [9:0] score,
    input [3:0] mistakes,
    input [3:0] question_num,
    input [7:0] operand1,
    input [7:0] operand2,
    input [7:0] result,
    input [1:0] operation,
    input [4:0] timer_count,
    output reg [15:0] pixel_data
);

    localparam WIDTH = 96;
    localparam HEIGHT = 64;
    
    wire [6:0] x_pos = pixel_index % WIDTH;
    wire [5:0] y_pos = pixel_index / WIDTH;
    
    localparam HOME = 2'b00;
    localparam PLAYING = 2'b01;
    localparam GAME_OVER = 2'b10;
    localparam CORRECT_PAUSE = 2'b11;
    
    localparam COLOR_HEADER = 16'hFC60;
    localparam COLOR_BG = 16'h5D45;
    localparam COLOR_BOTTOM = 16'hFFFF;
    localparam COLOR_TEXT = 16'hFFFF;
    localparam COLOR_BTN_GREEN = 16'h07E0;
    localparam COLOR_BTN_RED = 16'hF800;
    localparam COLOR_PROGRESS_BG = 16'h8410;
    localparam COLOR_PROGRESS_FILL = 16'hFFE0;
    
    localparam BTN_CENTER_Y = 52;
    localparam BTN_RADIUS = 8;
    localparam BTN_LEFT_X = 32;
    localparam BTN_RIGHT_X = 64;
    
    reg [9:0] final_score;
    always @(posedge clk_6p25M) begin
        if (game_state == GAME_OVER) begin
            final_score <= final_score; // Hold the value
        end else begin
            final_score <= score; // Continuously track score during gameplay
        end
    end
    
    function in_circle;
        input [6:0] px, py, cx, cy, radius;
        reg signed [8:0] dx, dy;
        reg [16:0] dist_sq;
        begin
            dx = px - cx;
            dy = py - cy;
            dist_sq = (dx * dx) + (dy * dy);
            in_circle = (dist_sq <= (radius * radius));
        end
    endfunction
    
    wire in_btn_left = in_circle(x_pos, y_pos, BTN_LEFT_X, BTN_CENTER_Y, BTN_RADIUS);
    wire in_btn_right = in_circle(x_pos, y_pos, BTN_RIGHT_X, BTN_CENTER_Y, BTN_RADIUS);
    
    wire in_checkmark = in_btn_left && (
        ((x_pos >= BTN_LEFT_X - 4 && x_pos <= BTN_LEFT_X - 2) && 
         (y_pos >= BTN_CENTER_Y && y_pos <= BTN_CENTER_Y + 3)) ||
        ((x_pos >= BTN_LEFT_X - 1 && x_pos <= BTN_LEFT_X + 3) && 
         (y_pos >= BTN_CENTER_Y - 2 && y_pos <= BTN_CENTER_Y + 2) &&
         ((BTN_CENTER_Y + 2 - y_pos) == (x_pos - (BTN_LEFT_X - 1))))
    );
    
    wire in_x_mark = in_btn_right && (
        ((x_pos - (BTN_RIGHT_X - 4)) == (y_pos - (BTN_CENTER_Y - 4))) ||
        ((x_pos - (BTN_RIGHT_X - 4)) == (y_pos - (BTN_CENTER_Y - 3))) ||
        ((x_pos - (BTN_RIGHT_X - 4)) == ((BTN_CENTER_Y + 4) - y_pos)) ||
        ((x_pos - (BTN_RIGHT_X - 4)) == ((BTN_CENTER_Y + 3) - y_pos))
    );
    
    // Timer progress bar (shows time remaining out of 15 seconds)
    wire [6:0] progress_width = (timer_count * 70) / 15;
    wire in_progress = (y_pos >= 38 && y_pos <= 41 && x_pos >= 13 && x_pos <= 83);
    wire in_progress_fill = in_progress && (x_pos < (13 + progress_width));
    
    function [4:0] get_char;
        input [7:0] char;
        input [2:0] row;
        begin
            case (char)
                "0": case(row) 0:get_char=5'b01110; 1:get_char=5'b10001; 2:get_char=5'b10001; 3:get_char=5'b10001; 4:get_char=5'b10001; 5:get_char=5'b10001; 6:get_char=5'b01110; default:get_char=5'b00000; endcase
                "1": case(row) 0:get_char=5'b00100; 1:get_char=5'b01100; 2:get_char=5'b00100; 3:get_char=5'b00100; 4:get_char=5'b00100; 5:get_char=5'b00100; 6:get_char=5'b01110; default:get_char=5'b00000; endcase
                "2": case(row) 0:get_char=5'b01110; 1:get_char=5'b10001; 2:get_char=5'b00001; 3:get_char=5'b00010; 4:get_char=5'b00100; 5:get_char=5'b01000; 6:get_char=5'b11111; default:get_char=5'b00000; endcase
                "3": case(row) 0:get_char=5'b01110; 1:get_char=5'b10001; 2:get_char=5'b00001; 3:get_char=5'b00110; 4:get_char=5'b00001; 5:get_char=5'b10001; 6:get_char=5'b01110; default:get_char=5'b00000; endcase
                "4": case(row) 0:get_char=5'b00010; 1:get_char=5'b00110; 2:get_char=5'b01010; 3:get_char=5'b10010; 4:get_char=5'b11111; 5:get_char=5'b00010; 6:get_char=5'b00010; default:get_char=5'b00000; endcase
                "5": case(row) 0:get_char=5'b11111; 1:get_char=5'b10000; 2:get_char=5'b11110; 3:get_char=5'b00001; 4:get_char=5'b00001; 5:get_char=5'b10001; 6:get_char=5'b01110; default:get_char=5'b00000; endcase
                "6": case(row) 0:get_char=5'b01110; 1:get_char=5'b10000; 2:get_char=5'b11110; 3:get_char=5'b10001; 4:get_char=5'b10001; 5:get_char=5'b10001; 6:get_char=5'b01110; default:get_char=5'b00000; endcase
                "7": case(row) 0:get_char=5'b11111; 1:get_char=5'b00001; 2:get_char=5'b00010; 3:get_char=5'b00100; 4:get_char=5'b01000; 5:get_char=5'b01000; 6:get_char=5'b01000; default:get_char=5'b00000; endcase
                "8": case(row) 0:get_char=5'b01110; 1:get_char=5'b10001; 2:get_char=5'b10001; 3:get_char=5'b01110; 4:get_char=5'b10001; 5:get_char=5'b10001; 6:get_char=5'b01110; default:get_char=5'b00000; endcase
                "9": case(row) 0:get_char=5'b01110; 1:get_char=5'b10001; 2:get_char=5'b10001; 3:get_char=5'b01111; 4:get_char=5'b00001; 5:get_char=5'b00001; 6:get_char=5'b01110; default:get_char=5'b00000; endcase
                "S": case(row) 0:get_char=5'b01110; 1:get_char=5'b10001; 2:get_char=5'b10000; 3:get_char=5'b01110; 4:get_char=5'b00001; 5:get_char=5'b10001; 6:get_char=5'b01110; default:get_char=5'b00000; endcase
                "C": case(row) 0:get_char=5'b01110; 1:get_char=5'b10001; 2:get_char=5'b10000; 3:get_char=5'b10000; 4:get_char=5'b10000; 5:get_char=5'b10001; 6:get_char=5'b01110; default:get_char=5'b00000; endcase
                "O": case(row) 0:get_char=5'b01110; 1:get_char=5'b10001; 2:get_char=5'b10001; 3:get_char=5'b10001; 4:get_char=5'b10001; 5:get_char=5'b10001; 6:get_char=5'b01110; default:get_char=5'b00000; endcase
                "R": case(row) 0:get_char=5'b11110; 1:get_char=5'b10001; 2:get_char=5'b10001; 3:get_char=5'b11110; 4:get_char=5'b10100; 5:get_char=5'b10010; 6:get_char=5'b10001; default:get_char=5'b00000; endcase
                "E": case(row) 0:get_char=5'b11111; 1:get_char=5'b10000; 2:get_char=5'b10000; 3:get_char=5'b11110; 4:get_char=5'b10000; 5:get_char=5'b10000; 6:get_char=5'b11111; default:get_char=5'b00000; endcase
                ":": case(row) 0:get_char=5'b00000; 1:get_char=5'b01100; 2:get_char=5'b01100; 3:get_char=5'b00000; 4:get_char=5'b01100; 5:get_char=5'b01100; 6:get_char=5'b00000; default:get_char=5'b00000; endcase
                "T": case(row) 0:get_char=5'b11111; 1:get_char=5'b00100; 2:get_char=5'b00100; 3:get_char=5'b00100; 4:get_char=5'b00100; 5:get_char=5'b00100; 6:get_char=5'b00100; default:get_char=5'b00000; endcase
                "A": case(row) 0:get_char=5'b01110; 1:get_char=5'b10001; 2:get_char=5'b10001; 3:get_char=5'b11111; 4:get_char=5'b10001; 5:get_char=5'b10001; 6:get_char=5'b10001; default:get_char=5'b00000; endcase
                "G": case(row) 0:get_char=5'b01110; 1:get_char=5'b10001; 2:get_char=5'b10000; 3:get_char=5'b10011; 4:get_char=5'b10001; 5:get_char=5'b10001; 6:get_char=5'b01110; default:get_char=5'b00000; endcase
                "M": case(row) 0:get_char=5'b10001; 1:get_char=5'b11011; 2:get_char=5'b10101; 3:get_char=5'b10101; 4:get_char=5'b10001; 5:get_char=5'b10001; 6:get_char=5'b10001; default:get_char=5'b00000; endcase
                "V": case(row) 0:get_char=5'b10001; 1:get_char=5'b10001; 2:get_char=5'b10001; 3:get_char=5'b10001; 4:get_char=5'b10001; 5:get_char=5'b01010; 6:get_char=5'b00100; default:get_char=5'b00000; endcase
                "X": case(row) 0:get_char=5'b10001; 1:get_char=5'b10001; 2:get_char=5'b01010; 3:get_char=5'b00100; 4:get_char=5'b01010; 5:get_char=5'b10001; 6:get_char=5'b10001; default:get_char=5'b00000; endcase
                "+": case(row) 0:get_char=5'b00000; 1:get_char=5'b00100; 2:get_char=5'b00100; 3:get_char=5'b11111; 4:get_char=5'b00100; 5:get_char=5'b00100; 6:get_char=5'b00000; default:get_char=5'b00000; endcase
                "-": case(row) 0:get_char=5'b00000; 1:get_char=5'b00000; 2:get_char=5'b00000; 3:get_char=5'b11111; 4:get_char=5'b00000; 5:get_char=5'b00000; 6:get_char=5'b00000; default:get_char=5'b00000; endcase
                "/": case(row) 0:get_char=5'b00001; 1:get_char=5'b00010; 2:get_char=5'b00010; 3:get_char=5'b00100; 4:get_char=5'b01000; 5:get_char=5'b01000; 6:get_char=5'b10000; default:get_char=5'b00000; endcase
                "=": case(row) 0:get_char=5'b00000; 1:get_char=5'b00000; 2:get_char=5'b11111; 3:get_char=5'b00000; 4:get_char=5'b11111; 5:get_char=5'b00000; 6:get_char=5'b00000; default:get_char=5'b00000; endcase
                default: get_char = 5'b00000;
            endcase
        end
    endfunction
    
    reg is_text;
    reg [7:0] cur_char;
    reg [2:0] char_row, char_col;
    reg [4:0] char_data;
    
    always @(*) begin
        pixel_data = COLOR_BG;
        is_text = 0;
        cur_char = " ";
        char_row = 0;
        char_col = 0;
        char_data = 5'b00000;
        
        case (game_state)
            HOME: begin
                if (y_pos >= 26 && y_pos <= 32) begin
                    char_row = y_pos - 26;
                    if (x_pos >= 32 && x_pos < 37) begin cur_char = "S"; char_col = x_pos - 32; end
                    else if (x_pos >= 38 && x_pos < 43) begin cur_char = "T"; char_col = x_pos - 38; end
                    else if (x_pos >= 44 && x_pos < 49) begin cur_char = "A"; char_col = x_pos - 44; end
                    else if (x_pos >= 50 && x_pos < 55) begin cur_char = "R"; char_col = x_pos - 50; end
                    else if (x_pos >= 56 && x_pos < 61) begin cur_char = "T"; char_col = x_pos - 56; end
                    
                    char_data = get_char(cur_char, char_row);
                    if (char_col < 5 && char_data[4-char_col])
                        is_text = 1;
                end
            end
            
            CORRECT_PAUSE,
            PLAYING: begin
                if (y_pos < 10) begin
                    pixel_data = COLOR_HEADER;
                end else if (y_pos >= 10 && y_pos < 43) begin
                    pixel_data = COLOR_BG;
                end else begin
                    pixel_data = COLOR_BOTTOM;
                end

                // Score display at top - handles up to 3 digits
                if (y_pos >= 2 && y_pos <= 8) begin
                    char_row = y_pos - 2;
                    if (x_pos >= 24 && x_pos < 29) begin cur_char = "S"; char_col = x_pos - 24; end
                    else if (x_pos >= 30 && x_pos < 35) begin cur_char = "C"; char_col = x_pos - 30; end
                    else if (x_pos >= 36 && x_pos < 41) begin cur_char = "O"; char_col = x_pos - 36; end
                    else if (x_pos >= 42 && x_pos < 47) begin cur_char = "R"; char_col = x_pos - 42; end
                    else if (x_pos >= 48 && x_pos < 53) begin cur_char = "E"; char_col = x_pos - 48; end
                    else if (x_pos >= 54 && x_pos < 59) begin cur_char = ":"; char_col = x_pos - 54; end
                    // Display score with proper digit handling (up to 3 digits)
                    else if (score >= 100) begin
                        // 3 digits
                        if (x_pos >= 60 && x_pos < 65) begin cur_char = "0" + (score / 100); char_col = x_pos - 60; end
                        else if (x_pos >= 66 && x_pos < 71) begin cur_char = "0" + ((score % 100) / 10); char_col = x_pos - 66; end
                        else if (x_pos >= 72 && x_pos < 77) begin cur_char = "0" + (score % 10); char_col = x_pos - 72; end
                    end else if (score >= 10) begin
                        // 2 digits
                        if (x_pos >= 66 && x_pos < 71) begin cur_char = "0" + (score / 10); char_col = x_pos - 66; end
                        else if (x_pos >= 72 && x_pos < 77) begin cur_char = "0" + (score % 10); char_col = x_pos - 72; end
                    end else begin
                        // 1 digit
                        if (x_pos >= 72 && x_pos < 77) begin cur_char = "0" + score; char_col = x_pos - 72; end
                    end

                    char_data = get_char(cur_char, char_row);
                    if (char_col < 5 && char_data[4 - char_col])
                        is_text = 1;
                end

                if (y_pos >= 18 && y_pos <= 24) begin
                    char_row = y_pos - 18;

                    // Operand 1 with 1-pixel spacing between digits
                    if (operand1 >= 10) begin
                        if (x_pos >= 14 && x_pos < 19) begin cur_char = "0" + (operand1 / 10); char_col = x_pos - 14; end
                        else if (x_pos >= 20 && x_pos < 25) begin cur_char = "0" + (operand1 % 10); char_col = x_pos - 20; end
                    end else begin
                        if (x_pos >= 20 && x_pos < 25) begin cur_char = "0" + operand1; char_col = x_pos - 20; end
                    end

                    // Operation symbol
                    if (x_pos >= 28 && x_pos < 33) begin
                        case (operation)
                            2'b00: cur_char = "+";
                            2'b01: cur_char = "-";
                            2'b10: cur_char = "/";
                            2'b11: cur_char = "X";
                            default: cur_char = " ";
                        endcase
                        char_col = x_pos - 28;
                    end

                    // Operand 2 with 1-pixel spacing between digits
                    if (operand2 >= 10) begin
                        if (x_pos >= 36 && x_pos < 41) begin cur_char = "0" + (operand2 / 10); char_col = x_pos - 36; end
                        else if (x_pos >= 42 && x_pos < 47) begin cur_char = "0" + (operand2 % 10); char_col = x_pos - 42; end
                    end else begin
                        if (x_pos >= 42 && x_pos < 47) begin cur_char = "0" + operand2; char_col = x_pos - 42; end
                    end

                    // Equals sign
                    if (x_pos >= 50 && x_pos < 55) begin cur_char = "="; char_col = x_pos - 50; end

                    // Result with 1-pixel spacing between digits
                    if (result >= 100) begin
                        if (x_pos >= 58 && x_pos < 63) begin cur_char = "0" + (result / 100); char_col = x_pos - 58; end
                        else if (x_pos >= 64 && x_pos < 69) begin cur_char = "0" + ((result % 100) / 10); char_col = x_pos - 64; end
                        else if (x_pos >= 70 && x_pos < 75) begin cur_char = "0" + (result % 10); char_col = x_pos - 70; end
                    end else if (result >= 10) begin
                        if (x_pos >= 64 && x_pos < 69) begin cur_char = "0" + (result / 10); char_col = x_pos - 64; end
                        else if (x_pos >= 70 && x_pos < 75) begin cur_char = "0" + (result % 10); char_col = x_pos - 70; end
                    end else begin
                        if (x_pos >= 70 && x_pos < 75) begin cur_char = "0" + result; char_col = x_pos - 70; end
                    end

                    char_data = get_char(cur_char, char_row);
                    if (char_col < 5 && char_data[4 - char_col])
                        is_text = 1;
                end

                if (in_progress) begin
                    pixel_data = in_progress_fill ? COLOR_PROGRESS_FILL : COLOR_PROGRESS_BG;
                end

                if (in_btn_left) begin
                    if (in_checkmark)
                        pixel_data = COLOR_TEXT;
                    else
                        pixel_data = COLOR_BTN_GREEN;
                end

                if (in_btn_right) begin
                    if (in_x_mark)
                        pixel_data = COLOR_TEXT;
                    else
                        pixel_data = COLOR_BTN_RED;
                end
            end
            
// Replace the GAME_OVER case in your always @(*) block with this:
            
            GAME_OVER: begin
                if (y_pos >= 18 && y_pos <= 24) begin
                    char_row = y_pos - 18;
                    if (x_pos >= 14 && x_pos < 19) begin cur_char = "G"; char_col = x_pos - 14; end
                    else if (x_pos >= 20 && x_pos < 25) begin cur_char = "A"; char_col = x_pos - 20; end
                    else if (x_pos >= 26 && x_pos < 31) begin cur_char = "M"; char_col = x_pos - 26; end
                    else if (x_pos >= 32 && x_pos < 37) begin cur_char = "E"; char_col = x_pos - 32; end
                    else if (x_pos >= 44 && x_pos < 49) begin cur_char = "O"; char_col = x_pos - 44; end
                    else if (x_pos >= 50 && x_pos < 55) begin cur_char = "V"; char_col = x_pos - 50; end
                    else if (x_pos >= 56 && x_pos < 61) begin cur_char = "E"; char_col = x_pos - 56; end
                    else if (x_pos >= 62 && x_pos < 67) begin cur_char = "R"; char_col = x_pos - 62; end
                    
                    char_data = get_char(cur_char, char_row);
                    if (char_col < 5 && char_data[4-char_col])
                        is_text = 1;
                end
                
                // Score display with "SCORE:" label - handles up to 3 digits
                if (y_pos >= 34 && y_pos <= 40) begin
                    char_row = y_pos - 34;
                    if (x_pos >= 14 && x_pos < 19) begin cur_char = "S"; char_col = x_pos - 14; end
                    else if (x_pos >= 20 && x_pos < 25) begin cur_char = "C"; char_col = x_pos - 20; end
                    else if (x_pos >= 26 && x_pos < 31) begin cur_char = "O"; char_col = x_pos - 26; end
                    else if (x_pos >= 32 && x_pos < 37) begin cur_char = "R"; char_col = x_pos - 32; end
                    else if (x_pos >= 38 && x_pos < 43) begin cur_char = "E"; char_col = x_pos - 38; end
                    else if (x_pos >= 44 && x_pos < 49) begin cur_char = ":"; char_col = x_pos - 44; end
                    // Display final_score with proper digit handling (up to 3 digits)
                    else if (final_score >= 100) begin
                        // 3 digits
                        if (x_pos >= 50 && x_pos < 55) begin cur_char = "0" + (final_score / 100); char_col = x_pos - 50; end
                        else if (x_pos >= 56 && x_pos < 61) begin cur_char = "0" + ((final_score % 100) / 10); char_col = x_pos - 56; end
                        else if (x_pos >= 62 && x_pos < 67) begin cur_char = "0" + (final_score % 10); char_col = x_pos - 62; end
                    end else if (final_score >= 10) begin
                        // 2 digits
                        if (x_pos >= 56 && x_pos < 61) begin cur_char = "0" + (final_score / 10); char_col = x_pos - 56; end
                        else if (x_pos >= 62 && x_pos < 67) begin cur_char = "0" + (final_score % 10); char_col = x_pos - 62; end
                    end else begin
                        // 1 digit
                        if (x_pos >= 62 && x_pos < 67) begin cur_char = "0" + final_score; char_col = x_pos - 62; end
                    end
                    
                    char_data = get_char(cur_char, char_row);
                    if (char_col < 5 && char_data[4-char_col])
                        is_text = 1;
                end
            end
        endcase
        
        if (is_text) pixel_data = COLOR_TEXT;
    end

endmodule