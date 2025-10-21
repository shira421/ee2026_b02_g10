`timescale 1ns / 1ps

module top_top(
    input clk, btnC, btnL, btnR, btnU, btnD, 
    input [15:0] sw,
    output [7:0] JB,
    output [7:0] JA,
    output [15:0] led
    );
    
    // Clocks
    wire freq625m;
    freq_625m c0(clk, freq625m);
    
    wire btnCD, btnUD, btnLD, btnRD, btnDD;
    // Debouncing parent function
    debouncer_parent f0(
        clk, btnC, btnU, btnL, btnR, btnD,
        btnCD, btnUD, btnLD, btnRD, btnDD
    );
        
    // Main functions
    wire [15:0] screen1_data, screen2_data;
    
    graphing_calculator_top f1(
        .clk(freq625m),
        .reset(sw[15]),
        .btnC(btnCD),
        .btnL(btnLD),
        .btnR(btnRD),
        .btnU(btnUD),
        .btnD(btnDD),
        .negative_sign(sw[10]),  // NEW: Connect sw[10] for negative input
        .pixel_index_1(pixel_index_1), 
        .pixel_index_2(pixel_index_2),
    
        // Outputs to screens
        .screen1_data(screen1_data),
        .screen2_data(screen2_data),
        
        // Debug outputs
        .fsm_state_debug(fsm_state_debug),
        .cursor_pos_debug(cursor_pos_debug),
        .graph1_type_debug(graph1_type_debug),
        .graph2_type_debug(graph2_type_debug),
        .row_pos_debug(row_pos_debug),
        .col_pos_debug(col_pos_debug),
        .temp_coeff_debug(temp_coeff_debug),
        .digit_count_debug(digit_count_debug),
        .all_inputs_confirmed_debug(all_inputs_confirmed_debug),
        .g1_cos_coeff_a_debug(g1_cos_coeff_a_debug), 
        .g1_sin_coeff_a_debug(g1_sin_coeff_a_debug),
        .g2_cos_coeff_a_debug(g2_cos_coeff_a_debug), 
        .g2_sin_coeff_a_debug(g2_sin_coeff_a_debug),
        .g1_poly_coeff_a_debug(g1_poly_coeff_a_debug),
        .g1_poly_coeff_b_debug(g1_poly_coeff_b_debug), 
        .g1_poly_coeff_c_debug(g1_poly_coeff_c_debug),
        .g2_poly_coeff_a_debug(g2_poly_coeff_a_debug),
        .g2_poly_coeff_b_debug(g2_poly_coeff_b_debug),
        .g2_poly_coeff_c_debug(g2_poly_coeff_c_debug),
        .current_graph_slot_debug(current_graph_slot_debug),
        .current_coeff_pos_debug(current_coeff_pos_debug)
    );
    
    // Debug helpers
    wire [1:0] graph1_type_debug, graph2_type_debug;
    wire [1:0] row_pos_debug, col_pos_debug;
    wire cursor_pos_debug, all_inputs_confirmed_debug;
    wire [2:0] fsm_state_debug;
    wire [7:0] temp_coeff_debug;
    wire [1:0] digit_count_debug;
    wire [7:0] g1_cos_coeff_a_debug, g1_sin_coeff_a_debug, g2_cos_coeff_a_debug, g2_sin_coeff_a_debug;
    wire [7:0] g1_poly_coeff_a_debug, g1_poly_coeff_b_debug, g1_poly_coeff_c_debug;
    wire [7:0] g2_poly_coeff_a_debug, g2_poly_coeff_b_debug, g2_poly_coeff_c_debug;
    wire [1:0] current_graph_slot_debug;
    wire [3:0] current_coeff_pos_debug;
    
    assign led[3:0] = current_coeff_pos_debug;
    assign led[4] = all_inputs_confirmed_debug;
    assign led[7:5] = fsm_state_debug;
    
    // Graphical output
    wire [12:0] pixel_index_1, pixel_index_2;
    wire frame_begin_1, sending_pixels_1, sample_pixel_1;
    wire frame_begin_2, sending_pixels_2, sample_pixel_2;
    
    oled_display g0(
        .clk(freq625m), 
        .reset(1'b0), 
        .frame_begin(frame_begin_1), 
        .sending_pixels(sending_pixels_1), 
        .sample_pixel(sample_pixel_1),
        .pixel_index(pixel_index_2), 
        .pixel_data(screen2_data),
        .cs(JB[0]), 
        .sdin(JB[1]), 
        .sclk(JB[3]), 
        .d_cn(JB[4]), 
        .resn(JB[5]), 
        .vccen(JB[6]), 
        .pmoden(JB[7])
    );
    
    oled_display g1(
        .clk(freq625m), 
        .reset(1'b0), 
        .frame_begin(frame_begin_2), 
        .sending_pixels(sending_pixels_2), 
        .sample_pixel(sample_pixel_2),
        .pixel_index(pixel_index_1), 
        .pixel_data(screen1_data),
        .cs(JA[0]), 
        .sdin(JA[1]), 
        .sclk(JA[3]), 
        .d_cn(JA[4]), 
        .resn(JA[5]), 
        .vccen(JA[6]), 
        .pmoden(JA[7])
    );
    
endmodule