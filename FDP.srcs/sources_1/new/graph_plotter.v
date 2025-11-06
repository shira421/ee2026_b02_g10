module graph_plotter (
    input wire clk,
    input wire reset,
    input wire [12:0] pixel_index,
    input wire [1:0] graph1_type,
    input wire [1:0] graph2_type,
    input wire signed [7:0] g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c,
    input wire signed [7:0] g1_cos_coeff_a, g1_sin_coeff_a,
    input wire signed [7:0] g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c,
    input wire signed [7:0] g2_cos_coeff_a, g2_sin_coeff_a,
    output reg [15:0] pixel_data,
    
    output wire [15:0] area_out,
    output wire area_valid_out,
    output wire [1:0] intersect_count_out,
    output wire [3:0] int0_d0, int0_d1, int0_d2, int0_d3, int0_d4, int0_d5, int0_d6, int0_d7,
    output wire [3:0] int1_d0, int1_d1, int1_d2, int1_d3, int1_d4, int1_d5, int1_d6, int1_d7
);
    localparam POLY = 2'b00, COS = 2'b01, SIN = 2'b10, NOT_SET = 8'h7F;
    localparam [15:0] COLOR_WHITE = 16'hFFFF, COLOR_BLACK = 16'h0000, 
                      COLOR_BLUE = 16'h001F, COLOR_RED = 16'hF800, 
                      COLOR_GRAY = 16'hBDF7, COLOR_DARK_GRAY = 16'h31A6;
    
    wire [6:0] screen_x = pixel_index % 96;
    wire [5:0] screen_y = pixel_index / 96;
    wire signed [9:0] x_val_temp = -10'd48 + screen_x;
    wire signed [15:0] x_val = {{6{x_val_temp[9]}}, x_val_temp};
    wire signed [15:0] x_prev = x_val - 1, x_next = x_val + 1;
    
    wire both_poly = (graph1_type == POLY) && (graph2_type == POLY);
    
    reg signed [7:0] sol_x [0:1];
    reg signed [6:0] sol_y [0:1];
    reg [1:0] sol_cnt;
    reg [15:0] area_value;
    reg area_valid;
    reg g1_is_bigger;
    reg solver_done;
    
    reg [1:0] sol_cnt_prev;
    reg [15:0] area_prev;
    reg area_valid_prev;
    reg g1_is_bigger_prev;
    
    reg [3:0] disp_line0_d0, disp_line0_d1, disp_line0_d2, disp_line0_d3;
    reg [3:0] disp_line0_d4, disp_line0_d5, disp_line0_d6, disp_line0_d7;
    reg [3:0] disp_line1_d0, disp_line1_d1, disp_line1_d2, disp_line1_d3;
    reg [3:0] disp_line1_d4, disp_line1_d5, disp_line1_d6, disp_line1_d7;
    
    function [15:0] sqrt_fast;
        input [31:0] val;
        reg [31:0] a, b, test;
        integer i;
        begin
            a = val; b = 0;
            for (i = 15; i >= 0; i = i - 1) begin
                test = (b << 1) | (1 << i);
                if (a >= (test << i)) begin
                    a = a - (test << i);
                    b = b | (1 << i);
                end
            end
            sqrt_fast = b[15:0];
        end
    endfunction
    
    function signed [15:0] div_round;
        input signed [15:0] num, den;
        begin
            if (den == 0) 
                div_round = 0;
            else if ((num >= 0 && den > 0) || (num < 0 && den < 0))
                div_round = (num + (den >>> 1)) / den;
            else
                div_round = (num - (den >>> 1)) / den;
        end
    endfunction
    
    function signed [15:0] calc_poly;
        input signed [15:0] x;
        input signed [7:0] a, b, c;
        reg signed [31:0] result;
        begin
            result = ($signed({{8{a[7]}}, a}) * x * x) + ($signed({{8{b[7]}}, b}) * x) + $signed({{24{c[7]}}, c});
            calc_poly = result[15:0];
        end
    endfunction
    
    function signed [15:0] abs_val;
        input signed [15:0] val;
        begin
            abs_val = (val < 0) ? -val : val;
        end
    endfunction
    
    // Helper function to format intersection point display
    task format_intersection;
        input signed [7:0] x_coord;
        input signed [6:0] y_coord;
        output [3:0] d0, d1, d2, d3, d4, d5, d6, d7;
        reg [7:0] abs_x;
        reg [6:0] abs_y;
        reg [3:0] x_tens, x_ones, y_tens, y_ones;
        begin
            abs_x = x_coord[7] ? (-x_coord) : x_coord;
            abs_y = y_coord[6] ? (-y_coord) : y_coord;
            x_tens = abs_x / 10;
            x_ones = abs_x % 10;
            y_tens = abs_y / 10;
            y_ones = abs_y % 10;
            
            d0 = 4'd11;  // "("
            d1 = x_coord[7] ? 4'd10 : (x_tens > 0 ? x_tens : 4'd15);  // "-" or tens or blank
            d2 = x_ones;
            d3 = 4'd13;  // ","
            d4 = y_coord[6] ? 4'd10 : (y_tens > 0 ? y_tens : 4'd15);  // "-" or tens or blank
            d5 = y_ones;
            d6 = 4'd12;  // ")"
            d7 = 4'd15;  // blank
        end
    endtask
    
    reg signed [15:0] da, db, dc;
    reg signed [31:0] disc;
    reg [15:0] sq;
    reg signed [15:0] x1, x2, y1, y2;
    reg signed [15:0] g1_a, g1_b, g1_c, g2_a, g2_b, g2_c;
    reg signed [15:0] g1_vertex_x, g2_vertex_x, g1_vertex_y, g2_vertex_y;
    reg signed [15:0] g1_vertex_abs, g2_vertex_abs;
    reg signed [15:0] diff_a, diff_b, diff_c;
    reg signed [31:0] term1_x1, term1_x2, term2_x1, term2_x2, term3_x1, term3_x2, area_raw;
    reg signed [15:0] x_min, x_max;
    
    integer i;
    
    always @(posedge clk) begin
        if (reset) begin
            sol_cnt <= 0; solver_done <= 0;
            sol_x[0] <= 0; sol_y[0] <= 0; sol_x[1] <= 0; sol_y[1] <= 0;
            sol_cnt_prev <= 0;
            area_value <= 0; area_valid <= 0; area_prev <= 0; area_valid_prev <= 0;
            g1_is_bigger <= 0; g1_is_bigger_prev <= 0;
            
            for (i = 0; i < 8; i = i + 1) begin
                disp_line0_d0 <= 4'd15; disp_line0_d1 <= 4'd15; disp_line0_d2 <= 4'd15; disp_line0_d3 <= 4'd15;
                disp_line0_d4 <= 4'd15; disp_line0_d5 <= 4'd15; disp_line0_d6 <= 4'd15; disp_line0_d7 <= 4'd15;
                disp_line1_d0 <= 4'd15; disp_line1_d1 <= 4'd15; disp_line1_d2 <= 4'd15; disp_line1_d3 <= 4'd15;
                disp_line1_d4 <= 4'd15; disp_line1_d5 <= 4'd15; disp_line1_d6 <= 4'd15; disp_line1_d7 <= 4'd15;
            end
            
        end else begin
            if (pixel_index == 0 && !solver_done && both_poly) begin
                g1_a = $signed({{8{g1_poly_coeff_a[7]}}, g1_poly_coeff_a});
                g1_b = $signed({{8{g1_poly_coeff_b[7]}}, g1_poly_coeff_b});
                g1_c = $signed({{8{g1_poly_coeff_c[7]}}, g1_poly_coeff_c});
                g2_a = $signed({{8{g2_poly_coeff_a[7]}}, g2_poly_coeff_a});
                g2_b = $signed({{8{g2_poly_coeff_b[7]}}, g2_poly_coeff_b});
                g2_c = $signed({{8{g2_poly_coeff_c[7]}}, g2_poly_coeff_c});
                
                if (g1_a != 0)
                    g1_vertex_x = div_round(-g1_b, 2 * g1_a);
                else
                    g1_vertex_x = 0;
                
                if (g2_a != 0)
                    g2_vertex_x = div_round(-g2_b, 2 * g2_a);
                else
                    g2_vertex_x = 0;
                
                g1_vertex_y = calc_poly(g1_vertex_x, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                g2_vertex_y = calc_poly(g2_vertex_x, g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c);
                
                g1_vertex_abs = abs_val(g1_vertex_y);
                g2_vertex_abs = abs_val(g2_vertex_y);
                
                g1_is_bigger <= (g1_vertex_abs > g2_vertex_abs);
                
                da = g2_a - g1_a;
                db = g2_b - g1_b;
                dc = g2_c - g1_c;
                
                sol_cnt <= 0;
                area_valid <= 0;
                
                if (da == 0 && db != 0) begin
                    x1 = div_round(-dc, db);
                    y1 = calc_poly(x1, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                    
                    if (y1 >= -31 && y1 <= 31 && x1 >= -48 && x1 <= 47) begin
                        sol_x[0] <= x1[7:0];
                        sol_y[0] <= y1[6:0];
                        sol_cnt <= 1;
                        
                        format_intersection(x1[7:0], y1[6:0],
                            disp_line0_d0, disp_line0_d1, disp_line0_d2, disp_line0_d3,
                            disp_line0_d4, disp_line0_d5, disp_line0_d6, disp_line0_d7);
                    end
                    
                end else if (da != 0) begin
                    disc = (db * db) - (4 * da * dc);
                    
                    if (disc > 0) begin
                        sq = sqrt_fast(disc[31:0]);
                        x1 = div_round(-db + $signed({1'b0, sq}), 2 * da);
                        x2 = div_round(-db - $signed({1'b0, sq}), 2 * da);
                        y1 = calc_poly(x1, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                        y2 = calc_poly(x2, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                        
                        if (y1 >= -31 && y1 <= 31 && x1 >= -48 && x1 <= 47 &&
                            y2 >= -31 && y2 <= 31 && x2 >= -48 && x2 <= 47) begin
                            
                            if (x1 < x2) begin
                                sol_x[0] <= x1[7:0]; sol_y[0] <= y1[6:0];
                                sol_x[1] <= x2[7:0]; sol_y[1] <= y2[6:0];
                                x_min = x1; x_max = x2;
                            end else begin
                                sol_x[0] <= x2[7:0]; sol_y[0] <= y2[6:0];
                                sol_x[1] <= x1[7:0]; sol_y[1] <= y1[6:0];
                                x_min = x2; x_max = x1;
                            end
                            sol_cnt <= 2;
                            
                            // Format both intersections using the task
                            if (x1 < x2) begin
                                format_intersection(x1[7:0], y1[6:0],
                                    disp_line0_d0, disp_line0_d1, disp_line0_d2, disp_line0_d3,
                                    disp_line0_d4, disp_line0_d5, disp_line0_d6, disp_line0_d7);
                                format_intersection(x2[7:0], y2[6:0],
                                    disp_line1_d0, disp_line1_d1, disp_line1_d2, disp_line1_d3,
                                    disp_line1_d4, disp_line1_d5, disp_line1_d6, disp_line1_d7);
                            end else begin
                                format_intersection(x2[7:0], y2[6:0],
                                    disp_line0_d0, disp_line0_d1, disp_line0_d2, disp_line0_d3,
                                    disp_line0_d4, disp_line0_d5, disp_line0_d6, disp_line0_d7);
                                format_intersection(x1[7:0], y1[6:0],
                                    disp_line1_d0, disp_line1_d1, disp_line1_d2, disp_line1_d3,
                                    disp_line1_d4, disp_line1_d5, disp_line1_d6, disp_line1_d7);
                            end
                            
                            // ========== FIXED AREA CALCULATION ==========
                            // Compute: ?(ax² + bx + c)dx = (a/3)x³ + (b/2)x² + cx
                            // To avoid precision loss, use: [2a(x³) + 3b(x²) + 6c(x)] / 6
                            
                            if (g1_vertex_abs > g2_vertex_abs) begin
                                diff_a = g1_a - g2_a;
                                diff_b = g1_b - g2_b;
                                diff_c = g1_c - g2_c;
                            end else begin
                                diff_a = g2_a - g1_a;
                                diff_b = g2_b - g1_b;
                                diff_c = g2_c - g1_c;
                            end
                            
                            term1_x2 = 2 * diff_a * x_max * x_max * x_max;
                            term1_x1 = 2 * diff_a * x_min * x_min * x_min;
                            term2_x2 = 3 * diff_b * x_max * x_max;
                            term2_x1 = 3 * diff_b * x_min * x_min;
                            term3_x2 = 6 * diff_c * x_max;
                            term3_x1 = 6 * diff_c * x_min;
                            
                            area_raw = ((term1_x2 - term1_x1) + (term2_x2 - term2_x1) + (term3_x2 - term3_x1)) / 6;
                            area_value <= abs_val(area_raw[15:0]);
                            area_valid <= 1;
                            
                        end else if (y1 >= -31 && y1 <= 31 && x1 >= -48 && x1 <= 47) begin
                            sol_x[0] <= x1[7:0]; sol_y[0] <= y1[6:0]; sol_cnt <= 1;
                            format_intersection(x1[7:0], y1[6:0],
                                disp_line0_d0, disp_line0_d1, disp_line0_d2, disp_line0_d3,
                                disp_line0_d4, disp_line0_d5, disp_line0_d6, disp_line0_d7);
                        end else if (y2 >= -31 && y2 <= 31 && x2 >= -48 && x2 <= 47) begin
                            sol_x[0] <= x2[7:0]; sol_y[0] <= y2[6:0]; sol_cnt <= 1;
                            format_intersection(x2[7:0], y2[6:0],
                                disp_line0_d0, disp_line0_d1, disp_line0_d2, disp_line0_d3,
                                disp_line0_d4, disp_line0_d5, disp_line0_d6, disp_line0_d7);
                        end
                        
                    end else if (disc == 0) begin
                        x1 = div_round(-db, 2 * da);
                        y1 = calc_poly(x1, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                        
                        if (y1 >= -31 && y1 <= 31 && x1 >= -48 && x1 <= 47) begin
                            sol_x[0] <= x1[7:0]; sol_y[0] <= y1[6:0]; sol_cnt <= 1;
                            format_intersection(x1[7:0], y1[6:0],
                                disp_line0_d0, disp_line0_d1, disp_line0_d2, disp_line0_d3,
                                disp_line0_d4, disp_line0_d5, disp_line0_d6, disp_line0_d7);
                        end
                    end
                end
                
                solver_done <= 1;
            end
            
            if (pixel_index == 100) begin
                sol_cnt_prev <= both_poly ? sol_cnt : 0;
                area_prev <= area_value;
                area_valid_prev <= area_valid && both_poly;
                g1_is_bigger_prev <= g1_is_bigger;
                solver_done <= 0;
            end
        end
    end
    
    wire signed [15:0] trig_out1, trig_out2;
    trig_lut trig1 (.x(x_val), .is_cos(graph1_type == COS), .trig_val(trig_out1));
    trig_lut trig2 (.x(x_val), .is_cos(graph2_type == COS), .trig_val(trig_out2));
    
    reg signed [15:0] g1_y_prev, g1_y_curr, g1_y_next, g2_y_prev, g2_y_curr, g2_y_next;
    wire signed [7:0] g1_trig_coeff = (graph1_type == COS) ? g1_cos_coeff_a : g1_sin_coeff_a;
    wire signed [7:0] g2_trig_coeff = (graph2_type == COS) ? g2_cos_coeff_a : g2_sin_coeff_a;
    
    always @(*) begin
        case (graph1_type)
            POLY: begin
                g1_y_prev = calc_poly(x_prev, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                g1_y_curr = calc_poly(x_val, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                g1_y_next = calc_poly(x_next, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
            end
            COS, SIN: begin
                g1_y_prev = ((($signed({{8{g1_trig_coeff[7]}}, g1_trig_coeff}) * trig_out1) * 32'sd41) >>> 12);
                g1_y_curr = g1_y_prev; g1_y_next = g1_y_prev;
            end
            default: begin g1_y_prev = 0; g1_y_curr = 0; g1_y_next = 0; end
        endcase
        
        case (graph2_type)
            POLY: begin
                g2_y_prev = calc_poly(x_prev, g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c);
                g2_y_curr = calc_poly(x_val, g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c);
                g2_y_next = calc_poly(x_next, g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c);
            end
            COS, SIN: begin
                g2_y_prev = ((($signed({{8{g2_trig_coeff[7]}}, g2_trig_coeff}) * trig_out2) * 32'sd41) >>> 12);
                g2_y_curr = g2_y_prev; g2_y_next = g2_y_prev;
            end
            default: begin g2_y_prev = 0; g2_y_curr = 0; g2_y_next = 0; end
        endcase
    end
    
    wire [5:0] g1_yp = (32 - g1_y_prev < 0) ? 0 : (32 - g1_y_prev > 63) ? 63 : (32 - g1_y_prev);
    wire [5:0] g1_yc = (32 - g1_y_curr < 0) ? 0 : (32 - g1_y_curr > 63) ? 63 : (32 - g1_y_curr);
    wire [5:0] g1_yn = (32 - g1_y_next < 0) ? 0 : (32 - g1_y_next > 63) ? 63 : (32 - g1_y_next);
    wire [5:0] g2_yp = (32 - g2_y_prev < 0) ? 0 : (32 - g2_y_prev > 63) ? 63 : (32 - g2_y_prev);
    wire [5:0] g2_yc = (32 - g2_y_curr < 0) ? 0 : (32 - g2_y_curr > 63) ? 63 : (32 - g2_y_curr);
    wire [5:0] g2_yn = (32 - g2_y_next < 0) ? 0 : (32 - g2_y_next > 63) ? 63 : (32 - g2_y_next);
    
    wire g1_on = ((screen_y >= g1_yp && screen_y <= g1_yc) || (screen_y <= g1_yp && screen_y >= g1_yc) ||
                  (screen_y >= g1_yc && screen_y <= g1_yn) || (screen_y <= g1_yc && screen_y >= g1_yn)) &&
                 (g1_y_curr >= -31 && g1_y_curr <= 31);
    wire g2_on = ((screen_y >= g2_yp && screen_y <= g2_yc) || (screen_y <= g2_yp && screen_y >= g2_yc) ||
                  (screen_y >= g2_yc && screen_y <= g2_yn) || (screen_y <= g2_yc && screen_y >= g2_yn)) &&
                 (g2_y_curr >= -31 && g2_y_curr <= 31);
    
    wire g1_set = (graph1_type == POLY) ? (g1_poly_coeff_a != NOT_SET || g1_poly_coeff_b != NOT_SET || g1_poly_coeff_c != NOT_SET) :
                  (graph1_type == COS) ? (g1_cos_coeff_a != NOT_SET && g1_cos_coeff_a != 0) :
                  (graph1_type == SIN) ? (g1_sin_coeff_a != NOT_SET && g1_sin_coeff_a != 0) : 0;
    wire g2_set = (graph2_type == POLY) ? (g2_poly_coeff_a != NOT_SET || g2_poly_coeff_b != NOT_SET || g2_poly_coeff_c != NOT_SET) :
                  (graph2_type == COS) ? (g2_cos_coeff_a != NOT_SET && g2_cos_coeff_a != 0) :
                  (graph2_type == SIN) ? (g2_sin_coeff_a != NOT_SET && g2_sin_coeff_a != 0) : 0;
    
    wire signed [7:0] min_x_int = sol_x[0];
    wire signed [7:0] max_x_int = sol_x[1];
    wire signed [9:0] x_screen = screen_x - 48;
    wire x_in_range = (sol_cnt >= 1) && (x_screen >= min_x_int) && (sol_cnt == 1 || x_screen <= max_x_int);
    
    wire [5:0] bigger_y = g1_is_bigger_prev ? g1_yc : g2_yc;
    wire [5:0] smaller_y = g1_is_bigger_prev ? g2_yc : g1_yc;
    wire [5:0] upper_y = (bigger_y < smaller_y) ? bigger_y : smaller_y;
    wire [5:0] lower_y = (bigger_y < smaller_y) ? smaller_y : bigger_y;
    
    wire in_shaded = both_poly && area_valid_prev && x_in_range && 
                     (screen_y > upper_y) && (screen_y < lower_y) &&
                     g1_set && g2_set && (g1_y_curr >= -31) && (g1_y_curr <= 31) &&
                     (g2_y_curr >= -31) && (g2_y_curr <= 31);
    
    assign area_out = area_prev;
    assign area_valid_out = area_valid_prev;
    assign intersect_count_out = sol_cnt_prev;
    assign int0_d0 = disp_line0_d0; assign int0_d1 = disp_line0_d1; assign int0_d2 = disp_line0_d2; assign int0_d3 = disp_line0_d3;
    assign int0_d4 = disp_line0_d4; assign int0_d5 = disp_line0_d5; assign int0_d6 = disp_line0_d6; assign int0_d7 = disp_line0_d7;
    assign int1_d0 = disp_line1_d0; assign int1_d1 = disp_line1_d1; assign int1_d2 = disp_line1_d2; assign int1_d3 = disp_line1_d3;
    assign int1_d4 = disp_line1_d4; assign int1_d5 = disp_line1_d5; assign int1_d6 = disp_line1_d6; assign int1_d7 = disp_line1_d7;
    
    wire on_haxis = (screen_y == 32);
    wire on_vaxis = (screen_x == 48);
    wire on_grid = ((screen_x % 12) == 0) || ((screen_y % 12) == 0);
    
    always @(*) begin
        if (in_shaded)
            pixel_data = COLOR_DARK_GRAY;
        else if (g1_on && g1_set) 
            pixel_data = COLOR_BLUE;
        else if (g2_on && g2_set) 
            pixel_data = COLOR_RED;
        else if (on_haxis || on_vaxis) 
            pixel_data = COLOR_BLACK;
        else if (on_grid) 
            pixel_data = COLOR_GRAY;
        else 
            pixel_data = COLOR_WHITE;
    end
endmodule

module trig_lut(
    input signed [15:0] x,
    input is_cos,
    output reg signed [15:0] trig_val
);
    reg signed [15:0] x_work;
    reg is_neg;
    
    always @(*) begin
        is_neg = (x < 0);
        x_work = is_neg ? ((-x) % 48) : (x % 48);
        if (is_cos) x_work = (x_work + 12) % 48;
        
        case (x_work)
            0:  trig_val = 0;   1:  trig_val = 13;  2:  trig_val = 26;  3:  trig_val = 38;
            4:  trig_val = 50;  5:  trig_val = 61;  6:  trig_val = 71;  7:  trig_val = 79;
            8:  trig_val = 87;  9:  trig_val = 93;  10: trig_val = 97;  11: trig_val = 99;
            12: trig_val = 100; 13: trig_val = 99;  14: trig_val = 97;  15: trig_val = 93;
            16: trig_val = 87;  17: trig_val = 79;  18: trig_val = 71;  19: trig_val = 61;
            20: trig_val = 50;  21: trig_val = 38;  22: trig_val = 26;  23: trig_val = 13;
            24: trig_val = 0;   25: trig_val = -13; 26: trig_val = -26; 27: trig_val = -38;
            28: trig_val = -50; 29: trig_val = -61; 30: trig_val = -71; 31: trig_val = -79;
            32: trig_val = -87; 33: trig_val = -93; 34: trig_val = -97; 35: trig_val = -99;
            36: trig_val = -100;37: trig_val = -99; 38: trig_val = -97; 39: trig_val = -93;
            40: trig_val = -87; 41: trig_val = -79; 42: trig_val = -71; 43: trig_val = -61;
            44: trig_val = -50; 45: trig_val = -38; 46: trig_val = -26; 47: trig_val = -13;
            default: trig_val = 0;
        endcase
        
        if (!is_cos && is_neg) trig_val = -trig_val;
    end
endmodule