
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: sine_func (Synthesizable Replacement)
// Description: Generates sine wave using fixed-point Q1.14 lookup table.
// Compatible with Basys-3, no "real" or $sin used.
//////////////////////////////////////////////////////////////////////////////////
module sine_func(
    input  signed [7:0] a,      // amplitude in pixels
    input  [7:0] x,             // phase 0..255  ->  0..2?
    output reg signed [15:0] y  // signed pixel offset
);
    // Decode quadrant and index
    wire [1:0] q = x[7:6];
    wire [5:0] off = x[5:0];
    wire [5:0] mir = 6'd63 - off;

    wire signed [15:0] lut_q, lut_mir;
    sin_q14_lut_64 LUT0 (.idx(off), .val_q14(lut_q));
    sin_q14_lut_64 LUT1 (.idx(mir), .val_q14(lut_mir));

    reg signed [15:0] s_q14;
    always @* begin
        case (q)
            2'd0: s_q14 =  lut_q;    // 0..?/2
            2'd1: s_q14 =  lut_mir;  // ?/2..?
            2'd2: s_q14 = -lut_q;    // ?..3?/2
            2'd3: s_q14 = -lut_mir;  // 3?/2..2?
        endcase
        // Scale amplitude: (a * sin) >> 14
        y = ($signed({8'd0,a}) * s_q14) >>> 14;
    end
endmodule
