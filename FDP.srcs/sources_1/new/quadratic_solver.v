`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: quadratic_solver (With signed coefficient support)
// Description: Displays solutions for quadratic equation ax²+bx+c=0
// Shows integer solutions only to save resources
// Now supports negative coefficients
//////////////////////////////////////////////////////////////////////////////////

module quadratic_solver(
    input clk_6p25M,
    input reset,
    input signed [10:0] coeff_a,  // -999 to 999
    input signed [10:0] coeff_b,  // -999 to 999
    input signed [10:0] coeff_c,  // -999 to 999
    input [12:0] pixel_index,
    output reg [15:0] pixel_data
);

    localparam WIDTH = 96;
    localparam HEIGHT = 64;
    
    reg [6:0] x_pos;
    reg [5:0] y_pos;
    
    always @(*) begin
        x_pos = pixel_index % WIDTH;
        y_pos = pixel_index / WIDTH;
    end
    
    // Colors
    localparam COLOR_BG = 16'h0000;
    localparam COLOR_TEXT = 16'hFFFF;
    localparam COLOR_RESULT = 16'h07FF;
    localparam COLOR_ERROR = 16'hF800;
    
    // Discriminant and solution type
    reg signed [31:0] discriminant;
    reg signed [31:0] b_squared;
    reg signed [31:0] four_ac;
    reg [1:0] solution_type;
    
    always @(posedge clk_6p25M) begin
        if (reset) begin
            discriminant <= 0;
            solution_type <= 0;
            b_squared <= 0;
            four_ac <= 0;
        end else begin
            // Calculate b²
            b_squared <= $signed(coeff_b) * $signed(coeff_b);
            
            // Calculate 4ac
            four_ac <= $signed(4 * coeff_a) * $signed(coeff_c);
            
            // Calculate discriminant: b² - 4ac
            discriminant <= b_squared - four_ac;
            
            // Determine solution type
            if ($signed(coeff_a) == 0) begin
                solution_type <= 0;  // Error: not a quadratic equation
            end else if (discriminant < 0) begin
                solution_type <= 0;  // Imaginary solutions
            end else if (discriminant == 0) begin
                solution_type <= 1;  // One solution (repeated root)
            end else begin
                solution_type <= 2;  // Two distinct real solutions
            end
        end
    end
    
    // Character ROM
    function [4:0] get_char_row;
        input [7:0] char;
        input [2:0] row;
        begin
            case (char)
                "0": case(row) 0: get_char_row=5'b01110; 1: get_char_row=5'b10001; 2: get_char_row=5'b10001; 3: get_char_row=5'b10001; 4: get_char_row=5'b10001; 5: get_char_row=5'b10001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "1": case(row) 0: get_char_row=5'b00100; 1: get_char_row=5'b01100; 2: get_char_row=5'b00100; 3: get_char_row=5'b00100; 4: get_char_row=5'b00100; 5: get_char_row=5'b00100; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "2": case(row) 0: get_char_row=5'b01110; 1: get_char_row=5'b10001; 2: get_char_row=5'b00001; 3: get_char_row=5'b00010; 4: get_char_row=5'b00100; 5: get_char_row=5'b01000; 6: get_char_row=5'b11111; default: get_char_row=5'b00000; endcase
                "S": case(row) 0: get_char_row=5'b01110; 1: get_char_row=5'b10001; 2: get_char_row=5'b10000; 3: get_char_row=5'b01110; 4: get_char_row=5'b00001; 5: get_char_row=5'b10001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "o": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b01110; 3: get_char_row=5'b10001; 4: get_char_row=5'b10001; 5: get_char_row=5'b10001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "l": case(row) 0: get_char_row=5'b01100; 1: get_char_row=5'b00100; 2: get_char_row=5'b00100; 3: get_char_row=5'b00100; 4: get_char_row=5'b00100; 5: get_char_row=5'b00100; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "u": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b10001; 3: get_char_row=5'b10001; 4: get_char_row=5'b10001; 5: get_char_row=5'b10001; 6: get_char_row=5'b01111; default: get_char_row=5'b00000; endcase
                "t": case(row) 0: get_char_row=5'b00100; 1: get_char_row=5'b00100; 2: get_char_row=5'b11111; 3: get_char_row=5'b00100; 4: get_char_row=5'b00100; 5: get_char_row=5'b00100; 6: get_char_row=5'b00011; default: get_char_row=5'b00000; endcase
                "i": case(row) 0: get_char_row=5'b00100; 1: get_char_row=5'b00000; 2: get_char_row=5'b01100; 3: get_char_row=5'b00100; 4: get_char_row=5'b00100; 5: get_char_row=5'b00100; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "n": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b10110; 3: get_char_row=5'b11001; 4: get_char_row=5'b10001; 5: get_char_row=5'b10001; 6: get_char_row=5'b10001; default: get_char_row=5'b00000; endcase
                "s": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b01111; 3: get_char_row=5'b10000; 4: get_char_row=5'b01110; 5: get_char_row=5'b00001; 6: get_char_row=5'b11110; default: get_char_row=5'b00000; endcase
                "I": case(row) 0: get_char_row=5'b01110; 1: get_char_row=5'b00100; 2: get_char_row=5'b00100; 3: get_char_row=5'b00100; 4: get_char_row=5'b00100; 5: get_char_row=5'b00100; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "m": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b11010; 3: get_char_row=5'b10101; 4: get_char_row=5'b10101; 5: get_char_row=5'b10001; 6: get_char_row=5'b10001; default: get_char_row=5'b00000; endcase
                "a": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b01110; 3: get_char_row=5'b00001; 4: get_char_row=5'b01111; 5: get_char_row=5'b10001; 6: get_char_row=5'b01111; default: get_char_row=5'b00000; endcase
                "g": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b01111; 3: get_char_row=5'b10001; 4: get_char_row=5'b01111; 5: get_char_row=5'b00001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                "r": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b10110; 3: get_char_row=5'b11001; 4: get_char_row=5'b10000; 5: get_char_row=5'b10000; 6: get_char_row=5'b10000; default: get_char_row=5'b00000; endcase
                "y": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b00000; 2: get_char_row=5'b10001; 3: get_char_row=5'b10001; 4: get_char_row=5'b01111; 5: get_char_row=5'b00001; 6: get_char_row=5'b01110; default: get_char_row=5'b00000; endcase
                ":": case(row) 0: get_char_row=5'b00000; 1: get_char_row=5'b01100; 2: get_char_row=5'b01100; 3: get_char_row=5'b00000; 4: get_char_row=5'b01100; 5: get_char_row=5'b01100; 6: get_char_row=5'b00000; default: get_char_row=5'b00000; endcase
                " ": get_char_row = 5'b00000;
                default: get_char_row = 5'b00000;
            endcase
        end
    endfunction
    
    // Rendering
    reg is_text_pixel;
    reg [7:0] current_char;
    reg [2:0] char_row, char_col;
    reg [4:0] char_row_data;
    
    always @(*) begin
        pixel_data = COLOR_BG;
        is_text_pixel = 0;
        current_char = " ";
        char_row = 0;
        char_col = 0;
        
        // Title: "Solutions:"
        if (y_pos >= 4 && y_pos <= 10) begin
            char_row = y_pos - 4;
            if (x_pos >= 20 && x_pos < 25) begin current_char = "S"; char_col = x_pos - 20; end
            else if (x_pos >= 25 && x_pos < 30) begin current_char = "o"; char_col = x_pos - 25; end
            else if (x_pos >= 30 && x_pos < 35) begin current_char = "l"; char_col = x_pos - 30; end
            else if (x_pos >= 35 && x_pos < 40) begin current_char = "u"; char_col = x_pos - 35; end
            else if (x_pos >= 40 && x_pos < 45) begin current_char = "t"; char_col = x_pos - 40; end
            else if (x_pos >= 45 && x_pos < 50) begin current_char = "i"; char_col = x_pos - 45; end
            else if (x_pos >= 50 && x_pos < 55) begin current_char = "o"; char_col = x_pos - 50; end
            else if (x_pos >= 55 && x_pos < 60) begin current_char = "n"; char_col = x_pos - 55; end
            else if (x_pos >= 60 && x_pos < 65) begin current_char = "s"; char_col = x_pos - 60; end
            else if (x_pos >= 65 && x_pos < 70) begin current_char = ":"; char_col = x_pos - 65; end
            
            char_row_data = get_char_row(current_char, char_row);
            if (char_col < 5 && char_row_data[4-char_col])
                is_text_pixel = 1;
        end
        
        // Display result based on solution type
        case (solution_type)
            2'd0: begin  // Imaginary or Error
                if (y_pos >= 28 && y_pos <= 34) begin
                    char_row = y_pos - 28;
                    if (x_pos >= 18 && x_pos < 23) begin current_char = "I"; char_col = x_pos - 18; end
                    else if (x_pos >= 23 && x_pos < 28) begin current_char = "m"; char_col = x_pos - 23; end
                    else if (x_pos >= 28 && x_pos < 33) begin current_char = "a"; char_col = x_pos - 28; end
                    else if (x_pos >= 33 && x_pos < 38) begin current_char = "g"; char_col = x_pos - 33; end
                    else if (x_pos >= 38 && x_pos < 43) begin current_char = "i"; char_col = x_pos - 38; end
                    else if (x_pos >= 43 && x_pos < 48) begin current_char = "n"; char_col = x_pos - 43; end
                    else if (x_pos >= 48 && x_pos < 53) begin current_char = "a"; char_col = x_pos - 48; end
                    else if (x_pos >= 53 && x_pos < 58) begin current_char = "r"; char_col = x_pos - 53; end
                    else if (x_pos >= 58 && x_pos < 63) begin current_char = "y"; char_col = x_pos - 58; end
                    char_row_data = get_char_row(current_char, char_row);
                    if (char_col < 5 && char_row_data[4-char_col])
                        is_text_pixel = 1;
                end
            end
            
            2'd1: begin  // One solution (repeated root)
                if (y_pos >= 28 && y_pos <= 34) begin
                    char_row = y_pos - 28;
                    if (x_pos >= 28 && x_pos < 33) begin current_char = "1"; char_col = x_pos - 28; end
                    else if (x_pos >= 38 && x_pos < 43) begin current_char = "s"; char_col = x_pos - 38; end
                    else if (x_pos >= 43 && x_pos < 48) begin current_char = "o"; char_col = x_pos - 43; end
                    else if (x_pos >= 48 && x_pos < 53) begin current_char = "l"; char_col = x_pos - 48; end
                    else if (x_pos >= 53 && x_pos < 58) begin current_char = "u"; char_col = x_pos - 53; end
                    else if (x_pos >= 58 && x_pos < 63) begin current_char = "t"; char_col = x_pos - 58; end
                    else if (x_pos >= 63 && x_pos < 68) begin current_char = "i"; char_col = x_pos - 63; end
                    else if (x_pos >= 68 && x_pos < 73) begin current_char = "o"; char_col = x_pos - 68; end
                    else if (x_pos >= 73 && x_pos < 78) begin current_char = "n"; char_col = x_pos - 73; end
                    char_row_data = get_char_row(current_char, char_row);
                    if (char_col < 5 && char_row_data[4-char_col])
                        is_text_pixel = 1;
                end
            end
            
            2'd2: begin  // Two distinct real solutions
                if (y_pos >= 28 && y_pos <= 34) begin
                    char_row = y_pos - 28;
                    if (x_pos >= 24 && x_pos < 29) begin current_char = "2"; char_col = x_pos - 24; end
                    else if (x_pos >= 34 && x_pos < 39) begin current_char = "s"; char_col = x_pos - 34; end
                    else if (x_pos >= 39 && x_pos < 44) begin current_char = "o"; char_col = x_pos - 39; end
                    else if (x_pos >= 44 && x_pos < 49) begin current_char = "l"; char_col = x_pos - 44; end
                    else if (x_pos >= 49 && x_pos < 54) begin current_char = "u"; char_col = x_pos - 49; end
                    else if (x_pos >= 54 && x_pos < 59) begin current_char = "t"; char_col = x_pos - 54; end
                    else if (x_pos >= 59 && x_pos < 64) begin current_char = "i"; char_col = x_pos - 59; end
                    else if (x_pos >= 64 && x_pos < 69) begin current_char = "o"; char_col = x_pos - 64; end
                    else if (x_pos >= 69 && x_pos < 74) begin current_char = "n"; char_col = x_pos - 69; end
                    else if (x_pos >= 74 && x_pos < 79) begin current_char = "s"; char_col = x_pos - 74; end
                    char_row_data = get_char_row(current_char, char_row);
                    if (char_col < 5 && char_row_data[4-char_col])
                        is_text_pixel = 1;
                end
            end
        endcase
        
        if (is_text_pixel) begin
            if (solution_type == 0)
                pixel_data = COLOR_ERROR;
            else
                pixel_data = COLOR_RESULT;
        end
    end

endmodule