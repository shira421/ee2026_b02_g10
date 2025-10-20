`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: quadratic_input
// Description: Input screen for quadratic equation ax²+bx+c=0
// Supports negative numbers using switch 15 as sign toggle
//////////////////////////////////////////////////////////////////////////////////

module quadratic_input(
    input clk_6p25M,
    input clk_100M,
    input reset,
    input [15:0] switches,       // sw[15] for sign, sw[9:0] for digits 0-9
    input btn_left,              // Navigate left / back from solver
    input btn_right,             // Navigate right
    input btn_select,            // Select/activate current item (DOWN button)
    input [12:0] pixel_index,
    output reg [15:0] pixel_data,
    output reg signed [10:0] coeff_a,    // Coefficient a (-999 to 999)
    output reg signed [10:0] coeff_b,    // Coefficient b (-999 to 999)
    output reg signed [10:0] coeff_c     // Coefficient c (-999 to 999)
);

    // Screen state: 0 = input, 1 = solver
    reg screen_state;
    
    // Wires from solver module
    wire [15:0] solver_pixel_data;
    
    // Input screen pixel data
    reg [15:0] input_pixel_data;
    
    // Screen dimensions
    localparam WIDTH = 96;
    localparam HEIGHT = 64;
    
    // Calculate current pixel position
    reg [6:0] x_pos;
    reg [5:0] y_pos;
    
    always @(*) begin
        x_pos = pixel_index % WIDTH;
        y_pos = pixel_index / WIDTH;
    end
    
    // Colors
    localparam COLOR_BG = 16'h0000;         // Black
    localparam COLOR_TEXT = 16'hFFFF;       // White
    localparam COLOR_BOX = 16'h18C3;        // Dark blue box
    localparam COLOR_BOX_ACTIVE = 16'h07E0; // Green for active box
    localparam COLOR_BORDER = 16'h7BEF;     // Light gray border
    localparam COLOR_BUTTON = 16'h4208;     // Dark gray button
    localparam COLOR_BUTTON_ACTIVE = 16'hFD20; // Orange for active button
    localparam COLOR_CLR_BUTTON = 16'hF800; // Red for CLR button
    
    // Box definitions for a, b, c input
    localparam BOX_WIDTH = 28;
    localparam BOX_HEIGHT = 12;
    
    // Box A position (left)
    localparam BOX_A_X1 = 4;
    localparam BOX_A_Y1 = 20;
    localparam BOX_A_X2 = BOX_A_X1 + BOX_WIDTH;
    localparam BOX_A_Y2 = BOX_A_Y1 + BOX_HEIGHT;
    
    // Box B position (middle)
    localparam BOX_B_X1 = 34;
    localparam BOX_B_Y1 = 20;
    localparam BOX_B_X2 = BOX_B_X1 + BOX_WIDTH;
    localparam BOX_B_Y2 = BOX_B_Y1 + BOX_HEIGHT;
    
    // Box C position (right)
    localparam BOX_C_X1 = 64;
    localparam BOX_C_Y1 = 20;
    localparam BOX_C_X2 = BOX_C_X1 + BOX_WIDTH;
    localparam BOX_C_Y2 = BOX_C_Y1 + BOX_HEIGHT;
    
    // CLR button position (bottom left)
    localparam BTN_CLR_X1 = 10;
    localparam BTN_CLR_Y1 = 45;
    localparam BTN_CLR_X2 = BTN_CLR_X1 + 30;
    localparam BTN_CLR_Y2 = BTN_CLR_Y1 + 10;
    
    // Solve button position (bottom right)
    localparam BTN_SOLVE_X1 = 56;
    localparam BTN_SOLVE_Y1 = 45;
    localparam BTN_SOLVE_X2 = BTN_SOLVE_X1 + 30;
    localparam BTN_SOLVE_Y2 = BTN_SOLVE_Y1 + 10;
    
    // Active item tracking (1=a, 2=b, 3=c, 4=clr button, 5=solve button)
    reg [2:0] active_item;
    
    // Button navigation
    reg btn_left_prev, btn_right_prev, btn_select_prev;
    wire btn_left_edge = btn_left && !btn_left_prev;
    wire btn_right_edge = btn_right && !btn_right_prev;
    wire btn_select_edge = btn_select && !btn_select_prev;
    
    // Clear control signals (set by button logic, used by switch logic)
    reg clear_all;
    
    // Switch debouncing and digit entry
    reg [15:0] switches_prev;
    reg [15:0] switches_stable;
    reg [15:0] debounce_counter;
    localparam DEBOUNCE_TIME = 16'd50000;  // ~8ms at 6.25MHz
    
    // Digit storage for each coefficient (3 digits max)
    reg [3:0] digit_a [0:2];
    reg [3:0] digit_b [0:2];
    reg [3:0] digit_c [0:2];
    reg [1:0] digit_count_a;
    reg [1:0] digit_count_b;
    reg [1:0] digit_count_c;
    
    // Sign for each coefficient (0 = positive, 1 = negative)
    reg sign_a, sign_b, sign_c;
    
    // Previous sign switch state for edge detection
    reg sign_switch_prev;
    wire sign_switch_edge = switches[15] && !sign_switch_prev;
    
    // Convert switch position to digit
    function [3:0] switch_to_digit;
        input [9:0] sw;
        begin
            case (sw)
                10'b0000000001: switch_to_digit = 4'd0;
                10'b0000000010: switch_to_digit = 4'd1;
                10'b0000000100: switch_to_digit = 4'd2;
                10'b0000001000: switch_to_digit = 4'd3;
                10'b0000010000: switch_to_digit = 4'd4;
                10'b0000100000: switch_to_digit = 4'd5;
                10'b0001000000: switch_to_digit = 4'd6;
                10'b0010000000: switch_to_digit = 4'd7;
                10'b0100000000: switch_to_digit = 4'd8;
                10'b1000000000: switch_to_digit = 4'd9;
                default: switch_to_digit = 4'd15;
            endcase
        end
    endfunction
    
    // Screen state management and button navigation
    always @(posedge clk_6p25M) begin
        if (reset) begin
            btn_left_prev <= 0;
            btn_right_prev <= 0;
            btn_select_prev <= 0;
            active_item <= 1;
            screen_state <= 0;
            clear_all <= 0;
        end else begin
            btn_left_prev <= btn_left;
            btn_right_prev <= btn_right;
            btn_select_prev <= btn_select;
            
            // Default: no clearing
            clear_all <= 0;
            
            // Handle screen transitions
            if (screen_state == 1) begin
                // On solver screen - LEFT button goes back to input
                if (btn_left_edge) begin
                    screen_state <= 0;
                end
            end else begin
                // On input screen
                // Navigate left
                if (btn_left_edge) begin
                    if (active_item > 1)
                        active_item <= active_item - 1;
                    else
                        active_item <= 5;  // Wrap to solve button
                end
                
                // Navigate right
                if (btn_right_edge) begin
                    if (active_item < 5)
                        active_item <= active_item + 1;
                    else
                        active_item <= 1;  // Wrap to box a
                end
                
                // Select button (DOWN button)
                if (btn_select_edge) begin
                    case (active_item)
                        3'd4: begin
                            // CLR button pressed - clear all boxes
                            clear_all <= 1;
                        end
                        3'd5: begin
                            // Solve button pressed - go to solver
                            screen_state <= 1;
                        end
                        // For boxes 1-3, do nothing on select (only switches input digits)
                    endcase
                end
            end
        end
    end
    
    // Switch input handling - ALL coefficient updates here
    always @(posedge clk_100M) begin
        if (reset) begin
            switches_prev <= 0;
            switches_stable <= 0;
            debounce_counter <= 0;
            digit_count_a <= 0;
            digit_count_b <= 0;
            digit_count_c <= 0;
            digit_a[0] <= 0; digit_a[1] <= 0; digit_a[2] <= 0;
            digit_b[0] <= 0; digit_b[1] <= 0; digit_b[2] <= 0;
            digit_c[0] <= 0; digit_c[1] <= 0; digit_c[2] <= 0;
            sign_a <= 0; sign_b <= 0; sign_c <= 0;
            sign_switch_prev <= 0;
            coeff_a <= 0;
            coeff_b <= 0;
            coeff_c <= 0;
        end else begin
            // Track sign switch for edge detection
            sign_switch_prev <= switches[15];
            
            // Handle clear all signal from button logic
            if (clear_all) begin
                digit_count_a <= 0;
                digit_a[0] <= 0; digit_a[1] <= 0; digit_a[2] <= 0;
                sign_a <= 0;
                coeff_a <= 0;
                digit_count_b <= 0;
                digit_b[0] <= 0; digit_b[1] <= 0; digit_b[2] <= 0;
                sign_b <= 0;
                coeff_b <= 0;
                digit_count_c <= 0;
                digit_c[0] <= 0; digit_c[1] <= 0; digit_c[2] <= 0;
                sign_c <= 0;
                coeff_c <= 0;
            end
            
            // Only process switches on input screen
            if (screen_state == 0 && !clear_all) begin
                // Debounce switches (only check lower 10 bits for debouncing)
                if (switches[9:0] != switches_prev[9:0]) begin
                    switches_prev <= switches;
                    debounce_counter <= 0;
                end else if (debounce_counter < DEBOUNCE_TIME) begin
                    debounce_counter <= debounce_counter + 1;
                end else if (switches[9:0] != switches_stable[9:0]) begin
                    switches_stable <= switches;
                    
                    // Only allow digit entry when a coefficient box is active
                    if (active_item <= 3) begin
                        if (switches[9:0] != 0 && (switches[9:0] & (switches[9:0] - 1)) == 0) begin
                            case (active_item)
                                3'd1: begin
                                    if (digit_count_a < 3) begin
                                        digit_a[digit_count_a] <= switch_to_digit(switches[9:0]);
                                        digit_count_a <= digit_count_a + 1;
                                        coeff_a <= sign_a ? -(digit_a[2]*100 + digit_a[1]*10 + switch_to_digit(switches[9:0])) 
                                                          : (digit_a[2]*100 + digit_a[1]*10 + switch_to_digit(switches[9:0]));
                                    end
                                end
                                3'd2: begin
                                    if (digit_count_b < 3) begin
                                        digit_b[digit_count_b] <= switch_to_digit(switches[9:0]);
                                        digit_count_b <= digit_count_b + 1;
                                        coeff_b <= sign_b ? -(digit_b[2]*100 + digit_b[1]*10 + switch_to_digit(switches[9:0]))
                                                          : (digit_b[2]*100 + digit_b[1]*10 + switch_to_digit(switches[9:0]));
                                    end
                                end
                                3'd3: begin
                                    if (digit_count_c < 3) begin
                                        digit_c[digit_count_c] <= switch_to_digit(switches[9:0]);
                                        digit_count_c <= digit_count_c + 1;
                                        coeff_c <= sign_c ? -(digit_c[2]*100 + digit_c[1]*10 + switch_to_digit(switches[9:0]))
                                                          : (digit_c[2]*100 + digit_c[1]*10 + switch_to_digit(switches[9:0]));
                                    end
                                end
                            endcase
                        end
                    end
                end
                
                // Handle sign toggle separately (no debouncing needed, using edge detection)
                if (sign_switch_edge && active_item <= 3) begin
                    case (active_item)
                        3'd1: begin
                            sign_a <= ~sign_a;
                            if (digit_count_a > 0)
                                coeff_a <= -coeff_a;
                        end
                        3'd2: begin
                            sign_b <= ~sign_b;
                            if (digit_count_b > 0)
                                coeff_b <= -coeff_b;
                        end
                        3'd3: begin
                            sign_c <= ~sign_c;
                            if (digit_count_c > 0)
                                coeff_c <= -coeff_c;
                        end
                    endcase
                end
            end
        end
    end
    
    // Instantiate solver module
    quadratic_solver solver_inst (
        .clk_6p25M(clk_6p25M),
        .reset(reset),
        .coeff_a(coeff_a),
        .coeff_b(coeff_b),
        .coeff_c(coeff_c),
        .pixel_index(pixel_index),
        .pixel_data(solver_pixel_data)
    );
    
    // Character ROM
    function [4:0] get_char_row;
        input [7:0] char;
        input [2:0] row;
        begin
            case (char)
                "0": case(row) 0: get_char_row=5'b01110; 1: get_char_row=5'b10001; 2: get_char_row=5'b10011; 3: get_char_row=5'b10101; 4: get_char_row=5'b11001; 5: get_char_row=5'b10001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "1": case(row) 0: get_char_row=5'b01100; 1: get_char_row=5'b11100; 2: get_char_row=5'b00100; 3: get_char_row=5'b00100; 4: get_char_row=5'b00100; 5: get_char_row=5'b00100; 6: get_char_row=5'b11111; default: get_char_row=5'b00000; endcase
                "2": case(row) 0: get_char_row=5'b01110; 1: get_char_row=5'b10001; 2: get_char_row=5'b00001; 3: get_char_row=5'b00110; 4: get_char_row=5'b01000; 5: get_char_row=5'b10000; 6: get_char_row=5'b11111; default: get_char_row=5'b00000; endcase
                "3": case(row) 0: get_char_row=5'b01110; 1: get_char_row=5'b10001; 2: get_char_row=5'b00001; 3: get_char_row=5'b00110; 4: get_char_row=5'b00001; 5: get_char_row=5'b10001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "4": case(row) 0: get_char_row=5'b00010; 1: get_char_row=5'b00110; 2: get_char_row=5'b01010; 3: get_char_row=5'b10010; 4: get_char_row=5'b11111; 5: get_char_row=5'b00010; 6: get_char_row=5'b00010; default: get_char_row=5'b00000; endcase
                "5": case(row) 0: get_char_row=5'b11111; 1: get_char_row=5'b10000; 2: get_char_row=5'b11110; 3: get_char_row=5'b00001; 4: get_char_row=5'b00001; 5: get_char_row=5'b10001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "6": case(row) 0: get_char_row=5'b01110; 1: get_char_row=5'b10000; 2: get_char_row=5'b11110; 3: get_char_row=5'b10001; 4: get_char_row=5'b10001; 5: get_char_row=5'b10001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "7": case(row) 0: get_char_row=5'b11111; 1: get_char_row=5'b00001; 2: get_char_row=5'b00010; 3: get_char_row=5'b00100; 4: get_char_row=5'b01000; 5: get_char_row=5'b01000; 6: get_char_row=5'b01000; default: get_char_row=5'b00000; endcase
                "8": case(row) 0: get_char_row=5'b01110; 1: get_char_row=5'b10001; 2: get_char_row=5'b10001; 3: get_char_row=5'b01110; 4: get_char_row=5'b10001; 5: get_char_row=5'b10001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "9": case(row) 0: get_char_row=5'b01110; 1: get_char_row=5'b10001; 2: get_char_row=5'b10001; 3: get_char_row=5'b01111; 4: get_char_row=5'b00001; 5: get_char_row=5'b00001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "a": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b01110; 3: get_char_row=5'b00001; 4: get_char_row=5'b01111; 5: get_char_row=5'b10001; 6: get_char_row=5'b01111; default: get_char_row=5'b00000; endcase
                "b": case(row) 0: get_char_row=5'b10000; 1: get_char_row=5'b10000; 2: get_char_row=5'b11110; 3: get_char_row=5'b10001; 4: get_char_row=5'b10001; 5: get_char_row=5'b10001; 6: get_char_row=5'b11110; default: get_char_row=5'b00000; endcase
                "c": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b01110; 3: get_char_row=5'b10001; 4: get_char_row=5'b10000; 5: get_char_row=5'b10001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "x": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b10001; 3: get_char_row=5'b01010; 4: get_char_row=5'b00100; 5: get_char_row=5'b01010; 6: get_char_row=5'b10001; default: get_char_row=5'b00000; endcase
                "S": case(row) 0: get_char_row=5'b01110; 1: get_char_row=5'b10001; 2: get_char_row=5'b10000; 3: get_char_row=5'b01110; 4: get_char_row=5'b00001; 5: get_char_row=5'b10001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "C": case(row) 0: get_char_row=5'b01110; 1: get_char_row=5'b10001; 2: get_char_row=5'b10000; 3: get_char_row=5'b10000; 4: get_char_row=5'b10000; 5: get_char_row=5'b10001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "L": case(row) 0: get_char_row=5'b10000; 1: get_char_row=5'b10000; 2: get_char_row=5'b10000; 3: get_char_row=5'b10000; 4: get_char_row=5'b10000; 5: get_char_row=5'b10000; 6: get_char_row=5'b11111; default: get_char_row=5'b00000; endcase
                "R": case(row) 0: get_char_row=5'b11110; 1: get_char_row=5'b10001; 2: get_char_row=5'b10001; 3: get_char_row=5'b11110; 4: get_char_row=5'b10100; 5: get_char_row=5'b10010; 6: get_char_row=5'b10001; default: get_char_row=5'b00000; endcase
                "o": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b01110; 3: get_char_row=5'b10001; 4: get_char_row=5'b10001; 5: get_char_row=5'b10001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "l": case(row) 0: get_char_row=5'b01100; 1: get_char_row=5'b00100; 2: get_char_row=5'b00100; 3: get_char_row=5'b00100; 4: get_char_row=5'b00100; 5: get_char_row=5'b00100; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "v": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b10001; 3: get_char_row=5'b10001; 4: get_char_row=5'b10001; 5: get_char_row=5'b01010; 6: get_char_row=5'b00100; default: get_char_row=5'b00000; endcase
                "e": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b01110; 3: get_char_row=5'b10001; 4: get_char_row=5'b11111; 5: get_char_row=5'b10000; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "+": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00100; 2: get_char_row=5'b00100; 3: get_char_row=5'b11111; 4: get_char_row=5'b00100; 5: get_char_row=5'b00100; 6: get_char_row=5'b00000; default: get_char_row=5'b00000; endcase
                "-": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b00000; 3: get_char_row=5'b11111; 4: get_char_row=5'b00000; 5: get_char_row=5'b00000; 6: get_char_row=5'b00000; default: get_char_row=5'b00000; endcase
                "=": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b11111; 3: get_char_row=5'b00000; 4: get_char_row=5'b11111; 5: get_char_row=5'b00000; 6: get_char_row=5'b00000; default: get_char_row=5'b00000; endcase
                "²": case(row) 0: get_char_row=5'b01110; 1: get_char_row=5'b10001; 2: get_char_row=5'b00010; 3: get_char_row=5'b00100; 4: get_char_row=5'b11111; 5: get_char_row=5'b00000; 6: get_char_row=5'b00000; default: get_char_row=5'b00000; endcase
                " ": get_char_row = 5'b00000;
                default: get_char_row = 5'b00000;
            endcase
        end
    endfunction
    
    // Input screen rendering logic
    reg is_text_pixel;
    reg [7:0] current_char;
    reg [2:0] char_row, char_col;
    reg [4:0] char_row_data;
    
    always @(*) begin
        input_pixel_data = COLOR_BG;
        is_text_pixel = 0;
        current_char = " ";
        char_row = 0;
        char_col = 0;
        char_row_data = 0;
        
        // Draw title: ax²+bx+c=0
        if (y_pos >= 4 && y_pos <= 10) begin
            char_row = y_pos - 4;
            if (x_pos >= 18 && x_pos < 23) begin current_char = "a"; char_col = x_pos - 18; end
            else if (x_pos >= 23 && x_pos < 28) begin current_char = "x"; char_col = x_pos - 23; end
            else if (x_pos >= 28 && x_pos < 33) begin current_char = "²"; char_col = x_pos - 28; end
            else if (x_pos >= 35 && x_pos < 40) begin current_char = "+"; char_col = x_pos - 35; end
            else if (x_pos >= 42 && x_pos < 47) begin current_char = "b"; char_col = x_pos - 42; end
            else if (x_pos >= 47 && x_pos < 52) begin current_char = "x"; char_col = x_pos - 47; end
            else if (x_pos >= 54 && x_pos < 59) begin current_char = "+"; char_col = x_pos - 54; end
            else if (x_pos >= 61 && x_pos < 66) begin current_char = "c"; char_col = x_pos - 61; end
            else if (x_pos >= 68 && x_pos < 73) begin current_char = "="; char_col = x_pos - 68; end
            else if (x_pos >= 75 && x_pos < 80) begin current_char = "0"; char_col = x_pos - 75; end
            
            char_row_data = get_char_row(current_char, char_row);
            if (char_col < 5 && char_row_data[4-char_col])
                is_text_pixel = 1;
        end
        
        // Draw box A
        if (x_pos >= BOX_A_X1 && x_pos <= BOX_A_X2 && y_pos >= BOX_A_Y1 && y_pos <= BOX_A_Y2) begin
            if (x_pos == BOX_A_X1 || x_pos == BOX_A_X2 || y_pos == BOX_A_Y1 || y_pos == BOX_A_Y2)
                input_pixel_data = (active_item == 1) ? COLOR_BOX_ACTIVE : COLOR_BORDER;
            else
                input_pixel_data = COLOR_BOX;
        end
        
        // Draw box B
        if (x_pos >= BOX_B_X1 && x_pos <= BOX_B_X2 && y_pos >= BOX_B_Y1 && y_pos <= BOX_B_Y2) begin
            if (x_pos == BOX_B_X1 || x_pos == BOX_B_X2 || y_pos == BOX_B_Y1 || y_pos == BOX_B_Y2)
                input_pixel_data = (active_item == 2) ? COLOR_BOX_ACTIVE : COLOR_BORDER;
            else
                input_pixel_data = COLOR_BOX;
        end
        
        // Draw box C
        if (x_pos >= BOX_C_X1 && x_pos <= BOX_C_X2 && y_pos >= BOX_C_Y1 && y_pos <= BOX_C_Y2) begin
            if (x_pos == BOX_C_X1 || x_pos == BOX_C_X2 || y_pos == BOX_C_Y1 || y_pos == BOX_C_Y2)
                input_pixel_data = (active_item == 3) ? COLOR_BOX_ACTIVE : COLOR_BORDER;
            else
                input_pixel_data = COLOR_BOX;
        end
        
        // Draw CLR button
        if (x_pos >= BTN_CLR_X1 && x_pos <= BTN_CLR_X2 && y_pos >= BTN_CLR_Y1 && y_pos <= BTN_CLR_Y2) begin
            if (x_pos == BTN_CLR_X1 || x_pos == BTN_CLR_X2 || y_pos == BTN_CLR_Y1 || y_pos == BTN_CLR_Y2)
                input_pixel_data = (active_item == 4) ? COLOR_BUTTON_ACTIVE : COLOR_BORDER;
            else
                input_pixel_data = (active_item == 4) ? COLOR_CLR_BUTTON : COLOR_BUTTON;
        end
        
        // Draw Solve button
        if (x_pos >= BTN_SOLVE_X1 && x_pos <= BTN_SOLVE_X2 && y_pos >= BTN_SOLVE_Y1 && y_pos <= BTN_SOLVE_Y2) begin
            if (x_pos == BTN_SOLVE_X1 || x_pos == BTN_SOLVE_X2 || y_pos == BTN_SOLVE_Y1 || y_pos == BTN_SOLVE_Y2)
                input_pixel_data = (active_item == 5) ? COLOR_BUTTON_ACTIVE : COLOR_BORDER;
            else
                input_pixel_data = COLOR_BUTTON;
        end
        
        // Draw "CLR" text
        if (y_pos >= BTN_CLR_Y1 + 2 && y_pos <= BTN_CLR_Y1 + 8) begin
            char_row = y_pos - (BTN_CLR_Y1 + 2);
            if (x_pos >= BTN_CLR_X1 + 6 && x_pos < BTN_CLR_X1 + 11) begin current_char = "C"; char_col = x_pos - (BTN_CLR_X1 + 6); end
            else if (x_pos >= BTN_CLR_X1 + 11 && x_pos < BTN_CLR_X1 + 16) begin current_char = "L"; char_col = x_pos - (BTN_CLR_X1 + 11); end
            else if (x_pos >= BTN_CLR_X1 + 16 && x_pos < BTN_CLR_X1 + 21) begin current_char = "R"; char_col = x_pos - (BTN_CLR_X1 + 16); end
            char_row_data = get_char_row(current_char, char_row);
            if (char_col < 5 && char_row_data[4-char_col])
                is_text_pixel = 1;
        end
        
        // Draw "Solve" text
        if (y_pos >= BTN_SOLVE_Y1 + 2 && y_pos <= BTN_SOLVE_Y1 + 8) begin
            char_row = y_pos - (BTN_SOLVE_Y1 + 2);
            if (x_pos >= BTN_SOLVE_X1 + 4 && x_pos < BTN_SOLVE_X1 + 9) begin current_char = "S"; char_col = x_pos - (BTN_SOLVE_X1 + 4); end
            else if (x_pos >= BTN_SOLVE_X1 + 9 && x_pos < BTN_SOLVE_X1 + 14) begin current_char = "o"; char_col = x_pos - (BTN_SOLVE_X1 + 9); end
            else if (x_pos >= BTN_SOLVE_X1 + 14 && x_pos < BTN_SOLVE_X1 + 19) begin current_char = "l"; char_col = x_pos - (BTN_SOLVE_X1 + 14); end
            else if (x_pos >= BTN_SOLVE_X1 + 19 && x_pos < BTN_SOLVE_X1 + 24) begin current_char = "v"; char_col = x_pos - (BTN_SOLVE_X1 + 19); end
            else if (x_pos >= BTN_SOLVE_X1 + 24 && x_pos < BTN_SOLVE_X1 + 29) begin current_char = "e"; char_col = x_pos - (BTN_SOLVE_X1 + 24); end
            char_row_data = get_char_row(current_char, char_row);
            if (char_col < 5 && char_row_data[4-char_col])
                is_text_pixel = 1;
        end
        
        // Draw sign and digits in box A
        if (y_pos >= BOX_A_Y1 + 3 && y_pos <= BOX_A_Y1 + 9) begin
            char_row = y_pos - (BOX_A_Y1 + 3);
            // Draw negative sign if negative
            if (sign_a && x_pos >= BOX_A_X1 + 2 && x_pos < BOX_A_X1 + 7) begin 
                current_char = "-"; 
                char_col = x_pos - (BOX_A_X1 + 2); 
                char_row_data = get_char_row(current_char, char_row);
                if (char_col < 5 && char_row_data[4-char_col])
                    is_text_pixel = 1;
            end
            // Draw digits
            if (digit_count_a > 0) begin
                if (x_pos >= BOX_A_X1 + 8 && x_pos < BOX_A_X1 + 13 && digit_count_a >= 1) begin current_char = "0" + digit_a[0]; char_col = x_pos - (BOX_A_X1 + 8); end
                else if (x_pos >= BOX_A_X1 + 14 && x_pos < BOX_A_X1 + 19 && digit_count_a >= 2) begin current_char = "0" + digit_a[1]; char_col = x_pos - (BOX_A_X1 + 14); end
                else if (x_pos >= BOX_A_X1 + 20 && x_pos < BOX_A_X1 + 25 && digit_count_a >= 3) begin current_char = "0" + digit_a[2]; char_col = x_pos - (BOX_A_X1 + 20); end
                char_row_data = get_char_row(current_char, char_row);
                if (char_col < 5 && char_row_data[4-char_col])
                    is_text_pixel = 1;
            end
        end
        
        // Draw sign and digits in box B
        if (y_pos >= BOX_B_Y1 + 3 && y_pos <= BOX_B_Y1 + 9) begin
            char_row = y_pos - (BOX_B_Y1 + 3);
            // Draw negative sign if negative
            if (sign_b && x_pos >= BOX_B_X1 + 2 && x_pos < BOX_B_X1 + 7) begin 
                current_char = "-"; 
                char_col = x_pos - (BOX_B_X1 + 2); 
                char_row_data = get_char_row(current_char, char_row);
                if (char_col < 5 && char_row_data[4-char_col])
                    is_text_pixel = 1;
            end
            // Draw digits
            if (digit_count_b > 0) begin
                if (x_pos >= BOX_B_X1 + 8 && x_pos < BOX_B_X1 + 13 && digit_count_b >= 1) begin current_char = "0" + digit_b[0]; char_col = x_pos - (BOX_B_X1 + 8); end
                else if (x_pos >= BOX_B_X1 + 14 && x_pos < BOX_B_X1 + 19 && digit_count_b >= 2) begin current_char = "0" + digit_b[1]; char_col = x_pos - (BOX_B_X1 + 14); end
                else if (x_pos >= BOX_B_X1 + 20 && x_pos < BOX_B_X1 + 25 && digit_count_b >= 3) begin current_char = "0" + digit_b[2]; char_col = x_pos - (BOX_B_X1 + 20); end
                char_row_data = get_char_row(current_char, char_row);
                if (char_col < 5 && char_row_data[4-char_col])
                    is_text_pixel = 1;
            end
        end
        
        // Draw sign and digits in box C
        if (y_pos >= BOX_C_Y1 + 3 && y_pos <= BOX_C_Y1 + 9) begin
            char_row = y_pos - (BOX_C_Y1 + 3);
            // Draw negative sign if negative
            if (sign_c && x_pos >= BOX_C_X1 + 2 && x_pos < BOX_C_X1 + 7) begin 
                current_char = "-"; 
                char_col = x_pos - (BOX_C_X1 + 2); 
                char_row_data = get_char_row(current_char, char_row);
                if (char_col < 5 && char_row_data[4-char_col])
                    is_text_pixel = 1;
            end
            // Draw digits
            if (digit_count_c > 0) begin
                if (x_pos >= BOX_C_X1 + 8 && x_pos < BOX_C_X1 + 13 && digit_count_c >= 1) begin current_char = "0" + digit_c[0]; char_col = x_pos - (BOX_C_X1 + 8); end
                else if (x_pos >= BOX_C_X1 + 14 && x_pos < BOX_C_X1 + 19 && digit_count_c >= 2) begin current_char = "0" + digit_c[1]; char_col = x_pos - (BOX_C_X1 + 14); end
                else if (x_pos >= BOX_C_X1 + 20 && x_pos < BOX_C_X1 + 25 && digit_count_c >= 3) begin current_char = "0" + digit_c[2]; char_col = x_pos - (BOX_C_X1 + 20); end
                char_row_data = get_char_row(current_char, char_row);
                if (char_col < 5 && char_row_data[4-char_col])
                    is_text_pixel = 1;
            end
        end
        
        // Apply text color
        if (is_text_pixel)
            input_pixel_data = COLOR_TEXT;
    end
    
    // Final pixel data mux
    always @(*) begin
        if (screen_state == 1)
            pixel_data = solver_pixel_data;
        else
            pixel_data = input_pixel_data;
    end

endmodule