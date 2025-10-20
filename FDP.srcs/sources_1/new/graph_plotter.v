`timescale 1ns / 1ps
/**
module graph_plotter (
    input wire clk,
    input wire reset,
    input wire [12:0] pixel_index,
    
    // Graph types
    input wire [1:0] graph1_type,
    input wire [1:0] graph2_type,
    
    // Graph coefficients
    input wire signed [7:0] g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c,
    input wire signed [7:0] g1_cos_coeff_a, g1_sin_coeff_a,
    input wire signed [7:0] g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c,
    input wire signed [7:0] g2_cos_coeff_a, g2_sin_coeff_a,
    
    output reg [15:0] pixel_data
);

    // ========================================================================
    // PARAMETERS AND CONSTANTS
    // ========================================================================
    localparam SCREEN_WIDTH = 96;
    localparam SCREEN_HEIGHT = 64;
    
    // Graph types
    localparam POLY = 2'b00;
    localparam COS  = 2'b01;
    localparam SIN  = 2'b10;
    localparam NOT_SET = 8'h7F;
    
    // Colors (RGB565)
    localparam [15:0] COLOR_WHITE   = 16'hFFFF;
    localparam [15:0] COLOR_BLACK   = 16'h0000;
    localparam [15:0] COLOR_BLUE    = 16'h001F;
    localparam [15:0] COLOR_RED     = 16'hF800;
    localparam [15:0] COLOR_MAGENTA = 16'hF81F;
    localparam [15:0] COLOR_GRAY    = 16'hBDF7;
    
    // ========================================================================
    // COORDINATE CONVERSION
    // ========================================================================
    // Current pixel position
    wire [6:0] screen_x = pixel_index % SCREEN_WIDTH;
    wire [5:0] screen_y = pixel_index / SCREEN_WIDTH;
    
    // Map screen_x (0-95) to x_val (-48 to +47)
    wire signed [9:0] x_val_temp = -10'd48 + screen_x;
    wire signed [15:0] x_val = {{6{x_val_temp[9]}}, x_val_temp};
    
    // Adjacent x positions for line interpolation
    wire signed [15:0] x_prev = x_val - 16'sd1;
    wire signed [15:0] x_next = x_val + 16'sd1;
    
    // ========================================================================
    // GRAPH 1 FUNCTION CALCULATION
    // ========================================================================
    // Calculate y-values at x-1, x, and x+1 for smooth line rendering
    
    reg signed [15:0] g1_y_at_x_prev;
    reg signed [15:0] g1_y_at_x;
    reg signed [15:0] g1_y_at_x_next;
    
    always @(*) begin
        case (graph1_type)
            POLY: begin
                // Polynomial: y = a*x� + b*x + c
                g1_y_at_x_prev = calculate_poly(x_prev, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                g1_y_at_x      = calculate_poly(x_val,  g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                g1_y_at_x_next = calculate_poly(x_next, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
            end
            
            COS: begin
                // Cosine: y = a * cos(x)
                g1_y_at_x_prev = calculate_cos(cos_val_g1_prev, g1_cos_coeff_a);
                g1_y_at_x      = calculate_cos(cos_val_g1_curr, g1_cos_coeff_a);
                g1_y_at_x_next = calculate_cos(cos_val_g1_next, g1_cos_coeff_a);
            end
            
            SIN: begin
                // TODO: Sine: y = a * sin(x)
                // INSERT SINE CALCULATION HERE
                g1_y_at_x_prev = 16'sd0;  // Placeholder
                g1_y_at_x      = 16'sd0;  // Placeholder
                g1_y_at_x_next = 16'sd0;  // Placeholder
            end
            
            default: begin
                g1_y_at_x_prev = 16'sd0;
                g1_y_at_x      = 16'sd0;
                g1_y_at_x_next = 16'sd0;
            end
        endcase
    end
    
    // ========================================================================
    // GRAPH 2 FUNCTION CALCULATION
    // ========================================================================
    reg signed [15:0] g2_y_at_x_prev;
    reg signed [15:0] g2_y_at_x;
    reg signed [15:0] g2_y_at_x_next;
    
    always @(*) begin
        case (graph2_type)
            POLY: begin
                // Polynomial: y = a*x� + b*x + c
                g2_y_at_x_prev = calculate_poly(x_prev, g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c);
                g2_y_at_x      = calculate_poly(x_val,  g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c);
                g2_y_at_x_next = calculate_poly(x_next, g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c);
            end
            
            COS: begin
                // Cosine: y = a * cos(x)
                g2_y_at_x_prev = calculate_cos(cos_val_g2_prev, g2_cos_coeff_a);
                g2_y_at_x      = calculate_cos(cos_val_g2_curr, g2_cos_coeff_a);
                g2_y_at_x_next = calculate_cos(cos_val_g2_next, g2_cos_coeff_a);
            end
            
            SIN: begin
                // TODO: Sine: y = a * sin(x)
                // INSERT SINE CALCULATION HERE
                g2_y_at_x_prev = 16'sd0;  // Placeholder
                g2_y_at_x      = 16'sd0;  // Placeholder
                g2_y_at_x_next = 16'sd0;  // Placeholder
            end
            
            default: begin
                g2_y_at_x_prev = 16'sd0;
                g2_y_at_x      = 16'sd0;
                g2_y_at_x_next = 16'sd0;
            end
        endcase
    end
    
    // ========================================================================
    // POLYNOMIAL CALCULATION FUNCTION
    // ========================================================================
    function signed [15:0] calculate_poly;
        input signed [15:0] x;
        input signed [7:0] a;
        input signed [7:0] b;
        input signed [7:0] c;
        reg signed [31:0] x_squared;
        reg signed [31:0] ax2;
        reg signed [31:0] bx;
        reg signed [31:0] const_c;
        reg signed [31:0] result_full;
        begin
            x_squared = x * x;
            ax2 = {{8{a[7]}}, a} * x_squared;
            bx = {{8{b[7]}}, b} * x;
            const_c = {{24{c[7]}}, c};
            result_full = ax2 + bx + const_c;
            calculate_poly = result_full[15:0];
        end
    endfunction
    
    // ========================================================================
    // COSINE LOOKUP TABLE INSTANTIATION
    // ========================================================================
    // Wires for cosine lookups
    wire signed [15:0] cos_val_g1_prev, cos_val_g1_curr, cos_val_g1_next;
    wire signed [15:0] cos_val_g2_prev, cos_val_g2_curr, cos_val_g2_next;
    
    // Instantiate cosine LUT modules for graph 1
    cos_lut cos_lut_g1_prev (.x(x_prev), .cos_val(cos_val_g1_prev));
    cos_lut cos_lut_g1_curr (.x(x_val),  .cos_val(cos_val_g1_curr));
    cos_lut cos_lut_g1_next (.x(x_next), .cos_val(cos_val_g1_next));
    
    // Instantiate cosine LUT modules for graph 2
    cos_lut cos_lut_g2_prev (.x(x_prev), .cos_val(cos_val_g2_prev));
    cos_lut cos_lut_g2_curr (.x(x_val),  .cos_val(cos_val_g2_curr));
    cos_lut cos_lut_g2_next (.x(x_next), .cos_val(cos_val_g2_next));
    
    // ========================================================================
    // COSINE CALCULATION FUNCTION
    // ========================================================================
    function signed [15:0] calculate_cos;
        input signed [15:0] cos_val;
        input signed [7:0] a;
        reg signed [31:0] result_full;
        begin
            // Scale by coefficient a: y = a * cos(x)
            // cos_val ranges from -100 to +100 (representing -1.0 to +1.0)
            // We divide by 100 to get the actual cosine value
            // So: a=1 gives amplitude of 1, a=5 gives amplitude of 5, etc.
            result_full = {{8{a[7]}}, a} * cos_val;
            
            // Divide by 100 to convert back to normal range
            calculate_cos = result_full[15:0] / 16'sd100;
        end
    endfunction
    
    // ========================================================================
    // Y-VALUE CLAMPING (Keep values within displayable range: -31 to +31)
    // ========================================================================
    reg signed [15:0] g1_y_prev_clamped, g1_y_clamped, g1_y_next_clamped;
    reg signed [15:0] g2_y_prev_clamped, g2_y_clamped, g2_y_next_clamped;
    
    always @(*) begin
        // Graph 1 - Previous
        g1_y_prev_clamped = clamp_y(g1_y_at_x_prev);
        
        // Graph 1 - Current
        g1_y_clamped = clamp_y(g1_y_at_x);
        
        // Graph 1 - Next
        g1_y_next_clamped = clamp_y(g1_y_at_x_next);
        
        // Graph 2 - Previous
        g2_y_prev_clamped = clamp_y(g2_y_at_x_prev);
        
        // Graph 2 - Current
        g2_y_clamped = clamp_y(g2_y_at_x);
        
        // Graph 2 - Next
        g2_y_next_clamped = clamp_y(g2_y_at_x_next);
    end
    
    // Clamp function
    function signed [15:0] clamp_y;
        input signed [15:0] y;
        begin
            if (y > 16'sd31)
                clamp_y = 16'sd31;
            else if (y < -16'sd31)
                clamp_y = -16'sd31;
            else
                clamp_y = y;
        end
    endfunction
    
    // ========================================================================
    // CONVERT TO SCREEN COORDINATES (y-axis is inverted on screen)
    // ========================================================================
    wire signed [6:0] g1_y_prev_screen_calc = 7'sd32 - g1_y_prev_clamped;
    wire signed [6:0] g1_y_screen_calc = 7'sd32 - g1_y_clamped;
    wire signed [6:0] g1_y_next_screen_calc = 7'sd32 - g1_y_next_clamped;
    
    wire signed [6:0] g2_y_prev_screen_calc = 7'sd32 - g2_y_prev_clamped;
    wire signed [6:0] g2_y_screen_calc = 7'sd32 - g2_y_clamped;
    wire signed [6:0] g2_y_next_screen_calc = 7'sd32 - g2_y_next_clamped;
    
    // ========================================================================
    // LINE SEGMENT DETECTION (Check if current pixel is on the graph line)
    // ========================================================================
    wire signed [6:0] screen_y_signed = {1'b0, screen_y};
    
    // Graph 1: Check if pixel lies between adjacent points
    wire g1_on_segment_prev = is_on_segment(screen_y_signed, g1_y_prev_screen_calc, g1_y_screen_calc);
    wire g1_on_segment_next = is_on_segment(screen_y_signed, g1_y_screen_calc, g1_y_next_screen_calc);
    
    // Graph 2: Check if pixel lies between adjacent points
    wire g2_on_segment_prev = is_on_segment(screen_y_signed, g2_y_prev_screen_calc, g2_y_screen_calc);
    wire g2_on_segment_next = is_on_segment(screen_y_signed, g2_y_screen_calc, g2_y_next_screen_calc);
    
    // Function to check if point is on line segment
    function is_on_segment;
        input signed [6:0] y;
        input signed [6:0] y1;
        input signed [6:0] y2;
        reg signed [6:0] y_min;
        reg signed [6:0] y_max;
        begin
            y_min = (y1 < y2) ? y1 : y2;
            y_max = (y1 > y2) ? y1 : y2;
            is_on_segment = (y >= y_min) && (y <= y_max);
        end
    endfunction
    
    // ========================================================================
    // GRAPH VALIDITY CHECKS
    // ========================================================================
    // Check if calculated y-values are within displayable range
    wire g1_in_bounds = (g1_y_at_x <= 16'sd31) && (g1_y_at_x >= -16'sd31);
    wire g2_in_bounds = (g2_y_at_x <= 16'sd31) && (g2_y_at_x >= -16'sd31);
    
    // Check if coefficients are set (not equal to NOT_SET value)
    wire g1_is_set = (graph1_type == POLY) ? 
                     (g1_poly_coeff_a != NOT_SET || g1_poly_coeff_b != NOT_SET || g1_poly_coeff_c != NOT_SET) :
                     (graph1_type == COS) ? (g1_cos_coeff_a != NOT_SET) :
                     (graph1_type == SIN) ? (g1_sin_coeff_a != NOT_SET) : 1'b0;
    
    wire g2_is_set = (graph2_type == POLY) ? 
                     (g2_poly_coeff_a != NOT_SET || g2_poly_coeff_b != NOT_SET || g2_poly_coeff_c != NOT_SET) :
                     (graph2_type == COS) ? (g2_cos_coeff_a != NOT_SET) :
                     (graph2_type == SIN) ? (g2_sin_coeff_a != NOT_SET) : 1'b0;
    
    // Final decision: draw the graph if valid and on line segment
    wire on_g1 = g1_in_bounds && g1_is_set && (g1_on_segment_prev || g1_on_segment_next);
    wire on_g2 = g2_in_bounds && g2_is_set && (g2_on_segment_prev || g2_on_segment_next);
    
    // ========================================================================
    // AXIS AND GRID DETECTION
    // ========================================================================
    wire on_h_axis = (screen_y == 6'd32);  // Horizontal axis at y=0
    wire on_v_axis = (screen_x == 7'd48);  // Vertical axis at x=0
    wire on_grid = ((screen_x % 7'd12) == 7'd0) || ((screen_y % 6'd12) == 6'd0);
    
    // ========================================================================
    // COLOR ASSIGNMENT (Priority: graphs > axes > grid > background)
    // ========================================================================
    always @(*) begin
        if (on_g1 && on_g2)
            pixel_data = COLOR_MAGENTA;  // Both graphs overlap
        else if (on_g1)
            pixel_data = COLOR_BLUE;     // Graph 1 only
        else if (on_g2)
            pixel_data = COLOR_RED;      // Graph 2 only
        else if (on_h_axis || on_v_axis)
            pixel_data = COLOR_BLACK;    // Axes
        else if (on_grid)
            pixel_data = COLOR_GRAY;     // Grid lines
        else
            pixel_data = COLOR_WHITE;    // Background
    end

endmodule
**/

module graph_plotter (
    input wire clk,
    input wire reset,
    input wire [12:0] pixel_index,
    
    // Graph types
    input wire [1:0] graph1_type,
    input wire [1:0] graph2_type,
    
    // Graph coefficients
    input wire signed [7:0] g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c,
    input wire signed [7:0] g1_cos_coeff_a, g1_sin_coeff_a,
    input wire signed [7:0] g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c,
    input wire signed [7:0] g2_cos_coeff_a, g2_sin_coeff_a,
    
    output reg [15:0] pixel_data
);

    // ========================================================================
    // PARAMETERS AND CONSTANTS
    // ========================================================================
    localparam SCREEN_WIDTH = 96;
    localparam SCREEN_HEIGHT = 64;
    
    // Graph types
    localparam POLY = 2'b00;
    localparam COS  = 2'b01;
    localparam SIN  = 2'b10;
    localparam NOT_SET = 8'h7F;
    
    // Colors (RGB565)
    localparam [15:0] COLOR_WHITE   = 16'hFFFF;
    localparam [15:0] COLOR_BLACK   = 16'h0000;
    localparam [15:0] COLOR_BLUE    = 16'h001F;
    localparam [15:0] COLOR_RED     = 16'hF800;
    localparam [15:0] COLOR_MAGENTA = 16'hF81F;
    localparam [15:0] COLOR_GRAY    = 16'hBDF7;
    
    // ========================================================================
    // COORDINATE CONVERSION
    // ========================================================================
    // Current pixel position
    wire [6:0] screen_x = pixel_index % SCREEN_WIDTH;
    wire [5:0] screen_y = pixel_index / SCREEN_WIDTH;
    
    // Map screen_x (0-95) to x_val (-48 to +47)
    wire signed [9:0] x_val_temp = -10'd48 + screen_x;
    wire signed [15:0] x_val = {{6{x_val_temp[9]}}, x_val_temp};
    
    // Adjacent x positions for line interpolation
    wire signed [15:0] x_prev = x_val - 16'sd1;
    wire signed [15:0] x_next = x_val + 16'sd1;
    
    // ========================================================================
    // GRAPH 1 FUNCTION CALCULATION
    // ========================================================================
    // Calculate y-values at x-1, x, and x+1 for smooth line rendering
    
    reg signed [15:0] g1_y_at_x_prev;
    reg signed [15:0] g1_y_at_x;
    reg signed [15:0] g1_y_at_x_next;
    
    always @(*) begin
        case (graph1_type)
            POLY: begin
                // Polynomial: y = a*x� + b*x + c
                g1_y_at_x_prev = calculate_poly(x_prev, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                g1_y_at_x      = calculate_poly(x_val,  g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                g1_y_at_x_next = calculate_poly(x_next, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
            end
            
            COS: begin
                // Cosine: y = a * cos(x)
                g1_y_at_x_prev = calculate_cos(cos_val_g1_prev, g1_cos_coeff_a);
                g1_y_at_x      = calculate_cos(cos_val_g1_curr, g1_cos_coeff_a);
                g1_y_at_x_next = calculate_cos(cos_val_g1_next, g1_cos_coeff_a);
            end
            
            SIN: begin
                // TODO: Sine: y = a * sin(x)
                // INSERT SINE CALCULATION HERE
                g1_y_at_x_prev = 16'sd0;  // Placeholder
                g1_y_at_x      = 16'sd0;  // Placeholder
                g1_y_at_x_next = 16'sd0;  // Placeholder
            end
            
            default: begin
                g1_y_at_x_prev = 16'sd0;
                g1_y_at_x      = 16'sd0;
                g1_y_at_x_next = 16'sd0;
            end
        endcase
    end
    
    // ========================================================================
    // GRAPH 2 FUNCTION CALCULATION
    // ========================================================================
    reg signed [15:0] g2_y_at_x_prev;
    reg signed [15:0] g2_y_at_x;
    reg signed [15:0] g2_y_at_x_next;
    
    always @(*) begin
        case (graph2_type)
            POLY: begin
                // Polynomial: y = a*x� + b*x + c
                g2_y_at_x_prev = calculate_poly(x_prev, g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c);
                g2_y_at_x      = calculate_poly(x_val,  g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c);
                g2_y_at_x_next = calculate_poly(x_next, g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c);
            end
            
            COS: begin
                // Cosine: y = a * cos(x)
                g2_y_at_x_prev = calculate_cos(cos_val_g2_prev, g2_cos_coeff_a);
                g2_y_at_x      = calculate_cos(cos_val_g2_curr, g2_cos_coeff_a);
                g2_y_at_x_next = calculate_cos(cos_val_g2_next, g2_cos_coeff_a);
            end
            
            SIN: begin
                // TODO: Sine: y = a * sin(x)
                // INSERT SINE CALCULATION HERE
                g2_y_at_x_prev = 16'sd0;  // Placeholder
                g2_y_at_x      = 16'sd0;  // Placeholder
                g2_y_at_x_next = 16'sd0;  // Placeholder
            end
            
            default: begin
                g2_y_at_x_prev = 16'sd0;
                g2_y_at_x      = 16'sd0;
                g2_y_at_x_next = 16'sd0;
            end
        endcase
    end
    
    // ========================================================================
    // POLYNOMIAL CALCULATION FUNCTION
    // ========================================================================
    function signed [15:0] calculate_poly;
        input signed [15:0] x;
        input signed [7:0] a;
        input signed [7:0] b;
        input signed [7:0] c;
        reg signed [31:0] x_squared;
        reg signed [31:0] ax2;
        reg signed [31:0] bx;
        reg signed [31:0] const_c;
        reg signed [31:0] result_full;
        begin
            x_squared = x * x;
            ax2 = {{8{a[7]}}, a} * x_squared;
            bx = {{8{b[7]}}, b} * x;
            const_c = {{24{c[7]}}, c};
            result_full = ax2 + bx + const_c;
            calculate_poly = result_full[15:0];
        end
    endfunction
    
    // ========================================================================
    // COSINE LOOKUP TABLE INSTANTIATION
    // ========================================================================
    // Wires for cosine lookups
    wire signed [15:0] cos_val_g1_prev, cos_val_g1_curr, cos_val_g1_next;
    wire signed [15:0] cos_val_g2_prev, cos_val_g2_curr, cos_val_g2_next;
    
    // Instantiate cosine LUT modules for graph 1
    cos_lut cos_lut_g1_prev (.x(x_prev), .cos_val(cos_val_g1_prev));
    cos_lut cos_lut_g1_curr (.x(x_val),  .cos_val(cos_val_g1_curr));
    cos_lut cos_lut_g1_next (.x(x_next), .cos_val(cos_val_g1_next));
    
    // Instantiate cosine LUT modules for graph 2
    cos_lut cos_lut_g2_prev (.x(x_prev), .cos_val(cos_val_g2_prev));
    cos_lut cos_lut_g2_curr (.x(x_val),  .cos_val(cos_val_g2_curr));
    cos_lut cos_lut_g2_next (.x(x_next), .cos_val(cos_val_g2_next));
    
    // ========================================================================
    // COSINE CALCULATION FUNCTION
    // ========================================================================
    function signed [15:0] calculate_cos;
        input signed [15:0] cos_val;
        input signed [7:0] a;
        reg signed [31:0] result_full;
        begin
            // Scale by coefficient a: y = a * cos(x)
            // cos_val ranges from -100 to +100 (representing -1.0 to +1.0)
            // We divide by 100 to get the actual cosine value
            // So: a=1 gives amplitude of 1, a=5 gives amplitude of 5, etc.
            result_full = {{8{a[7]}}, a} * cos_val;
            
            // Divide by 100 to convert back to normal range
            calculate_cos = result_full[15:0] / 16'sd100;
        end
    endfunction
    
    // ========================================================================
    // Y-VALUE CLAMPING (Keep values within displayable range: -31 to +31)
    // ========================================================================
    reg signed [15:0] g1_y_prev_clamped, g1_y_clamped, g1_y_next_clamped;
    reg signed [15:0] g2_y_prev_clamped, g2_y_clamped, g2_y_next_clamped;
    
    always @(*) begin
        // Graph 1 - Previous
        g1_y_prev_clamped = clamp_y(g1_y_at_x_prev);
        
        // Graph 1 - Current
        g1_y_clamped = clamp_y(g1_y_at_x);
        
        // Graph 1 - Next
        g1_y_next_clamped = clamp_y(g1_y_at_x_next);
        
        // Graph 2 - Previous
        g2_y_prev_clamped = clamp_y(g2_y_at_x_prev);
        
        // Graph 2 - Current
        g2_y_clamped = clamp_y(g2_y_at_x);
        
        // Graph 2 - Next
        g2_y_next_clamped = clamp_y(g2_y_at_x_next);
    end
    
    // Clamp function
    function signed [15:0] clamp_y;
        input signed [15:0] y;
        begin
            if (y > 16'sd31)
                clamp_y = 16'sd31;
            else if (y < -16'sd31)
                clamp_y = -16'sd31;
            else
                clamp_y = y;
        end
    endfunction
    
    // ========================================================================
    // CONVERT TO SCREEN COORDINATES (y-axis is inverted on screen)
    // ========================================================================
    // Need to handle signed arithmetic properly
    // y_val = +31 should map to screen_y = 1
    // y_val = 0 should map to screen_y = 32
    // y_val = -31 should map to screen_y = 63
    
    reg signed [6:0] g1_y_prev_screen_calc;
    reg signed [6:0] g1_y_screen_calc;
    reg signed [6:0] g1_y_next_screen_calc;
    reg signed [6:0] g2_y_prev_screen_calc;
    reg signed [6:0] g2_y_screen_calc;
    reg signed [6:0] g2_y_next_screen_calc;
    
    always @(*) begin
        // Convert signed y values to screen coordinates
        // Must preserve sign through the conversion
        g1_y_prev_screen_calc = 32 - $signed(g1_y_prev_clamped);
        g1_y_screen_calc = 32 - $signed(g1_y_clamped);
        g1_y_next_screen_calc = 32 - $signed(g1_y_next_clamped);
        
        g2_y_prev_screen_calc = 32 - $signed(g2_y_prev_clamped);
        g2_y_screen_calc = 32 - $signed(g2_y_clamped);
        g2_y_next_screen_calc = 32 - $signed(g2_y_next_clamped);
    end
    
    // ========================================================================
    // LINE SEGMENT DETECTION (Check if current pixel is on the graph line)
    // ========================================================================
    // screen_y is unsigned 6-bit (0-63)
    // But g1_y_screen_calc might be signed or outside valid range
    // We need to compare properly
    
    wire [5:0] g1_y_prev_screen = (g1_y_prev_screen_calc < 0) ? 6'd0 : 
                                   (g1_y_prev_screen_calc > 63) ? 6'd63 : 
                                   g1_y_prev_screen_calc[5:0];
    wire [5:0] g1_y_screen = (g1_y_screen_calc < 0) ? 6'd0 : 
                              (g1_y_screen_calc > 63) ? 6'd63 : 
                              g1_y_screen_calc[5:0];
    wire [5:0] g1_y_next_screen = (g1_y_next_screen_calc < 0) ? 6'd0 : 
                                   (g1_y_next_screen_calc > 63) ? 6'd63 : 
                                   g1_y_next_screen_calc[5:0];
    
    wire [5:0] g2_y_prev_screen = (g2_y_prev_screen_calc < 0) ? 6'd0 : 
                                   (g2_y_prev_screen_calc > 63) ? 6'd63 : 
                                   g2_y_prev_screen_calc[5:0];
    wire [5:0] g2_y_screen = (g2_y_screen_calc < 0) ? 6'd0 : 
                              (g2_y_screen_calc > 63) ? 6'd63 : 
                              g2_y_screen_calc[5:0];
    wire [5:0] g2_y_next_screen = (g2_y_next_screen_calc < 0) ? 6'd0 : 
                                   (g2_y_next_screen_calc > 63) ? 6'd63 : 
                                   g2_y_next_screen_calc[5:0];
    
    // Graph 1: Check if pixel lies between adjacent points
    wire g1_on_segment_prev = is_on_segment(screen_y, g1_y_prev_screen, g1_y_screen);
    wire g1_on_segment_next = is_on_segment(screen_y, g1_y_screen, g1_y_next_screen);
    
    // Graph 2: Check if pixel lies between adjacent points
    wire g2_on_segment_prev = is_on_segment(screen_y, g2_y_prev_screen, g2_y_screen);
    wire g2_on_segment_next = is_on_segment(screen_y, g2_y_screen, g2_y_next_screen);
    
    // Function to check if point is on line segment (unsigned comparison)
    function is_on_segment;
        input [5:0] y;
        input [5:0] y1;
        input [5:0] y2;
        reg [5:0] y_min;
        reg [5:0] y_max;
        begin
            // Handle the case where y1 and y2 might be equal
            if (y1 == y2) begin
                is_on_segment = (y == y1);
            end
            else begin
                y_min = (y1 < y2) ? y1 : y2;
                y_max = (y1 > y2) ? y1 : y2;
                is_on_segment = (y >= y_min) && (y <= y_max);
            end
        end
    endfunction
    
    // ========================================================================
    // GRAPH VALIDITY CHECKS
    // ========================================================================
    // Check if calculated y-values are within displayable range
    wire g1_in_bounds = (g1_y_at_x <= 16'sd31) && (g1_y_at_x >= -16'sd31);
    wire g2_in_bounds = (g2_y_at_x <= 16'sd31) && (g2_y_at_x >= -16'sd31);
    
    // Check if coefficients are set (not equal to NOT_SET value)
    wire g1_is_set = (graph1_type == POLY) ? 
                     (g1_poly_coeff_a != NOT_SET || g1_poly_coeff_b != NOT_SET || g1_poly_coeff_c != NOT_SET) :
                     (graph1_type == COS) ? (g1_cos_coeff_a != NOT_SET && g1_cos_coeff_a != 8'd0) :
                     (graph1_type == SIN) ? (g1_sin_coeff_a != NOT_SET && g1_sin_coeff_a != 8'd0) : 1'b0;
    
    wire g2_is_set = (graph2_type == POLY) ? 
                     (g2_poly_coeff_a != NOT_SET || g2_poly_coeff_b != NOT_SET || g2_poly_coeff_c != NOT_SET) :
                     (graph2_type == COS) ? (g2_cos_coeff_a != NOT_SET && g2_cos_coeff_a != 8'd0) :
                     (graph2_type == SIN) ? (g2_sin_coeff_a != NOT_SET && g2_sin_coeff_a != 8'd0) : 1'b0;
    
    // Final decision: draw the graph if valid and on line segment
    wire on_g1 = g1_in_bounds && g1_is_set && (g1_on_segment_prev || g1_on_segment_next);
    wire on_g2 = g2_in_bounds && g2_is_set && (g2_on_segment_prev || g2_on_segment_next);
    
    // ========================================================================
    // AXIS AND GRID DETECTION
    // ========================================================================
    wire on_h_axis = (screen_y == 6'd32);  // Horizontal axis at y=0
    wire on_v_axis = (screen_x == 7'd48);  // Vertical axis at x=0
    wire on_grid = ((screen_x % 7'd12) == 7'd0) || ((screen_y % 6'd12) == 6'd0);
    
    // ========================================================================
    // COLOR ASSIGNMENT (Priority: graphs > axes > grid > background)
    // ========================================================================
    always @(*) begin
        if (on_g1 && on_g2)
            pixel_data = COLOR_MAGENTA;  // Both graphs overlap
        else if (on_g1)
            pixel_data = COLOR_BLUE;     // Graph 1 only
        else if (on_g2)
            pixel_data = COLOR_RED;      // Graph 2 only
        else if (on_h_axis || on_v_axis)
            pixel_data = COLOR_BLACK;    // Axes
        else if (on_grid)
            pixel_data = COLOR_GRAY;     // Grid lines
        else
            pixel_data = COLOR_WHITE;    // Background
    end

endmodule
