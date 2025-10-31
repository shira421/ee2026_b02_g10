`timescale 1ns / 1ps

module tb_poly4;

    // Testbench signals
    reg signed [15:0] x;
    reg signed [15:0] a0, a1, a2, a3, a4;
    wire signed [63:0] y;

    // Instantiate the DUT
    polynomial_engine dut (
        .x(x),
        .a0(a0),
        .a1(a1),
        .a2(a2),
        .a3(a3),
        .a4(a4),
        .y(y)
    );

    initial begin
        // Initialize coefficients for example polynomial: y = 2x^4 - 3x^3 + x^2 + 4x - 5
        a4 = 16'sd2;
        a3 = -16'sd3;
        a2 = 16'sd1;
        a1 = 16'sd4;
        a0 = -16'sd5;

        // Test different x values
        x = 16'sd0;
        #10;
        $display("x=%d, y=%d", x, y);

        x = 16'sd1;
        #10;
        $display("x=%d, y=%d", x, y);

        x = -16'sd1;
        #10;
        $display("x=%d, y=%d", x, y);

        x = 16'sd2;
        #10;
        $display("x=%d, y=%d", x, y);

        x = -16'sd2;
        #10;
        $display("x=%d, y=%d", x, y);

        // Finish simulation
        $stop;
    end

endmodule




