`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/30/2025 08:24:44 PM
// Design Name: 
// Module Name: top_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_module(
    input clk,
    input [15:12] sw,   // SW15-SW12
    input btnC, btnU, btnL, btnR, btnD,
    output [3:0] an,
    output [7:0] seg,
    output [7:0] JB
);


     assign an = 4'b1111;  // All anodes off
     assign seg = 8'b11111111;  // All segments off
    //connections for frequency clock
    wire freq625m, clk_25mhz;
    parameter m_25mhz = 1; 
    //connectiojns for the task_q
    wire [15:0] pixel_data_p,pixel_data_q, pixel_data_s;
    //connections for the multiplexer, i am just gonna place the multiplexer in the top
    wire [15:0] pixel_data_multiplexed;
    //connections for the oled_display
    wire [12:0] pixel_index;
    wire frame_begin, sending_pixels, sample_pixel;
    parameter m_6_25mhz = 7;
    //frequency clock function
//    freq_6_25m f0(clk, freq625m); //input is the native clock, output is 6.25Mhz signal to run the oled display

flexible_clock clock_6_25_mhz(.clk(clk), .m(m_6_25mhz), .slow_clock(freq625m));
flexible_clock clock_25mhz(.clk(clk), .m(m_25mhz), .slow_clock(clk_25mhz));
    
//    // Always running seven segment
//    seven_segment_display f1(clk, an, seg); //clk is the native clokc input
    
    //initiate the separate task here
//    task_p t0(clk, btnC, btnL, btnR, pixel_index, pixel_data_p);
//    task_q t1(clk, btnL, btnC, btnR, pixel_index, pixel_data_q);
    task_s t3(
    .clk(clk), 
    .clk_6_25mhz(freq625m),  // ADD THIS
    .btnU(btnU), 
    .btnL(btnL), 
    .btnR(btnR), 
    .btnD(btnD),  
    .pixel_index(pixel_index), 
    .oled_data(pixel_data_s)
);
    //clk is the native clock, btn are direct, pixel_index is the output of the display
    //pixel_data_q is the output of this module fed back to the oled_display function later
    
    assign pixel_data_multiplexed = sw[15] ? pixel_data_s : 16'b11111_111111_11111;
    
        Oled_Display f2(clk_25mhz, 0, frame_begin, sending_pixels, sample_pixel, 
                   pixel_index, pixel_data_multiplexed, JB[0], JB[1], JB[3], JB[4], JB[5], JB[6], JB[7]);
                   //freq625m comes from the clock above the next 4 on the same row not important
                   //pixel_index goes to the tasks and pixel_data goes into this module from the task
                   //that is the multiplexed part
endmodule