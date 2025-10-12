`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: equation_menu
// Description: Main menu for equation solver with 4 options
// Display: 96x64 OLED
// Navigation: UP/DOWN buttons
// Options: 
//   1: 2×2 Simultaneous Equations
//   2: 3×3 Simultaneous Equations
//   3: Quadratic Equation (ax²+bx+c=0)
//   4: Cubic Equation (ax³+bx²+cx+d=0)
//////////////////////////////////////////////////////////////////////////////////

module equation_menu(
    input clk_6p25M,
    input reset,
    input btn_up,           // Navigate up
    input btn_down,         // Navigate down
    input btn_select,       // Select current option (UP button in menu mode)
    input [12:0] pixel_index,
    input clear_selection,
    output reg [15:0] pixel_data,
    output reg [2:0] selected_option  // 0=none, 1-4=selected option
);

    // Screen dimensions
    localparam WIDTH = 96;
    localparam HEIGHT = 64;
    
    // Box definitions for each option (with borders)
    localparam BOX_LEFT = 4;
    localparam BOX_RIGHT = 91;
    
    // Calculate current pixel position from pixel_index
    reg [6:0] x_pos;  // 0-95
    reg [5:0] y_pos;  // 0-63
    
    always @(*) begin
        x_pos = pixel_index % WIDTH;
        y_pos = pixel_index / WIDTH;
    end
    
    // Colors (RGB565 format)
    localparam COLOR_BG = 16'h0000;      // Black background
    localparam COLOR_TEXT = 16'hFFFF;    // White text
    localparam COLOR_LINE = 16'h7BEF;    // Light gray separator
    localparam COLOR_HOVER = 16'h2124;   // Dark gray hover
    
    // Menu item regions (y-coordinates for each line)
    // Each option occupies ~16 rows (64/4 = 16 rows per option)
    localparam Y_OPTION1_START = 0;
    localparam Y_OPTION1_END = 15;
    
    localparam Y_OPTION2_START = 16;
    localparam Y_OPTION2_END = 31;
    
    localparam Y_OPTION3_START = 32;
    localparam Y_OPTION3_END = 47;
    
    localparam Y_OPTION4_START = 48;
    localparam Y_OPTION4_END = 63;
    
    // Button navigation
    reg [2:0] highlighted_option;  // Which option is highlighted (1-4)
    reg btn_up_prev, btn_down_prev, btn_select_prev;
    wire btn_up_edge = btn_up && !btn_up_prev;
    wire btn_down_edge = btn_down && !btn_down_prev;
    wire btn_select_edge = btn_select && !btn_select_prev;
    
    always @(posedge clk_6p25M) begin
        if (reset) begin
            btn_up_prev <= 0;
            btn_down_prev <= 0;
            btn_select_prev <= 0;
            selected_option <= 0;
            highlighted_option <= 1;  // Start at first option
        end else begin
            btn_up_prev <= btn_up;
            btn_down_prev <= btn_down;
            btn_select_prev <= btn_select;
            
            // Clear selection when requested (when leaving menu)
            if (clear_selection) begin
                selected_option <= 0;
            end
            
            // Navigate up
            if (btn_up_edge) begin
                if (highlighted_option > 1)
                    highlighted_option <= highlighted_option - 1;
                else
                    highlighted_option <= 4;  // Wrap to bottom
            end
            
            // Navigate down
            if (btn_down_edge) begin
                if (highlighted_option < 4)
                    highlighted_option <= highlighted_option + 1;
                else
                    highlighted_option <= 1;  // Wrap to top
            end
            
            // Select current option
            if (btn_select_edge && !clear_selection) begin
                selected_option <= highlighted_option;
            end
        end
    end
    
    // Character ROM for text rendering
    // Each character is 5×7 pixels
    
    // Simple character patterns (5-bit width for each row)
    function [4:0] get_char_row;
        input [7:0] char;
        input [2:0] row;
        begin
            case (char)
                "1": case(row)
                    0: get_char_row = 5'b01100;
                    1: get_char_row = 5'b11100;
                    2: get_char_row = 5'b00100;
                    3: get_char_row = 5'b00100;
                    4: get_char_row = 5'b00100;
                    5: get_char_row = 5'b00100;
                    6: get_char_row = 5'b11111;
                    default: get_char_row = 5'b00000;
                endcase
                "2": case(row)
                    0: get_char_row = 5'b01110;
                    1: get_char_row = 5'b10001;
                    2: get_char_row = 5'b00001;
                    3: get_char_row = 5'b00110;
                    4: get_char_row = 5'b01000;
                    5: get_char_row = 5'b10000;
                    6: get_char_row = 5'b11111;
                    default: get_char_row = 5'b00000;
                endcase
                "3": case(row)
                    0: get_char_row = 5'b01110;
                    1: get_char_row = 5'b10001;
                    2: get_char_row = 5'b00001;
                    3: get_char_row = 5'b00110;
                    4: get_char_row = 5'b00001;
                    5: get_char_row = 5'b10001;
                    6: get_char_row = 5'b01110;
                    default: get_char_row = 5'b00000;
                endcase
                "4": case(row)
                    0: get_char_row = 5'b00010;
                    1: get_char_row = 5'b00110;
                    2: get_char_row = 5'b01010;
                    3: get_char_row = 5'b10010;
                    4: get_char_row = 5'b11111;
                    5: get_char_row = 5'b00010;
                    6: get_char_row = 5'b00010;
                    default: get_char_row = 5'b00000;
                endcase
                "x": case(row)
                    0: get_char_row = 5'b00000;
                    1: get_char_row = 5'b00000;
                    2: get_char_row = 5'b10001;
                    3: get_char_row = 5'b01010;
                    4: get_char_row = 5'b00100;
                    5: get_char_row = 5'b01010;
                    6: get_char_row = 5'b10001;
                    default: get_char_row = 5'b00000;
                endcase
                ":": case(row)
                    0: get_char_row = 5'b00000;
                    1: get_char_row = 5'b00000;
                    2: get_char_row = 5'b01100;
                    3: get_char_row = 5'b01100;
                    4: get_char_row = 5'b00000;
                    5: get_char_row = 5'b01100;
                    6: get_char_row = 5'b01100;
                    default: get_char_row = 5'b00000;
                endcase
                " ": get_char_row = 5'b00000;
                "S": case(row)
                    0: get_char_row = 5'b01110;
                    1: get_char_row = 5'b10001;
                    2: get_char_row = 5'b10000;
                    3: get_char_row = 5'b01110;
                    4: get_char_row = 5'b00001;
                    5: get_char_row = 5'b10001;
                    6: get_char_row = 5'b01110;
                    default: get_char_row = 5'b00000;
                endcase
                "I": case(row)
                    0: get_char_row = 5'b11111;
                    1: get_char_row = 5'b00100;
                    2: get_char_row = 5'b00100;
                    3: get_char_row = 5'b00100;
                    4: get_char_row = 5'b00100;
                    5: get_char_row = 5'b00100;
                    6: get_char_row = 5'b11111;
                    default: get_char_row = 5'b00000;
                endcase
                "M": case(row)
                    0: get_char_row = 5'b10001;
                    1: get_char_row = 5'b11011;
                    2: get_char_row = 5'b10101;
                    3: get_char_row = 5'b10101;
                    4: get_char_row = 5'b10001;
                    5: get_char_row = 5'b10001;
                    6: get_char_row = 5'b10001;
                    default: get_char_row = 5'b00000;
                endcase
                "U": case(row)
                    0: get_char_row = 5'b10001;
                    1: get_char_row = 5'b10001;
                    2: get_char_row = 5'b10001;
                    3: get_char_row = 5'b10001;
                    4: get_char_row = 5'b10001;
                    5: get_char_row = 5'b10001;
                    6: get_char_row = 5'b01110;
                    default: get_char_row = 5'b00000;
                endcase
                "L": case(row)
                    0: get_char_row = 5'b10000;
                    1: get_char_row = 5'b10000;
                    2: get_char_row = 5'b10000;
                    3: get_char_row = 5'b10000;
                    4: get_char_row = 5'b10000;
                    5: get_char_row = 5'b10000;
                    6: get_char_row = 5'b11111;
                    default: get_char_row = 5'b00000;
                endcase
                "Q": case(row)
                    0: get_char_row = 5'b01110;
                    1: get_char_row = 5'b10001;
                    2: get_char_row = 5'b10001;
                    3: get_char_row = 5'b10001;
                    4: get_char_row = 5'b10101;
                    5: get_char_row = 5'b10010;
                    6: get_char_row = 5'b01101;
                    default: get_char_row = 5'b00000;
                endcase
                "A": case(row)
                    0: get_char_row = 5'b01110;
                    1: get_char_row = 5'b10001;
                    2: get_char_row = 5'b10001;
                    3: get_char_row = 5'b11111;
                    4: get_char_row = 5'b10001;
                    5: get_char_row = 5'b10001;
                    6: get_char_row = 5'b10001;
                    default: get_char_row = 5'b00000;
                endcase
                "D": case(row)
                    0: get_char_row = 5'b11110;
                    1: get_char_row = 5'b10001;
                    2: get_char_row = 5'b10001;
                    3: get_char_row = 5'b10001;
                    4: get_char_row = 5'b10001;
                    5: get_char_row = 5'b10001;
                    6: get_char_row = 5'b11110;
                    default: get_char_row = 5'b00000;
                endcase
                "R": case(row)
                    0: get_char_row = 5'b11110;
                    1: get_char_row = 5'b10001;
                    2: get_char_row = 5'b10001;
                    3: get_char_row = 5'b11110;
                    4: get_char_row = 5'b10100;
                    5: get_char_row = 5'b10010;
                    6: get_char_row = 5'b10001;
                    default: get_char_row = 5'b00000;
                endcase
                "T": case(row)
                    0: get_char_row = 5'b11111;
                    1: get_char_row = 5'b00100;
                    2: get_char_row = 5'b00100;
                    3: get_char_row = 5'b00100;
                    4: get_char_row = 5'b00100;
                    5: get_char_row = 5'b00100;
                    6: get_char_row = 5'b00100;
                    default: get_char_row = 5'b00000;
                endcase
                "C": case(row)
                    0: get_char_row = 5'b01110;
                    1: get_char_row = 5'b10001;
                    2: get_char_row = 5'b10000;
                    3: get_char_row = 5'b10000;
                    4: get_char_row = 5'b10000;
                    5: get_char_row = 5'b10001;
                    6: get_char_row = 5'b01110;
                    default: get_char_row = 5'b00000;
                endcase
                "B": case(row)
                    0: get_char_row = 5'b11110;
                    1: get_char_row = 5'b10001;
                    2: get_char_row = 5'b10001;
                    3: get_char_row = 5'b11110;
                    4: get_char_row = 5'b10001;
                    5: get_char_row = 5'b10001;
                    6: get_char_row = 5'b11110;
                    default: get_char_row = 5'b00000;
                endcase
                default: get_char_row = 5'b00000;
            endcase
        end
    endfunction
    
    // Text rendering logic
    reg is_text_pixel;
    reg [7:0] current_char;
    reg [2:0] char_row, char_col;
    reg [4:0] char_row_data;
    
    always @(*) begin
        is_text_pixel = 0;
        current_char = " ";
        char_row = 0;
        char_col = 0;
        char_row_data = 0;
        
        // Option 1: "1: 2x2 SIMUL" - centered at row 7
        if (y_pos >= 7 && y_pos <= 13) begin
            char_row = y_pos - 7;
            if (x_pos >= 8 && x_pos < 13) begin
                current_char = "1";
                char_col = x_pos - 8;
            end else if (x_pos >= 14 && x_pos < 19) begin
                current_char = ":";
                char_col = x_pos - 14;
            end else if (x_pos >= 21 && x_pos < 26) begin
                current_char = "2";
                char_col = x_pos - 21;
            end else if (x_pos >= 27 && x_pos < 32) begin
                current_char = "x";
                char_col = x_pos - 27;
            end else if (x_pos >= 33 && x_pos < 38) begin
                current_char = "2";
                char_col = x_pos - 33;
            end else if (x_pos >= 41 && x_pos < 46) begin
                current_char = "S";
                char_col = x_pos - 41;
            end else if (x_pos >= 47 && x_pos < 52) begin
                current_char = "I";
                char_col = x_pos - 47;
            end else if (x_pos >= 53 && x_pos < 58) begin
                current_char = "M";
                char_col = x_pos - 53;
            end else if (x_pos >= 59 && x_pos < 64) begin
                current_char = "U";
                char_col = x_pos - 59;
            end else if (x_pos >= 65 && x_pos < 70) begin
                current_char = "L";
                char_col = x_pos - 65;
            end
            
            char_row_data = get_char_row(current_char, char_row);
            if (char_col < 5 && char_row_data[4-char_col])
                is_text_pixel = 1;
        end
        
        // Option 2: "2: 3x3 SIMUL" - centered at row 23
        if (y_pos >= 23 && y_pos <= 29) begin
            char_row = y_pos - 23;
            if (x_pos >= 8 && x_pos < 13) begin
                current_char = "2";
                char_col = x_pos - 8;
            end else if (x_pos >= 14 && x_pos < 19) begin
                current_char = ":";
                char_col = x_pos - 14;
            end else if (x_pos >= 21 && x_pos < 26) begin
                current_char = "3";
                char_col = x_pos - 21;
            end else if (x_pos >= 27 && x_pos < 32) begin
                current_char = "x";
                char_col = x_pos - 27;
            end else if (x_pos >= 33 && x_pos < 38) begin
                current_char = "3";
                char_col = x_pos - 33;
            end else if (x_pos >= 41 && x_pos < 46) begin
                current_char = "S";
                char_col = x_pos - 41;
            end else if (x_pos >= 47 && x_pos < 52) begin
                current_char = "I";
                char_col = x_pos - 47;
            end else if (x_pos >= 53 && x_pos < 58) begin
                current_char = "M";
                char_col = x_pos - 53;
            end else if (x_pos >= 59 && x_pos < 64) begin
                current_char = "U";
                char_col = x_pos - 59;
            end else if (x_pos >= 65 && x_pos < 70) begin
                current_char = "L";
                char_col = x_pos - 65;
            end
            
            char_row_data = get_char_row(current_char, char_row);
            if (char_col < 5 && char_row_data[4-char_col])
                is_text_pixel = 1;
        end
        
        // Option 3: "3: QUADRATIC" - centered at row 39
        if (y_pos >= 39 && y_pos <= 45) begin
            char_row = y_pos - 39;
            if (x_pos >= 8 && x_pos < 13) begin
                current_char = "3";
                char_col = x_pos - 8;
            end else if (x_pos >= 14 && x_pos < 19) begin
                current_char = ":";
                char_col = x_pos - 14;
            end else if (x_pos >= 21 && x_pos < 26) begin
                current_char = "Q";
                char_col = x_pos - 21;
            end else if (x_pos >= 27 && x_pos < 32) begin
                current_char = "U";
                char_col = x_pos - 27;
            end else if (x_pos >= 33 && x_pos < 38) begin
                current_char = "A";
                char_col = x_pos - 33;
            end else if (x_pos >= 39 && x_pos < 44) begin
                current_char = "D";
                char_col = x_pos - 39;
            end else if (x_pos >= 45 && x_pos < 50) begin
                current_char = "R";
                char_col = x_pos - 45;
            end else if (x_pos >= 51 && x_pos < 56) begin
                current_char = "A";
                char_col = x_pos - 51;
            end else if (x_pos >= 57 && x_pos < 62) begin
                current_char = "T";
                char_col = x_pos - 57;
            end else if (x_pos >= 63 && x_pos < 68) begin
                current_char = "I";
                char_col = x_pos - 63;
            end else if (x_pos >= 69 && x_pos < 74) begin
                current_char = "C";
                char_col = x_pos - 69;
            end
            
            char_row_data = get_char_row(current_char, char_row);
            if (char_col < 5 && char_row_data[4-char_col])
                is_text_pixel = 1;
        end
        
        // Option 4: "4: CUBIC" - centered at row 55
        if (y_pos >= 55 && y_pos <= 61) begin
            char_row = y_pos - 55;
            if (x_pos >= 8 && x_pos < 13) begin
                current_char = "4";
                char_col = x_pos - 8;
            end else if (x_pos >= 14 && x_pos < 19) begin
                current_char = ":";
                char_col = x_pos - 14;
            end else if (x_pos >= 30 && x_pos < 35) begin
                current_char = "C";
                char_col = x_pos - 30;
            end else if (x_pos >= 36 && x_pos < 41) begin
                current_char = "U";
                char_col = x_pos - 36;
            end else if (x_pos >= 42 && x_pos < 47) begin
                current_char = "B";
                char_col = x_pos - 42;
            end else if (x_pos >= 48 && x_pos < 53) begin
                current_char = "I";
                char_col = x_pos - 48;
            end else if (x_pos >= 54 && x_pos < 59) begin
                current_char = "C";
                char_col = x_pos - 54;
            end
            
            char_row_data = get_char_row(current_char, char_row);
            if (char_col < 5 && char_row_data[4-char_col])
                is_text_pixel = 1;
        end
    end
    
    // Check if current pixel is on a box border
    wire on_box1_border = (y_pos >= Y_OPTION1_START && y_pos <= Y_OPTION1_END) &&
                          (x_pos >= BOX_LEFT && x_pos <= BOX_RIGHT) &&
                          (x_pos == BOX_LEFT || x_pos == BOX_RIGHT || 
                           y_pos == Y_OPTION1_START || y_pos == Y_OPTION1_END);
    
    wire on_box2_border = (y_pos >= Y_OPTION2_START && y_pos <= Y_OPTION2_END) &&
                          (x_pos >= BOX_LEFT && x_pos <= BOX_RIGHT) &&
                          (x_pos == BOX_LEFT || x_pos == BOX_RIGHT || 
                           y_pos == Y_OPTION2_START || y_pos == Y_OPTION2_END);
    
    wire on_box3_border = (y_pos >= Y_OPTION3_START && y_pos <= Y_OPTION3_END) &&
                          (x_pos >= BOX_LEFT && x_pos <= BOX_RIGHT) &&
                          (x_pos == BOX_LEFT || x_pos == BOX_RIGHT || 
                           y_pos == Y_OPTION3_START || y_pos == Y_OPTION3_END);
    
    wire on_box4_border = (y_pos >= Y_OPTION4_START && y_pos <= Y_OPTION4_END) &&
                          (x_pos >= BOX_LEFT && x_pos <= BOX_RIGHT) &&
                          (x_pos == BOX_LEFT || x_pos == BOX_RIGHT || 
                           y_pos == Y_OPTION4_START || y_pos == Y_OPTION4_END);
    
    wire inside_box1 = (y_pos >= Y_OPTION1_START && y_pos <= Y_OPTION1_END) &&
                       (x_pos >= BOX_LEFT && x_pos <= BOX_RIGHT);
    wire inside_box2 = (y_pos >= Y_OPTION2_START && y_pos <= Y_OPTION2_END) &&
                       (x_pos >= BOX_LEFT && x_pos <= BOX_RIGHT);
    wire inside_box3 = (y_pos >= Y_OPTION3_START && y_pos <= Y_OPTION3_END) &&
                       (x_pos >= BOX_LEFT && x_pos <= BOX_RIGHT);
    wire inside_box4 = (y_pos >= Y_OPTION4_START && y_pos <= Y_OPTION4_END) &&
                       (x_pos >= BOX_LEFT && x_pos <= BOX_RIGHT);
    
    // Pixel rendering
    always @(*) begin
        // Default background
        pixel_data = COLOR_BG;
        
        // Highlight effect - fill box with hover color for highlighted option
        if (highlighted_option == 1 && inside_box1)
            pixel_data = COLOR_HOVER;
        else if (highlighted_option == 2 && inside_box2)
            pixel_data = COLOR_HOVER;
        else if (highlighted_option == 3 && inside_box3)
            pixel_data = COLOR_HOVER;
        else if (highlighted_option == 4 && inside_box4)
            pixel_data = COLOR_HOVER;
        
        // Draw box borders
        if (on_box1_border || on_box2_border || on_box3_border || on_box4_border)
            pixel_data = COLOR_LINE;
        
        // Draw text (on top of everything)
        if (is_text_pixel)
            pixel_data = COLOR_TEXT;
    end

endmodule