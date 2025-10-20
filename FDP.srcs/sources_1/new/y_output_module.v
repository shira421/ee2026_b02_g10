
//`timescale 1ns / 1ps

//module y_output_module (
//    input clk,
//    input reset,
    
//    input wire [1:0] graph1_type,
//    input wire [1:0] graph2_type,

//    input wire signed [7:0] g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c,
//    input wire signed [7:0] g1_cos_coeff_a,
//    input wire signed [7:0] g1_sin_coeff_a,
    
//    input wire signed [7:0] g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c,
//    input wire signed [7:0] g2_cos_coeff_a,
//    input wire signed [7:0] g2_sin_coeff_a,

//    input wire signed [9:0] x_val,

//    output reg signed [15:0] g1_y_final,
//    output reg signed [15:0] g2_y_final
//);

//    wire [16:0] temp_calc;
//    wire [7:0] x_val_8bit;
    
//    assign temp_calc = (x_val + 10'd180) * 17'd256;
//    assign x_val_8bit = temp_calc / 17'd360;

//    wire signed [15:0] g1_y_sine, g1_y_cosine;
//    wire signed [47:0] g1_y_poly;
//    wire signed [15:0] g2_y_sine, g2_y_cosine;
//    wire signed [47:0] g2_y_poly;

//    sine_func sine_func_g1 (
//        .a(g1_sin_coeff_a),
//        .x(x_val_8bit),
//        .y(g1_y_sine)
//    );
    
//    cosine_func cosine_func_g1 (
//        .clk(clk),
//        .a(g1_cos_coeff_a),
//        .x(x_val_8bit),
//        .y(g1_y_cosine)
//    );
    
//    // ? BIGGER coefficients: y = 5x (will show clearly!)
//    polynomial_engine poly_engine_g1 (
//        .x({{6{x_val[9]}}, x_val}),
//        .a2(16'sd0),   // a=0
//        .a1(16'sd5),   // ? b=5 (was 1, too small!)
//        .a0(16'sd0),   // c=0
//        .y(g1_y_poly)
//    );
    
//    sine_func sine_func_g2 (
//        .a(g2_sin_coeff_a),
//        .x(x_val_8bit),
//        .y(g2_y_sine)
//    );
    
//    cosine_func cosine_func_g2 (
//        .clk(clk),
//        .a(g2_cos_coeff_a),
//        .x(x_val_8bit),
//        .y(g2_y_cosine)
//    );
    
//    // ? BIGGER coefficients: y = -5x (opposite diagonal)
//    polynomial_engine poly_engine_g2 (
//        .x({{6{x_val[9]}}, x_val}),
//        .a2(16'sd0),    // a=0
//        .a1(-16'sd5),   // ? b=-5 (was -1, too small!)
//        .a0(16'sd0),    // c=0
//        .y(g2_y_poly)
//    );

//    always @(*) begin
//        case (graph1_type)
//            2'b00: g1_y_final = g1_y_poly >>> 8;
//            2'b01: g1_y_final = g1_y_cosine;
//            2'b10: g1_y_final = g1_y_sine;
//            default: g1_y_final = 16'sd0;
//        endcase
        
//        case (graph2_type)
//            2'b00: g2_y_final = g2_y_poly >>> 8;
//            2'b01: g2_y_final = g2_y_cosine;
//            2'b10: g2_y_final = g2_y_sine;
//            default: g2_y_final = 16'sd0;
//        endcase
//    end
//endmodule

