
//endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: game_display
// Description: Renders math game on 96x64 OLED display with improved UI
//////////////////////////////////////////////////////////////////////////////////

module game_display(
    input clk_6p25M,
    input [12:0] pixel_index,
    input [1:0] game_state,
    input [3:0] score,
    input [3:0] mistakes,
    input [3:0] question_num,
    input [7:0] operand1,
    input [7:0] operand2,
    input [7:0] result,
    input [1:0] operation,
    output reg [15:0] pixel_data
);

    // Screen dimensions
    localparam WIDTH = 96;
    localparam HEIGHT = 64;
    
    // Calculate pixel position
    wire [6:0] x_pos = pixel_index % WIDTH;
    wire [5:0] y_pos = pixel_index / WIDTH;
    
    // States
    localparam HOME = 2'b00;
    localparam PLAYING = 2'b01;
    localparam GAME_OVER = 2'b10;
    
    // Colors (RGB565)
    localparam COLOR_HEADER = 16'hFC60;    // Orange banner
    localparam COLOR_BG = 16'h5D45;        // Green background for question area
    localparam COLOR_BOTTOM = 16'hFFFF;    // White background for button area
    localparam COLOR_TEXT = 16'hFFFF;      // White text
    localparam COLOR_TEXT_DARK = 16'h0000; // Black text for white background
    localparam COLOR_BTN_GREEN = 16'h07E0; // Bright green for YES button
    localparam COLOR_BTN_RED = 16'hF800;   // Bright red for NO button
    localparam COLOR_PROGRESS_BG = 16'h8410; // Gray progress background
    localparam COLOR_PROGRESS_FILL = 16'hFFE0; // Yellow progress fill
    
    // Button regions - larger and centered
    localparam BTN_CENTER_Y = 52;
    localparam BTN_RADIUS = 8;
    localparam BTN_LEFT_X = 32;
    localparam BTN_RIGHT_X = 64;
    
    // Check if pixel is inside a circle
    function in_circle;
        input [6:0] px, py;
        input [6:0] cx, cy;
        input [6:0] radius;
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
    
    // Checkmark and X rendering
    wire in_checkmark = in_btn_left && (
        // Checkmark left stroke
        ((x_pos >= BTN_LEFT_X - 4 && x_pos <= BTN_LEFT_X - 2) && 
         (y_pos >= BTN_CENTER_Y && y_pos <= BTN_CENTER_Y + 3)) ||
        // Checkmark right stroke  
        ((x_pos >= BTN_LEFT_X - 1 && x_pos <= BTN_LEFT_X + 3) && 
         (y_pos >= BTN_CENTER_Y - 2 && y_pos <= BTN_CENTER_Y + 2) &&
         ((BTN_CENTER_Y + 2 - y_pos) == (x_pos - (BTN_LEFT_X - 1))))
    );
    
    wire in_x_mark = in_btn_right && (
        // X mark diagonal 1
        ((x_pos - (BTN_RIGHT_X - 4)) == (y_pos - (BTN_CENTER_Y - 4))) ||
        ((x_pos - (BTN_RIGHT_X - 4)) == (y_pos - (BTN_CENTER_Y - 3))) ||
        // X mark diagonal 2
        ((x_pos - (BTN_RIGHT_X - 4)) == ((BTN_CENTER_Y + 4) - y_pos)) ||
        ((x_pos - (BTN_RIGHT_X - 4)) == ((BTN_CENTER_Y + 3) - y_pos))
    );
    
    // Progress bar
    wire [6:0] progress_width = (question_num * 7);  // 70 pixels / 10 questions
    wire in_progress = (y_pos >= 38 && y_pos <= 41 && x_pos >= 13 && x_pos <= 83);
    wire in_progress_fill = in_progress && (x_pos < (13 + progress_width));
    
    // Character ROM function
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
                "+": case(row) 0:get_char=5'b00000; 1:get_char=5'b00100; 2:get_char=5'b00100; 3:get_char=5'b11111; 4:get_char=5'b00100; 5:get_char=5'b00100; 6:get_char=5'b00000; default:get_char=5'b00000; endcase
                "-": case(row) 0:get_char=5'b00000; 1:get_char=5'b00000; 2:get_char=5'b00000; 3:get_char=5'b11111; 4:get_char=5'b00000; 5:get_char=5'b00000; 6:get_char=5'b00000; default:get_char=5'b00000; endcase
                "/": case(row) 0:get_char=5'b00001; 1:get_char=5'b00010; 2:get_char=5'b00010; 3:get_char=5'b00100; 4:get_char=5'b01000; 5:get_char=5'b01000; 6:get_char=5'b10000; default:get_char=5'b00000; endcase
                "=": case(row) 0:get_char=5'b00000; 1:get_char=5'b00000; 2:get_char=5'b11111; 3:get_char=5'b00000; 4:get_char=5'b11111; 5:get_char=5'b00000; 6:get_char=5'b00000; default:get_char=5'b00000; endcase
                default: get_char = 5'b00000;
            endcase
        end
    endfunction
    
    // Text rendering variables
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
                // "START" text at center
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
            

                
//                // Override text color - white on colored backgrounds, handled at end
//            end
            PLAYING: begin
                // Orange header/banner area (top ~15% of screen)
                if (y_pos < 10) begin
                    pixel_data = COLOR_HEADER;
                end
                // Green question area (middle)
                else if (y_pos >= 10 && y_pos < 43) begin
                    pixel_data = COLOR_BG;
                end
                // White button area (bottom)
                else begin
                    pixel_data = COLOR_BOTTOM;
                end

                // Score display at top (white text on orange)
                if (y_pos >= 2 && y_pos <= 8) begin
                    char_row = y_pos - 2;
                    if (x_pos >= 30 && x_pos < 35) begin cur_char = "S"; char_col = x_pos - 30; end
                    else if (x_pos >= 36 && x_pos < 41) begin cur_char = "C"; char_col = x_pos - 36; end
                    else if (x_pos >= 42 && x_pos < 47) begin cur_char = "O"; char_col = x_pos - 42; end
                    else if (x_pos >= 48 && x_pos < 53) begin cur_char = "R"; char_col = x_pos - 48; end
                    else if (x_pos >= 54 && x_pos < 59) begin cur_char = "E"; char_col = x_pos - 54; end
                    else if (x_pos >= 60 && x_pos < 65) begin cur_char = ":"; char_col = x_pos - 60; end
                    else if (x_pos >= 68 && x_pos < 73) begin cur_char = "0" + score; char_col = x_pos - 68; end

                    char_data = get_char(cur_char, char_row);
                    if (char_col < 5 && char_data[4 - char_col])
                        is_text = 1;
                end

                // Question and result display centered (single line)
                if (y_pos >= 18 && y_pos <= 24) begin
                    char_row = y_pos - 18;

                    // Operand 1
                    if (operand1 >= 10) begin
                        if (x_pos >= 15 && x_pos < 20) begin cur_char = "0" + (operand1 / 10); char_col = x_pos - 15; end
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
                            default: cur_char = " ";
                        endcase
                        char_col = x_pos - 28;
                    end

                    // Operand 2
                    if (operand2 >= 10) begin
                        if (x_pos >= 36 && x_pos < 41) begin cur_char = "0" + (operand2 / 10); char_col = x_pos - 36; end
                        else if (x_pos >= 41 && x_pos < 46) begin cur_char = "0" + (operand2 % 10); char_col = x_pos - 41; end
                    end else begin
                        if (x_pos >= 41 && x_pos < 46) begin cur_char = "0" + operand2; char_col = x_pos - 41; end
                    end

                    // Equals sign
                    if (x_pos >= 49 && x_pos < 54) begin cur_char = "="; char_col = x_pos - 49; end

                    // Result
                    if (result >= 10) begin
                        if (x_pos >= 57 && x_pos < 62) begin cur_char = "0" + (result / 10); char_col = x_pos - 57; end
                        else if (x_pos >= 62 && x_pos < 67) begin cur_char = "0" + (result % 10); char_col = x_pos - 62; end
                    end else begin
                        if (x_pos >= 62 && x_pos < 67) begin cur_char = "0" + result; char_col = x_pos - 62; end
                    end

                    // Render text pixels
                    char_data = get_char(cur_char, char_row);
                    if (char_col < 5 && char_data[4 - char_col])
                        is_text = 1;
                end

                // Progress bar (on green background)
                if (in_progress) begin
                    pixel_data = in_progress_fill ? COLOR_PROGRESS_FILL : COLOR_PROGRESS_BG;
                end

                // Render buttons (on white background)
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

                // Override text color - white on colored backgrounds, handled at end
            end
            GAME_OVER: begin
                // "GAME OVER" text
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
                
                // Score display
                if (y_pos >= 34 && y_pos <= 40) begin
                    char_row = y_pos - 34;
                    if (x_pos >= 28 && x_pos < 33) begin cur_char = "S"; char_col = x_pos - 28; end
                    else if (x_pos >= 34 && x_pos < 39) begin cur_char = ":"; char_col = x_pos - 34; end
                    else if (x_pos >= 44 && x_pos < 49) begin cur_char = "0" + score; char_col = x_pos - 44; end
                    
                    char_data = get_char(cur_char, char_row);
                    if (char_col < 5 && char_data[4-char_col])
                        is_text = 1;
                end
            end
        endcase
        
        if (is_text) pixel_data = COLOR_TEXT;
    end

endmodule