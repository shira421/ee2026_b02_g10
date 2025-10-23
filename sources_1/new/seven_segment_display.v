`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/30/2025 07:43:11 PM
// Design Name: 
// Module Name: seven_segment_display
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


module seven_segment_display(input clk, output reg [3:0] an, reg [7:0] seg);
    wire freq500;
    wire [1:0] ctr;
    freq_200 f0(clk, freq500);
    mod4counter f1(freq500, ctr);
    //implement a four mod counter that counts 0,1,2,3
    //each number corrspeonds to a state
    
    always@(*)begin
        case(ctr)
            2'b00: begin an <= 4'b0111; seg <= 8'b10010010; end
            2'b01: begin an <= 4'b1011; seg <= 8'b00100100; end
            2'b10: begin an <= 4'b1101; seg <= 8'b11111001; end
            2'b11: begin an <= 4'b1110; seg <= 8'b11000000; end
            default : begin an <= 4'b1111; seg <= 8'b11111111; end
        endcase
    end
endmodule

module mod4counter(input freq500, output reg [1:0] ctr);
    initial begin
        ctr = 2'b00;
    end
    
    always@(posedge freq500)begin
        ctr <= ctr + 1;
    end
endmodule
