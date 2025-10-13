`timescale 1ns / 1ps
module linear_solver(
    input clk,
    input reset,
    input signed [10:0] a1, b1, c1,
    input signed [10:0] a2, b2, c2,
    output reg [2:0] solution_type,
    output reg signed [22:0] D, Dx, Dy
);

    reg signed [21:0] a1b2, a2b1, c1b2, c2b1, a1c2, a2c1;

    always @(posedge clk) begin
        if (reset) begin
            D <= 0; Dx <= 0; Dy <= 0;
            solution_type <= 0;
        end else begin
            a1b2 <= a1 * b2;
            a2b1 <= a2 * b1;
            c1b2 <= c1 * b2;
            c2b1 <= c2 * b1;
            a1c2 <= a1 * c2;
            a2c1 <= a2 * c1;

            D  <= a1b2 - a2b1;
            Dx <= c1b2 - c2b1;
            Dy <= a1c2 - a2c1;

            if ((a1b2 - a2b1) != 0) begin
                solution_type <= 0;
            end else begin
                if ((c1b2 - c2b1) == 0 && (a1c2 - a2c1) == 0) begin
                    solution_type <= 2;
                end else begin
                    solution_type <= 1;
                end
            end
        end
    end
endmodule