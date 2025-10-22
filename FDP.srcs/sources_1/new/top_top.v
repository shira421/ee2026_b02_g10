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
        .screen2_data(screen2_data)
    );
    
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