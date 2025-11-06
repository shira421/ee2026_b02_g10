`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//this polynomial engine would take in the coefficients of each exponent and
// the return would be the the output y value
//////////////////////////////////////////////////////////////////////////////////

module polynomial_engine(
    input  signed [15:0] x,              // 16-bit signed input x
    input  signed [15:0] a0, a1, a2,    // 16-bit signed coefficients
    output signed [47:0] y              // 48-bit signed output
);

    wire signed [31:0] x2;

    // Compute powers of x
    assign x2 = x * x;        // x^2

    // Compute polynomial: y = a2*x^2 + a1*x + a0
    assign y = a2 * x2 + a1 * x + a0;

endmodule



