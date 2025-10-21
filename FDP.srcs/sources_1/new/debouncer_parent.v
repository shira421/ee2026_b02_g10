`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2025 01:02:45 AM
// Design Name: 
// Module Name: debouncer_parent
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


module debouncer_parent(
    input clk, btnC, btnU, btnL, btnR, btnD,
    output btnCD, btnUD, btnLD, btnRD, btnDD
    );
    
    debounce d0(clk, btnC, btnCD);
    debounce d1(clk, btnU, btnUD);
    debounce d2(clk, btnL, btnLD);
    debounce d3(clk, btnR, btnRD);
    debounce d4(clk, btnD, btnDD);
endmodule
