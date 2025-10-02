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

module sync_2ff (
    input clk,           // Destination clock (6.25 MHz)
    input async_in,      // Signal from source domain (100 MHz)
    output reg sync_out  // Safe synchronized output
);
    reg sync_ff1;  // First flip-flop
    
    always @(posedge clk) begin
        sync_ff1 <= async_in;  // First stage: may go metastable
        sync_out <= sync_ff1;  // Second stage: stable by now
    end
endmodule