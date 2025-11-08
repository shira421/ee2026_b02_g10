`timescale 1ns / 1ps

module subtract_function(input [16:0] num_1, num_2, output [19:0] num_3);
    assign num_3 = num_1 - num_2;
endmodule
