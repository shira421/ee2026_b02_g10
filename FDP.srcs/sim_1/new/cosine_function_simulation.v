`timescale 1ns / 1ps

module tb_cos_func;

    // Testbench signals
    reg [7:0] x;
    reg signed [7:0] k, c;
    wire signed [15:0] y;

    // Instantiate the DUT
    cosine_func dut (
        .x(x),
        .k(k),
        .c(c),
        .y(y)
    );

    initial begin
        // Test 1: k=1, c=0
        k = 8'sd1;
        c = 8'sd0;

        x = 8'd0;  #10; $display("x=%d, k=%d, c=%d, y=%d", x, k, c, y);
        x = 8'd64; #10; $display("x=%d, k=%d, c=%d, y=%d", x, k, c, y);
        x = 8'd128;#10; $display("x=%d, k=%d, c=%d, y=%d", x, k, c, y);
        x = 8'd192;#10; $display("x=%d, k=%d, c=%d, y=%d", x, k, c, y);

        // Test 2: k=2, c=1
        k = 8'sd2;
        c = 8'sd1;

        x = 8'd0;  #10; $display("x=%d, k=%d, c=%d, y=%d", x, k, c, y);
        x = 8'd64; #10; $display("x=%d, k=%d, c=%d, y=%d", x, k, c, y);
        x = 8'd128;#10; $display("x=%d, k=%d, c=%d, y=%d", x, k, c, y);
        x = 8'd192;#10; $display("x=%d, k=%d, c=%d, y=%d", x, k, c, y);

        // Finish simulation
        $stop;
    end

endmodule
