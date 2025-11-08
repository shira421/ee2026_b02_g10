module text_renderer(
    input [6:0] x,
    input [5:0] y,
    output reg [7:0] char_code,
    output reg char_pixel,
    output reg text_active
);

    // Font data (5x7 pixels per character)
    wire [34:0] font_data;
    
    font_rom font (
        .char_code(char_code),
        .font_data(font_data)
    );
    
    // Small font data (3x5 pixels per character for SW indicators)
    wire [14:0] small_font_data;
    
    small_font_rom small_font (
        .char_code(char_code),
        .font_data(small_font_data)
    );
    
    reg [3:0] char_index;
    reg [2:0] char_col;
    reg [2:0] char_row;
    reg bold_pixel;
    reg [1:0] small_char_col;
    reg [2:0] small_char_row;
    
    always @(*) begin
        text_active = 0;
        char_code = 8'h20; // Space
        char_pixel = 0;
        bold_pixel = 0;
        char_index = 0;
        char_col = 0;
        char_row = 0;
        small_char_col = 0;
        small_char_row = 0;
        
        // Box 1: "CALCULATOR" left, separator line at x=70, "SW1" right
        if (y >= 3 && y <= 17) begin
            // Vertical separator line at x=70
            if (x == 70 && y >= 5 && y <= 15) begin
                text_active = 1;
                char_pixel = 1;
            end
            // "CALCULATOR" at y=7-13, starting at x=5 (left-aligned, bold)
            else if (y >= 7 && y <= 13 && x >= 5 && x < 65) begin
                char_row = y - 7;
                if ((x - 5) < 60) begin
                    char_index = (x - 5) / 6;
                    char_col = (x - 5) % 6;
                    
                    if (char_col < 5 && char_index < 10) begin
                        text_active = 1;
                        case (char_index)
                            0:  char_code = "C";
                            1:  char_code = "A";
                            2:  char_code = "L";
                            3:  char_code = "C";
                            4:  char_code = "U";
                            5:  char_code = "L";
                            6:  char_code = "A";
                            7:  char_code = "T";
                            8:  char_code = "O";
                            9:  char_code = "R";
                            default: char_code = " ";
                        endcase
                        bold_pixel = font_data[(6 - char_row) * 5 + (4 - char_col)];
                        // Bold effect: also check next column
                        if (char_col < 4)
                            bold_pixel = bold_pixel | font_data[(6 - char_row) * 5 + (4 - char_col - 1)];
                        char_pixel = bold_pixel;
                    end
                end
            end
            // "SW1" at y=8-12, right-aligned (smaller 3x5 font)
            else if (y >= 8 && y <= 12 && x >= 77 && x <= 88) begin
                small_char_row = y - 8;
                if ((x - 77) < 12) begin
                    char_index = (x - 77) / 4;
                    small_char_col = (x - 77) % 4;
                    
                    if (small_char_col < 3) begin
                        text_active = 1;
                        case (char_index)
                            0:  char_code = "S";
                            1:  char_code = "W";
                            2:  char_code = "1";
                            default: char_code = " ";
                        endcase
                        char_pixel = small_font_data[(4 - small_char_row) * 3 + (2 - small_char_col)];
                    end
                end
            end
        end
        
        // Box 2: "GRAPHING" left, separator line at x=70, "SW2" right
        else if (y >= 19 && y <= 35) begin
            // Vertical separator line at x=70
            if (x == 70 && y >= 21 && y <= 33) begin
                text_active = 1;
                char_pixel = 1;
            end
            // "GRAPHING" at y=24-30, starting at x=5 (left-aligned, bold)
            else if (y >= 24 && y <= 30 && x >= 5 && x < 53) begin
                char_row = y - 24;
                if ((x - 5) < 48) begin
                    char_index = (x - 5) / 6;
                    char_col = (x - 5) % 6;
                    
                    if (char_col < 5 && char_index < 8) begin
                        text_active = 1;
                        case (char_index)
                            0:  char_code = "G";
                            1:  char_code = "R";
                            2:  char_code = "A";
                            3:  char_code = "P";
                            4:  char_code = "H";
                            5:  char_code = "I";
                            6:  char_code = "N";
                            7:  char_code = "G";
                            default: char_code = " ";
                        endcase
                        bold_pixel = font_data[(6 - char_row) * 5 + (4 - char_col)];
                        // Bold effect: also check next column
                        if (char_col < 4)
                            bold_pixel = bold_pixel | font_data[(6 - char_row) * 5 + (4 - char_col - 1)];
                        char_pixel = bold_pixel;
                    end
                end
            end
            // "SW2" at y=25-29, right-aligned (smaller 3x5 font)
            else if (y >= 25 && y <= 29 && x >= 77 && x <= 88) begin
                small_char_row = y - 25;
                if ((x - 77) < 12) begin
                    char_index = (x - 77) / 4;
                    small_char_col = (x - 77) % 4;
                    
                    if (small_char_col < 3) begin
                        text_active = 1;
                        case (char_index)
                            0:  char_code = "S";
                            1:  char_code = "W";
                            2:  char_code = "2";
                            default: char_code = " ";
                        endcase
                        char_pixel = small_font_data[(4 - small_char_row) * 3 + (2 - small_char_col)];
                    end
                end
            end
        end
        
        // Box 3: "MATH GAME" left, separator line at x=70, "SW3" right
        else if (y >= 37 && y <= 52) begin
            // Vertical separator line at x=70
            if (x == 70 && y >= 39 && y <= 50) begin
                text_active = 1;
                char_pixel = 1;
            end
            // "MATH GAME" at y=41-47, starting at x=5 (left-aligned, bold)
            else if (y >= 41 && y <= 47 && x >= 5 && x < 59) begin
                char_row = y - 41;
                if ((x - 5) < 54) begin
                    char_index = (x - 5) / 6;
                    char_col = (x - 5) % 6;
                    
                    if (char_col < 5 && char_index < 9) begin
                        text_active = 1;
                        case (char_index)
                            0:  char_code = "M";
                            1:  char_code = "A";
                            2:  char_code = "T";
                            3:  char_code = "H";
                            4:  char_code = " ";
                            5:  char_code = "G";
                            6:  char_code = "A";
                            7:  char_code = "M";
                            8:  char_code = "E";
                            default: char_code = " ";
                        endcase
                        bold_pixel = font_data[(6 - char_row) * 5 + (4 - char_col)];
                        // Bold effect: also check next column
                        if (char_col < 4)
                            bold_pixel = bold_pixel | font_data[(6 - char_row) * 5 + (4 - char_col - 1)];
                        char_pixel = bold_pixel;
                    end
                end
            end
            // "SW3" at y=42-46, right-aligned (smaller 3x5 font)
            else if (y >= 42 && y <= 46 && x >= 77 && x <= 88) begin
                small_char_row = y - 42;
                if ((x - 77) < 12) begin
                    char_index = (x - 77) / 4;
                    small_char_col = (x - 77) % 4;
                    
                    if (small_char_col < 3) begin
                        text_active = 1;
                        case (char_index)
                            0:  char_code = "S";
                            1:  char_code = "W";
                            2:  char_code = "3";
                            default: char_code = " ";
                        endcase
                        char_pixel = small_font_data[(4 - small_char_row) * 3 + (2 - small_char_col)];
                    end
                end
            end
        end
        
        // Box 4: "RESET" left, separator line at x=70, "SW0" right (smaller font, white text on black)
        else if (y >= 54 && y <= 63) begin
            // Vertical separator line at x=70
            if (x == 70 && y >= 56 && y <= 61) begin
                text_active = 1;
                char_pixel = 1;
            end
            // "RESET" at y=57-61, starting at x=5 (left-aligned, smaller 3x5 font)
            else if (y >= 57 && y <= 61 && x >= 5 && x < 25) begin
                small_char_row = y - 57;
                if ((x - 5) < 20) begin
                    char_index = (x - 5) / 4;
                    small_char_col = (x - 5) % 4;
                    
                    if (small_char_col < 3 && char_index < 5) begin
                        text_active = 1;
                        case (char_index)
                            0:  char_code = "R";
                            1:  char_code = "E";
                            2:  char_code = "S";
                            3:  char_code = "E";
                            4:  char_code = "T";
                            default: char_code = " ";
                        endcase
                        char_pixel = small_font_data[(4 - small_char_row) * 3 + (2 - small_char_col)];
                    end
                end
            end
            // "SW0" at y=57-61, right-aligned (smaller 3x5 font)
            else if (y >= 57 && y <= 61 && x >= 77 && x <= 88) begin
                small_char_row = y - 57;
                if ((x - 77) < 12) begin
                    char_index = (x - 77) / 4;
                    small_char_col = (x - 77) % 4;
                    
                    if (small_char_col < 3) begin
                        text_active = 1;
                        case (char_index)
                            0:  char_code = "S";
                            1:  char_code = "W";
                            2:  char_code = "0";
                            default: char_code = " ";
                        endcase
                        char_pixel = small_font_data[(4 - small_char_row) * 3 + (2 - small_char_col)];
                    end
                end
            end
        end
    end

endmodule
