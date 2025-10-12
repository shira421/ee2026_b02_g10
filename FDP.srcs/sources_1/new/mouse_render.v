module Mouse_Renderer(
    input clk,                   
    input [12:0] pixel_index,    
    input [11:0] canvas_addr,    
    input [2:0] canvas_data,     // 3-bit color data (0-4) from canvas memory
    input [11:0] mouse_x, mouse_y,// Current raw mouse coordinates 
    output reg [15:0] pixel_data // 16-bit RGB565 color output
);

// --- Local Parameters ---
localparam WIDTH  = 96;
localparam HEIGHT = 64;

// 16-bit RGB565 Color Definitions 
localparam COLOR_WHITE  = 16'b11111_111111_11111;
localparam COLOR_BLACK  = 16'b00000_000000_00000;
localparam COLOR_BLUE   = 16'b00000_000000_11111;
localparam COLOR_GREEN  = 16'b00000_111111_00000;
localparam COLOR_RED    = 16'b11111_000000_00000;
localparam COLOR_PURPLE = 16'b11111_000000_11110;
localparam COLOR_ORANGE = 16'b11111_101101_00000;

// --- Coordinate Mapping ---
wire [6:0] col_x = pixel_index % WIDTH; 
wire [6:0] row_y = pixel_index / WIDTH; 

// --- Cursor Logic (Simple 3x3 Cursor) ---
wire [6:0] mouse_x_7bit = mouse_x[6:0]; 
wire [6:0] mouse_y_7bit = mouse_y[6:0]; 

wire within_cursor = (col_x >= mouse_x_7bit - 1 && col_x <= mouse_x_7bit + 1 &&
                      row_y >= mouse_y_7bit - 1 && row_y <= mouse_y_7bit + 1);

// --- Combinatorial Drawing Logic ---
always @(*) begin
    // 1. Default background (Outside 56x56 canvas area)
    pixel_data = COLOR_BLACK;

    // 2. Draw the 56x56 canvas area (OLED top-left corner is 0,0)
    if (col_x < 56 && row_y < 56) begin
        // Use the 3-bit data read from canvas memory to set the pixel color
        case (canvas_data)
            0: pixel_data = COLOR_WHITE; // Background
            1: pixel_data = COLOR_BLUE;
            2: pixel_data = COLOR_GREEN;
            3: pixel_data = COLOR_RED; // Drawing color
            4: pixel_data = COLOR_ORANGE;
            default: pixel_data = COLOR_BLACK;
        endcase
    end
    
    // 3. Draw the cursor overlay (always on top)
    if (within_cursor) begin
        pixel_data = COLOR_PURPLE;
    end
end

endmodule