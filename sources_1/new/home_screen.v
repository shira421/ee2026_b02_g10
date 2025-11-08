`timescale 1ns / 1ps

module home_screen(
    input [12:0] pixel_index,
    output [15:0] pixel_data
);
    // Calculate x, y coordinates from pixel_index
    wire [6:0] x = pixel_index % 96;
    wire [5:0] y = pixel_index / 96;
    
    // Define box regions (adjusted heights)
    // Box 1: rows 3-17 (15 pixels tall - reduced by 2)
    wire in_box1 = (y >= 3 && y <= 17 && x >= 3 && x <= 92);
    wire box1_border = in_box1 && (y == 3 || y == 17 || x == 3 || x == 92);
    wire box1_fill = in_box1 && !box1_border;
    
    // Box 2: rows 19-35 (17 pixels tall - same)
    wire in_box2 = (y >= 19 && y <= 35 && x >= 3 && x <= 92);
    wire box2_border = in_box2 && (y == 19 || y == 35 || x == 3 || x == 92);
    wire box2_fill = in_box2 && !box2_border;
    
    // Box 3: rows 37-52 (16 pixels tall - reduced by 1)
    wire in_box3 = (y >= 37 && y <= 52 && x >= 3 && x <= 92);
    wire box3_border = in_box3 && (y == 37 || y == 52 || x == 3 || x == 92);
    wire box3_fill = in_box3 && !box3_border;
    
    // Box 4 (RESET): rows 54-63 (10 pixels tall - increased by 3)
    wire in_box4 = (y >= 54 && y <= 63 && x >= 3 && x <= 92);
    wire box4_border = in_box4 && (y == 54 || y == 63 || x == 3 || x == 92);
    wire box4_fill = in_box4 && !box4_border;
    
    // Colors (RGB565 format: RRRRRGGGGGGBBBBB)
    parameter BLACK  = 16'h0000;
    parameter WHITE  = 16'hFFFF;
    parameter BOX1_COLOR = 16'hE9E6;  // #ee3e34 - Red
    parameter BOX2_COLOR = 16'h55C9;  // #54b948 - Green
    parameter BOX3_COLOR = 16'h1A73;  // #1d4f9c - Blue
    
    // Text rendering
    wire [7:0] char_code;
    wire char_pixel;
    wire text_active;
    
    text_renderer text_render (
        .x(x),
        .y(y),
        .char_code(char_code),
        .char_pixel(char_pixel),
        .text_active(text_active)
    );
    
    // Pixel data assignment
    reg [15:0] pixel_color;
    
    always @(*) begin
        if (box1_border || box2_border || box3_border || box4_border) begin
            pixel_color = WHITE;
        end else if (box1_fill) begin
            pixel_color = text_active ? (char_pixel ? WHITE : BOX1_COLOR) : BOX1_COLOR;
        end else if (box2_fill) begin
            pixel_color = text_active ? (char_pixel ? WHITE : BOX2_COLOR) : BOX2_COLOR;
        end else if (box3_fill) begin
            pixel_color = text_active ? (char_pixel ? WHITE : BOX3_COLOR) : BOX3_COLOR;
        end else if (box4_fill) begin
            pixel_color = text_active ? (char_pixel ? WHITE : BLACK) : BLACK;
        end else begin
            pixel_color = BLACK;
        end
    end
    
    assign pixel_data = pixel_color;

endmodule
