`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/30/2025 08:14:52 PM
// Design Name: 
// Module Name: freq_200
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


module freq_200(input clk, output reg slow_clk);  
    reg [9:0] ctr; //for declaration of the variable itself must do ooutside the inital block
    
    initial begin
        slow_clk = 0; //initalising the start value
        ctr = 0; //initalise the ctr value
    end
    
    always @ (posedge clk) begin
        if (ctr == 10'd999) begin
            slow_clk <= ~slow_clk;
            ctr <= 0;
        end else begin
            ctr <= ctr + 1;
        end
    end 
endmodule
