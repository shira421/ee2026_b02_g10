`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2025 04:28:23 PM
// Design Name: 
// Module Name: task_s
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


module task_s(
    input clk, 
    input clk_6_25mhz,  // ADD THIS
    input btnU, btnL, btnR, btnD, 
    input [12:0] pixel_index, 
    output [15:0] oled_data
);
    
    wire clk_move;
    wire signed [7:0] circle_x, circle_y;
    wire btnU_clean, btnD_clean, btnL_clean, btnR_clean;
    wire btnU_sync, btnD_sync, btnL_sync, btnR_sync;
    
    debounce dbU (.clk(clk), .pb_1(btnU), .pb_out(btnU_clean));
    debounce dbD (.clk(clk), .pb_1(btnD), .pb_out(btnD_clean));
    debounce dbL (.clk(clk), .pb_1(btnL), .pb_out(btnL_clean));
    debounce dbR (.clk(clk), .pb_1(btnR), .pb_out(btnR_clean));
    
    sync_2ff syncU (.clk(clk_6_25mhz), .async_in(btnU_clean), .sync_out(btnU_sync));
    sync_2ff syncD (.clk(clk_6_25mhz), .async_in(btnD_clean), .sync_out(btnD_sync));
    sync_2ff syncL (.clk(clk_6_25mhz), .async_in(btnL_clean), .sync_out(btnL_sync));
    sync_2ff syncR (.clk(clk_6_25mhz), .async_in(btnR_clean), .sync_out(btnR_sync));
    
    // REMOVE THIS
    // flexible_clock clock_6_25_mhz(.clk(clk), .m(m_6_25mhz), .slow_clock(clk_6_25mhz));
    
    flexible_clock clock_move (.clk(clk), .m(32'd1249999), .slow_clock(clk_move));
    
    wire [6:0] x = pixel_index % 96;
    wire [5:0] y = pixel_index / 96;
    
    CircleMover move(.clk(clk_6_25mhz), .move_tick(clk_move),
        .btnU(btnU_sync), .btnD(btnD_sync), .btnL(btnL_sync), .btnR(btnR_sync),
        .circle_x(circle_x), .circle_y(circle_y));
        
    draw_shapes draw(.clk_6_25mhz(clk_6_25mhz), .circle_x(circle_x), .circle_y(circle_y), 
                     .x(x), .y(y), .pixel_index(pixel_index), .oled_data(oled_data));
endmodule

