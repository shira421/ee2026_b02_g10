module trig_lut(
    input signed [15:0] x,
    input is_cos,  // 0=sine, 1=cosine
    output reg signed [15:0] trig_val
);
    reg signed [15:0] x_work;
    reg is_neg;
    
    always @(*) begin
        // Handle negative inputs
        is_neg = (x < 0);
        x_work = is_neg ? ((-x) % 48) : (x % 48);
        
        // Cosine is just sine shifted by 12
        if (is_cos)
            x_work = (x_work + 12) % 48;
        
        // Sine lookup
        case (x_work)
            0:  trig_val = 0;
            1:  trig_val = 13;
            2:  trig_val = 26;
            3:  trig_val = 38;
            4:  trig_val = 50;
            5:  trig_val = 61;
            6:  trig_val = 71;
            7:  trig_val = 79;
            8:  trig_val = 87;
            9:  trig_val = 93;
            10: trig_val = 97;
            11: trig_val = 99;
            12: trig_val = 100;
            13: trig_val = 99;
            14: trig_val = 97;
            15: trig_val = 93;
            16: trig_val = 87;
            17: trig_val = 79;
            18: trig_val = 71;
            19: trig_val = 61;
            20: trig_val = 50;
            21: trig_val = 38;
            22: trig_val = 26;
            23: trig_val = 13;
            24: trig_val = 0;
            25: trig_val = -13;
            26: trig_val = -26;
            27: trig_val = -38;
            28: trig_val = -50;
            29: trig_val = -61;
            30: trig_val = -71;
            31: trig_val = -79;
            32: trig_val = -87;
            33: trig_val = -93;
            34: trig_val = -97;
            35: trig_val = -99;
            36: trig_val = -100;
            37: trig_val = -99;
            38: trig_val = -97;
            39: trig_val = -93;
            40: trig_val = -87;
            41: trig_val = -79;
            42: trig_val = -71;
            43: trig_val = -61;
            44: trig_val = -50;
            45: trig_val = -38;
            46: trig_val = -26;
            47: trig_val = -13;
            default: trig_val = 0;
        endcase
        
        // Negate for negative input (sine only)
        if (!is_cos && is_neg)
            trig_val = -trig_val;
    end
endmodule

