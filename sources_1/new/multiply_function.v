`timescale 1ns / 1ps

module multiply_function(input [16:0] num_1, num_2, output [19:0] num_3);
    // Note: For large numbers, this will infer a large multiplier.
    // For this project, 17x17 is acceptable for the FPGA.
    assign num_3 = num_1 * num_2;
endmodule
