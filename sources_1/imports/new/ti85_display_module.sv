`timescale 1ns / 1ps

module ti85_display_module (
    input freq625m,
    input [12:0] pixel_index,                 // From OLED driver (0 to 6143)
    output reg [15:0] pixel_data              // RGB565 output to OLED
);
    localparam Width = 96;
    localparam Height = 64;
    
    // Text positioning - centered on screen
    // "TI85" is 4 chars * 6 pixels = 24 pixels wide
    // Center: (96 - 24) / 2 = 36
    localparam TI85_X_START = 36;
    localparam TI85_Y_START = 24;  // Centered vertically
    
    // "Graphing" is 8 chars * 6 pixels = 48 pixels wide
    // Center: (96 - 48) / 2 = 24
    localparam GRAPHING_X_START = 24;
    localparam GRAPHING_Y_START = 35;  // Below TI85
    
    wire [6:0] x = pixel_index % Width;
    wire [5:0] y = pixel_index / Width;
    
    // Font bitmap storage (5x7 font)
    reg [4:0] font_row;
    reg is_text_pixel;
    
    // 5x7 font data for characters T, I, 8, 5, G, R, A, P, H, N
    function [4:0] get_char_row(input [7:0] char_code, input [2:0] row);
        case (char_code)
            // 'T'
            8'd84: case(row)
                0: get_char_row = 5'b11111;
                1: get_char_row = 5'b00100;
                2: get_char_row = 5'b00100;
                3: get_char_row = 5'b00100;
                4: get_char_row = 5'b00100;
                5: get_char_row = 5'b00100;
                6: get_char_row = 5'b00100;
                default: get_char_row = 5'b00000;
            endcase
            
            // 'I'
            8'd73: case(row)
                0: get_char_row = 5'b11111;
                1: get_char_row = 5'b00100;
                2: get_char_row = 5'b00100;
                3: get_char_row = 5'b00100;
                4: get_char_row = 5'b00100;
                5: get_char_row = 5'b00100;
                6: get_char_row = 5'b11111;
                default: get_char_row = 5'b00000;
            endcase
            
            // '8'
            8'd56: case(row)
                0: get_char_row = 5'b01110;
                1: get_char_row = 5'b10001;
                2: get_char_row = 5'b10001;
                3: get_char_row = 5'b01110;
                4: get_char_row = 5'b10001;
                5: get_char_row = 5'b10001;
                6: get_char_row = 5'b01110;
                default: get_char_row = 5'b00000;
            endcase
            
            // '5'
            8'd53: case(row)
                0: get_char_row = 5'b11111;
                1: get_char_row = 5'b10000;
                2: get_char_row = 5'b10000;
                3: get_char_row = 5'b11110;
                4: get_char_row = 5'b00001;
                5: get_char_row = 5'b00001;
                6: get_char_row = 5'b11110;
                default: get_char_row = 5'b00000;
            endcase
            
            // 'G'
            8'd71: case(row)
                0: get_char_row = 5'b01110;
                1: get_char_row = 5'b10001;
                2: get_char_row = 5'b10000;
                3: get_char_row = 5'b10111;
                4: get_char_row = 5'b10001;
                5: get_char_row = 5'b10001;
                6: get_char_row = 5'b01110;
                default: get_char_row = 5'b00000;
            endcase
            
            // 'R'
            8'd82: case(row)
                0: get_char_row = 5'b11110;
                1: get_char_row = 5'b10001;
                2: get_char_row = 5'b10001;
                3: get_char_row = 5'b11110;
                4: get_char_row = 5'b10010;
                5: get_char_row = 5'b10001;
                6: get_char_row = 5'b10001;
                default: get_char_row = 5'b00000;
            endcase
            
            // 'A'
            8'd65: case(row)
                0: get_char_row = 5'b01110;
                1: get_char_row = 5'b10001;
                2: get_char_row = 5'b10001;
                3: get_char_row = 5'b11111;
                4: get_char_row = 5'b10001;
                5: get_char_row = 5'b10001;
                6: get_char_row = 5'b10001;
                default: get_char_row = 5'b00000;
            endcase
            
            // 'P'
            8'd80: case(row)
                0: get_char_row = 5'b11110;
                1: get_char_row = 5'b10001;
                2: get_char_row = 5'b10001;
                3: get_char_row = 5'b11110;
                4: get_char_row = 5'b10000;
                5: get_char_row = 5'b10000;
                6: get_char_row = 5'b10000;
                default: get_char_row = 5'b00000;
            endcase
            
            // 'H'
            8'd72: case(row)
                0: get_char_row = 5'b10001;
                1: get_char_row = 5'b10001;
                2: get_char_row = 5'b10001;
                3: get_char_row = 5'b11111;
                4: get_char_row = 5'b10001;
                5: get_char_row = 5'b10001;
                6: get_char_row = 5'b10001;
                default: get_char_row = 5'b00000;
            endcase
            
            // 'N'
            8'd78: case(row)
                0: get_char_row = 5'b10001;
                1: get_char_row = 5'b11001;
                2: get_char_row = 5'b10101;
                3: get_char_row = 5'b10011;
                4: get_char_row = 5'b10001;
                5: get_char_row = 5'b10001;
                6: get_char_row = 5'b10001;
                default: get_char_row = 5'b00000;
            endcase
            
            default: get_char_row = 5'b00000;
        endcase
    endfunction
    
    // Check if current pixel is part of text
    function is_pixel_in_text(input [6:0] px, input [5:0] py);
        reg [6:0] rel_x;
        reg [5:0] rel_y;
        reg [2:0] char_idx;
        reg [2:0] col_idx;
        reg [7:0] char_code;
        
        begin
            is_pixel_in_text = 0;
            
            // Check "TI85" text
            if (py >= TI85_Y_START && py < TI85_Y_START + 7) begin
                rel_y = py - TI85_Y_START;
                // Each char is 6 pixels wide (5 + 1 spacing)
                if (px >= TI85_X_START && px < TI85_X_START + 24) begin
                    rel_x = px - TI85_X_START;
                    char_idx = rel_x / 6;
                    col_idx = rel_x % 6;
                    
                    if (col_idx < 5) begin
                        case (char_idx)
                            0: char_code = 8'd84; // 'T'
                            1: char_code = 8'd73; // 'I'
                            2: char_code = 8'd56; // '8'
                            3: char_code = 8'd53; // '5'
                            default: char_code = 8'd0;
                        endcase
                        
                        font_row = get_char_row(char_code, rel_y);
                        is_pixel_in_text = font_row[4 - col_idx];
                    end
                end
            end
            
            // Check "Graphing" text
            else if (py >= GRAPHING_Y_START && py < GRAPHING_Y_START + 7) begin
                rel_y = py - GRAPHING_Y_START;
                if (px >= GRAPHING_X_START && px < GRAPHING_X_START + 48) begin
                    rel_x = px - GRAPHING_X_START;
                    char_idx = rel_x / 6;
                    col_idx = rel_x % 6;
                    
                    if (col_idx < 5) begin
                        case (char_idx)
                            0: char_code = 8'd71; // 'G'
                            1: char_code = 8'd82; // 'R'
                            2: char_code = 8'd65; // 'A'
                            3: char_code = 8'd80; // 'P'
                            4: char_code = 8'd72; // 'H'
                            5: char_code = 8'd73; // 'I'
                            6: char_code = 8'd78; // 'N'
                            7: char_code = 8'd71; // 'G'
                            default: char_code = 8'd0;
                        endcase
                        
                        font_row = get_char_row(char_code, rel_y);
                        is_pixel_in_text = font_row[4 - col_idx];
                    end
                end
            end
        end
    endfunction
    
    always @(posedge freq625m) begin
        // Check if pixel is part of text
        is_text_pixel = is_pixel_in_text(x, y);
        
        if (is_text_pixel) begin
            pixel_data <= 16'b11111_111111_11111; // white text
        end else begin
            pixel_data <= 16'h0000; // black background
        end
    end
endmodule

module pixel_output_generator (
    input freq625m,
    input [12:0] pixel_index,
    output reg [15:0] pixel_data
);
    localparam Width = 96;
    localparam Height = 64;
    
    wire [6:0] x = pixel_index % Width;
    wire [5:0] y = pixel_index / Width;
    
    // Text positioning - centered on screen
    // "press any button" is 16 chars * 6 pixels = 96 pixels wide (full width)
    localparam LINE1_X_START = 0;
    localparam LINE1_Y_START = 24;  // Centered vertically
    
    // "to continue" is 11 chars * 6 pixels = 66 pixels wide
    // Center: (96 - 66) / 2 = 15
    localparam LINE2_X_START = 15;
    localparam LINE2_Y_START = 35;  // Below line 1
    
    // 5x7 font bitmap - each character is 5 bits wide, 7 rows tall
    function [4:0] get_char_bitmap;
        input [7:0] ascii;
        input [2:0] row;
        case (ascii)
            "p": case(row)
                0: get_char_bitmap = 5'b11110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b11110;
                4: get_char_bitmap = 5'b10000;
                5: get_char_bitmap = 5'b10000;
                6: get_char_bitmap = 5'b10000;
            endcase
            "r": case(row)
                0: get_char_bitmap = 5'b11110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b11110;
                4: get_char_bitmap = 5'b10010;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b10001;
            endcase
            "e": case(row)
                0: get_char_bitmap = 5'b11111;
                1: get_char_bitmap = 5'b10000;
                2: get_char_bitmap = 5'b10000;
                3: get_char_bitmap = 5'b11110;
                4: get_char_bitmap = 5'b10000;
                5: get_char_bitmap = 5'b10000;
                6: get_char_bitmap = 5'b11111;
            endcase
            "s": case(row)
                0: get_char_bitmap = 5'b01111;
                1: get_char_bitmap = 5'b10000;
                2: get_char_bitmap = 5'b10000;
                3: get_char_bitmap = 5'b01110;
                4: get_char_bitmap = 5'b00001;
                5: get_char_bitmap = 5'b00001;
                6: get_char_bitmap = 5'b11110;
            endcase
            "a": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b11111;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b10001;
            endcase
            "n": case(row)
                0: get_char_bitmap = 5'b10001;
                1: get_char_bitmap = 5'b11001;
                2: get_char_bitmap = 5'b10101;
                3: get_char_bitmap = 5'b10011;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b10001;
            endcase
            "y": case(row)
                0: get_char_bitmap = 5'b10001;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b01110;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b00100;
            endcase
            "b": case(row)
                0: get_char_bitmap = 5'b11110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b11110;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b11110;
            endcase
            "u": case(row)
                0: get_char_bitmap = 5'b10001;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b10001;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "t": case(row)
                0: get_char_bitmap = 5'b11111;
                1: get_char_bitmap = 5'b00100;
                2: get_char_bitmap = 5'b00100;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b00100;
            endcase
            "o": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b10001;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "c": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10000;
                3: get_char_bitmap = 5'b10000;
                4: get_char_bitmap = 5'b10000;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "i": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b00100;
                2: get_char_bitmap = 5'b00100;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b01110;
            endcase
            " ": get_char_bitmap = 5'b00000; // space
            default: get_char_bitmap = 5'b00000;
        endcase
    endfunction
    
    // Text strings stored as character arrays
    function [7:0] get_line1_char;
        input [3:0] pos;
        case (pos)
            0: get_line1_char = "p";
            1: get_line1_char = "r";
            2: get_line1_char = "e";
            3: get_line1_char = "s";
            4: get_line1_char = "s";
            5: get_line1_char = " ";
            6: get_line1_char = "a";
            7: get_line1_char = "n";
            8: get_line1_char = "y";
            9: get_line1_char = " ";
            10: get_line1_char = "b";
            11: get_line1_char = "u";
            12: get_line1_char = "t";
            13: get_line1_char = "t";
            14: get_line1_char = "o";
            15: get_line1_char = "n";
            default: get_line1_char = " ";
        endcase
    endfunction
    
    function [7:0] get_line2_char;
        input [3:0] pos;
        case (pos)
            0: get_line2_char = "t";
            1: get_line2_char = "o";
            2: get_line2_char = " ";
            3: get_line2_char = "c";
            4: get_line2_char = "o";
            5: get_line2_char = "n";
            6: get_line2_char = "t";
            7: get_line2_char = "i";
            8: get_line2_char = "n";
            9: get_line2_char = "u";
            10: get_line2_char = "e";
            default: get_line2_char = " ";
        endcase
    endfunction
    
    // Check if current pixel is part of text
    function is_pixel_in_text;
        input [6:0] px;
        input [5:0] py;
        reg [6:0] rel_x;
        reg [5:0] rel_y;
        reg [3:0] char_idx;
        reg [2:0] col_idx;
        reg [7:0] char_code;
        reg [4:0] font_row;
        
        begin
            is_pixel_in_text = 0;
            
            // Check line 1: "press any button"
            if (py >= LINE1_Y_START && py < LINE1_Y_START + 7) begin
                rel_y = py - LINE1_Y_START;
                if (px >= LINE1_X_START && px < LINE1_X_START + 96) begin
                    rel_x = px - LINE1_X_START;
                    char_idx = rel_x / 6;  // 6 pixels per char
                    col_idx = rel_x % 6;
                    
                    if (col_idx < 5 && char_idx < 16) begin
                        char_code = get_line1_char(char_idx);
                        font_row = get_char_bitmap(char_code, rel_y);
                        is_pixel_in_text = font_row[4 - col_idx];
                    end
                end
            end
            
            // Check line 2: "to continue"
            else if (py >= LINE2_Y_START && py < LINE2_Y_START + 7) begin
                rel_y = py - LINE2_Y_START;
                if (px >= LINE2_X_START && px < LINE2_X_START + 66) begin
                    rel_x = px - LINE2_X_START;
                    char_idx = rel_x / 6;
                    col_idx = rel_x % 6;
                    
                    if (col_idx < 5 && char_idx < 11) begin
                        char_code = get_line2_char(char_idx);
                        font_row = get_char_bitmap(char_code, rel_y);
                        is_pixel_in_text = font_row[4 - col_idx];
                    end
                end
            end
        end
    endfunction
    
    always @(posedge freq625m) begin
        if (is_pixel_in_text(x, y)) begin
            pixel_data <= 16'b11111_111111_11111; // white text
        end else begin
            pixel_data <= 16'h0000; // black background
        end
    end
endmodule

module pixel_output_state_graph_menu (
    input freq625m,
    input cursor_pos,           // 0 for row 1, 1 for row 2
    input [1:0] graph1_type,    // 00=polynomial, 01=cosine, 10=sine
    input [1:0] graph2_type,    // 00=polynomial, 01=cosine, 10=sine
    input [12:0] pixel_index,
    output reg [15:0] pixel_data
);
    localparam Width = 96;
    localparam Height = 64;
    
    wire [6:0] x = pixel_index % Width;
    wire [5:0] y = pixel_index / Width;
    
    // 5x7 font bitmap
    function [4:0] get_char_bitmap;
        input [7:0] ascii;
        input [2:0] row;
        case (ascii)
            "T": case(row)
                0: get_char_bitmap = 5'b11111;
                1: get_char_bitmap = 5'b00100;
                2: get_char_bitmap = 5'b00100;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b00100;
            endcase
            "I": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b00100;
                2: get_char_bitmap = 5'b00100;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b01110;
            endcase
            "8": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b01110;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "5": case(row)
                0: get_char_bitmap = 5'b11111;
                1: get_char_bitmap = 5'b10000;
                2: get_char_bitmap = 5'b10000;
                3: get_char_bitmap = 5'b11110;
                4: get_char_bitmap = 5'b00001;
                5: get_char_bitmap = 5'b00001;
                6: get_char_bitmap = 5'b11110;
            endcase
            "G": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10000;
                3: get_char_bitmap = 5'b10111;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "r": case(row)
                0: get_char_bitmap = 5'b01011;
                1: get_char_bitmap = 5'b01100;
                2: get_char_bitmap = 5'b01000;
                3: get_char_bitmap = 5'b01000;
                4: get_char_bitmap = 5'b01000;
                5: get_char_bitmap = 5'b01000;
                6: get_char_bitmap = 5'b01000;
            endcase
            "a": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b01110;
                2: get_char_bitmap = 5'b00001;
                3: get_char_bitmap = 5'b01111;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01111;
            endcase
            "p": case(row)
                0: get_char_bitmap = 5'b11110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b11110;
                4: get_char_bitmap = 5'b10000;
                5: get_char_bitmap = 5'b10000;
                6: get_char_bitmap = 5'b10000;
            endcase
            "h": case(row)
                0: get_char_bitmap = 5'b10000;
                1: get_char_bitmap = 5'b10000;
                2: get_char_bitmap = 5'b10110;
                3: get_char_bitmap = 5'b11001;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b10001;
            endcase
            "i": case(row)
                0: get_char_bitmap = 5'b00100;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01100;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b01110;
            endcase
            "n": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b10110;
                3: get_char_bitmap = 5'b11001;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b10001;
            endcase
            "g": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b01111;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b10001;
                4: get_char_bitmap = 5'b01111;
                5: get_char_bitmap = 5'b00001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "o": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b10001;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "l": case(row)
                0: get_char_bitmap = 5'b01100;
                1: get_char_bitmap = 5'b00100;
                2: get_char_bitmap = 5'b00100;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b01110;
            endcase
            "y": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b10001;
                4: get_char_bitmap = 5'b01111;
                5: get_char_bitmap = 5'b00001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "m": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b11010;
                3: get_char_bitmap = 5'b10101;
                4: get_char_bitmap = 5'b10101;
                5: get_char_bitmap = 5'b10101;
                6: get_char_bitmap = 5'b10101;
            endcase
            "c": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b10000;
                4: get_char_bitmap = 5'b10000;
                5: get_char_bitmap = 5'b10000;
                6: get_char_bitmap = 5'b01110;
            endcase
            "s": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b10000;
                4: get_char_bitmap = 5'b01110;
                5: get_char_bitmap = 5'b00001;
                6: get_char_bitmap = 5'b11110;
            endcase
            "e": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b10001;
                4: get_char_bitmap = 5'b11111;
                5: get_char_bitmap = 5'b10000;
                6: get_char_bitmap = 5'b01110;
            endcase
            "<": case(row)
                0: get_char_bitmap = 5'b00010;
                1: get_char_bitmap = 5'b00100;
                2: get_char_bitmap = 5'b01000;
                3: get_char_bitmap = 5'b10000;
                4: get_char_bitmap = 5'b01000;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b00010;
            endcase
            ">": case(row)
                0: get_char_bitmap = 5'b10000;
                1: get_char_bitmap = 5'b01000;
                2: get_char_bitmap = 5'b00100;
                3: get_char_bitmap = 5'b00010;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b01000;
                6: get_char_bitmap = 5'b10000;
            endcase
            " ": get_char_bitmap = 5'b00000;
            default: get_char_bitmap = 5'b00000;
        endcase
    endfunction
    
    // Title text: "TI85 Graphing" - 13 chars * 6 = 78 pixels, centered at x=9
    function [7:0] get_title_char;
        input [3:0] char_pos;
        case (char_pos)
            0: get_title_char = "T";
            1: get_title_char = "I";
            2: get_title_char = "8";
            3: get_title_char = "5";
            4: get_title_char = " ";
            5: get_title_char = "G";
            6: get_title_char = "r";
            7: get_title_char = "a";
            8: get_title_char = "p";
            9: get_title_char = "h";
            10: get_title_char = "i";
            11: get_title_char = "n";
            12: get_title_char = "g";
            default: get_title_char = " ";
        endcase
    endfunction
    
    // Get menu option text based on graph type
    function [7:0] get_option_char;
        input [1:0] graph_type;
        input [3:0] char_pos;
        reg [7:0] result;
        begin
            case (graph_type)
                2'b00: begin // polynomial - 10 chars
                    case (char_pos)
                        0: result = "p";
                        1: result = "o";
                        2: result = "l";
                        3: result = "y";
                        4: result = "n";
                        5: result = "o";
                        6: result = "m";
                        7: result = "i";
                        8: result = "a";
                        9: result = "l";
                        default: result = " ";
                    endcase
                end
                2'b01: begin // cosine - 6 chars
                    case (char_pos)
                        0: result = "c";
                        1: result = "o";
                        2: result = "s";
                        3: result = "i";
                        4: result = "n";
                        5: result = "e";
                        default: result = " ";
                    endcase
                end
                2'b10: begin // sine - 4 chars
                    case (char_pos)
                        0: result = "s";
                        1: result = "i";
                        2: result = "n";
                        3: result = "e";
                        default: result = " ";
                    endcase
                end
                default: result = " ";
            endcase
            get_option_char = result;
        end
    endfunction
    
    // Get the max length for each type (for centering)
    function [3:0] get_option_length;
        input [1:0] graph_type;
        case (graph_type)
            2'b00: get_option_length = 10; // polynomial
            2'b01: get_option_length = 6;  // cosine
            2'b10: get_option_length = 4;  // sine
            default: get_option_length = 0;
        endcase
    endfunction
    
    // Convert RGB to RGB565
    function [15:0] rgb_to_rgb565;
        input [2:0] rgb;
        case (rgb)
            3'b000: rgb_to_rgb565 = 16'b00000_000000_00000; // black
            3'b100: rgb_to_rgb565 = 16'b11111_111111_11111; // white
            3'b010: rgb_to_rgb565 = 16'b11111_111111_00000; // yellow (highlight)
            default: rgb_to_rgb565 = 16'b00000_000000_00000;
        endcase
    endfunction
    
    localparam TitleY = 4;
    localparam Row1Y = 24;
    localparam Row2Y = 40;
    localparam CharWidth = 6;
    localparam TitleStartX = 9;  // Centered for 13 chars
    
    reg is_text_pixel;
    reg [3:0] char_index;
    reg [2:0] row_in_char;
    reg [2:0] col_in_char;
    reg [4:0] char_row_bitmap;
    reg [7:0] current_char;
    reg is_highlighted;
    reg [3:0] option_length;
    reg [6:0] option_start_x;
    
    always @(*) begin
        is_text_pixel = 0;
        is_highlighted = 0;
        
        // Title: "TI85 Graphing"
        if (y >= TitleY && y < TitleY + 7) begin
            row_in_char = y - TitleY;
            if (x >= TitleStartX && x < TitleStartX + 13 * CharWidth) begin
                char_index = (x - TitleStartX) / CharWidth;
                col_in_char = (x - TitleStartX) % CharWidth;
                if (col_in_char < 5 && char_index < 13) begin
                    current_char = get_title_char(char_index);
                    char_row_bitmap = get_char_bitmap(current_char, row_in_char);
                    is_text_pixel = char_row_bitmap[4 - col_in_char];
                end
            end
        end
        
        // Row 1: << [option] >>
        if (y >= Row1Y && y < Row1Y + 7) begin
            row_in_char = y - Row1Y;
            is_highlighted = (cursor_pos == 0);
            
            // Calculate centered position for option text
            option_length = get_option_length(graph1_type);
            // Total width = 2 (<<) + 1 (space) + option_length + 1 (space) + 2 (>>) = option_length + 6
            // Centered: (96 - (option_length + 6) * 6) / 2
            option_start_x = (96 - (option_length + 6) * CharWidth) / 2;
            
            if (x >= option_start_x && x < option_start_x + (option_length + 6) * CharWidth) begin
                char_index = (x - option_start_x) / CharWidth;
                col_in_char = (x - option_start_x) % CharWidth;
                
                if (col_in_char < 5) begin
                    if (char_index == 0) current_char = "<";
                    else if (char_index == 1) current_char = "<";
                    else if (char_index == 2) current_char = " ";
                    else if (char_index < 3 + option_length) current_char = get_option_char(graph1_type, char_index - 3);
                    else if (char_index == 3 + option_length) current_char = " ";
                    else if (char_index == 4 + option_length) current_char = ">";
                    else if (char_index == 5 + option_length) current_char = ">";
                    else current_char = " ";
                    
                    char_row_bitmap = get_char_bitmap(current_char, row_in_char);
                    is_text_pixel = char_row_bitmap[4 - col_in_char];
                end
            end
        end
        
        // Row 2: << [option] >>
        if (y >= Row2Y && y < Row2Y + 7) begin
            row_in_char = y - Row2Y;
            is_highlighted = (cursor_pos == 1);
            
            option_length = get_option_length(graph2_type);
            option_start_x = (96 - (option_length + 6) * CharWidth) / 2;
            
            if (x >= option_start_x && x < option_start_x + (option_length + 6) * CharWidth) begin
                char_index = (x - option_start_x) / CharWidth;
                col_in_char = (x - option_start_x) % CharWidth;
                
                if (col_in_char < 5) begin
                    if (char_index == 0) current_char = "<";
                    else if (char_index == 1) current_char = "<";
                    else if (char_index == 2) current_char = " ";
                    else if (char_index < 3 + option_length) current_char = get_option_char(graph2_type, char_index - 3);
                    else if (char_index == 3 + option_length) current_char = " ";
                    else if (char_index == 4 + option_length) current_char = ">";
                    else if (char_index == 5 + option_length) current_char = ">";
                    else current_char = " ";
                    
                    char_row_bitmap = get_char_bitmap(current_char, row_in_char);
                    is_text_pixel = char_row_bitmap[4 - col_in_char];
                end
            end
        end
    end
    
    always @(posedge freq625m) begin
        // Default to black
        pixel_data <= 16'h0000;
        
        // Render text
        if (is_text_pixel) begin
            if (is_highlighted)
                pixel_data <= rgb_to_rgb565(3'b010); // yellow for highlighted
            else
                pixel_data <= rgb_to_rgb565(3'b100); // white for normal
        end
    end
endmodule

module confirmation_screen (
    input freq625m,
    input [12:0] pixel_index,
    output reg [15:0] pixel_data
);
    localparam Width = 96;
    localparam Height = 64;
    
    wire [6:0] x = pixel_index % Width;
    wire [5:0] y = pixel_index / Width;
    
    // 5x7 font bitmap
    function [4:0] get_char_bitmap;
        input [7:0] ascii;
        input [2:0] row;
        case (ascii)
            "a": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b00001;
                4: get_char_bitmap = 5'b01111;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01111;
            endcase
            "c": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b10000;
                4: get_char_bitmap = 5'b10000;
                5: get_char_bitmap = 5'b10000;
                6: get_char_bitmap = 5'b01110;
            endcase
            "h": case(row)
                0: get_char_bitmap = 5'b10000;
                1: get_char_bitmap = 5'b10000;
                2: get_char_bitmap = 5'b10110;
                3: get_char_bitmap = 5'b11001;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b10001;
            endcase
            "o": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b10001;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "i": case(row)
                0: get_char_bitmap = 5'b00100;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01100;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b01110;
            endcase
            "e": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b10001;
                4: get_char_bitmap = 5'b11111;
                5: get_char_bitmap = 5'b10000;
                6: get_char_bitmap = 5'b01110;
            endcase
            "s": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b10000;
                4: get_char_bitmap = 5'b01110;
                5: get_char_bitmap = 5'b00001;
                6: get_char_bitmap = 5'b11110;
            endcase
            "n": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b10110;
                3: get_char_bitmap = 5'b11001;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b10001;
            endcase
            "f": case(row)
                0: get_char_bitmap = 5'b00110;
                1: get_char_bitmap = 5'b01001;
                2: get_char_bitmap = 5'b01000;
                3: get_char_bitmap = 5'b11110;
                4: get_char_bitmap = 5'b01000;
                5: get_char_bitmap = 5'b01000;
                6: get_char_bitmap = 5'b01000;
            endcase
            "r": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b10110;
                3: get_char_bitmap = 5'b11001;
                4: get_char_bitmap = 5'b10000;
                5: get_char_bitmap = 5'b10000;
                6: get_char_bitmap = 5'b10000;
            endcase
            "m": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b11010;
                3: get_char_bitmap = 5'b10101;
                4: get_char_bitmap = 5'b10101;
                5: get_char_bitmap = 5'b10101;
                6: get_char_bitmap = 5'b10101;
            endcase
            "d": case(row)
                0: get_char_bitmap = 5'b00001;
                1: get_char_bitmap = 5'b00001;
                2: get_char_bitmap = 5'b01101;
                3: get_char_bitmap = 5'b10011;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01111;
            endcase
            "p": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b11110;
                3: get_char_bitmap = 5'b10001;
                4: get_char_bitmap = 5'b11110;
                5: get_char_bitmap = 5'b10000;
                6: get_char_bitmap = 5'b10000;
            endcase
            "b": case(row)
                0: get_char_bitmap = 5'b10000;
                1: get_char_bitmap = 5'b10000;
                2: get_char_bitmap = 5'b10110;
                3: get_char_bitmap = 5'b11001;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b11110;
            endcase
            "t": case(row)
                0: get_char_bitmap = 5'b00100;
                1: get_char_bitmap = 5'b00100;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b00011;
            endcase
            "C": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10000;
                3: get_char_bitmap = 5'b10000;
                4: get_char_bitmap = 5'b10000;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "u": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b10001;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01111;
            endcase
            " ": get_char_bitmap = 5'b00000;
            default: get_char_bitmap = 5'b00000;
        endcase
    endfunction
    
    // Line 1: "once choices" (12 chars)
    function [7:0] get_line1_char;
        input [4:0] char_pos;
        case (char_pos)
            0: get_line1_char = "o";
            1: get_line1_char = "n";
            2: get_line1_char = "c";
            3: get_line1_char = "e";
            4: get_line1_char = " ";
            5: get_line1_char = "c";
            6: get_line1_char = "h";
            7: get_line1_char = "o";
            8: get_line1_char = "i";
            9: get_line1_char = "c";
            10: get_line1_char = "e";
            11: get_line1_char = "s";
            default: get_line1_char = " ";
        endcase
    endfunction
    
    // Line 2: "are confirmed" (13 chars)
    function [7:0] get_line2_char;
        input [4:0] char_pos;
        case (char_pos)
            0: get_line2_char = "a";
            1: get_line2_char = "r";
            2: get_line2_char = "e";
            3: get_line2_char = " ";
            4: get_line2_char = "c";
            5: get_line2_char = "o";
            6: get_line2_char = "n";
            7: get_line2_char = "f";
            8: get_line2_char = "i";
            9: get_line2_char = "r";
            10: get_line2_char = "m";
            11: get_line2_char = "e";
            12: get_line2_char = "d";
            default: get_line2_char = " ";
        endcase
    endfunction
    
    // Line 3: "press btnC to" (13 chars)
    function [7:0] get_line3_char;
        input [4:0] char_pos;
        case (char_pos)
            0: get_line3_char = "p";
            1: get_line3_char = "r";
            2: get_line3_char = "e";
            3: get_line3_char = "s";
            4: get_line3_char = "s";
            5: get_line3_char = " ";
            6: get_line3_char = "b";
            7: get_line3_char = "t";
            8: get_line3_char = "n";
            9: get_line3_char = "C";
            10: get_line3_char = " ";
            11: get_line3_char = "t";
            12: get_line3_char = "o";
            default: get_line3_char = " ";
        endcase
    endfunction
    
    // Line 4: "continue" (8 chars)
    function [7:0] get_line4_char;
        input [4:0] char_pos;
        case (char_pos)
            0: get_line4_char = "c";
            1: get_line4_char = "o";
            2: get_line4_char = "n";
            3: get_line4_char = "t";
            4: get_line4_char = "i";
            5: get_line4_char = "n";
            6: get_line4_char = "u";
            7: get_line4_char = "e";
            default: get_line4_char = " ";
        endcase
    endfunction
    
    localparam Line1Y = 12;
    localparam Line2Y = 23;
    localparam Line3Y = 34;
    localparam Line4Y = 45;
    localparam CharWidth = 6;
    
    // Line 1: 12 chars * 6 = 72, center at (96-72)/2 = 12
    localparam Line1StartX = 12;
    // Line 2: 13 chars * 6 = 78, center at (96-78)/2 = 9
    localparam Line2StartX = 9;
    // Line 3: 13 chars * 6 = 78, center at (96-78)/2 = 9
    localparam Line3StartX = 9;
    // Line 4: 8 chars * 6 = 48, center at (96-48)/2 = 24
    localparam Line4StartX = 24;
    
    reg is_text_pixel;
    reg [4:0] char_index;
    reg [2:0] row_in_char;
    reg [2:0] col_in_char;
    reg [4:0] char_row_bitmap;
    reg [7:0] current_char;
    
    always @(*) begin
        is_text_pixel = 0;
        
        // Line 1: "once choices"
        if (y >= Line1Y && y < Line1Y + 7) begin
            row_in_char = y - Line1Y;
            if (x >= Line1StartX && x < Line1StartX + 12 * CharWidth) begin
                char_index = (x - Line1StartX) / CharWidth;
                col_in_char = (x - Line1StartX) % CharWidth;
                if (col_in_char < 5 && char_index < 12) begin
                    current_char = get_line1_char(char_index);
                    char_row_bitmap = get_char_bitmap(current_char, row_in_char);
                    is_text_pixel = char_row_bitmap[4 - col_in_char];
                end
            end
        end
        
        // Line 2: "are confirmed"
        if (y >= Line2Y && y < Line2Y + 7) begin
            row_in_char = y - Line2Y;
            if (x >= Line2StartX && x < Line2StartX + 13 * CharWidth) begin
                char_index = (x - Line2StartX) / CharWidth;
                col_in_char = (x - Line2StartX) % CharWidth;
                if (col_in_char < 5 && char_index < 13) begin
                    current_char = get_line2_char(char_index);
                    char_row_bitmap = get_char_bitmap(current_char, row_in_char);
                    is_text_pixel = char_row_bitmap[4 - col_in_char];
                end
            end
        end
        
        // Line 3: "press btnC to"
        if (y >= Line3Y && y < Line3Y + 7) begin
            row_in_char = y - Line3Y;
            if (x >= Line3StartX && x < Line3StartX + 13 * CharWidth) begin
                char_index = (x - Line3StartX) / CharWidth;
                col_in_char = (x - Line3StartX) % CharWidth;
                if (col_in_char < 5 && char_index < 13) begin
                    current_char = get_line3_char(char_index);
                    char_row_bitmap = get_char_bitmap(current_char, row_in_char);
                    is_text_pixel = char_row_bitmap[4 - col_in_char];
                end
            end
        end
        
        // Line 4: "continue"
        if (y >= Line4Y && y < Line4Y + 7) begin
            row_in_char = y - Line4Y;
            if (x >= Line4StartX && x < Line4StartX + 8 * CharWidth) begin
                char_index = (x - Line4StartX) / CharWidth;
                col_in_char = (x - Line4StartX) % CharWidth;
                if (col_in_char < 5 && char_index < 8) begin
                    current_char = get_line4_char(char_index);
                    char_row_bitmap = get_char_bitmap(current_char, row_in_char);
                    is_text_pixel = char_row_bitmap[4 - col_in_char];
                end
            end
        end
    end
    
    always @(posedge freq625m) begin
        // Default to black
        pixel_data <= 16'h0000;
        
        // Render text in white
        if (is_text_pixel)
            pixel_data <= 16'b11111_111111_11111; // white
    end
endmodule

module equation_display (
    input wire clk,
    input wire [12:0] pixel_index,
    input wire [1:0] graph1_type,
    input wire [1:0] graph2_type,
    input wire signed [7:0] g1_poly_coeff_a,
    input wire signed [7:0] g1_poly_coeff_b,
    input wire signed [7:0] g1_poly_coeff_c,
    input wire signed [7:0] g1_cos_coeff_a,
    input wire signed [7:0] g1_sin_coeff_a,
    input wire signed [7:0] g2_poly_coeff_a,
    input wire signed [7:0] g2_poly_coeff_b,
    input wire signed [7:0] g2_poly_coeff_c,
    input wire signed [7:0] g2_cos_coeff_a,
    input wire signed [7:0] g2_sin_coeff_a,
    input wire [7:0] temp_coeff,
    input wire [1:0] digit_count,
    input wire is_negative,  // NEW: Flag indicating if current input is negative
    input wire [1:0] current_graph_slot,
    input wire [3:0] current_coeff_pos,
    output reg [15:0] pixel_color
);

    // Parameters
    localparam POLYNOMIAL = 2'b00;
    localparam COSINE     = 2'b01;
    localparam SINE       = 2'b10;
    localparam NOT_SET    = 8'h7F;
    
    localparam SCREEN_WIDTH = 96;
    localparam COLOR_WHITE = 16'hFFFF;
    localparam COLOR_BLACK = 16'h0000;
    localparam COLOR_GREEN = 16'h07E0;
    localparam CHAR_WIDTH = 6;
    localparam CHAR_HEIGHT = 7;
    
    // Calculate pixel position
    wire [6:0] x = pixel_index % SCREEN_WIDTH;
    wire [5:0] y = pixel_index / SCREEN_WIDTH;
    
    // 5x7 font bitmap - returns 5 bits for each row
    function [4:0] get_char_bitmap;
        input [7:0] ascii;
        input [2:0] row;
        case (ascii)
            "0": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10011;
                3: get_char_bitmap = 5'b10101;
                4: get_char_bitmap = 5'b11001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "1": case(row)
                0: get_char_bitmap = 5'b00100;
                1: get_char_bitmap = 5'b01100;
                2: get_char_bitmap = 5'b00100;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b01110;
            endcase
            "2": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b00001;
                3: get_char_bitmap = 5'b00110;
                4: get_char_bitmap = 5'b01000;
                5: get_char_bitmap = 5'b10000;
                6: get_char_bitmap = 5'b11111;
            endcase
            "3": case(row)
                0: get_char_bitmap = 5'b11110;
                1: get_char_bitmap = 5'b00001;
                2: get_char_bitmap = 5'b00001;
                3: get_char_bitmap = 5'b01110;
                4: get_char_bitmap = 5'b00001;
                5: get_char_bitmap = 5'b00001;
                6: get_char_bitmap = 5'b11110;
            endcase
            "4": case(row)
                0: get_char_bitmap = 5'b00010;
                1: get_char_bitmap = 5'b00110;
                2: get_char_bitmap = 5'b01010;
                3: get_char_bitmap = 5'b10010;
                4: get_char_bitmap = 5'b11111;
                5: get_char_bitmap = 5'b00010;
                6: get_char_bitmap = 5'b00010;
            endcase
            "5": case(row)
                0: get_char_bitmap = 5'b11111;
                1: get_char_bitmap = 5'b10000;
                2: get_char_bitmap = 5'b10000;
                3: get_char_bitmap = 5'b11110;
                4: get_char_bitmap = 5'b00001;
                5: get_char_bitmap = 5'b00001;
                6: get_char_bitmap = 5'b11110;
            endcase
            "6": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b10000;
                2: get_char_bitmap = 5'b10000;
                3: get_char_bitmap = 5'b11110;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "7": case(row)
                0: get_char_bitmap = 5'b11111;
                1: get_char_bitmap = 5'b00001;
                2: get_char_bitmap = 5'b00010;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b01000;
                5: get_char_bitmap = 5'b01000;
                6: get_char_bitmap = 5'b01000;
            endcase
            "8": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b01110;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "9": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b01111;
                4: get_char_bitmap = 5'b00001;
                5: get_char_bitmap = 5'b00001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "-": case(row)  // NEW: Minus sign
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b00000;
                3: get_char_bitmap = 5'b11111;
                4: get_char_bitmap = 5'b00000;
                5: get_char_bitmap = 5'b00000;
                6: get_char_bitmap = 5'b00000;
            endcase
            "+": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00100;
                2: get_char_bitmap = 5'b00100;
                3: get_char_bitmap = 5'b11111;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b00000;
            endcase
            "_": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b00000;
                3: get_char_bitmap = 5'b00000;
                4: get_char_bitmap = 5'b00000;
                5: get_char_bitmap = 5'b00000;
                6: get_char_bitmap = 5'b11111;
            endcase
            "X": case(row)
                0: get_char_bitmap = 5'b10001;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b01010;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b01010;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b10001;
            endcase
            "Y": case(row)
                0: get_char_bitmap = 5'b10001;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b01010;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b00100;
            endcase
            "=": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b11111;
                3: get_char_bitmap = 5'b00000;
                4: get_char_bitmap = 5'b11111;
                5: get_char_bitmap = 5'b00000;
                6: get_char_bitmap = 5'b00000;
            endcase
            "^": case(row)
                0: get_char_bitmap = 5'b00100;
                1: get_char_bitmap = 5'b01010;
                2: get_char_bitmap = 5'b10001;
                3: get_char_bitmap = 5'b00000;
                4: get_char_bitmap = 5'b00000;
                5: get_char_bitmap = 5'b00000;
                6: get_char_bitmap = 5'b00000;
            endcase
            "(": case(row)
                0: get_char_bitmap = 5'b00010;
                1: get_char_bitmap = 5'b00100;
                2: get_char_bitmap = 5'b01000;
                3: get_char_bitmap = 5'b01000;
                4: get_char_bitmap = 5'b01000;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b00010;
            endcase
            ")": case(row)
                0: get_char_bitmap = 5'b01000;
                1: get_char_bitmap = 5'b00100;
                2: get_char_bitmap = 5'b00010;
                3: get_char_bitmap = 5'b00010;
                4: get_char_bitmap = 5'b00010;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b01000;
            endcase
            "T": case(row)
                0: get_char_bitmap = 5'b11111;
                1: get_char_bitmap = 5'b00100;
                2: get_char_bitmap = 5'b00100;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b00100;
            endcase
            "I": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b00100;
                2: get_char_bitmap = 5'b00100;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b01110;
            endcase
            "G": case(row)
                0: get_char_bitmap = 5'b01110;
                1: get_char_bitmap = 5'b10001;
                2: get_char_bitmap = 5'b10000;
                3: get_char_bitmap = 5'b10111;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "r": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b10110;
                3: get_char_bitmap = 5'b11001;
                4: get_char_bitmap = 5'b10000;
                5: get_char_bitmap = 5'b10000;
                6: get_char_bitmap = 5'b10000;
            endcase
            "a": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b00001;
                4: get_char_bitmap = 5'b01111;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01111;
            endcase
            "p": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b11110;
                3: get_char_bitmap = 5'b10001;
                4: get_char_bitmap = 5'b11110;
                5: get_char_bitmap = 5'b10000;
                6: get_char_bitmap = 5'b10000;
            endcase
            "h": case(row)
                0: get_char_bitmap = 5'b10000;
                1: get_char_bitmap = 5'b10000;
                2: get_char_bitmap = 5'b10110;
                3: get_char_bitmap = 5'b11001;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b10001;
            endcase
            "c": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b10000;
                4: get_char_bitmap = 5'b10000;
                5: get_char_bitmap = 5'b10000;
                6: get_char_bitmap = 5'b01110;
            endcase
            "o": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b10001;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b01110;
            endcase
            "s": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01110;
                3: get_char_bitmap = 5'b10000;
                4: get_char_bitmap = 5'b01110;
                5: get_char_bitmap = 5'b00001;
                6: get_char_bitmap = 5'b11110;
            endcase
            "i": case(row)
                0: get_char_bitmap = 5'b00100;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b01100;
                3: get_char_bitmap = 5'b00100;
                4: get_char_bitmap = 5'b00100;
                5: get_char_bitmap = 5'b00100;
                6: get_char_bitmap = 5'b01110;
            endcase
            "n": case(row)
                0: get_char_bitmap = 5'b00000;
                1: get_char_bitmap = 5'b00000;
                2: get_char_bitmap = 5'b10110;
                3: get_char_bitmap = 5'b11001;
                4: get_char_bitmap = 5'b10001;
                5: get_char_bitmap = 5'b10001;
                6: get_char_bitmap = 5'b10001;
            endcase
            default: get_char_bitmap = 5'b00000;
        endcase
    endfunction
    
    // Helper function to get ASCII character from digit
    function [7:0] digit_to_ascii;
        input [3:0] digit;
        case (digit)
            4'd0: digit_to_ascii = "0";
            4'd1: digit_to_ascii = "1";
            4'd2: digit_to_ascii = "2";
            4'd3: digit_to_ascii = "3";
            4'd4: digit_to_ascii = "4";
            4'd5: digit_to_ascii = "5";
            4'd6: digit_to_ascii = "6";
            4'd7: digit_to_ascii = "7";
            4'd8: digit_to_ascii = "8";
            4'd9: digit_to_ascii = "9";
            default: digit_to_ascii = "_";
        endcase
    endfunction
    
    // Function to check if pixel is in character (5x7 version)
    function is_pixel_in_char;
        input [6:0] px, py, char_x, char_y;
        input [7:0] ascii_char;
        reg [6:0] rel_x, rel_y;
        reg [4:0] row_bitmap;
        begin
            rel_x = px - char_x;
            rel_y = py - char_y;
            if (rel_x < 5 && rel_y < CHAR_HEIGHT) begin
                row_bitmap = get_char_bitmap(ascii_char, rel_y[2:0]);
                is_pixel_in_char = row_bitmap[4 - rel_x[2:0]];
            end else begin
                is_pixel_in_char = 0;
            end
        end
    endfunction
    
    // Display logic
    always @(*) begin
        pixel_color = COLOR_BLACK;
        
        // Header: TI85 Graph (y=2-9, centered)
        if (y >= 2 && y < 9) begin
            if (is_pixel_in_char(x, y, 24, 2, "T")) pixel_color = COLOR_GREEN;
            if (is_pixel_in_char(x, y, 30, 2, "I")) pixel_color = COLOR_GREEN;
            if (is_pixel_in_char(x, y, 36, 2, "8")) pixel_color = COLOR_GREEN;
            if (is_pixel_in_char(x, y, 42, 2, "5")) pixel_color = COLOR_GREEN;
            if (is_pixel_in_char(x, y, 48, 2, "G")) pixel_color = COLOR_GREEN;
            if (is_pixel_in_char(x, y, 54, 2, "r")) pixel_color = COLOR_GREEN;
            if (is_pixel_in_char(x, y, 60, 2, "a")) pixel_color = COLOR_GREEN;
            if (is_pixel_in_char(x, y, 66, 2, "p")) pixel_color = COLOR_GREEN;
            if (is_pixel_in_char(x, y, 72, 2, "h")) pixel_color = COLOR_GREEN;
        end
        
        // Graph 1 (y=14-21)
        else if (y >= 14 && y < 21) begin
            case (graph1_type)
                POLYNOMIAL: begin
                    // Y =
                    if (is_pixel_in_char(x, y, 2, 14, "Y")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 8, 14, "=")) pixel_color = COLOR_WHITE;
                    
                    // Coeff A with negative support
                    if (current_graph_slot == 0 && current_coeff_pos == 0 && digit_count > 0) begin
                        // Currently being entered
                        if (is_negative) begin
                            if (is_pixel_in_char(x, y, 14, 14, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 20, 14, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 20, 14, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end
                    end else if (g1_poly_coeff_a != NOT_SET) begin
                        // Stored value
                        if (g1_poly_coeff_a[7]) begin  // Negative
                            if (is_pixel_in_char(x, y, 14, 14, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 20, 14, digit_to_ascii((-g1_poly_coeff_a) & 8'hF))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 20, 14, digit_to_ascii(g1_poly_coeff_a & 8'hF))) pixel_color = COLOR_WHITE;
                        end
                    end else begin
                        if (is_pixel_in_char(x, y, 20, 14, "_")) pixel_color = COLOR_WHITE;
                    end
                    
                    // X^2 +
                    if (is_pixel_in_char(x, y, 26, 14, "X")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 32, 14, "^")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 38, 14, "2")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 44, 14, "+")) pixel_color = COLOR_WHITE;
                    
                    // Coeff B with negative support
                    if (current_graph_slot == 0 && current_coeff_pos == 1 && digit_count > 0) begin
                        if (is_negative) begin
                            if (is_pixel_in_char(x, y, 50, 14, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 56, 14, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 56, 14, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end
                    end else if (g1_poly_coeff_b != NOT_SET) begin
                        if (g1_poly_coeff_b[7]) begin
                            if (is_pixel_in_char(x, y, 50, 14, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 56, 14, digit_to_ascii((-g1_poly_coeff_b) & 8'hF))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 56, 14, digit_to_ascii(g1_poly_coeff_b & 8'hF))) pixel_color = COLOR_WHITE;
                        end
                    end else begin
                        if (is_pixel_in_char(x, y, 56, 14, "_")) pixel_color = COLOR_WHITE;
                    end
                    
                    // X +
                    if (is_pixel_in_char(x, y, 62, 14, "X")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 68, 14, "+")) pixel_color = COLOR_WHITE;
                    
                    // Coeff C with negative support
                    if (current_graph_slot == 0 && current_coeff_pos == 2 && digit_count > 0) begin
                        if (is_negative) begin
                            if (is_pixel_in_char(x, y, 74, 14, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 80, 14, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 80, 14, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end
                    end else if (g1_poly_coeff_c != NOT_SET) begin
                        if (g1_poly_coeff_c[7]) begin
                            if (is_pixel_in_char(x, y, 74, 14, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 80, 14, digit_to_ascii((-g1_poly_coeff_c) & 8'hF))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 80, 14, digit_to_ascii(g1_poly_coeff_c & 8'hF))) pixel_color = COLOR_WHITE;
                        end
                    end else begin
                        if (is_pixel_in_char(x, y, 80, 14, "_")) pixel_color = COLOR_WHITE;
                    end
                end
                
                COSINE: begin
                    // Y =
                    if (is_pixel_in_char(x, y, 2, 14, "Y")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 8, 14, "=")) pixel_color = COLOR_WHITE;
                    
                    // Coeff A (variable) with negative support
                    if (current_graph_slot == 0 && current_coeff_pos == 0 && digit_count > 0) begin
                        if (is_negative) begin
                            if (is_pixel_in_char(x, y, 14, 14, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 20, 14, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 14, 14, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end
                    end else if (g1_cos_coeff_a != NOT_SET) begin
                        if (g1_cos_coeff_a[7]) begin
                            if (is_pixel_in_char(x, y, 14, 14, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 20, 14, digit_to_ascii((-g1_cos_coeff_a) & 8'hF))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 14, 14, digit_to_ascii(g1_cos_coeff_a & 8'hF))) pixel_color = COLOR_WHITE;
                        end
                    end else begin
                        if (is_pixel_in_char(x, y, 14, 14, "_")) pixel_color = COLOR_WHITE;
                    end
                    
                    // cos(
                    if (is_pixel_in_char(x, y, 26, 14, "c")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 32, 14, "o")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 38, 14, "s")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 44, 14, "(")) pixel_color = COLOR_WHITE;
                    
                    // Fixed value 9
                    if (is_pixel_in_char(x, y, 50, 14, "9")) pixel_color = COLOR_WHITE;
                    
                    // X)
                    if (is_pixel_in_char(x, y, 56, 14, "X")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 62, 14, ")")) pixel_color = COLOR_WHITE;
                end
                
                SINE: begin
                    // Y =
                    if (is_pixel_in_char(x, y, 2, 14, "Y")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 8, 14, "=")) pixel_color = COLOR_WHITE;
                    
                    // Coeff A (variable) with negative support
                    if (current_graph_slot == 0 && current_coeff_pos == 0 && digit_count > 0) begin
                        if (is_negative) begin
                            if (is_pixel_in_char(x, y, 14, 14, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 20, 14, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 14, 14, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end
                    end else if (g1_sin_coeff_a != NOT_SET) begin
                        if (g1_sin_coeff_a[7]) begin
                            if (is_pixel_in_char(x, y, 14, 14, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 20, 14, digit_to_ascii((-g1_sin_coeff_a) & 8'hF))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 14, 14, digit_to_ascii(g1_sin_coeff_a & 8'hF))) pixel_color = COLOR_WHITE;
                        end
                    end else begin
                        if (is_pixel_in_char(x, y, 14, 14, "_")) pixel_color = COLOR_WHITE;
                    end
                    
                    // sin(
                    if (is_pixel_in_char(x, y, 26, 14, "s")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 32, 14, "i")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 38, 14, "n")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 44, 14, "(")) pixel_color = COLOR_WHITE;
                    
                    // Fixed value 9
                    if (is_pixel_in_char(x, y, 50, 14, "9")) pixel_color = COLOR_WHITE;
                    
                    // X)
                    if (is_pixel_in_char(x, y, 56, 14, "X")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 62, 14, ")")) pixel_color = COLOR_WHITE;
                end
            endcase
        end
            
        // Graph 2 (y=26-33) - Similar pattern with negative support
        else if (y >= 26 && y < 33) begin
            reg [3:0] g2_coeff_a_pos, g2_coeff_b_pos, g2_coeff_c_pos;
            
            case (graph1_type)
                POLYNOMIAL: begin
                    g2_coeff_a_pos = 4'd3;
                    g2_coeff_b_pos = 4'd4;
                    g2_coeff_c_pos = 4'd5;
                end
                COSINE, SINE: begin
                    g2_coeff_a_pos = 4'd1;
                    g2_coeff_b_pos = 4'd2;
                    g2_coeff_c_pos = 4'd3;
                end
                default: begin
                    g2_coeff_a_pos = 4'd3;
                    g2_coeff_b_pos = 4'd4;
                    g2_coeff_c_pos = 4'd5;
                end
            endcase
            
            case (graph2_type)
                POLYNOMIAL: begin
                    // Y =
                    if (is_pixel_in_char(x, y, 2, 26, "Y")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 8, 26, "=")) pixel_color = COLOR_WHITE;
                    
                    // Coeff A with negative support
                    if (current_graph_slot == 2'd1 && current_coeff_pos == g2_coeff_a_pos && digit_count > 2'd0) begin
                        if (is_negative) begin
                            if (is_pixel_in_char(x, y, 14, 26, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 20, 26, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 20, 26, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end
                    end else if (g2_poly_coeff_a != NOT_SET) begin
                        if (g2_poly_coeff_a[7]) begin
                            if (is_pixel_in_char(x, y, 14, 26, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 20, 26, digit_to_ascii((-g2_poly_coeff_a) & 8'hF))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 20, 26, digit_to_ascii(g2_poly_coeff_a & 8'hF))) pixel_color = COLOR_WHITE;
                        end
                    end else begin
                        if (is_pixel_in_char(x, y, 20, 26, "_")) pixel_color = COLOR_WHITE;
                    end
                    
                    // X^2 +
                    if (is_pixel_in_char(x, y, 26, 26, "X")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 32, 26, "^")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 38, 26, "2")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 44, 26, "+")) pixel_color = COLOR_WHITE;
                    
                    // Coeff B with negative support
                    if (current_graph_slot == 2'd1 && current_coeff_pos == g2_coeff_b_pos && digit_count > 2'd0) begin
                        if (is_negative) begin
                            if (is_pixel_in_char(x, y, 50, 26, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 56, 26, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 56, 26, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end
                    end else if (g2_poly_coeff_b != NOT_SET) begin
                        if (g2_poly_coeff_b[7]) begin
                            if (is_pixel_in_char(x, y, 50, 26, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 56, 26, digit_to_ascii((-g2_poly_coeff_b) & 8'hF))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 56, 26, digit_to_ascii(g2_poly_coeff_b & 8'hF))) pixel_color = COLOR_WHITE;
                        end
                    end else begin
                        if (is_pixel_in_char(x, y, 56, 26, "_")) pixel_color = COLOR_WHITE;
                    end
                    
                    // X +
                    if (is_pixel_in_char(x, y, 62, 26, "X")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 68, 26, "+")) pixel_color = COLOR_WHITE;
                    
                    // Coeff C with negative support
                    if (current_graph_slot == 2'd1 && current_coeff_pos == g2_coeff_c_pos && digit_count > 2'd0) begin
                        if (is_negative) begin
                            if (is_pixel_in_char(x, y, 74, 26, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 80, 26, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 80, 26, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end
                    end else if (g2_poly_coeff_c != NOT_SET) begin
                        if (g2_poly_coeff_c[7]) begin
                            if (is_pixel_in_char(x, y, 74, 26, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 80, 26, digit_to_ascii((-g2_poly_coeff_c) & 8'hF))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 80, 26, digit_to_ascii(g2_poly_coeff_c & 8'hF))) pixel_color = COLOR_WHITE;
                        end
                    end else begin
                        if (is_pixel_in_char(x, y, 80, 26, "_")) pixel_color = COLOR_WHITE;
                    end
                end
                
                COSINE: begin
                    // Y = cos(
                    if (is_pixel_in_char(x, y, 2, 26, "Y")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 8, 26, "=")) pixel_color = COLOR_WHITE;
                    
                    // Coeff A (variable) with negative support
                    if (current_graph_slot == 2'd1 && current_coeff_pos == g2_coeff_a_pos && digit_count > 2'd0) begin
                        if (is_negative) begin
                            if (is_pixel_in_char(x, y, 14, 26, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 20, 26, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 14, 26, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end
                    end else if (g2_cos_coeff_a != NOT_SET) begin
                        if (g2_cos_coeff_a[7]) begin
                            if (is_pixel_in_char(x, y, 14, 26, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 20, 26, digit_to_ascii((-g2_cos_coeff_a) & 8'hF))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 14, 26, digit_to_ascii(g2_cos_coeff_a & 8'hF))) pixel_color = COLOR_WHITE;
                        end
                    end else begin
                        if (is_pixel_in_char(x, y, 14, 26, "_")) pixel_color = COLOR_WHITE;
                    end
                    
                    // cos(
                    if (is_pixel_in_char(x, y, 26, 26, "c")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 32, 26, "o")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 38, 26, "s")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 44, 26, "(")) pixel_color = COLOR_WHITE;
                    
                    // Fixed value 9
                    if (is_pixel_in_char(x, y, 50, 26, "9")) pixel_color = COLOR_WHITE;
                    
                    // X)
                    if (is_pixel_in_char(x, y, 56, 26, "X")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 62, 26, ")")) pixel_color = COLOR_WHITE;
                end
                
                SINE: begin
                    // Y = sin(
                    if (is_pixel_in_char(x, y, 2, 26, "Y")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 8, 26, "=")) pixel_color = COLOR_WHITE;
                    
                    // Coeff A (variable) with negative support
                    if (current_graph_slot == 2'd1 && current_coeff_pos == g2_coeff_a_pos && digit_count > 2'd0) begin
                        if (is_negative) begin
                            if (is_pixel_in_char(x, y, 14, 26, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 20, 26, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 14, 26, digit_to_ascii(temp_coeff))) pixel_color = COLOR_WHITE;
                        end
                    end else if (g2_sin_coeff_a != NOT_SET) begin
                        if (g2_sin_coeff_a[7]) begin
                            if (is_pixel_in_char(x, y, 14, 26, "-")) pixel_color = COLOR_WHITE;
                            if (is_pixel_in_char(x, y, 20, 26, digit_to_ascii((-g2_sin_coeff_a) & 8'hF))) pixel_color = COLOR_WHITE;
                        end else begin
                            if (is_pixel_in_char(x, y, 14, 26, digit_to_ascii(g2_sin_coeff_a & 8'hF))) pixel_color = COLOR_WHITE;
                        end
                    end else begin
                        if (is_pixel_in_char(x, y, 14, 26, "_")) pixel_color = COLOR_WHITE;
                    end
                    
                    // sin(
                    if (is_pixel_in_char(x, y, 26, 26, "s")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 32, 26, "i")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 38, 26, "n")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 44, 26, "(")) pixel_color = COLOR_WHITE;
                    
                    // Fixed value 9
                    if (is_pixel_in_char(x, y, 50, 26, "9")) pixel_color = COLOR_WHITE;
                    
                    // X)
                    if (is_pixel_in_char(x, y, 56, 26, "X")) pixel_color = COLOR_WHITE;
                    if (is_pixel_in_char(x, y, 62, 26, ")")) pixel_color = COLOR_WHITE;
                end
            endcase
        end
    end
endmodule

module keypad_screen (
    input freq625m,
    input [1:0] row_pos,        // Cursor row position (0-3)
    input [1:0] col_pos,        // Cursor column position (0-2)
    input [12:0] pixel_index,
    output reg [15:0] pixel_data
);
    localparam Width = 96;
    localparam Height = 64;
    
    wire [6:0] x = pixel_index % Width;
    wire [5:0] y = pixel_index / Width;
    
    // Colors matching input_screen_renderer
    localparam COLOR_BG        = 16'h0000; // Black
    localparam COLOR_BORDER    = 16'h8410; // Grey
    localparam COLOR_TEXT      = 16'hFFFF; // White
    localparam COLOR_HIGHLIGHT = 16'hFD20; // Orange
    
    // 8x7 font bitmap (matching input_screen_renderer style)
    function [7:0] get_char_bitmap;
        input [7:0] ascii;
        input [2:0] row;
        case (ascii)
            "0": case(row)
                0: get_char_bitmap = 8'b00111100;
                1: get_char_bitmap = 8'b01000010;
                2: get_char_bitmap = 8'b01000010;
                3: get_char_bitmap = 8'b01000010;
                4: get_char_bitmap = 8'b01000010;
                5: get_char_bitmap = 8'b01000010;
                6: get_char_bitmap = 8'b00111100;
                default: get_char_bitmap = 8'b00000000;
            endcase
            "1": case(row)
                0: get_char_bitmap = 8'b00001000;
                1: get_char_bitmap = 8'b00011000;
                2: get_char_bitmap = 8'b00001000;
                3: get_char_bitmap = 8'b00001000;
                4: get_char_bitmap = 8'b00001000;
                5: get_char_bitmap = 8'b00001000;
                6: get_char_bitmap = 8'b00111100;
                default: get_char_bitmap = 8'b00000000;
            endcase
            "2": case(row)
                0: get_char_bitmap = 8'b00111100;
                1: get_char_bitmap = 8'b01000010;
                2: get_char_bitmap = 8'b00000010;
                3: get_char_bitmap = 8'b00000100;
                4: get_char_bitmap = 8'b00001000;
                5: get_char_bitmap = 8'b00100000;
                6: get_char_bitmap = 8'b01111110;
                default: get_char_bitmap = 8'b00000000;
            endcase
            "3": case(row)
                0: get_char_bitmap = 8'b00111100;
                1: get_char_bitmap = 8'b01000010;
                2: get_char_bitmap = 8'b00000010;
                3: get_char_bitmap = 8'b00011100;
                4: get_char_bitmap = 8'b00000010;
                5: get_char_bitmap = 8'b01000010;
                6: get_char_bitmap = 8'b00111100;
                default: get_char_bitmap = 8'b00000000;
            endcase
            "4": case(row)
                0: get_char_bitmap = 8'b00000100;
                1: get_char_bitmap = 8'b00001100;
                2: get_char_bitmap = 8'b00010100;
                3: get_char_bitmap = 8'b00100100;
                4: get_char_bitmap = 8'b01111110;
                5: get_char_bitmap = 8'b00000100;
                6: get_char_bitmap = 8'b00000100;
                default: get_char_bitmap = 8'b00000000;
            endcase
            "5": case(row)
                0: get_char_bitmap = 8'b01111110;
                1: get_char_bitmap = 8'b01000000;
                2: get_char_bitmap = 8'b01111100;
                3: get_char_bitmap = 8'b00000010;
                4: get_char_bitmap = 8'b00000010;
                5: get_char_bitmap = 8'b01000010;
                6: get_char_bitmap = 8'b00111100;
                default: get_char_bitmap = 8'b00000000;
            endcase
            "6": case(row)
                0: get_char_bitmap = 8'b00111100;
                1: get_char_bitmap = 8'b01000000;
                2: get_char_bitmap = 8'b01111100;
                3: get_char_bitmap = 8'b01000010;
                4: get_char_bitmap = 8'b01000010;
                5: get_char_bitmap = 8'b01000010;
                6: get_char_bitmap = 8'b00111100;
                default: get_char_bitmap = 8'b00000000;
            endcase
            "7": case(row)
                0: get_char_bitmap = 8'b01111110;
                1: get_char_bitmap = 8'b00000010;
                2: get_char_bitmap = 8'b00000100;
                3: get_char_bitmap = 8'b00001000;
                4: get_char_bitmap = 8'b00010000;
                5: get_char_bitmap = 8'b00100000;
                6: get_char_bitmap = 8'b01000000;
                default: get_char_bitmap = 8'b00000000;
            endcase
            "8": case(row)
                0: get_char_bitmap = 8'b00111100;
                1: get_char_bitmap = 8'b01000010;
                2: get_char_bitmap = 8'b01000010;
                3: get_char_bitmap = 8'b00111100;
                4: get_char_bitmap = 8'b01000010;
                5: get_char_bitmap = 8'b01000010;
                6: get_char_bitmap = 8'b00111100;
                default: get_char_bitmap = 8'b00000000;
            endcase
            "9": case(row)
                0: get_char_bitmap = 8'b00111100;
                1: get_char_bitmap = 8'b01000010;
                2: get_char_bitmap = 8'b01000010;
                3: get_char_bitmap = 8'b00111110;
                4: get_char_bitmap = 8'b00000010;
                5: get_char_bitmap = 8'b01000010;
                6: get_char_bitmap = 8'b00111100;
                default: get_char_bitmap = 8'b00000000;
            endcase
            default: get_char_bitmap = 8'b00000000;
        endcase
    endfunction
    
    // Backspace icon drawing (matches input_screen_renderer)
    function draw_backspace_icon;
        input [6:0] x_in_btn, y_in_btn;
        integer rel_x, rel_y;
        begin
            rel_x = x_in_btn;
            rel_y = y_in_btn;
            draw_backspace_icon = (rel_y >= 5 && rel_y <= 8 && rel_x >= 10 && rel_x <= 21) ||
                                (rel_x >= 6 && rel_x <= 10 && rel_y >= (7 - (rel_x - 6)) && rel_y <= (7 + (rel_x - 6)));
        end
    endfunction
    
    // Tick/Enter icon drawing (matches input_screen_renderer)
    function draw_tick_icon;
        input [6:0] x_in_btn, y_in_btn;
        integer cx, cy;
        begin
            cx = 14; cy = 7; // Center of 28x14 button
            draw_tick_icon = ((x_in_btn - y_in_btn > cx - cy - 6) && (x_in_btn - y_in_btn < cx - cy - 2) && 
                            (x_in_btn > cx - 6 && x_in_btn < cx + 1) && (y_in_btn > cy - 3 && y_in_btn < cy + 3)) ||
                           ((x_in_btn + y_in_btn > cx + cy - 3) && (x_in_btn + y_in_btn < cx + cy + 1) && 
                            (x_in_btn > cx - 2 && x_in_btn < cx + 7) && (y_in_btn > cy - 7 && y_in_btn < cy + 1));
        end
    endfunction
    
    // Keypad layout (unchanged logic)
    function [7:0] get_key_char;
        input [1:0] row;
        input [1:0] col;
        case (row)
            2'd0: case(col)
                2'd0: get_key_char = "1";
                2'd1: get_key_char = "2";
                2'd2: get_key_char = "3";
                default: get_key_char = " ";
            endcase
            2'd1: case(col)
                2'd0: get_key_char = "4";
                2'd1: get_key_char = "5";
                2'd2: get_key_char = "6";
                default: get_key_char = " ";
            endcase
            2'd2: case(col)
                2'd0: get_key_char = "7";
                2'd1: get_key_char = "8";
                2'd2: get_key_char = "9";
                default: get_key_char = " ";
            endcase
            2'd3: case(col)
                2'd0: get_key_char = "<"; // Backspace
                2'd1: get_key_char = "0";
                2'd2: get_key_char = ">"; // Enter
                default: get_key_char = " ";
            endcase
            default: get_key_char = " ";
        endcase
    endfunction
    
    // Keypad button dimensions (matching input_screen_renderer)
    localparam ButtonWidth = 28;
    localparam ButtonHeight = 14;
    localparam ButtonSpacingX = 2;
    localparam ButtonSpacingY = 2;
    localparam KeypadStartX = 4;
    localparam KeypadStartY = 2;
    
    reg [1:0] button_row;
    reg [1:0] button_col;
    reg [6:0] x_in_button;
    reg [5:0] y_in_button;
    reg is_in_button;
    reg is_button_border;
    reg is_button_char;
    reg is_highlighted;
    
    reg [7:0] current_char;
    reg [2:0] char_row;
    reg [2:0] char_col;
    reg [7:0] char_bitmap;
    
    always @(*) begin
        is_in_button = 0;
        is_button_border = 0;
        is_button_char = 0;
        is_highlighted = 0;
        button_row = 0;
        button_col = 0;
        
        // Check if we're in the keypad area
        if (x >= KeypadStartX && y >= KeypadStartY) begin
            // Calculate which button we might be in
            if ((x - KeypadStartX) < 3 * (ButtonWidth + ButtonSpacingX) &&
                (y - KeypadStartY) < 4 * (ButtonHeight + ButtonSpacingY)) begin
                
                // Calculate row and column
                button_row = (y - KeypadStartY) / (ButtonHeight + ButtonSpacingY);
                button_col = (x - KeypadStartX) / (ButtonWidth + ButtonSpacingX);
                
                // Position within button
                x_in_button = (x - KeypadStartX) % (ButtonWidth + ButtonSpacingX);
                y_in_button = (y - KeypadStartY) % (ButtonHeight + ButtonSpacingY);
                
                // Check if we're actually in a button (not in spacing)
                if (x_in_button < ButtonWidth && y_in_button < ButtonHeight && button_col < 3 && button_row < 4) begin
                    is_in_button = 1;
                    is_highlighted = (button_row == row_pos && button_col == col_pos);
                    
                    // Border is outer edge of button
                    if (x_in_button == 0 || x_in_button == ButtonWidth - 1 ||
                        y_in_button == 0 || y_in_button == ButtonHeight - 1) begin
                        is_button_border = 1;
                    end
                    
                    current_char = get_key_char(button_row, button_col);
                    
                    // For backspace icon (row 3, col 0)
                    if (button_row == 3 && button_col == 0) begin
                        is_button_char = draw_backspace_icon(x_in_button, y_in_button);
                    end
                    // For enter/tick icon (row 3, col 2)
                    else if (button_row == 3 && button_col == 2) begin
                        is_button_char = draw_tick_icon(x_in_button, y_in_button);
                    end
                    // For number characters (centered at offset 10,3 for 8x8 char in 28x14 button)
                    else if (current_char >= "0" && current_char <= "9") begin
                        if (x_in_button >= 10 && x_in_button < 18 &&
                            y_in_button >= 3 && y_in_button < 11) begin
                            char_col = x_in_button - 10;
                            char_row = y_in_button - 3;
                            char_bitmap = get_char_bitmap(current_char, char_row);
                            is_button_char = char_bitmap[7 - char_col];
                        end
                    end
                end
            end
        end
    end
    
    always @(posedge freq625m) begin
        // Default to black background
        pixel_data <= COLOR_BG;
        
        if (is_in_button) begin
            if (is_highlighted) begin
                // Highlighted button: orange background
                pixel_data <= COLOR_HIGHLIGHT;
                if (is_button_border) begin
                    // Grey border even when highlighted
                    pixel_data <= COLOR_BORDER;
                end
                if (is_button_char) begin
                    // White text/icon
                    pixel_data <= COLOR_TEXT;
                end
            end else begin
                // Normal button: grey border, white text on black
                if (is_button_border) begin
                    pixel_data <= COLOR_BORDER;
                end
                if (is_button_char) begin
                    pixel_data <= COLOR_TEXT;
                end
            end
        end
    end
endmodule