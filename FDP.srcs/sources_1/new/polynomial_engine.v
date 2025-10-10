`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//this polynomial engine would take in the coefficients of each exponent and
// the return would be the the output y value
//////////////////////////////////////////////////////////////////////////////////

module polynomial_engine(
    input signed [15:0] x,         // 16-bit signed input x
    input signed [15:0] a0, a1, a2, a3, a4, // 16-bit signed coefficients
    output signed [63:0] y         // 64-bit signed output
);

    wire signed [31:0] x2;
    wire signed [47:0] x3;
    wire signed [63:0] x4;

    // Compute powers of x
    assign x2 = x * x;        // x^2
    assign x3 = x2 * x;       // x^3
    assign x4 = x3 * x;       // x^4

    // Compute polynomial
    assign y = a4 * x4 + a3 * x3 + a2 * x2 + a1 * x + a0;

endmodule