// ============================================================================
// Simplified Font ROM - FIXED DIGIT 0
// ============================================================================
module digit_rom(
    input [3:0] digit,
    input [2:0] row,
    input [1:0] col,
    output reg pixel
);
    always @(*) begin
        case (digit)
            4'd0: case (row) 3'd0, 3'd4: pixel = 1; 3'd1, 3'd2, 3'd3: pixel = (col == 0 || col == 2); default: pixel = 0; endcase  // Fixed 0
            4'd1: pixel = (col == 1 && row < 5);
            4'd2: case (row) 3'd0, 3'd2, 3'd4: pixel = 1; 3'd1: pixel = (col == 2); 3'd3: pixel = (col == 0); default: pixel = 0; endcase
            4'd3: case (row) 3'd0, 3'd2, 3'd4: pixel = 1; 3'd1, 3'd3: pixel = (col == 2); default: pixel = 0; endcase
            4'd4: case (row) 3'd0, 3'd1: pixel = (col != 1); 3'd2: pixel = 1; 3'd3, 3'd4: pixel = (col == 2); default: pixel = 0; endcase
            4'd5: case (row) 3'd0, 3'd2, 3'd4: pixel = 1; 3'd1: pixel = (col == 0); 3'd3: pixel = (col == 2); default: pixel = 0; endcase
            4'd6: case (row) 3'd0, 3'd2, 3'd4: pixel = 1; 3'd1: pixel = (col == 0); 3'd3: pixel = (col != 1); default: pixel = 0; endcase
            4'd7: case (row) 3'd0: pixel = 1; default: pixel = (col == 2 && row < 5); endcase
            4'd8: case (row) 3'd0, 3'd2, 3'd4: pixel = 1; 3'd1, 3'd3: pixel = (col != 1); default: pixel = 0; endcase
            4'd9: case (row) 3'd0, 3'd2, 3'd4: pixel = 1; 3'd1: pixel = (col != 1); 3'd3: pixel = (col == 2); default: pixel = 0; endcase
            4'd10: pixel = (row == 3'd2);  // minus
            4'd11: case (row) 3'd0, 3'd4: pixel = (col != 0); 3'd1, 3'd2, 3'd3: pixel = (col == 0); default: pixel = 0; endcase  // (
            4'd12: case (row) 3'd0, 3'd4: pixel = (col != 2); 3'd1, 3'd2, 3'd3: pixel = (col == 2); default: pixel = 0; endcase  // )
            4'd13: pixel = (row == 3'd3 && col == 1) || (row == 3'd4 && col == 0);  // comma
            default: pixel = 0;
        endcase
    end
endmodule


// ============================================================================
// Optimized Text Display
// ============================================================================
module text_display(
    input [6:0] screen_x,
    input [5:0] screen_y,
    input [1:0] intersect_count,
    input signed [7:0] x0, x1,
    input signed [6:0] y0, y1,
    output reg pixel_on,
    output reg [15:0] text_color
);
    localparam [15:0] COLOR_WHITE = 16'hFFFF;
    
    wire text_area = (screen_x >= 68 && screen_x < 96 && screen_y >= 2 && screen_y < 18);
    wire [4:0] text_x = screen_x - 68;
    wire [4:0] text_y = screen_y - 2;
    wire line = (text_y >= 8);
    wire [2:0] row = line ? (text_y - 8) : text_y[2:0];
    wire [2:0] char = text_x[4:2];
    wire [1:0] col = text_x[1:0];
    
    reg signed [7:0] disp_x;
    reg signed [6:0] disp_y;
    reg valid_line;
    
    always @(*) begin
        if (line) begin
            disp_x = x1; disp_y = y1; valid_line = (intersect_count >= 2'd2);
        end else begin
            disp_x = x0; disp_y = y0; valid_line = (intersect_count >= 2'd1);
        end
    end
    
    wire [3:0] x_ones = (disp_x[7]) ? ((-disp_x) % 10) : (disp_x % 10);
    wire [3:0] y_ones = (disp_y[6]) ? ((-disp_y) % 10) : (disp_y % 10);
    wire x_neg = disp_x[7];
    wire y_neg = disp_y[6];
    
    reg [3:0] digit;
    reg show;
    
    always @(*) begin
        show = 0; digit = 0;
        if (text_area && valid_line && row < 5) begin
            case (char)
                3'd0: begin digit = 4'd11; show = 1; end
                3'd1: begin digit = x_neg ? 4'd10 : x_ones; show = 1; end
                3'd2: begin digit = x_neg ? x_ones : 4'd13; show = 1; end
                3'd3: begin digit = x_neg ? 4'd13 : (y_neg ? 4'd10 : y_ones); show = 1; end
                3'd4: begin digit = (x_neg && y_neg) ? 4'd10 : (x_neg || y_neg) ? y_ones : 4'd12; show = 1; end
                3'd5: begin digit = (x_neg && y_neg) ? y_ones : ((x_neg || y_neg) ? 4'd12 : 0); show = (x_neg || y_neg); end
                3'd6: begin digit = 4'd12; show = (x_neg && y_neg); end
            endcase
        end
    end
    
    wire rom_pix;
    digit_rom rom (.digit(digit), .row(row), .col(col), .pixel(rom_pix));
    
    always @(*) begin
        pixel_on = show && rom_pix && (col < 3);
        text_color = pixel_on ? 16'h0000 : COLOR_WHITE;
    end
endmodule

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
    output reg [15:0] pixel_data
);
    localparam POLY = 2'b00, COS = 2'b01, SIN = 2'b10, NOT_SET = 8'h7F;
    localparam [15:0] COLOR_WHITE = 16'hFFFF, COLOR_BLACK = 16'h0000, COLOR_BLUE = 16'h001F, COLOR_RED = 16'hF800, COLOR_MAGENTA = 16'hF81F, COLOR_GRAY = 16'hBDF7;
    
    wire [6:0] screen_x = pixel_index % 96;
    wire [5:0] screen_y = pixel_index / 96;
    wire signed [9:0] x_val_temp = -10'd48 + screen_x;
    wire signed [15:0] x_val = {{6{x_val_temp[9]}}, x_val_temp};
    wire signed [15:0] x_prev = x_val - 1, x_next = x_val + 1;
    
    // Solver registers
    reg signed [7:0] sol_x [0:1];
    reg signed [6:0] sol_y [0:1];
    reg [1:0] sol_cnt, sol_cnt_prev;
    reg signed [7:0] sol_x_prev [0:1];
    reg signed [6:0] sol_y_prev [0:1];
    reg solver_done;
    
    // Solver temp variables (MOVED TO MODULE SCOPE)
    reg signed [15:0] da, db, dc, xs1, xs2, ys1, ys2;
    reg signed [31:0] disc;
    reg [31:0] sq;
    
    // Reduced-precision sqrt (10 iterations instead of 16 - saves ~35% sqrt LUTs)
    function [15:0] sqrt_fast;
        input [31:0] val;
        reg [31:0] a, b, test;
        integer i;
        begin
            a = val; b = 0;
            for (i = 10; i >= 0; i = i - 1) begin  // Reduced from 16 to 10
                test = (b << 1) | (1 << i);
                if (a >= test << i) begin
                    a = a - (test << i);
                    b = b | (1 << i);
                end
            end
            sqrt_fast = b[15:0];
        end
    endfunction
    
    // Polynomial calculation
    function signed [15:0] calc_poly;
        input signed [15:0] x;
        input signed [7:0] a, b, c;
        reg signed [31:0] result;
        begin
            result = ($signed({{8{a[7]}}, a}) * x * x) + ($signed({{8{b[7]}}, b}) * x) + $signed({{24{c[7]}}, c});
            calc_poly = result[15:0];
        end
    endfunction
    
    // Solver
    always @(posedge clk) begin
        if (reset) begin
            sol_cnt <= 0; sol_cnt_prev <= 0; solver_done <= 0;
            sol_x[0] <= 0; sol_y[0] <= 0; sol_x[1] <= 0; sol_y[1] <= 0;
            sol_x_prev[0] <= 0; sol_y_prev[0] <= 0; sol_x_prev[1] <= 0; sol_y_prev[1] <= 0;
        end else begin
            if (pixel_index == 0 && !solver_done) begin
                sol_cnt <= 0;
                if (graph1_type == POLY && graph2_type == POLY) begin
                    da = $signed(g1_poly_coeff_a) - $signed(g2_poly_coeff_a);
                    db = $signed(g1_poly_coeff_b) - $signed(g2_poly_coeff_b);
                    dc = $signed(g1_poly_coeff_c) - $signed(g2_poly_coeff_c);
                    
                    if (da == 0 && db != 0) begin
                        xs1 = -dc / db;
                        ys1 = calc_poly(xs1, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                        if (ys1 >= -31 && ys1 <= 31 && xs1 >= -48 && xs1 <= 47) begin
                            sol_x[0] <= xs1[7:0]; sol_y[0] <= ys1[6:0]; sol_cnt <= 1;
                        end
                    end else if (da != 0) begin
                        disc = (db * db) - (4 * da * dc);
                        if (disc >= 0) begin
                            sq = sqrt_fast(disc[31:0]);
                            xs1 = ($signed({1'b0, sq[15:0]}) - db) / (2 * da);
                            ys1 = calc_poly(xs1, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                            xs2 = (-$signed({1'b0, sq[15:0]}) - db) / (2 * da);
                            ys2 = calc_poly(xs2, g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c);
                            
                            if (ys1 >= -31 && ys1 <= 31 && xs1 >= -48 && xs1 <= 47) begin
                                sol_x[0] <= xs1[7:0]; sol_y[0] <= ys1[6:0]; sol_cnt <= 1;
                                if (disc > 0 && ys2 >= -31 && ys2 <= 31 && xs2 >= -48 && xs2 <= 47) begin
                                    sol_x[1] <= xs2[7:0]; sol_y[1] <= ys2[6:0]; sol_cnt <= 2;
                                end
                            end else if (disc > 0 && ys2 >= -31 && ys2 <= 31 && xs2 >= -48 && xs2 <= 47) begin
                                sol_x[0] <= xs2[7:0]; sol_y[0] <= ys2[6:0]; sol_cnt <= 1;
                            end
                        end
                    end
                end
                solver_done <= 1;
            end
            if (pixel_index == 100) begin
                sol_cnt_prev <= sol_cnt;
                sol_x_prev[0] <= sol_x[0]; sol_y_prev[0] <= sol_y[0];
                sol_x_prev[1] <= sol_x[1]; sol_y_prev[1] <= sol_y[1];
                solver_done <= 0;
            end
        end
    end
    
    // SHARED Trig LUT (2 instances - one for each graph)
    wire signed [15:0] trig_out1, trig_out2;
    
    trig_lut trig1 (.x(x_val), .is_cos(graph1_type == COS), .trig_val(trig_out1));
    trig_lut trig2 (.x(x_val), .is_cos(graph2_type == COS), .trig_val(trig_out2));
    
    // Simplified graph evaluation
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
                g1_y_curr = g1_y_prev;  // Approximation
                g1_y_next = g1_y_prev;
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
                g2_y_curr = g2_y_prev;
                g2_y_next = g2_y_prev;
            end
            default: begin g2_y_prev = 0; g2_y_curr = 0; g2_y_next = 0; end
        endcase
    end
    
    // Simplified screen conversion (removed excessive clamping)
    wire [5:0] g1_yp = (32 - g1_y_prev < 0) ? 0 : (32 - g1_y_prev > 63) ? 63 : (32 - g1_y_prev);
    wire [5:0] g1_yc = (32 - g1_y_curr < 0) ? 0 : (32 - g1_y_curr > 63) ? 63 : (32 - g1_y_curr);
    wire [5:0] g1_yn = (32 - g1_y_next < 0) ? 0 : (32 - g1_y_next > 63) ? 63 : (32 - g1_y_next);
    wire [5:0] g2_yp = (32 - g2_y_prev < 0) ? 0 : (32 - g2_y_prev > 63) ? 63 : (32 - g2_y_prev);
    wire [5:0] g2_yc = (32 - g2_y_curr < 0) ? 0 : (32 - g2_y_curr > 63) ? 63 : (32 - g2_y_curr);
    wire [5:0] g2_yn = (32 - g2_y_next < 0) ? 0 : (32 - g2_y_next > 63) ? 63 : (32 - g2_y_next);
    
    // Segment check (simplified)
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
    
    wire on_haxis = (screen_y == 32);
    wire on_vaxis = (screen_x == 48);
    wire on_grid = ((screen_x % 12) == 0) || ((screen_y % 12) == 0);
    
    wire disp_txt;
    wire [15:0] txt_col;
    text_display txt (.screen_x(screen_x), .screen_y(screen_y), .intersect_count(sol_cnt_prev),
                      .x0(sol_x_prev[0]), .y0(sol_y_prev[0]), .x1(sol_x_prev[1]), .y1(sol_y_prev[1]),
                      .pixel_on(disp_txt), .text_color(txt_col));
    
    always @(*) begin
        if (disp_txt) pixel_data = txt_col;
        else if (g1_on && g1_set && g2_on && g2_set) pixel_data = COLOR_MAGENTA;
        else if (g1_on && g1_set) pixel_data = COLOR_BLUE;
        else if (g2_on && g2_set) pixel_data = COLOR_RED;
        else if (on_haxis || on_vaxis) pixel_data = COLOR_BLACK;
        else if (on_grid) pixel_data = COLOR_GRAY;
        else pixel_data = COLOR_WHITE;
    end
endmodule