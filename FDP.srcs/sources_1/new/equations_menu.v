`timescale 1ns / 1ps
module equation_menu(
    input clk_6p25M,
    input reset,
    input btn_up,
    input btn_down,
    input btn_select,
    input [12:0] pixel_index,
    input clear_selection,
    output reg [15:0] pixel_data,
    output reg [2:0] selected_option
);
    localparam WIDTH = 96;
    localparam HEIGHT = 64;
    reg [6:0] x_pos;
    reg [5:0] y_pos;
    reg is_text_pixel;
    reg [7:0] current_char;
    reg [2:0] char_row;
    reg [4:0] char_data;
    reg [6:0] char_x_start;
    reg [2:0] char_col_index;


    always @(*) begin
        x_pos = pixel_index % WIDTH;
        y_pos = pixel_index / WIDTH;
    end

    localparam COLOR_BG = 16'h0000;
    localparam COLOR_TEXT = 16'hFFFF;
    localparam COLOR_LINE = 16'h7BEF;
    localparam COLOR_HOVER = 16'h2124;

    reg [2:0] highlighted_option = 1;
    reg btn_up_prev, btn_down_prev, btn_select_prev;
    wire btn_up_edge = btn_up && !btn_up_prev;
    wire btn_down_edge = btn_down && !btn_down_prev;
    wire btn_select_edge = btn_select && !btn_select_prev;

    always @(posedge clk_6p25M) begin
        if (reset) begin
            btn_up_prev <= 0; btn_down_prev <= 0; btn_select_prev <= 0;
            selected_option <= 0;
            highlighted_option <= 1;
        end else begin
            btn_up_prev <= btn_up; btn_down_prev <= btn_down; btn_select_prev <= btn_select;
            if (clear_selection) begin
                selected_option <= 0;
            end
            if (btn_up_edge) highlighted_option <= (highlighted_option > 1) ? highlighted_option - 1 : 4;
            if (btn_down_edge) highlighted_option <= (highlighted_option < 4) ? highlighted_option + 1 : 1;
            if (btn_select_edge && !clear_selection) selected_option <= highlighted_option;
        end
    end

    always @(*) begin
        pixel_data = COLOR_BG;
        is_text_pixel = 0;
        current_char = " ";
        char_data = 5'b0;
        char_x_start = 0;
        char_col_index = 0;

        if ((highlighted_option == 1 && y_pos < 16) ||
            (highlighted_option == 2 && y_pos >= 16 && y_pos < 32) ||
            (highlighted_option == 3 && y_pos >= 32 && y_pos < 48) ||
            (highlighted_option == 4 && y_pos >= 48 && y_pos < 64))
        begin
            pixel_data = COLOR_HOVER;
        end

        if (y_pos == 15 || y_pos == 31 || y_pos == 47)
            pixel_data = COLOR_LINE;

        if (y_pos >= 4 && y_pos < 11) begin
            char_row = y_pos - 4;
            char_x_start = 10;
                 if (x_pos >= char_x_start && x_pos < char_x_start+6) {current_char,char_col_index} = {"1", x_pos-char_x_start};
            else if (x_pos >= char_x_start+6 && x_pos < char_x_start+12) {current_char,char_col_index} = {":", x_pos-(char_x_start+6)};
            else if (x_pos >= char_x_start+18 && x_pos < char_x_start+24) {current_char,char_col_index} = {"2", x_pos-(char_x_start+18)};
            else if (x_pos >= char_x_start+24 && x_pos < char_x_start+30) {current_char,char_col_index} = {"x", x_pos-(char_x_start+24)};
            else if (x_pos >= char_x_start+30 && x_pos < char_x_start+36) {current_char,char_col_index} = {"2", x_pos-(char_x_start+30)};
            else if (x_pos >= char_x_start+42 && x_pos < char_x_start+48) {current_char,char_col_index} = {"S", x_pos-(char_x_start+42)};
            else if (x_pos >= char_x_start+48 && x_pos < char_x_start+54) {current_char,char_col_index} = {"I", x_pos-(char_x_start+48)};
            else if (x_pos >= char_x_start+54 && x_pos < char_x_start+60) {current_char,char_col_index} = {"M", x_pos-(char_x_start+54)};
            else if (x_pos >= char_x_start+60 && x_pos < char_x_start+66) {current_char,char_col_index} = {"U", x_pos-(char_x_start+60)};
            else if (x_pos >= char_x_start+66 && x_pos < char_x_start+72) {current_char,char_col_index} = {"L", x_pos-(char_x_start+66)};
        end else if (y_pos >= 20 && y_pos < 27) begin
            char_row = y_pos - 20;
            char_x_start = 10;
                 if (x_pos >= char_x_start && x_pos < char_x_start+6) {current_char,char_col_index} = {"2", x_pos-char_x_start};
            else if (x_pos >= char_x_start+6 && x_pos < char_x_start+12) {current_char,char_col_index} = {":", x_pos-(char_x_start+6)};
            else if (x_pos >= char_x_start+18 && x_pos < char_x_start+24) {current_char,char_col_index} = {"3", x_pos-(char_x_start+18)};
            else if (x_pos >= char_x_start+24 && x_pos < char_x_start+30) {current_char,char_col_index} = {"x", x_pos-(char_x_start+24)};
            else if (x_pos >= char_x_start+30 && x_pos < char_x_start+36) {current_char,char_col_index} = {"3", x_pos-(char_x_start+30)};
            else if (x_pos >= char_x_start+42 && x_pos < char_x_start+48) {current_char,char_col_index} = {"S", x_pos-(char_x_start+42)};
            else if (x_pos >= char_x_start+48 && x_pos < char_x_start+54) {current_char,char_col_index} = {"I", x_pos-(char_x_start+48)};
            else if (x_pos >= char_x_start+54 && x_pos < char_x_start+60) {current_char,char_col_index} = {"M", x_pos-(char_x_start+54)};
            else if (x_pos >= char_x_start+60 && x_pos < char_x_start+66) {current_char,char_col_index} = {"U", x_pos-(char_x_start+60)};
            else if (x_pos >= char_x_start+66 && x_pos < char_x_start+72) {current_char,char_col_index} = {"L", x_pos-(char_x_start+66)};
        end else if (y_pos >= 36 && y_pos < 43) begin
            char_row = y_pos - 36;
            char_x_start = 10;
                 if (x_pos >= char_x_start && x_pos < char_x_start+6) {current_char,char_col_index} = {"3", x_pos-char_x_start};
            else if (x_pos >= char_x_start+6 && x_pos < char_x_start+12) {current_char,char_col_index} = {":", x_pos-(char_x_start+6)};
            else if (x_pos >= char_x_start+18 && x_pos < char_x_start+24) {current_char,char_col_index} = {"Q", x_pos-(char_x_start+18)};
            else if (x_pos >= char_x_start+24 && x_pos < char_x_start+30) {current_char,char_col_index} = {"U", x_pos-(char_x_start+24)};
            else if (x_pos >= char_x_start+30 && x_pos < char_x_start+36) {current_char,char_col_index} = {"A", x_pos-(char_x_start+30)};
            else if (x_pos >= char_x_start+36 && x_pos < char_x_start+42) {current_char,char_col_index} = {"D", x_pos-(char_x_start+36)};
            else if (x_pos >= char_x_start+42 && x_pos < char_x_start+48) {current_char,char_col_index} = {"R", x_pos-(char_x_start+42)};
            else if (x_pos >= char_x_start+48 && x_pos < char_x_start+54) {current_char,char_col_index} = {"A", x_pos-(char_x_start+48)};
            else if (x_pos >= char_x_start+54 && x_pos < char_x_start+60) {current_char,char_col_index} = {"T", x_pos-(char_x_start+54)};
            else if (x_pos >= char_x_start+60 && x_pos < char_x_start+66) {current_char,char_col_index} = {"I", x_pos-(char_x_start+60)};
            else if (x_pos >= char_x_start+66 && x_pos < char_x_start+72) {current_char,char_col_index} = {"C", x_pos-(char_x_start+66)};
        end else if (y_pos >= 52 && y_pos < 59) begin
            char_row = y_pos - 52;
            char_x_start = 10;
                 if (x_pos >= char_x_start && x_pos < char_x_start+6) {current_char,char_col_index} = {"4", x_pos-char_x_start};
            else if (x_pos >= char_x_start+6 && x_pos < char_x_start+12) {current_char,char_col_index} = {":", x_pos-(char_x_start+6)};
            else if (x_pos >= char_x_start+18 && x_pos < char_x_start+24) {current_char,char_col_index} = {"C", x_pos-(char_x_start+18)};
            else if (x_pos >= char_x_start+24 && x_pos < char_x_start+30) {current_char,char_col_index} = {"U", x_pos-(char_x_start+24)};
            else if (x_pos >= char_x_start+30 && x_pos < char_x_start+36) {current_char,char_col_index} = {"B", x_pos-(char_x_start+30)};
            else if (x_pos >= char_x_start+36 && x_pos < char_x_start+42) {current_char,char_col_index} = {"I", x_pos-(char_x_start+36)};
            else if (x_pos >= char_x_start+42 && x_pos < char_x_start+48) {current_char,char_col_index} = {"C", x_pos-(char_x_start+42)};
        end
        
        case (current_char)
            "1": case(char_row) 0:char_data=5'b01100; 1:char_data=5'b11100; 2:char_data=5'b00100; 3:char_data=5'b00100; 4:char_data=5'b00100; 5:char_data=5'b00100; 6:char_data=5'b11111; default:char_data=5'b0; endcase
            "2": case(char_row) 0:char_data=5'b01110; 1:char_data=5'b10001; 2:char_data=5'b00001; 3:char_data=5'b00110; 4:char_data=5'b01000; 5:char_data=5'b10000; 6:char_data=5'b11111; default:char_data=5'b0; endcase
            "3": case(char_row) 0:char_data=5'b01110; 1:char_data=5'b10001; 2:char_data=5'b00001; 3:char_data=5'b00110; 4:char_data=5'b00001; 5:char_data=5'b10001; 6:char_data=5'b01110; default:char_data=5'b0; endcase
            "4": case(char_row) 0:char_data=5'b00010; 1:char_data=5'b00110; 2:char_data=5'b01010; 3:char_data=5'b10010; 4:char_data=5'b11111; 5:char_data=5'b00010; 6:char_data=5'b00010; default:char_data=5'b0; endcase
            "x": case(char_row) 2:char_data=5'b10001; 3:char_data=5'b01010; 4:char_data=5'b00100; 5:char_data=5'b01010; 6:char_data=5'b10001; default:char_data=5'b0; endcase
            ":": case(char_row) 2:char_data=5'b01100; 3:char_data=5'b01100; 5:char_data=5'b01100; 6:char_data=5'b01100; default:char_data=5'b0; endcase
            "A": case(char_row) 0:char_data=5'b01110; 1:char_data=5'b10001; 2:char_data=5'b10001; 3:char_data=5'b11111; 4:char_data=5'b10001; 5:char_data=5'b10001; 6:char_data=5'b10001; default:char_data=5'b0; endcase
            "B": case(char_row) 0:char_data=5'b11110; 1:char_data=5'b10001; 2:char_data=5'b10001; 3:char_data=5'b11110; 4:char_data=5'b10001; 5:char_data=5'b10001; 6:char_data=5'b11110; default:char_data=5'b0; endcase
            "C": case(char_row) 0:char_data=5'b01110; 1:char_data=5'b10001; 2:char_data=5'b10000; 3:char_data=5'b10000; 4:char_data=5'b10000; 5:char_data=5'b10001; 6:char_data=5'b01110; default:char_data=5'b0; endcase
            "D": case(char_row) 0:char_data=5'b11110; 1:char_data=5'b10001; 2:char_data=5'b10001; 3:char_data=5'b10001; 4:char_data=5'b10001; 5:char_data=5'b10001; 6:char_data=5'b11110; default:char_data=5'b0; endcase
            "I": case(char_row) 0:char_data=5'b11111; 1:char_data=5'b00100; 2:char_data=5'b00100; 3:char_data=5'b00100; 4:char_data=5'b00100; 5:char_data=5'b00100; 6:char_data=5'b11111; default:char_data=5'b0; endcase
            "L": case(char_row) 0:char_data=5'b10000; 1:char_data=5'b10000; 2:char_data=5'b10000; 3:char_data=5'b10000; 4:char_data=5'b10000; 5:char_data=5'b10000; 6:char_data=5'b11111; default:char_data=5'b0; endcase
            "M": case(char_row) 0:char_data=5'b10001; 1:char_data=5'b11011; 2:char_data=5'b10101; 3:char_data=5'b10101; 4:char_data=5'b10001; 5:char_data=5'b10001; 6:char_data=5'b10001; default:char_data=5'b0; endcase
            "Q": case(char_row) 0:char_data=5'b01110; 1:char_data=5'b10001; 2:char_data=5'b10001; 3:char_data=5'b10001; 4:char_data=5'b10101; 5:char_data=5'b10010; 6:char_data=5'b01101; default:char_data=5'b0; endcase
            "R": case(char_row) 0:char_data=5'b11110; 1:char_data=5'b10001; 2:char_data=5'b10001; 3:char_data=5'b11110; 4:char_data=5'b10100; 5:char_data=5'b10010; 6:char_data=5'b10001; default:char_data=5'b0; endcase
            "S": case(char_row) 0:char_data=5'b01110; 1:char_data=5'b10001; 2:char_data=5'b10000; 3:char_data=5'b01110; 4:char_data=5'b00001; 5:char_data=5'b10001; 6:char_data=5'b01110; default:char_data=5'b0; endcase
            "T": case(char_row) 0:char_data=5'b11111; 1:char_data=5'b00100; 2:char_data=5'b00100; 3:char_data=5'b00100; 4:char_data=5'b00100; 5:char_data=5'b00100; 6:char_data=5'b00100; default:char_data=5'b0; endcase
            "U": case(char_row) 0:char_data=5'b10001; 1:char_data=5'b10001; 2:char_data=5'b10001; 3:char_data=5'b10001; 4:char_data=5'b10001; 5:char_data=5'b10001; 6:char_data=5'b01110; default:char_data=5'b0; endcase
            default: char_data = 5'b0;
        endcase

        if (char_col_index < 5 && char_data[4 - char_col_index]) begin
            pixel_data = COLOR_TEXT;
        end
    end
endmodule