`timescale 1ns / 1ps

module y_output_module (
    input clk,
    input reset,
    
    input wire [1:0] graph1_type,
    input wire [1:0] graph2_type,

    input wire signed [7:0] g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c,
    input wire signed [7:0] g1_cos_coeff_a,
    input wire signed [7:0] g1_sin_coeff_a,
    
    input wire signed [7:0] g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c,
    input wire signed [7:0] g2_cos_coeff_a,
    input wire signed [7:0] g2_sin_coeff_a,

    input wire signed [9:0] x_val,  // -180 to 179

    output reg signed [15:0] g1_y_final,
    output reg signed [15:0] g2_y_final
);

    // Constants
    localparam POLY = 2'b00;
    localparam COS  = 2'b01;
    localparam SIN  = 2'b10;
    localparam NOT_SET = 8'h7F;

    // === X SCALING ===
    
    // For trig: map x_val (-180 to 179) to 0-255 for LUT
    wire [16:0] temp_calc = (x_val + 10'd180) * 17'd256;
    wire [7:0] x_val_8bit = temp_calc / 17'd360;

    // For polynomial: divide x by 6 to fit screen
    // x=-180 ? x_scaled=-30, x=179 ? x_scaled=29
    wire signed [15:0] x_val_16 = {{6{x_val[9]}}, x_val};
    wire signed [15:0] x_scaled = x_val_16 / 16'sd6;

    // === POLYNOMIAL COMPUTATION ===
    wire signed [47:0] g1_y_poly_raw, g2_y_poly_raw;
    
    polynomial_engine poly_g1 (
        .x(x_scaled),
        .a2({{8{g1_poly_coeff_a[7]}}, g1_poly_coeff_a}),
        .a1({{8{g1_poly_coeff_b[7]}}, g1_poly_coeff_b}),
        .a0({{8{g1_poly_coeff_c[7]}}, g1_poly_coeff_c}),
        .y(g1_y_poly_raw)
    );
    
    polynomial_engine poly_g2 (
        .x(x_scaled),
        .a2({{8{g2_poly_coeff_a[7]}}, g2_poly_coeff_a}),
        .a1({{8{g2_poly_coeff_b[7]}}, g2_poly_coeff_b}),
        .a0({{8{g2_poly_coeff_c[7]}}, g2_poly_coeff_c}),
        .y(g2_y_poly_raw)
    );

    // === TRIG COMPUTATION ===
    wire signed [15:0] g1_y_sine, g1_y_cosine, g2_y_sine, g2_y_cosine;
    
    sine_func sine_g1 (.a(g1_sin_coeff_a), .x(x_val_8bit), .y(g1_y_sine));
    cosine_func cos_g1 (.clk(clk), .a(g1_cos_coeff_a), .x(x_val_8bit), .y(g1_y_cosine));
    sine_func sine_g2 (.a(g2_sin_coeff_a), .x(x_val_8bit), .y(g2_y_sine));
    cosine_func cos_g2 (.clk(clk), .a(g2_cos_coeff_a), .x(x_val_8bit), .y(g2_y_cosine));

    // === POLYNOMIAL SCALING ===
    // Extract the relevant bits from 48-bit output
    // For small coefficients (0-5), values are already in good range
    wire signed [15:0] g1_y_poly = g1_y_poly_raw[15:0];
    wire signed [15:0] g2_y_poly = g2_y_poly_raw[15:0];

    // === OUTPUT SELECTION ===
    always @(*) begin
        // === GRAPH 1 ===
        case (graph1_type)
            POLY: begin
                if (g1_poly_coeff_a != NOT_SET || g1_poly_coeff_b != NOT_SET || g1_poly_coeff_c != NOT_SET) begin
                    g1_y_final = g1_y_poly;
                end else begin
                    // Default: y = x/6 (diagonal test line)
                    g1_y_final = x_scaled;
                end
            end
            COS: begin
                g1_y_final = (g1_cos_coeff_a != NOT_SET) ? g1_y_cosine : 16'sd10;
            end
            SIN: begin
                g1_y_final = (g1_sin_coeff_a != NOT_SET) ? g1_y_sine : 16'sd10;
            end
            default: g1_y_final = 16'sd0;
        endcase
        
        // === GRAPH 2 ===
        case (graph2_type)
            POLY: begin
                if (g2_poly_coeff_a != NOT_SET || g2_poly_coeff_b != NOT_SET || g2_poly_coeff_c != NOT_SET) begin
                    g2_y_final = g2_y_poly;
                end else begin
                    // Default: y = -x/6 (opposite diagonal)
                    g2_y_final = -x_scaled;
                end
            end
            COS: begin
                g2_y_final = (g2_cos_coeff_a != NOT_SET) ? g2_y_cosine : -16'sd10;
            end
            SIN: begin
                g2_y_final = (g2_sin_coeff_a != NOT_SET) ? g2_y_sine : -16'sd10;
            end
            default: g2_y_final = 16'sd0;
        endcase
    end
endmodule