`timescale 1ns / 1ps

module divide_function(input [16:0] num_1, num_2, output [19:0] num_3);
    // Note: Division is complex in hardware. The '/' operator is synthesizable
    // but can consume significant resources. For this project, it's okay.
    // A check for division by zero should be handled by the user.
    assign num_3 = num_2 == 0 ? 0 : num_1 / num_2;
endmodule
