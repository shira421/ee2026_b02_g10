`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2025 07:39:42 PM
// Design Name: 
// Module Name: task_q
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


module task_q(input clk, btnL, btnC, btnR, [12:0] pixel_index, output [15:0] pixel_data);
    //reduced clock frequency wire
    wire freq625m;
    //debounce buttons output
    wire btnLD, btnCD, btnRD;
    //colour identifier wires
    wire [2:0] box_0, box_1, box_2;
    wire num_state;
    
    freq_6_25m f0(clk, freq625m);
    debounce d0(clk, btnL, btnLD);
    debounce d1(clk, btnC, btnCD);
    debounce d2(clk, btnR, btnRD);
    
    colour_identifier f1(freq625m, btnLD, btnCD, btnRD, box_0, box_1, box_2, num_state);
    
    pixel_output_generator f2(freq625m, num_state, box_0, box_1, box_2, pixel_index, pixel_data);
endmodule
