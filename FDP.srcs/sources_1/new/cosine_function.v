////`timescale 1ns / 1ps

////module cosine_func(
////    input clk,                    // clock
////    input signed [7:0] a,         // amplitude coefficient
////    input [7:0] x,                // ? ADDED: x input
////    output reg signed [15:0] y    // cosine output
////);

////    // 256-entry LUT for cosine values scaled by 1000 (fixed-point)
////    reg signed [15:0] cos_lut [0:255];
////    integer i;
////    real angle_rad;

////    // Initialize cosine lookup table
////    initial begin
////        for (i = 0; i < 256; i = i + 1) begin
////            angle_rad = i * 2.0 * 3.14159265 / 256.0;
////            cos_lut[i] = $rtoi($cos(angle_rad) * 1000); // scale by 1000
////        end
////    end

////    // Compute y = a * cos(x)
////    always @(*) begin
////        y = a * cos_lut[x] / 10;  // divide to prevent overflow
////    end
////endmodule
//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Module: cosine_func (Synthesizable Replacement)
//// Description: Generates cosine wave using same Q1.14 LUT as sine_func.
//// Compatible with Basys-3 hardware.
////////////////////////////////////////////////////////////////////////////////////
//module cosine_func(
//    input  clk,                 // kept for interface compatibility
//    input  signed [7:0] a,      // amplitude in pixels
//    input  [7:0] x,             // phase 0..255
//    output reg signed [15:0] y
//);
//    // Decode quadrant and index
//    wire [1:0] q = x[7:6];
//    wire [5:0] off = x[5:0];
//    wire [5:0] mir = 6'd63 - off;

//    wire signed [15:0] lut_q, lut_mir;
//    sin_q14_lut_64 LUT0 (.idx(off), .val_q14(lut_q));
//    sin_q14_lut_64 LUT1 (.idx(mir), .val_q14(lut_mir));

//    reg signed [15:0] c_q14;
//    always @* begin
//        case (q)
//            2'd0: c_q14 =  lut_mir;  // cos starts at +1
//            2'd1: c_q14 = -lut_q;
//            2'd2: c_q14 = -lut_mir;
//            2'd3: c_q14 =  lut_q;
//        endcase
//        y = ($signed({8'd0,a}) * c_q14) >>> 14;
//    end
//endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: cosine_func (Synthesizable Replacement)
// Description: Generates cosine wave using same Q1.14 LUT as sine_func.
// Compatible with Basys-3 hardware.
//////////////////////////////////////////////////////////////////////////////////
module cosine_func(
    input  clk,                 // kept for interface compatibility
    input  signed [7:0] a,      // amplitude in pixels
    input  [7:0] x,             // phase 0..255
    output reg signed [15:0] y
);
    // Decode quadrant and index
    wire [1:0] q = x[7:6];
    wire [5:0] off = x[5:0];
    wire [5:0] mir = 6'd63 - off;

    wire signed [15:0] lut_q, lut_mir;
    sin_q14_lut_64 LUT0 (.idx(off), .val_q14(lut_q));
    sin_q14_lut_64 LUT1 (.idx(mir), .val_q14(lut_mir));

    reg signed [15:0] c_q14;
    always @* begin
        case (q)
            2'd0: c_q14 =  lut_mir;  // cos starts at +1
            2'd1: c_q14 = -lut_q;
            2'd2: c_q14 = -lut_mir;
            2'd3: c_q14 =  lut_q;
        endcase
        y = ($signed({8'd0,a}) * c_q14) >>> 14;
    end
endmodule

